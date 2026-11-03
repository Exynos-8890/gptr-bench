# Biomedical benchmark results

## v0.3: real GSE236581 single-cell data

[The reviewed v0.3 report](../v0.3/results/report.md) covers 100,000 real cells, all 36,027 genes
and a 1.64 GB fully resident sparse input. Both real arms explicitly use GPT 6.1 Sol.
All 66 formal executions pass: six real trials, thirty canonical repetitions and thirty fake
replays of three validated real trajectories. The 10,000-real-cell validation is reported separately.

Live medians are 61.851 s (A1) and 72.692 s (C1); canonical A2/C2/C3 medians are
11.991/10.358/5.116 s. Full-cohort capacity gating, original helper-compatibility rejections,
separately versioned supplementary replays, per-row provenance, byte-identical data preparation
and independent checks are documented in the report. No full 975,275-cell measurement is claimed.

## v0.2: historical clinical pilot

The agreed clinical MVP is implemented and verified. These exploratory results cover one
workflow, one host and the configured Codex model; expansion to other biomedical families
remains future work.

- [Clinical pilot: 137 rows](../v0.2/results/clinical-pilot/report.md): three real trials per agent, ten
  repetitions per canonical execution arm, and ten replays of each of three valid A1 trajectories.
- [Synthetic tier: 100,000 rows](../v0.2/results/clinical-synthetic-100000/report.md): one valid execution of
  each canonical offline arm, demonstrating the size parameter rather than estimating variance.

All 69 reported executions passed the independent artifact checks. A1's live median was
47.956 seconds and C1's was 69.019 seconds. On the small canonical task, A2/C2/C3 medians were
8.065/2.011/0.830 seconds; the synthetic executions took 8.117/2.562/1.512 seconds. The controlled
results do not demonstrate a gptr persistence advantage at these sizes. The real-agent timing
difference is a product-level observation from three trials, not an isolated causal estimate.

A1 uses gptr's configured `codex/default`, pinned to `codex/gpt-6-sol`, with its persistent R
bridge. C1 uses the same Codex CLI 0.165.0/model without the bridge. A2 uses the actual gptr loop
and fake provider; its CLI-derived trajectories mark synthetic model-request grouping. This
distinction matters when interpreting replay timing or request counts.

The real pilot was frozen at `2f88160e`; the synthetic run used `5c7f7339`, which additionally
forces offline mode for plain R replay children. Neither its computations nor A1/C1 settings
changed. Each report includes its original source digest, input checksum, environment versions,
summary CSV and SVG/PNG plot. Machine-local workspace paths are omitted from reviewed CSVs.

An earlier diagnostic run under `runs/pilot-smoke` found a C1 KM table that omitted
censoring-only times. The common prompt was clarified before freezing these reported trials.
That diagnostic attempt is retained locally and is not counted as a trial of the clarified task.

The three reviewed A1 traces retain R calls, their observed results and visible assistant
messages, with task-workspace paths normalized to `.`. R input code is unchanged; original and
reviewed checksums are in [the trace index](../v0.2/results/clinical-pilot/trace-index.json). Full raw traces,
including C1 commands, evaluations and retained task workspaces, remain in ignored `runs/`.
Reproduce one captured execution without a live model:

```bash
python3 dev/bench/biomedical/run.py --arms A2 \
  --replay dev/bench/biomedical/reports/clinical-pilot/trace-a1-1.jsonl
```

For the same dataset checksum, use the recorded R/survival versions. Reports distinguish
unknown usage from zero, sampled process-tree RSS from exact peak memory, and interface-specific
tool counts. OS cache state is uncontrolled. No cold-cache or broad statistical claim is made.
