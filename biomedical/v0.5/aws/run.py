"""Serial biomedical execution: verify the input hash, run the task, retain results."""
import argparse
import csv
from datetime import datetime, timezone
import hashlib
import importlib.util
import json
import os
import platform
from pathlib import Path
import shutil
import subprocess
import sys


HERE = Path(__file__).resolve().parent
BENCH = HERE.parents[1]
REPO = BENCH.parent
CATALOG = json.loads((HERE / "config.json").read_text())
TASKS = CATALOG["tasks"]
THREADS = {k: "1" for k in ("OMP_NUM_THREADS", "OPENBLAS_NUM_THREADS",
                              "MKL_NUM_THREADS", "VECLIB_MAXIMUM_THREADS")}


def load(path, name):
    spec = importlib.util.spec_from_file_location(name, path)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


execution = load(HERE / "shared/execute.py", "bench_execution")
process = execution.process
inventory = load(HERE / "code.py", "v05_code")


def stamp():
    return datetime.now(timezone.utc).isoformat(timespec="seconds")


def digest(path):
    with Path(path).open("rb") as stream:
        return hashlib.file_digest(stream, "sha256").hexdigest()


def source_digest():
    content = inventory.manifest(REPO, "benchmark") + inventory.manifest(Path(os.environ["GPTR_SOURCE"]).resolve(), "gptr")
    return hashlib.sha256(content.encode()).hexdigest()


def require_live_permission(live):
    if live and os.environ.get("GPTR_LIVE_TESTS") != "true":
        raise ValueError("Real model execution requires GPTR_LIVE_TESTS=true")


def read_input(task, directory):
    data = json.loads((directory / "dataset.json").read_text())
    checksum = digest(directory / "input.rds")
    if checksum != data["input_sha256"]:
        raise ValueError("Input SHA256 differs from dataset.json")
    return data, checksum


def collect(config, output):
    task_id = config["task"]
    require_live_permission(True)
    source = Path(config["input_root"]) / task_id
    data, checksum = read_input(task_id, source)
    settings = dict(task_id=task_id, dataset_sha256=checksum,
        timeout=config["timeout"], token_limit=config["token_limit"],
        cost_limit=config["cost_limit"], model="codex/"+CATALOG["model"],
        codex_model=CATALOG["model"])
    manifest = dict(benchmark_version=CATALOG["version"], phase=config["phase"], task=task_id,
        real_repeats=3 if config["phase"] == "formal" else 1, timeout=config["timeout"],
        started_at=stamp(), model=CATALOG["model"], reasoning_effort="low", dataset=data,
        dataset_sha256=checksum, source_sha256=source_digest(), revision=execution.revision(),
        gptr_source=str(Path(os.environ["GPTR_SOURCE"]).resolve()),
        gptr_source_sha256=hashlib.sha256(inventory.manifest(Path(os.environ["GPTR_SOURCE"]).resolve(), "gptr").encode()).hexdigest(),
        platform=platform.platform(), python=platform.python_version(), threads=THREADS,
        budgets=dict(timeout=config["timeout"], tokens=config["token_limit"], cost=config["cost_limit"]),
        review_status="pending", codex_version=subprocess.check_output(["codex", "--version"], text=True).strip())
    process.write_json(output / "manifest.json", manifest)
    repeats = 1 if config["phase"] != "formal" else 3
    rows = []

    def save(row):
        rows.append(row)
        process.write_json(output / "results.json", rows)
        fields = list(dict.fromkeys(k for r in rows for k in r))
        with (output / "summary.csv").open("w", newline="") as handle:
            writer = csv.DictWriter(handle, fieldnames=fields)
            writer.writeheader()
            writer.writerows(rows)
        print(json.dumps(dict(arm=row["arm"], trial=row["trial"], status=row["status"])), flush=True)

    for trial in range(1, repeats + 1):
        for arm in (["A1", "C1"] if trial % 2 else ["C1", "A1"]):
            save(execution.run_arm(arm, trial, source, output, config["timeout"], settings))
    return int(any(r["status"] != "ok" for r in rows))


def prepare(config, output):
    task = config["task"]
    destination = Path(config["input_root"]) / task
    source = Path(config["source"])
    if config["action"] == "import":
        data, checksum = read_input(task, source)
        destination.mkdir(parents=True)
        shutil.copyfile(source / "input.rds", destination / "input.rds")
        data = {**data, "inherited_provenance_file": str(source / "dataset.json"), "input_sha256": checksum}
    else:
        source.mkdir(parents=True, exist_ok=True)
        if task in ("T01", "T05"):
            scope = str(config["cells"]) if task == "T01" else config["gwas_scope"]
            command = ["Rscript", "--vanilla", str(HERE / "tools/prepare-inputs.R"), task,
                       str(source), str(destination), scope]
        else:
            script = BENCH / TASKS[task]["prepare"]
            command = ([sys.executable, str(script)] if script.suffix == ".py" else
                       ["Rscript", "--vanilla", str(script)]) + [str(source), str(destination)]
        subprocess.run(command, cwd=REPO, check=True)
        data, checksum = read_input(task, destination)
    data.update(profile_version=CATALOG["version"], input_sha256=checksum)
    process.write_json(destination / "dataset.json", data)
    process.write_json(output / "prepared.json", dict(task=task, input=str(destination), sha256=checksum))
    return 0


def preflight(task, input_root):
    runtime = subprocess.run(["Rscript", "--vanilla", str(HERE / "shared/setup-v04.R")],
        cwd=REPO, text=True, capture_output=True, check=True)
    data, checksum = read_input(task, input_root / task)
    auth = subprocess.run(["codex", "login", "status"], capture_output=True)
    return dict(task=task, input_sha256=checksum,
        profile=data.get("profile"), runtime=runtime.stdout.strip(),
        codex=subprocess.check_output(["codex", "--version"], text=True).strip(),
        authenticated=auth.returncode == 0,
        gptr_source=str(Path(os.environ["GPTR_SOURCE"]).resolve()),
        gptr_source_sha256=hashlib.sha256(inventory.manifest(Path(os.environ["GPTR_SOURCE"]).resolve(), "gptr").encode()).hexdigest())


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("command", choices=["preflight", "prepare", "import", "pilot", "formal"])
    parser.add_argument("--task", choices=list(TASKS), default="T01")
    parser.add_argument("--input-root", type=Path, default=BENCH / "data/v05-150000")
    parser.add_argument("--source", type=Path)
    parser.add_argument("--output", type=Path)
    parser.add_argument("--timeout", type=float)
    parser.add_argument("--cells", type=int, default=150000)
    parser.add_argument("--gwas-scope", default="full")
    args = parser.parse_args()
    if args.command == "preflight":
        print(json.dumps(preflight(args.task, args.input_root.resolve()), indent=2))
        return 0
    output = (args.output or BENCH / "runs" / ("v05-" + args.command + "-" +
              datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%SZ"))).resolve()
    output.mkdir(parents=True)
    timeout = args.timeout or (14400 if args.task == "T03" else
        3600 if args.task in ("T01", "T04", "T05", "T07") else 1800)
    config = dict(action=args.command, phase=args.command, task=args.task,
        input_root=str(args.input_root.resolve()), source=str(args.source.resolve()) if args.source else None,
        cells=args.cells, gwas_scope=args.gwas_scope,
        timeout=timeout, token_limit=1000000, cost_limit=5)
    if args.command in ("prepare", "import"):
        return prepare(config, output)
    return collect(config, output)


if __name__ == "__main__":
    raise SystemExit(main())
