"""Run Peter/Codex processes and record timing, usage and failures."""

import json
import importlib.util
import os
from pathlib import Path
import signal
import subprocess
import time

import psutil


BENCH = Path(__file__).resolve().parents[3]
REPO = BENCH.parent
RUNNER = Path(__file__).resolve().parents[1] / "peter.R"
spec = importlib.util.spec_from_file_location("bench_codex_policy", Path(__file__).with_name("codex_policy.py"))
codex_policy = importlib.util.module_from_spec(spec)
spec.loader.exec_module(codex_policy)


def write_json(path, value):
    path.write_text(json.dumps(value, indent=2) + "\n")



def measure(command, log_path, timeout, env=None):
    started = time.perf_counter()
    peak_rss = None
    memory_scope = "process_tree"
    status = "ok"
    with log_path.open("w") as log:
        process = subprocess.Popen(
            command, env=env, text=True, stdout=log,
            stderr=subprocess.STDOUT, start_new_session=True,
        )
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
    spec = importlib.util.spec_from_file_location("bench_codex_app", Path(__file__).with_name("codex_app.py"))
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module.run(config, directory, timeout)
