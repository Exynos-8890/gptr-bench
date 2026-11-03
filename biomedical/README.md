> Now maintained in **gptr-bench**. Use the [root README](../README.md) and [v0.5 runbook](v0.5/aws/RUNBOOK.md). Version notes below are historical.

# Biomedical workflow benchmark

Benchmark 1 compares gptr's persistent R workflow with Codex and Rscript execution.
See [the v0.3 plan](v0.3/plan.md) for the five arms, measurements and interpretation.
The clinical MVP implements and verifies all five arms. v0.3 completes 66 valid executions on real GSE236581 single-cell inputs. See [the initial results](reports/README.md).
All new real runs explicitly use GPT 6.1 Sol (`gpt-6.1-sol`); historical v0.2 results retain their original model.

## Version directory index

Directory layout revision: **1**, updated UTC: **2026-10-31T06:24:20Z**.
This is a navigation-only change. Scientific plan versions, dataset bytes and frozen run records
are unchanged. Start with the relevant version directory rather than the legacy filenames below.

| Version | Purpose and current status | Entry point |
|---|---|---|
| v0.2 | Historical clinical pilot and synthetic size check | [v0.2/](v0.2/README.md) |
| v0.3 | Completed real single-cell experiment; 100,000 cells, 66 valid executions | [v0.3/](v0.3/README.md) |
| v0.4 | Ten-task suite; T02 collected, T03 interrupted; execution paused | [v0.4/](v0.4/README.md) |
| v0.5 | First ten real tasks; data/code prepared, new AWS experiment pending | [Current comprehensive report](v0.5/docs/REPORT.zh-CN.html) · [Code directory](v0.5/README.md) |
| v0.6 | Thirty-task design: ten inherited plus twenty proposed additions | [v0.6/](v0.6/README.md) |

Each directory owns its plans, registries and version-specific documents. `docs/` holds local
Chinese reports and their figures; the repository-wide `*.zh-CN.*` rule excludes them from Git.
Reviewed portable results live in the version's `results/` directory. The superseded AWS study
belongs to `v0.4/aws/`; the current16GiB selection is in v0.5 and the thirty-task proposal is in v0.6.

Execution code, `tasks/`, `tests/`, ignored `data/` and ignored `runs/` retain their shared paths.
Version directories group experimental protocols and evidence, not independent code checkouts;
use the source revision recorded in each manifest to recover the corresponding implementation.
The old plan/registry filenames and reviewed-result directories are relative symlinks to the
canonical version files. Keep those compatibility links: runners, frozen hashes and historical
commands still use them. JSON task-module and preparation paths remain relative to this benchmark
root, rather than the directory containing the registry. Historical evidence retains original paths.

## v0.4 ten-task suite

The ten-task implementation uses [v04.py](v04.py), the portable [task registry](v0.4/tasks.json),
ten preparation scripts and `tasks/v04/`. Read [the execution contract](v0.4/plan.md) for the
scientific scope, host requirements, pilot/freeze/formal commands and validation gates.
Python >=3.11 with `psutil`, R and an authenticated Codex CLI are required. `setup-v04.R` checks
R dependencies; it installs nothing unless the operator explicitly supplies `--install`.

Real v0.4 execution is paused at the user's request. v0.5 now targets16GiB and restores scientific input where feasible; v0.6 proposes thirty tasks.
The checks below are offline. The legacy v0.3 commands and historical results remain available.

```bash
python3 dev/bench/biomedical/v04.py preflight
Rscript --vanilla -e 'testthat::test_dir("dev/bench/biomedical/tests", stop_on_failure=TRUE)'
python3 -m unittest discover -s dev/bench/biomedical/tests -p 'test_*.py'
```

The first implementation slice is one clinical workflow with at least three requests:
cohort QC, survival analysis, then a covariate or subgroup revision.
Use `survival::veteran` for the smoke test; add a declared synthetic size tier for performance.

