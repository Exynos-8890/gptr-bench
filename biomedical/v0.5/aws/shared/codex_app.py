"""Native Codex conversation on one app-server, with finite one-shot Rscript jobs.

Only conversation text survives between requests. R state may be reused via files.
"""
import hashlib
import importlib.util
import json
import os
from pathlib import Path
import queue
import shutil
import subprocess
import threading
import time

import psutil

spec = importlib.util.spec_from_file_location("app_codex_policy", Path(__file__).with_name("codex_policy.py"))
policy = importlib.util.module_from_spec(spec)
spec.loader.exec_module(policy)


class ProtocolError(RuntimeError):
    pass


class Server:
    def __init__(self, config, directory, timeout, on_message, command=None):
        self.started = time.perf_counter()
        self.deadline = self.started + timeout
        self.config = config
        self.directory = directory
        self.on_message = on_message
        self.pending = queue.Queue()
        self.responses = {}
        self.completed = {}
        self.counter = 0
        self.peak = None
        self.scope = "process_tree"
        self.descendants = {}
        env = {k:v for k,v in os.environ.items() if k not in
               {"OPENAI_API_KEY", "CODEX_API_KEY", "CODEX_ACCESS_TOKEN", "OPENAI_BASE_URL"}}
        env.update(config.get("child_env", {}))
        env["GPTR_BENCH_REQUEST"] = "0"  # Persistent tools are aligned to requests by timestamps.
        # app-server0.165 has no exec --ignore-user-config equivalent. The current
        # AWS account has no config.toml; fail explicitly rather than silently
        # change the baseline through a user's personal configuration.
        home = Path(env.get("CODEX_HOME", str(Path.home()/".codex")))
        if command is None and env.get("GPTR_LIVE_TESTS")!="true":
            raise ProtocolError("Live app-server execution requires GPTR_LIVE_TESTS=true")
        if command is None and (home/"config.toml").exists():
            raise ProtocolError("Reproducible app-server baseline requires an account without config.toml; do not modify user config automatically")
        argv = command or ["codex", "-c", 'model_reasoning_effort="low"',
                           "app-server", "--listen", "stdio://"]
        self.stderr = (directory/"app-server.stderr.log").open("w")
        try:
            self.child = subprocess.Popen(argv, cwd=config["workspace"], env=env, text=True,
                stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=self.stderr,
                bufsize=1, start_new_session=True)
        except OSError:
            self.stderr.close()
            raise
        self.root = psutil.Process(self.child.pid)
        self.birth = self.root.create_time()
        self.reader = threading.Thread(target=self._drain, daemon=True)
        self.reader.start()

    def _drain(self):
        try:
            with (self.directory/"app-server.jsonl").open("w") as raw:
                for line in self.child.stdout:
                    elapsed = 1000*(time.perf_counter()-self.started)
                    raw.write(line);raw.flush()
                    try:
                        self.pending.put((elapsed,json.loads(line)))
                    except json.JSONDecodeError:
                        self.pending.put((elapsed,{"parse_error":"Non-JSON app-server stdout"}))
        finally:
            self.child.stdout.close()
            self.pending.put((0,None))

    def sample(self):
        try:
            children = self.root.children(recursive=True)
        except psutil.NoSuchProcess:
            return
        except (psutil.AccessDenied, PermissionError):
            children = []
            self.scope = "partial_process_tree"
        rss = 0
        observed = False
        for p in [self.root,*children]:
            try:
                self.descendants[p.pid] = p.create_time()
                rss += p.memory_info().rss
                observed = True
            except psutil.NoSuchProcess:
                pass
            except (psutil.AccessDenied, PermissionError):
                self.scope = "partial_process_tree"
        if observed:
            self.peak = max(self.peak or 0,rss)

    def send(self, message):
        with (self.directory/"app-server-client.jsonl").open("a") as stream:
            stream.write(json.dumps(message)+"\n")
        try:
            self.child.stdin.write(json.dumps(message)+"\n")
            self.child.stdin.flush()
        except (BrokenPipeError,OSError) as error:
            raise ProtocolError("App-server input closed") from error

    def pump(self):
        self.sample()
        if time.perf_counter() >= self.deadline:
            raise TimeoutError("Codex app-server run timeout")
        try:
            elapsed,event = self.pending.get(timeout=.05)
        except queue.Empty:
            if self.child.poll() is not None:
                raise ProtocolError("App-server exited before turn completed")
            return
        if event is None:
            raise ProtocolError("App-server output closed before turn completed")
        if "parse_error" in event:
            raise ProtocolError(event["parse_error"])
        self.on_message(elapsed,event)
        if event.get("method")=="turn/completed":
            turn = event["params"]["turn"]
            self.completed[turn["id"]] = turn
        if "id" in event and "method" not in event:
            self.responses[event["id"]] = event
        elif "id" in event and "method" in event:
            # Benchmark turns are sandboxed and noninteractive. Never approve an
            # unexpected privilege request or fabricate a dynamic tool result.
            raise ProtocolError("Unexpected app-server request: "+event["method"])

    def request(self, method, params):
        self.counter += 1
        ident = self.counter
        self.send(dict(id=ident,method=method,params=params))
        while ident not in self.responses:
            self.pump()
        response = self.responses.pop(ident)
        if "error" in response:
            raise ProtocolError(str(response["error"]))
        return response["result"]

    def close(self):
        started = time.monotonic()
        self.sample()
        try:
            self.child.stdin.close()
            self.child.wait(timeout=3)
        except (BrokenPipeError,OSError,subprocess.TimeoutExpired):
            pass
        # Some tool processes own separate process groups. Match PID births so
        # cleanup cannot accidentally terminate a reused PID or another run.
        targets = []
        for pid,birth in reversed(list(self.descendants.items())):
            try:
                p = psutil.Process(pid)
                if p.create_time()==birth and p.status() not in ("zombie","dead"):
                    targets.append((p,birth))
                    p.kill()
            except psutil.NoSuchProcess:
                pass
        if self.child.poll() is None:
            self.child.kill()
        self.child.wait()
        # SIGKILL delivery does not wait for exit or release a large R heap.
        # Do not return the machine to the next arm/reviewer while a matched
        # descendant still owns memory. A zombie has already released its heap.
        deadline = time.monotonic()+10
        remaining = []
        while True:
            remaining = []
            for p,birth in targets:
                try:
                    if p.is_running() and p.create_time()==birth and p.status() not in ("zombie","dead"):
                        remaining.append(dict(pid=p.pid,create_time=birth,rss=p.memory_info().rss))
                except psutil.NoSuchProcess:
                    pass
            if not remaining or time.monotonic()>=deadline:
                break
            time.sleep(.02)
        self.reader.join(timeout=3)
        self.stderr.close()
        (self.directory/"cleanup.json").write_text(json.dumps(dict(
            elapsed_seconds=time.monotonic()-started,matched_processes=len(targets),
            remaining=remaining,complete=not remaining),indent=2)+"\n")
        if remaining:
            raise ProtocolError("App-server descendants did not exit within cleanup deadline")


