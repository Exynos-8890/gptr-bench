# v0.4 execution contract

Plan version: **0.4.0-draft.6**. Updated (UTC): **2026-10-31T00:40:12Z**.

Implementation version: **0.4.0-dev.2**. The task manifest records the plan version and UTC update time.
The user has approved the authenticated Codex route and global installation of missing R dependencies.
**T01 remains held for a suitable host. The user has authorized real execution of T02–T10.**

## Scope and measurements

Ten real biomedical tasks live in `tasks/v04/t01.R` through `t10.R`. Each has three user requests,
18–24 substantive reference R blocks, explicit artifacts and a checker. `v04-tasks.json` is the
portable registry. The Chinese proposal adds the source investigation and data-size budgets.
Reference block counts are planning choices, not measured paper function-call counts.

A1 uses the actual gptr loop and a persistent R session. C1 uses authenticated Codex and ordinary
R scripts/files. Both use `gpt-6.1-sol`, with `low` pinned by a child-only CLI launcher. A2 drives
the real gptr loop with fake replies. C2 starts one R process per user request and restores only
declared dependencies; C3 executes the same reference blocks in one process. The old v0.3 runner,
data and results remain independently usable.

Full collection plans three independent A1/C1 trials per task, ten canonical repetitions for
A2/C2/C3, and ten fake replays per validated A1 trajectory: at most660 measured executions.
Validation and pilots are separate. Actual call counts may be lower than the reference plan.
Failed trials and incompatible captured traces remain recorded; fake input is produced only after
clean-state execution and scientific verification succeed.

## Input preparation

Preparers accept `SOURCE_DIR OUTPUT_DIR`; no formal source is simulated or duplicated. Preparation
downloads/caches public processed files, aligns genuine observations, saves a fully resident
uncompressed `input.rds`, and writes source URLs, byte counts, hashes, actual scale and selection rules
to `dataset.json`. QC, normalization, feature engineering, fitting and sensitivity analyses remain timed.

- T01 uses all975275 cells/36027 genes. It refuses insufficient available RAM and never treats the
  old100000-cell diagnostic subset as the full task. The scheduler requires a host with at least64GiB.
- T05 uses real BMI GCST006900 (Yengo2018, hg19 CHR/POS). GCST009004 was replaced because its
  original summary file lacks coordinates. The replacement's actual bytes and row count still need freezing.
- T08 never accepts a data-use agreement by default. If PDC requires acceptance, preparation stops;
  an operator must review and explicitly authorize the opt-in flag or provide authorized source data.
- T10 accepts the official original MTX/spatial archives. The current host received HTTP403;
  correctly named local source archives are supported, without substituting a different study.

## Recording and fairness

Initial loading is in total wall time; download/preparation, independent checking and report drawing
are outside it. Child-only wrappers record RDS start/end timestamps, filename, bytes, PID, request,
duration and success, including explicit `base::readRDS`. C1 uses a transparent instrumented Rscript
launcher. This is serialization/deserialization time, not pure disk transfer or physical device bytes.
Request, tool and loading spans overlap and must not be added. Timeline gaps are not pure thinking time.

`v04_report.py` exports per-trial `timeline.csv`, `timeline-notes.json` and a scientific PNG Gantt chart.
The outer sampler records process-tree RSS every20ms. Unknown CLI provider-request counts and dollar
charges remain unknown. Token ceilings are checked at request boundaries; unknown subscription cost
cannot be enforced as a measured dollar cap.

Concurrency is explicit (`--jobs`), bounded by an in-process RAM reservation budget, and recorded as
shared-host contention in manifests. Arms inside a task remain serial with alternating A1/C1 order.
Use `--jobs1` for uncontended latency measurements; parallel results are tagged accordingly.

Agent-facing JSON contains instructions and prompts, never reference steps. Instrumentation copied
into the workspace contains no answer algorithms. Reference scripts/checkers remain outside that
workspace. This is structural separation, not an adversarial OS read-isolation claim; pilot traces
must be inspected for reference access and launcher bypass before interpreting formal comparisons.

