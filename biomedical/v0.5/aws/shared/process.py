"""Run Peter/Codex processes and record timing, usage and failures."""

import json
import os
from pathlib import Path
import signal
import subprocess
import threading
import time

import psutil


BENCH = Path(__file__).resolve().parents[3]
REPO = BENCH.parent
RUNNER = Path(__file__).resolve().parents[1] / "peter.R"


def write_json(path, value):
    path.write_text(json.dumps(value, indent=2) + "\n")



def measure(command, log_path, timeout, cwd=None, prompt=None, events=None, env=None):
    started = time.perf_counter()
    peak_rss = None
    memory_scope = "process_tree"
    status = "ok"
    with log_path.open("w") as log:
        process = subprocess.Popen(
            command, cwd=cwd, env=env, text=True, stdin=subprocess.PIPE if prompt else None,
            stdout=subprocess.PIPE if events is not None else log,
            stderr=log if events is not None else subprocess.STDOUT, start_new_session=True,
        )
        reader = None
        if events is not None:
            def drain():
                for line in process.stdout:
                    events.append((1000 * (time.perf_counter() - started), line))
                process.stdout.close()
            reader = threading.Thread(target=drain)
            reader.start()
        if prompt:
            process.stdin.write(prompt)
            process.stdin.close()
        root = psutil.Process(process.pid)
        while process.poll() is None:
            try:
                children = root.children(recursive=True)
                rss = sum(p.memory_info().rss for p in [root, *children])
                peak_rss = max(peak_rss or 0, rss)
            except psutil.NoSuchProcess:
                pass
            except (psutil.AccessDenied, PermissionError):
                memory_scope = "partial_process_tree"
            if time.perf_counter() - started > timeout:
                for child in root.children(recursive=True):
                    try:
                        child.kill()
                    except psutil.NoSuchProcess:
                        pass
                os.killpg(process.pid, signal.SIGKILL)
                process.wait()
                status = "timeout"
                break
            time.sleep(0.02)
        if reader:
            reader.join()
    wall_ms = 1000 * (time.perf_counter() - started)
    if process.returncode and status == "ok":
        status = "error"
    if peak_rss is None:
        memory_scope = "unavailable"
    return {"status": status, "total_wall_ms": wall_ms,
            "sampled_peak_rss_bytes": peak_rss, "memory_scope": memory_scope,
            "exit_code": process.returncode}


def execute(config, directory, timeout):
    request = directory / f"request-{config.get('step', 0)}.json"
    ready = request.with_suffix(".ready.json")
    result_path = request.with_suffix(".result.json")
    write_json(request, {"gptr_source": str(Path(os.environ["GPTR_SOURCE"]).resolve()),
                         "aws": str(RUNNER.parent), **config, "ready": str(ready),
                         "result": str(result_path)})
    started_unix = time.time()
    measured = measure(["Rscript", "--vanilla", str(RUNNER), "execute", str(request)],
                       request.with_suffix(".log"), timeout,
                       env={**os.environ, **config.get("child_env", {})})
    result = json.loads(result_path.read_text()) if result_path.exists() else {}
    if result.get("budget_exceeded"):
        measured["status"] = "budget"
    startup_ms = (1000 * (json.loads(ready.read_text())["unix"] - started_unix)
                  if ready.exists() else None)
    return {**result, **measured, "startup_ms": startup_ms}


def codex_run(config, directory, timeout):
    prompts = json.loads(Path(config["prompt_file"]).read_text())[config["task_id"]]
    session = None
    results = []
    cumulative_usage = {}
    started = time.perf_counter()
    tools = 0
    env = {key: value for key, value in os.environ.items() if key not in
           {"OPENAI_API_KEY", "CODEX_API_KEY", "CODEX_ACCESS_TOKEN", "OPENAI_BASE_URL"}}
    env.update(config.get("child_env", {}))
    with (directory / "trace.jsonl").open("w") as trace:
        for turn, prompt in enumerate(prompts, 1):
            env["GPTR_BENCH_REQUEST"] = str(turn)
            if config.get("io_events"):
                trace.write(json.dumps(dict(schema_version=1, task=config["task_id"], arm="C1",
                    turn=turn, dataset_sha256=config["dataset_sha256"],
                    time_ms=1000 * (time.perf_counter() - started), type="request_start",
                    data=dict(unix=time.time(), prompt=prompt))) + "\n")
                trace.flush()
            command = ["codex", "exec"]
            if session:
                command += ["resume", session]
            command += ["--json", "--ignore-user-config", "--ignore-rules",
                        "--skip-git-repo-check", "-m", config["codex_model"]]
            command += (["-c", 'sandbox_mode="workspace-write"'] if session else
                        ["--sandbox", "workspace-write"])
            command += ["-"]
            events = []
            offset = 1000 * (time.perf_counter() - started)
            measured = measure(command, directory / f"turn-{turn}.log",
                               timeout - (time.perf_counter() - started),
                               cwd=config["workspace"], prompt=prompt, events=events, env=env)
            results.append(measured)
            raw = directory / f"turn-{turn}.jsonl"
            raw.write_text("".join(line for _, line in events))
            completed = False
            for elapsed, line in events:
                event = json.loads(line)
                record = {"schema_version": 1, "task": config["task_id"], "arm": "C1", "turn": turn,
                          "dataset_sha256": config["dataset_sha256"],
                          "time_ms": offset + elapsed, "type": event["type"], "data": event}
                trace.write(json.dumps(record) + "\n")
                if event["type"] == "thread.started":
                    session = event["thread_id"]
                if event["type"] == "turn.completed":
                    completed = True
                    # Codex reports thread running totals, including after exec resume.
                    cumulative_usage = event.get("usage", {})
                if event["type"] == "item.completed":
                    tools += int(event.get("item", {}).get("type") in
                                 {"command_execution", "mcp_tool_call", "file_change", "web_search",
                                  "collab_tool_call"})
            if config.get("io_events"):
                trace.write(json.dumps(dict(schema_version=1, task=config["task_id"], arm="C1",
                    turn=turn, dataset_sha256=config["dataset_sha256"],
                    time_ms=1000 * (time.perf_counter() - started), type="request_end",
                    data=dict(unix=time.time(), status=measured["status"] if completed else "error"))) + "\n")
            if measured["status"] != "ok" or not completed:
                measured["status"] = measured["status"] if measured["status"] != "ok" else "error"
                break
            if sum(cumulative_usage.get(k, 0) for k in ("input_tokens", "output_tokens")) > config["token_limit"]:
                measured["status"] = "budget"
                break
    rss = [r["sampled_peak_rss_bytes"] for r in results if r["sampled_peak_rss_bytes"] is not None]
    return [{"status": results[-1]["status"], "total_wall_ms": 1000 * (time.perf_counter() - started),
             "startup_ms": None, "tool_calls": tools, "all_tool_calls": tools,
             "agent_turns": None, "model_requests": None,
             "provider_requests": None, "input_tokens": cumulative_usage.get("input_tokens"),
             "output_tokens": cumulative_usage.get("output_tokens"), "cost": None,
             "sampled_peak_rss_bytes": max(rss) if rss else None,
             "memory_scope": "process_tree" if all(r["memory_scope"] == "process_tree" for r in results)
             else "unavailable", "exit_code": results[-1]["exit_code"]}]