def capture(path, directory, thread):
    source = Path(path) if path else None
    if source is None or not source.is_file():
        records = dict(thread_id=thread,status="missing",original_path=path)
    else:
        dest = directory/"native-sessions"/source.name
        dest.parent.mkdir(exist_ok=True)
        with source.open("rb") as stream:
            checksum = hashlib.file_digest(stream,"sha256").hexdigest()
        shutil.copyfile(source,dest)
        records = dict(thread_id=thread,status="captured",original_path=str(source),
                       copied_path=str(dest),sha256=checksum)
    (directory/"native-capture.json").write_text(json.dumps(records,indent=2)+"\n")


def run(config, directory, timeout, command=None):
    prompts = json.loads(Path(config["prompt_file"]).read_text())[config["task_id"]]
    started = time.perf_counter()
    usage = {}
    status = "ok"
    current = 0
    completed_turns = 0
    thread_id = None
    native_path = None
    server = None
    error = None
    with (directory/"trace.jsonl").open("w") as trace:
        def emit(kind,data):
            trace.write(json.dumps(dict(schema_version=1,task=config["task_id"],arm="C1",
                turn=current,dataset_sha256=config["dataset_sha256"],
                time_ms=1000*(time.perf_counter()-started),type=kind,data=data))+"\n")
            trace.flush()
        def notification(elapsed,event):
            nonlocal usage
            emit("app_server_event",dict(server_time_ms=elapsed,message=event))
            if event.get("method")=="thread/tokenUsage/updated":
                usage = event["params"]["tokenUsage"]["total"]
        try:
            server = Server(config,directory,timeout,notification,command=command)
            server.request("initialize",dict(clientInfo=dict(name="gptr_bench",version="0.5.0"),
                                             capabilities=dict(experimentalApi=True)))
            server.send(dict(method="initialized",params={}))
            settings = server.request("thread/start",dict(cwd=config["workspace"],
                model=config["codex_model"],modelProvider="openai",sandbox="workspace-write",
                approvalPolicy="never",historyMode="legacy",experimentalRawEvents=True,
                developerInstructions=policy.INSTRUCTIONS,
                config={"model_reasoning_effort":"low"}))
            (directory/"thread-start.json").write_text(json.dumps(settings,indent=2)+"\n")
            thread_id = settings["thread"]["id"]
            native_path = settings["thread"].get("path")
            emit("thread.started",dict(thread_id=thread_id,transport="app-server"))
            for current,prompt in enumerate(prompts,1):
                emit("request_start",dict(unix=time.time(),prompt=prompt))
                turn_status = "error"
                try:
                    ack = server.request("turn/start",dict(threadId=thread_id,
                        input=[dict(type="text",text=prompt)],effort="low"))
                    turn_id = ack["turn"]["id"]
                    # Completion may arrive before its response acknowledgement.
                    while turn_id not in server.completed:
                        server.pump()
                    end = server.completed.pop(turn_id)
                    turn_status = "ok" if end["status"]=="completed" else "error"
                    if turn_status!="ok":
                        raise ProtocolError("Codex turn did not complete: "+end["status"])
                    audit = policy.audit_io(config.get("io_events"))
                    emit("r_execution_policy_check", audit)
                    (directory/f"r-execution-policy-{current}.json").write_text(json.dumps(audit,indent=2)+"\n")
                    if not audit["compliant"]:
                        turn_status = "error"
                        raise ProtocolError("C1 one-shot Rscript condition violated: "+"; ".join(audit["violations"]))
                    completed_turns += 1
                except TimeoutError:
                    turn_status = "timeout"
                    raise
                finally:
                    emit("request_end",dict(unix=time.time(),status=turn_status))
                if usage.get("inputTokens",0)+usage.get("outputTokens",0)>config["token_limit"]:
                    status = "budget"
                    break
        except TimeoutError as problem:
            status,error = "timeout",str(problem)
        except (ProtocolError, OSError, ValueError, KeyError) as problem:
            status,error = "error",str(problem)
        finally:
            if server is not None:
                try:
                    server.close()
                except ProtocolError as problem:
                    status,error = "error",str(problem)
    if error:
        (directory/"app-server-error.json").write_text(json.dumps(dict(status=status,error=error),indent=2)+"\n")
    if thread_id:
        capture(native_path,directory,thread_id)
    return [dict(status=status,total_wall_ms=1000*(time.perf_counter()-started),startup_ms=None,
        tool_calls=None,all_tool_calls=None,tool_counter_scope="native_session_audit_required",
        agent_turns=completed_turns,model_requests=None,provider_requests=None,
        input_tokens=usage.get("inputTokens"),cached_input_tokens=usage.get("cachedInputTokens"),
        output_tokens=usage.get("outputTokens"),reasoning_output_tokens=usage.get("reasoningOutputTokens"),cost=None,
        sampled_peak_rss_bytes=server.peak if server else None,
        memory_scope=server.scope if server and server.peak is not None else "unavailable",
        codex_transport="app-server",sampling_interval_seconds=.05,
        codex_r_execution_policy=policy.NAME,
        exit_code=0 if status in ("ok","budget") else 1)]