## Full-task time budget

T03 pilot1 exhausted1800seconds while request2 edgeR fitting was still running. Retain that
attempt as a timeout; remaining pilot1 work was interrupted for budget review. The next full T03
pilot and formal collection use14400seconds per arm, equally across all five arms. Keep the full
576-sample/60660-gene input, all three requests and the same methods. The successful full pilot
must be frozen before formal execution. Other tasks choose their budgets during their own pilots.

## Portable commands

Run from the repository root. Python needs `psutil`; R dependencies are listed by `setup-v04.R`.
That script installs nothing by default; `--install` is an explicit operator action. Keep the CLI
authenticated on the actual host. No credential files are copied, printed or placed in manifests.

```bash
Rscript --vanilla dev/bench/biomedical/setup-v04.R
python3 dev/bench/biomedical/v04.py preflight
# One task at a time; T01 remains deferred. T03 uses its revised full-task budget.
python3 dev/bench/biomedical/v04.py prepare --tasks T03
GPTR_LIVE_TESTS=true python3 dev/bench/biomedical/v04.py run --tasks T03 --live --phase pilot \
  --repeats 1 --replays 1 --jobs 1 --timeout 14400 --output /absolute/path/to/T03-pilot
python3 dev/bench/biomedical/v04.py freeze --tasks T03 \
  --pilot-output /absolute/path/to/T03-pilot --output /absolute/path/to/T03-freeze.json
GPTR_LIVE_TESTS=true python3 dev/bench/biomedical/v04.py run --tasks T03 --live --phase formal \
  --freeze /absolute/path/to/T03-freeze.json --repeats 3 --replays 10 \
  --jobs 1 --timeout 14400 --output /absolute/path/to/T03-formal
```

The freeze requires successful A1/C1 pilots, observable R execution/loading, all pilot checks passing,
and matching source/input identities. It retains observed function-call counts and actual RDS bytes.
The authors publish12–31 Turns on the leaderboard, not verified per-task raw function-call counts;
the resulting calibration must not be presented as exact replication of their call counts.

## Offline validation

```bash
Rscript --vanilla -e 'testthat::test_dir("dev/bench/biomedical/tests", stop_on_failure=TRUE)'
python3 -m unittest discover -s dev/bench/biomedical/tests -p 'test_*.py'
```

Fixtures are explicitly small test data, never formal benchmark inputs. Tests exercise scientific
invariants, deliberate numerical corruption, fresh-request serialization, fake-loop consumption,
RDS timing and public-task/reference separation. Restricted computer sandboxes may prevent processx
from initializing; run these offline child-process checks with normal host process permissions.

## Completion gates

Code and offline tests do not prove formal results. The currently authorized execution covers T02–T10;
T01 remains deferred for a suitable host. For each authorized task, prepare/freeze genuine input, inspect
full-task pilots and I/O coverage, complete planned real/canonical/compatible captured runs, retain
failures, and generate/open the measured report before the next task. Claim the complete ten-task suite
only after the separate T01 host hold is lifted and T01 has also passed these gates.

Change log: 2026-10-30T21:10:20Z — draft.4 authorizes T02–T10 preparation, pilots and real collection; T01 remains deferred.

Execution order amendment: one task at a time, T02 through T10, with --jobs 1. Briefly report each completed task before moving on. T01 remains deferred.

Change log: 2026-10-31T00:31:56Z — draft.5 records T03 pilot1 timeout and raises its equal per-arm budget to14400seconds; keeps complete real data and all methods/repetitions. Portable commands now show serial, per-task execution.

Change log: 2026-10-31T00:40:12Z — draft.6 / implementation dev.2 clarifies T03 gene-filter and analysis-audit CSV columns. Its checker accepts equivalent logical keep/retained flags and requires every source gene. Pilot2 was interrupted for this confirmed checker/protocol mismatch; retain its evidence and run a fresh complete pilot. The14400second budget and full data/methods remain in force.
