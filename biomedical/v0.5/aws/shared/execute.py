"""Run the two live arms; retain artifacts and traces for manual scientific review."""
import time
import importlib.util
import json
import os
from pathlib import Path
import shutil
import subprocess


BENCH = Path(__file__).resolve().parents[3]
REPO = BENCH.parent
spec = importlib.util.spec_from_file_location("bench_process", Path(__file__).with_name("process.py"))
process = importlib.util.module_from_spec(spec)
spec.loader.exec_module(process)


def launchers(directory, runtime=None, one_shot=False):
    """Pin reasoning in children without editing user config or package internals."""
    directory.mkdir(parents=True, exist_ok=True)
    codex = shutil.which("codex")
    if codex:
        text = ("#!/usr/bin/env python3\nimport os,sys\n"
                "args=sys.argv[1:]\n"
                "if args and args[0]=='exec':\n"
                " if '--ignore-rules' not in args: args.insert(len(args)-1,'--ignore-rules')\n"
                " args=['-c','model_reasoning_effort=\"low\"']+args\n"
                "os.execv(os.environ['GPTR_BENCH_CODEX_REAL'],"
                "[os.environ['GPTR_BENCH_CODEX_REAL'],*args])\n")
        (directory / "codex").write_text(text)
        (directory / "codex").chmod(0o700)
    rscript = shutil.which("Rscript")
    runtime = directory if runtime is None else runtime
    runtime.mkdir(parents=True, exist_ok=True)
    for name in ("io.R", "io-bootstrap.R"):
        shutil.copyfile(Path(__file__).with_name(name), runtime / name)
    script = (
        "#!/usr/bin/env python3\nimport os,sys,uuid\n"
        "args=[a for a in sys.argv[1:] if a!='--vanilla']\n"
        "if len(args)>=2 and args[0]=='-e':\n"
        " mode='expression'; value=args[1]; rest=args[2:]\n"
        "elif args and not args[0].startswith('-'):\n"
        " mode='file'; value=args[0]; rest=args[1:]\n"
        "else:\n raise SystemExit('Use bench-rscript --vanilla FILE or -e EXPRESSION')\n"
        "os.environ['GPTR_BENCH_PROGRAM_MODE']=mode\n"
        "os.environ['GPTR_BENCH_PROGRAM']=value\n"
        "os.environ['GPTR_BENCH_PROGRAM_ID']=uuid.uuid4().hex\n"
        + ("fd=os.open(os.devnull,os.O_RDONLY)\nos.dup2(fd,0)\n"
           "if fd>2: os.close(fd)\n" if one_shot else "") +
        f"os.execv({rscript!r},[{rscript!r},'--vanilla',"
        f"{str(runtime / 'io-bootstrap.R')!r},*rest])\n"
    )
    (runtime / "bench-rscript").write_text(script)
    (runtime / "bench-rscript").chmod(0o700)
    if one_shot:
        # Standard Rscript on PATH gets the same recording and closed stdin.
        (directory / "Rscript").symlink_to(runtime / "bench-rscript")
        (directory / "R").write_text("#!/bin/sh\necho 'C1 requires a finite Rscript; interactive R is disabled.' >&2\nexit 64\n")
        (directory / "R").chmod(0o700)
    library = str(REPO / ".runtime/library")
    return {**{k: "1" for k in ("OMP_NUM_THREADS", "OPENBLAS_NUM_THREADS",
                               "MKL_NUM_THREADS", "VECLIB_MAXIMUM_THREADS")},
            "PATH": str(directory) + os.pathsep + os.environ.get("PATH", ""),
            "GPTR_BENCH_CODEX_REAL": codex or "",
            "R_LIBS_USER": library + os.pathsep + os.environ.get("R_LIBS_USER", ""),
            "GPTR_BENCH_IO_HELPER": str(runtime / "io.R")}


