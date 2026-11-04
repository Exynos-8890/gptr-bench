# Methods: T08 full-file reading and reuse

[Results](result.md) · [Editable results](result.Rmd) · [HTML](result.html)

## Framework

GPT-R Bench compares two agent workflows across three sequential R requests.

| Condition | A1: GPT-R Peter | C1: native Codex |
|---|---|---|
| Inputs and scientific prompts | Identical | Identical |
| Model | `gpt-6.1-sol`, low reasoning | Same |
| R execution | Persistent session | Finite `Rscript --vanilla` processes |
| Cross-request state | Reuse in-memory objects | Processes exit; reload required data |
| Scientific disk caches | Prohibited, including RDS/RData and intermediate tables | Same |
| Permitted files | Requested results, R source, benchmark logs | Same |
| Independent runs | Fresh workspace and R state | Same |

The agent chooses its code and calls. C1’s process constraint is recorded separately from the shared scientific prompts.

```mermaid
flowchart LR
    I[Verified input + shared requests] --> A[A1: persistent R]
    I --> C[C1: finite Rscript]
    A --> A1[Load → reuse → reuse]
    C --> C1[Load + exit → reload + exit → reload + exit]
    A1 --> E[Outputs + timing traces]
    C1 --> E
    E --> V[Independent review]
```

## T08 task

| Property | Specification |
|---|---|
| Purpose | Full-file loading and reuse; no protein identification or biological group comparison |
| Dataset | MassIVE MSV000100943 / PXD060573; one plasma-proteomics run; CC0 |
| File | `20240912_WFB_exp01_magnet_5_0.mzML` |
| Size | 6,415,611,632 bytes; 307,590 spectra; 512,278,842 peaks |
| Required scope | Complete metadata and all MS1/MS2 m/z–intensity arrays in R memory |
| Reader | `mzR` 2.46.0: `openMSfile` → `header` + `peaks` → `close` |
| Excluded shortcuts | Subsets, streaming, index-only access, disk state caches, computing later requests early |

| Request | Computation | Output |
|---|---|---|
| 1 | Load; verify spectrum/peak counts and array dimensions; summarize MS levels and retention time | `input-audit.csv` |
| 2 | Calculate total ion current from every intensity array; summarize by MS level | `signal-summary.csv` |
| 3 | Calculate peak counts and maximum intensities; summarize by MS level and document limitations | `peak-summary.csv`, `research-report.md` |

Reuse `raw` when present; otherwise fully reload. Empty arrays contribute zero total and maximum intensity.

## Collection and timing

| Setting | Value |
|---|---|
| Runtime | v0.5 dev.24; Codex CLI 0.165.0; one 16 GiB / 2 vCPU AWS host |
| Repetitions | Three per arm; three requests per run; serial execution |
| Order | C1-1 → A1-1 → A1-2 → C1-2 → C1-3 → A1-3 |
| Limits per run | 1,800 seconds; configured 2,000,000 tokens; numerical-library thread settings of one |
| Measured | Agent startup through final response, including loading, computation, and output writing |
| Outside measurement | Download, installation, input verification/copying, independent review |
| OS cache | Not cleared; not a cold-disk benchmark |

| Exclusive time category | Includes |
|---|---|
| File reads | Opening, metadata parsing, peak decoding, result-table reads; overlapping intervals counted once |
| Tools excluding reads | Tool execution minus reads, including computation and output writing |
| Harness + model + network | Remaining time; thinking and generation are not separated |

C1 execution intervals include time between polling calls. Categories sum to request time; startup, gaps, and cleanup remain in the whole-run residual. Calls include commands, edits, and polling without double-counting outer wrappers.

## Reporting and evidence

| Item | Rule |
|---|---|
| Main comparison | Median, minimum, maximum; three runs per arm; no confidence intervals |
| Additive differences | Mean C1 − mean A1; positive means C1 is slower |
| Gantt chart | Actual intervals from each arm’s median-duration run |
| Validation | Independent full-data numerical comparison at tolerance `1e-10`; execution and artifact review |
| Interpretation | End-to-end agent workflows, including generated-code differences; not an isolated framework-cost estimate |

[Exact prompts](trace/shared-prompts-T08.json) · [Input source and hashes](trace/provenance.json) · [Review](trace/final-review.json) · [Tool calls](trace/tool-calls.csv) · [Intervals](trace/all-run-intervals.csv)

Shared traces are derived evidence, not a complete conversation archive.
