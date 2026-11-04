# Operator commands

Run from the independent repository root (`/data/gptr-bench` on the current AWS host).
Set `GPTR_SOURCE=/data/gptr` for the separate package checkout under test.
See [README.md](README.md) for output locations and review policy.

```bash
export GPTR_SOURCE=/absolute/path/to/gptr
b=biomedical/v0.5/aws
bash "$b/with-env.sh" python3 "$b/run.py" preflight
GPTR_LIVE_TESTS=true bash "$b/with-env.sh" python3 "$b/run.py" pilot
GPTR_LIVE_TESTS=true bash "$b/with-env.sh" python3 "$b/run.py" formal
```

Only A1/Peter and C1/Codex run. There is no `offline` benchmark command or automatic scientific checker.
After execution, review model-generated tables, plots, report and trace manually; execution success is not correctness.
For a detached run, apply the same command with `nohup` and redirect output to the chosen run log.

Offline developer tests (no real model requests):

```bash
bash "$b/with-env.sh" python3 -m unittest discover -s biomedical/v0.5/tests -p 'test_*.py'
```

## Required C1 R execution condition (dev.20)

All new experiments use one-shot native Rscript for C1, as explicitly requested
by the user. No interactive R, PTY R command loop, daemon, R server or retained R
heap is allowed. Each finite Rscript job exits before a request completes. Empty
polling of a finite job is allowed; sending R commands through stdin is not.
Later scripts may reuse completed files; the condition does not require reading
raw input when a completed derived file already supplies the requested analysis.

The ordinary Rscript launcher closes stdin, records unique program start/end
identities, and also handles `Rscript` on the C1 PATH. Interactive `R` is disabled
on that PATH. The native thread receives a recorded developer instruction and
workspace AGENTS.md with this execution condition; scientific user prompts are
still shared unchanged with A1. A request leaving an instrumented R process
running fails the condition. Audit native commands and generated scripts for
bypasses or services before accepting performance results.

The app-server may retain conversation text. This does not authorize a live R
process. Record `codex_r_execution_policy=one-shot-rscript`, instruction hash,
start/end events and per-request policy checks. Do not pool this condition with
the earlier unrestricted dev.18/19 runs. The in-flight dev.19 confirmation was
cancelled on the user's policy change, preserving its completed and partial runs.

## Latest T01 result and retained files

The published report measures dev.20, not the cleaned dev.21 source. Its source
manifest and archive remain in the ignored runs directory. Do not rewrite raw
records, recorded paths, hashes or collection-time pending review fields.
Postcollection review is recorded separately.

The final run used 450,000 real cells, standard gzip RDS, the frozen shared
prompts published in `../docs/t01-results-current/shared-prompts.json`,
`--first-arm C1 --timeout 1200 --token-limit 2000000`, and `R_MAX_VSIZE=10G`.
It ran C1-1, A1-1, A1-2, C1-2, C1-3, A1-3 serially. The local controller
and original source archive preserve its 12GiB start / 11GiB process-tree RSS /
3GiB available-memory guards. Do not substitute the default 150k input for
this measured profile. No experiment is started by rebuilding the report.

`experiments/t01-state-reuse/` retains only input preparation/read probes and
supervision helpers imported by that controller. The historical directory and
`storage-pilot.py` filename are retained for its recorded imports; the old
multi-storage CLI and unselected concise/matrix workloads are removed.
The old exec/resume transport is also removed; current C1 uses app-server with
finite one-shot Rscript only. Earlier protocols remain historical raw records.

To analyze a completed collection without model requests:

```bash
python3 biomedical/v0.5/aws/tools/analyze-state-reuse.py /path/to/run/formal
```

This writes derived accounting beside the raw records. Remaining wall time
includes model, network, startup and other tools; it is not pure reasoning time.
Use the native-session records to audit actual C1 calls, generated R scripts
and possible services/bypasses. Rscript completion events alone are not a
security boundary or a full scientific correctness check.

Public aggregate data, the exact shared prompt profile and report rebuild
instructions are in `../docs/t01-results-current/README.md`.