def run_arm(arm, trial, source, output, timeout, settings, prompt_file=None):
    directory = output / f"{arm}-{trial}"
    directory.mkdir()
    workspace = directory / "workspace"
    workspace.mkdir()
    shutil.copyfile(source / "input.rds", workspace / "input.rds")
    # Native Codex may write only inside its task workspace. Archive after it exits.
    io_path = workspace / "instrumentation" / "io.jsonl" if arm == "C1" else directory / "io.jsonl"
    env = launchers(directory / "launchers", workspace / "instrumentation", one_shot=arm == "C1")
    env["GPTR_BENCH_IO_EVENTS"] = str(io_path)
    if arm == "C1":
        (workspace / "AGENTS.md").write_text(process.codex_policy.INSTRUCTIONS + "\n")
    config = dict(arm=arm, workspace=str(workspace), input=str(workspace / "input.rds"),
                  private=str(directory / "private"), trace=str(directory / "trace.jsonl"),
                  prompt_file=str(prompt_file or Path(__file__).resolve().parents[1] / "prompts.json"),
                  io_events=str(io_path), child_env=env, **settings)
    started = time.perf_counter()
    started_unix = time.time()
    results = []
    if arm == "C1":
        results = process.codex_run(config, directory, timeout)
        if io_path.exists():
            shutil.copyfile(io_path, directory / "io.jsonl")
    else:
        results = [process.execute(config, directory, timeout)]
    row = dict(arm=arm, trial=trial, status=results[-1]["status"],
               total_wall_ms=1000 * (time.perf_counter() - started),
               run_started_unix=started_unix, run_finished_unix=time.time(),
               record_directory=str(directory),
               r_processes=len(results) if arm != "C1" else None,
               workspace=str(workspace), input_file_bytes=(workspace / "input.rds").stat().st_size)
    for key in ("startup_ms", "dataset_load_ms", "serialization_ms", "r_compute_ms",
                "tool_wall_ms", "tool_calls", "model_requests", "provider_requests",
                "input_tokens", "cached_input_tokens", "output_tokens", "reasoning_output_tokens", "cost"):
        values = [result.get(key) for result in results]
        row[key] = sum(values) if all(value is not None for value in values) else None
    rss = [result["sampled_peak_rss_bytes"] for result in results
           if result.get("sampled_peak_rss_bytes") is not None]
    row["sampled_peak_rss_bytes"] = max(rss) if rss else None
    row["memory_scope"] = ("process_tree" if all(result["memory_scope"] == "process_tree"
                                               for result in results) else "partial_or_unavailable")
    row["codex_transport"] = settings.get("codex_transport", "app-server") if arm == "C1" else None
    row["codex_r_execution_policy"] = process.codex_policy.NAME if arm == "C1" else None
    row["tool_counter_scope"] = "native_session_audit_required" if arm == "C1" else "Peter tool events"
    row["io_request_scope"] = "align by absolute timestamps; persistent child tag is 0" if arm == "C1" and row["codex_transport"] == "app-server" else "per-request tag"
    io = [json.loads(line) for line in io_path.read_text().splitlines()] if io_path.exists() else []
    original = [event for event in io if event["operation"] == "readRDS" and
                Path(event["file"]).resolve() == (workspace / "input.rds").resolve()]
    row.update(input_loads=len(original), input_load_ms=sum(e["duration_ms"] for e in original),
               logical_input_bytes=sum(e["bytes"] or 0 for e in original),
               io_coverage="events_recorded_not_independently_audited" if io else "unverified")
    row["r_execution_calls"] = (sum(event["operation"] == "rscript" for event in io)
                                 if arm == "C1" else row["tool_calls"])
    values = [result.get("all_tool_calls") for result in results]
    row["all_tool_calls"] = sum(values) if all(v is not None for v in values) else None
    turns = [result.get("agent_turns") for result in results]
    row["agent_turns"] = sum(turns) if all(v is not None for v in turns) else None
    row["input_load_attempts"] = len(original)
    row["input_loads"] = sum(event.get("success", True) for event in original)
    row["logical_input_bytes"] = sum(event["bytes"] or 0 for event in original
                                      if event.get("success", True))
    reads = [event for event in io if event["operation"] == "readRDS"]
    row["all_rds_read_attempts"] = len(reads)
    row["all_rds_read_ms"] = sum(event["duration_ms"] for event in reads)
    row["logical_all_rds_read_bytes"] = sum(event["bytes"] or 0 for event in reads
                                              if event.get("success", True))
    row["artifact_bytes"] = sum(path.stat().st_size for path in workspace.glob("*.csv"))
    row["review_status"] = "pending"
    process.write_json(directory / "result.json", dict(summary=row, processes=results))
    (workspace / "input.rds").unlink(missing_ok=True)
    return row


def revision():
    marker = REPO / "SOURCE-REVISION"
    if marker.exists():
        return marker.read_text().strip()
    result = subprocess.run(["git", "rev-parse", "HEAD"], cwd=REPO,
                            text=True, capture_output=True)
    return result.stdout.strip() if result.returncode == 0 else None