Run from the repository root on macOS or Linux. Development requirements are Python 3 with `psutil`, R with the
package Imports, `pkgload`, `withr` and `survival`. Live runs also need an authenticated Codex CLI.
Nothing installs dependencies or reads `.secrets/`.

```bash
# Offline: canonical computations through the real fake-provider loop, RDS steps and one R process.
python3 dev/bench/biomedical/run.py

# The five arms once, explicitly using gpt-6.1-sol.
GPTR_LIVE_TESTS=true python3 dev/bench/biomedical/run.py --live

# Pilot repetitions: three real trials per agent, ten canonical/trajectory replays.
GPTR_LIVE_TESTS=true python3 dev/bench/biomedical/run.py --live --repeats 3 --replays 10

# An explicitly synthetic performance cohort; smoke data is never a large-data speed claim.
python3 dev/bench/biomedical/run.py --rows 100000 --repeats 10

# Validate a saved gptr trace from a smoke run, then replay it through the fake provider.
python3 dev/bench/biomedical/run.py --arms A2 --replay /path/to/A1-1/trace.jsonl
```

Use `--output` for a new result directory. Each run retains its external temporary task workspace
and writes `manifest.json`, environment versions, traces, correctness checks, `summary.csv`,
`report.md` and `wall-time.svg`. Its manifest identifies the input checksum, revision and source
digest. Startup and initial loading are included in total wall time. Evaluators run afterward.

The default timeout is 900 seconds per task, the token ceiling is 1,000,000 and the nominal cost
ceiling is USD 5 (`--timeout`, `--token-limit`, `--cost-limit`). Codex usage can be incomplete and
subscription cost is unknown; token checks happen at turn boundaries, and unknown cost cannot
be enforced as a dollar ceiling. Both agents use the CLI model's default reasoning setting.
`--model` can explicitly pin a different Codex model id.

A successful A1 run is additionally validated in a clean R process before conversion and A2
replay. The Codex route exposes executed R calls through MCP rather than native assistant tool
blocks; its fake trajectory explicitly marks synthetic request grouping. It reproduces observed
R work through gptr's real loop, not Codex's internal model-request boundaries. C1 preserves
native CLI commands and outputs and is explicitly non-replayable by this minimal converter.
C2/C3 always use the declared canonical computations.

The synthetic cohort uses seed 20261027, balanced treatment assignment, a clipped normal age
distribution and Karnofsky values from 30 to 100. Event times are exponential with hazard
`0.01 * exp(0.15 * (trt - 1) + 0.02 * (age - 60) - 0.025 * (karno - 60))`; censoring times are
independent exponential draws at rate 0.004. See [the task](tasks/clinical.R).


## v0.3 real single-cell workflow

Reviewed results: [100,000 real cells, five arms](v0.3/results/report.md).

