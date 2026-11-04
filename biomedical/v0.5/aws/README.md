# Live biomedical benchmark

Current policy: run Peter (A1) and native Codex (C1) on the same three user prompts.
Review the produced data, statistics, figures and claims manually with Codex afterward.
`status=ok` means execution completed; `review_status=pending` means correctness has not been reviewed.

C1 uses native Codex with finite one-shot Rscript processes (dev.20 user requirement).
Every R execution exits; no interactive R, PTY R loop, service or live R heap reuse
is allowed. Completed files may be read by later scripts. The app-server retains
conversation text only. Shared scientific user prompts stay identical across arms;
the C1 execution condition is recorded separately. Historical dev.18/19 permitted
live R retention and are not pooled with this condition. See the [runbook](RUNBOOK.md).

## Files

```
run.py                prepare/import, preflight, pilot, formal
peter.R               load raw; call peter for the three prompts; record events
prompts.json          shared user messages for T01–T10
config.json           model and input preparation script names
source-hashes.json    pinned T01 source hashes
shared/               process execution and timing/I/O recording
prepare/, tools/      download and prepare data
setup-linux.sh        install dependencies
with-env.sh           select runtime and one numerical thread
code.py, links.tsv    source identity and preparation compatibility paths
```

The AWS tree has no task reference answers, scoring modules, canonical A2/C2/C3 runs,
or automatic captured-trajectory replay. Local historical material is in `../reference/`
and is excluded from deployment. Prompt text and data preparation still cover T01–T10.
Native R document replay is not part of this simplified runner yet; raw execution traces are retained.

## Run

From the independent repository root (`/data/gptr-bench` on AWS), with `GPTR_SOURCE=/data/gptr`:

```bash
b=biomedical/v0.5/aws
bash "$b/with-env.sh" python3 "$b/run.py" preflight
GPTR_LIVE_TESTS=true bash "$b/with-env.sh" python3 "$b/run.py" pilot
GPTR_LIVE_TESTS=true bash "$b/with-env.sh" python3 "$b/run.py" formal
```

T01 and `data/v05-150000` are the defaults. `pilot` runs each live arm once; `formal`
runs each three times, alternating arm order between repetitions. Both require the explicit
live environment variable. This code change itself does not launch a real model experiment.
`--task`, `--input-root`, `--output` and `--timeout` select other inputs and destinations.
`--prompt-file` freezes a shared experimental profile into the run directory before either arm;
the manifest records its SHA256. `--first-arm C1` reverses the alternating arm order.
Default scientific prompts are unchanged. The final 450k experiment used the frozen
profile published with the report. Input/read probes and collection support remain
under `experiments/t01-state-reuse/`; unused workload variants and the historical
exec/resume transport have been removed. See RUNBOOK.md for the measured settings.

Results are under `runs/v05-.../A1-1/` or `C1-1/`: `trace.jsonl`, logs, usage,
`result.json`, and `workspace/` containing the model's scripts, tables, figures and report.
The copied input is removed after execution; the original input and its manifest remain.
There is no automatic scientific pass/fail or aggregate scientific score.

## Prepare

```bash
bash "$b/with-env.sh" python3 "$b/run.py" prepare --task T01 --source /path/to/source
bash "$b/with-env.sh" python3 "$b/run.py" import --task T02 --source /path/to/prepared/T02
```

T01 verifies four source SHA256 values before conversion and records the output RDS hash.
Run/import verify the prepared input hash. Other preparation adapters retain their own provenance.
No data is regenerated unless preparation is explicitly invoked.

## Manual review

Inspect the shared prompt, input scope, generated code, logs and all artifacts together.
Check numerical quantities and statistical units against the supplied data, and recompute
important results where needed. Inspect plots for meaningful encodings, axes, labels and
consistency with tables; do not require a fixed visual template. Check reported uncertainty
and claims against the analysis. Save the review with evidence and unresolved issues in the
run directory. Missing/error runs remain visible. Until this review occurs, leave results pending.

## Environment and identity

`bash "$b/setup-linux.sh"` installs a new Linux environment. Existing AWS dependencies are reused.
`python3 "$b/code.py" benchmark` inventories deployment code; `gptr` inventories the package separately.
Data, results, local HTML and historical reference material are outside that inventory.
