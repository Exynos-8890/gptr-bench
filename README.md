# GPT-R Bench

Independent benchmarks comparing GPT-R (Peter) and native Codex agent execution.
Active workflow: biomedical v0.5, shared prompts, A1/C1, three requests per run.
Reports prioritize elapsed time, actual tool calls, polling, recovery and data reuse.

## Run from this repository root

```bash
export GPTR_SOURCE=/absolute/path/to/gptr
b=biomedical/v0.5/aws
bash "$b/with-env.sh" python3 "$b/run.py" preflight --task T01
GPTR_LIVE_TESTS=true bash "$b/with-env.sh" python3 "$b/run.py" formal --task T01
```

`GPTR_SOURCE` selects the separate gptr source checkout under test. Peter loads that checkout.
No gptr source or credentials are copied into this repository. The repositories can be located
anywhere. Runs record the benchmark revision/source hash and external gptr source hash.
Codex must be authenticated. On a fresh Ubuntu host, run
`bash biomedical/v0.5/aws/setup-linux.sh` to install dependencies into `.runtime/`.
See the [runbook](biomedical/v0.5/aws/RUNBOOK.md) for data preparation and import.

## Layout

- `biomedical/v0.5/aws/`: canonical runtime, prompts and data preparation.
- `biomedical/v0.5/tests/`: offline tests, including Peter with a fake provider.
- `biomedical/v0.5/docs/`: latest experiment report and per-call explanation.
- `biomedical/data/`, `biomedical/runs/`: local data and raw records; ignored by Git.
- `biomedical/v0.2` through `v0.6`: historical results, plans and future design material.
- `.runtime/`: local dependencies, ignored by Git.

Historical documents and raw logs retain their original paths and provenance. Their old commands
are historical; use the current runbook. Execution status does not certify biomedical correctness.

## Verify

```bash
export GPTR_SOURCE=/absolute/path/to/gptr
b=biomedical/v0.5/aws
bash "$b/with-env.sh" python3 -m unittest discover -s biomedical/v0.5/tests -p 'test_*.py'
bash "$b/with-env.sh" Rscript --vanilla -e 'library(testthat); source("biomedical/v0.5/tests/test-prepare.R"); source("biomedical/v0.5/tests/test-capacity.R")'
python3 "$b/code.py" benchmark
python3 "$b/code.py" gptr
```

## Origin and license

Extracted from `gptr/dev/bench/biomedical` at commit `939eed5ac9305ee43cc8d61dc8b0206bd8972a61`.
This repository starts with a snapshot; previous Git history remains in gptr.
Local documents and untracked artifacts are retained. Two already-broken task-catalogue aliases
were removed; historical reference files remain under `biomedical/v0.5/reference/`.

[Apache License 2.0](LICENSE.md). Original dataset licenses and source notices still apply.