[GSE236581](https://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=GSE236581) provides 36,027 genes,
975,275 cells and 169 samples from a real longitudinal study. Download the four public processed
files from the [GEO directory](https://ftp.ncbi.nlm.nih.gov/geo/series/GSE236nnn/GSE236581/suppl/):
`GSE236581_counts.mtx.gz`, `GSE236581_barcodes.tsv.gz`, `GSE236581_features.tsv.gz` and
`GSE236581_CRC-ICB_metadata.txt.gz`. Keep them together in `data/gse236581/`.
Preparation additionally uses the installed development packages `Matrix` and `openssl`.

```bash
Rscript --vanilla dev/bench/biomedical/prepare-single-cell.R \
  dev/bench/biomedical/data/gse236581 dev/bench/biomedical/data/gse236581-100000 100000

# Validate the three canonical execution paths on the prepared real input.
python3 dev/bench/biomedical/run.py --task single-cell \
  --input dev/bench/biomedical/data/gse236581-100000/input.rds --timeout 1800

# Three real trials per agent, ten canonical and captured-trajectory replays.
GPTR_LIVE_TESTS=true python3 dev/bench/biomedical/run.py --task single-cell \
  --input dev/bench/biomedical/data/gse236581-100000/input.rds \
  --live --model gpt-6.1-sol --repeats 3 --replays 10 --timeout 1800 \
  --output dev/bench/biomedical/runs/gse236581-v0.3
```

Preparation streams all source entries, verifies matrix dimensions/order and metadata alignment,
keeps a deterministic spread of original cells and all genes, and writes a fully resident sparse
input plus `dataset.json` and the exact `barcodes.tsv`. It neither simulates counts nor duplicates
cells. `dataset.json` stores source SHA-256, original/selected dimensions and selection rule.
The raw count download is 4,232,498,668 bytes; that is distinct from the prepared RDS size.
A full-matrix run needs a separate memory preflight: nonzero arrays alone require about 15.7 GB,
before temporary buffers, model processes and independent evaluation. The 100,000-cell tier
is explicitly a real subset, not a measurement of the full 975,275-cell cohort.

Requests calculate per-cell QC from counts, aggregate all-gene expression by patient/tissue/time,
then revise UMI/detected-gene thresholds and recompute. The eight marker outputs are CD3D,
CD3E, CD8A, MS4A1, LYZ, NKG7, EPCAM and COL1A1. Outputs are `qc.csv`, `cell-qc.csv`,
`baseline.csv` and `revised.csv`. Empty groups remain in the expression tables with zeros.
The independent evaluator sums marker rows and cell totals rather than repeating the canonical
all-gene matrix multiplication. This validates the adapted analysis, not the original paper's
clinical conclusions. No response labels are inferred from metadata that lacks them.

New manifests record plan version/UTC timestamp, task, dataset provenance, source revision/digest,
model, environment, measured scope and usage. The isolated A1 child supplements gptr's older
CLI model catalog with an explicit `codex/gpt-6.1-sol` model spec; package code, user configuration
and the global model default are not changed. Both routes invoke the same explicit model id.

Execution checklist:

- [x] Pin the gptr revision, R/package environment, Codex version and model settings.
- [x] Define prompts, input state, required artifacts, numerical tolerances and random seed.
- [x] Set the initial-load timing boundary, timeout and token/cost ceilings before execution.
- [x] Create isolated task workspaces outside the repository; keep evaluators and answers outside
      agent-accessible files. Continue the same agent session across a task's requests.
- [x] Run and validate one A1 and C1 trajectory; validate captured R execution before converting
      compatible gptr responses into a fake-provider script.
- [x] Run A2, C2 and C3 on the canonical computations and check equivalent required artifacts.
      Check fake-script consumption and allow no live provider calls during replay.
- [x] Export a five-arm summary with status, wall time, available usage and memory measurements.
- [x] Collect three real trials per agent and ten replays per valid trajectory; alternate real-agent
      order, run arms serially, and retain failures and their consumed time.

Permission checks and normal harness work stay in gptr's measured cost. The pilot assumes the
selected state is RDS-restorable. More detailed attribution, broader state support, larger samples
and domain expansion follow the first results.

Keep downloaded/generated inputs in ignored `data/` and raw traces/output in ignored `runs/`.
Commit source and reviewed summaries; keep machine-specific inventory in `dev/LOCAL_SETUP.md`.
Real runs use `GPTR_LIVE_TESTS=true`; preparation and offline replay need no paid model calls.
Python and biomedical development dependencies do not enter the package Imports.

Tool counts reflect each interface: A1/A2 count R calls, C1 counts native CLI tools, and C2/C3
count canonical steps. The three reviewed A1 trajectories in `reports/clinical-pilot/` can be
supplied to `--replay`; complete raw run records remain ignored.

Offline checks:

```bash
Rscript --vanilla -e 'testthat::test_dir("dev/bench/biomedical/tests", stop_on_failure = TRUE)'
python3 -m unittest discover -s dev/bench/biomedical/tests -p 'test_*.py'
```

These checks launch R children. The host must permit processx supervision; a restricted computer
sandbox can prevent its initialization. RSS sampling reports unknown when the host denies it.
