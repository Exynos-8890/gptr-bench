# gptr Benchmark 1: In-Memory Biomedical Agent Workflow Efficiency

**Project plan — Version 0.3.2 | Updated 2026-10-28T22:55:42Z**

**Repository:** [Broccolito/gptr](https://github.com/Broccolito/gptr)

**Status:** v0.3 real-data experiment complete: all 66 formal executions pass on 100,000 real GSE236581 cells, with GPT 6.1 Sol on both real arms. Source preparation reproduces a byte-identical input. The full 975,275-cell tier is explicitly capacity-gated on this host. See [the reviewed results](results/report.md).

## v0.3 execution scope and change history

| Version | Changed at (UTC) | Change |
|---|---|---|
| 0.2 | October 2026 (exact historical edit time not recorded) | Clinical pilot and synthetic diagnostic completed. |
| 0.3.0 | 2026-10-28T21:51:38Z | Add real GSE236581 single-cell experiment; pin GPT 6.1 Sol; declare input, task, measurements and acceptance below. |
| 0.3.1 | 2026-10-28T22:39:33Z | Load native gptr helpers in clean captured-trajectory validation; retain the initial rejections and separately version the supplementary replays. |
| 0.3.2 | 2026-10-28T22:55:42Z | Record 66 valid real-data executions, separately versioned capture supplements, byte-identical source preparation, reviewed reports and final acceptance evidence. |

The six real trials and thirty canonical repeats were collected under 0.3.0. Clean-state checks of A1-1 and A1-3 exposed `gptr_return()` as a missing export in the plain validation process; their real outputs were valid, and neither rejected capture produced fake input. Version 0.3.1 loads the real package helpers in the isolated captured-validation child, retains the R inputs verbatim, and records the source trace SHA-256 in supplementary run manifests. Only the twenty missing A1-1/A1-3 replays are added as separate collections; the original observations and rejection evidence are retained.

Every subsequent edit to this plan increments its patch version, updates the header timestamp and adds one dated row explaining the change. Original run manifests retain the plan version used to freeze their experiment.

- **Source:** [GSE236581](https://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=GSE236581), GEO update 2024-07-29, 36,027 genes, 975,275 cells and 1,310,816,895 nonzero counts. Download counts, barcodes, features and cell metadata directly from GEO; record retrieval times and SHA-256 checksums. Source investigation: [real-data-source-review.md](real-data-source-review.md).
- **Declared tiers:** first validate a fixed 10,000-cell real subset, then collect the five-arm results on 100,000 real cells spread deterministically across the original barcode ordering, retaining all genes. Store the exact selected barcodes and selection rule. No duplicated cells or synthetic values. A full 975,275-cell tier requires sufficient RAM and disk headroom; record the preflight result explicitly if the current host cannot support it. A 32 GB host with about 9 GB available cannot safely parse and evaluate the complete in-memory matrix whose nonzero arrays alone need about 15.7 GB.
- **Representation:** a fully resident sparse `dgCMatrix` plus matched metadata and features in one uncompressed RDS, identical across arms. Streaming source preparation is outside task timing; input loading is included. Record real compressed download size, selected-cell count, nonzero count, RDS bytes and available memory. Never convert the full expression matrix to dense form.
- **Requests:** (1) verify identifiers and calculate per-cell total UMI and detected-gene counts from the matrix; (2) retain cells with at least 1,000 UMI and 500 detected genes, aggregate expression by patient/tissue/treatment time, and report fixed marker expression; (3) change the thresholds to 2,000 UMI and 1,000 genes and recompute, reusing the input and QC. Both aggregation steps must consume the full input expression matrix. Retain all annotated groups, including groups with zero qualifying cells; normalized expression in an empty group is zero. These are adapted benchmark tasks, not a claim of reproducing the original study's clinical findings.
- **Validity:** independent checks compare per-cell QC, retained-cell counts, group UMI totals, marker counts and normalized expression. Compare tables by declared identifiers; tolerance `1e-6`. Only transform captured A1 operations after clean-state validation. Preserve failures, consumed time, tool errors, replay compatibility and each trial's raw records.
- **Runs:** three real trials per A1/C1, ten canonical repeats per A2/C2/C3, then ten fake replays of each valid A1 trajectory. Keep the existing serial/alternating-order policy. The timeout is 1,800 seconds per run for this tier; retain the existing token limit of 1,000,000 and unknown-cost accounting. Preflight/model access checks are diagnostic and excluded from these trial counts.
- **Deliverables:** `tasks/single-cell.R`, a source preparation entry point, task-aware runner and evaluator, offline tests, reviewed `reports/gse236581-v0.3/`, and complete local `runs/gse236581-v0.3/`. Record task, source version, plan version/timestamp, model, CLI/R/package versions, SHA-256 and subset identity in manifests. Maintain the existing package Imports and historical report values.

| Acceptance | Command or evidence | Actual | Status |
|---|---|---|---|
| Real input and barcode alignment | source checksums, subset manifest and preparation validation | 100,000 real cells; all 36,027 genes; 134,275,503 nonzeros; 1,636,075,918-byte RDS; source annotations match; clean standalone reproduction is byte-identical | PASS |
| Task and validator | offline R tests, including deliberately wrong outputs | 29 assertions, no warnings; integer counts compare exactly, CPM tolerance `1e-6` | PASS |
| Three replay paths and capture validation | offline Python integration suite | 6 tests pass, including native-helper round-trip, trace hash and invalid capture rejection | PASS |
| Fixed model on both real arms | frozen manifest plus real Codex invocation/trace evidence | `gpt-6.1-sol`, Codex CLI 0.165.0, shared CLI default reasoning; six valid real trials | PASS |
| Five-arm 100,000-real-cell experiment | run summaries, per-run evaluations and captured compatibility | 6 real + 30 canonical + 30 captured replays = 66 valid executions; initial missing-helper rejections retained | PASS |
| Reports and preflight classification | reviewed CSV, manifests, plots, scope and capacity evidence | `reports/gse236581-v0.3/`; primary and supplemental versions explicit; 10,000-cell validation separate; full tier not measured | PASS |
| Cross-plan consistency | all four consolidation commands | Latest recorded checks: 28 plans, 1444 blocks, 0 errors; 770 R blocks, 0 parse/style problems; no lints. Repeat after this final documentation revision; logs in benchmark progress evidence. | PASS |

Implementation commits: `feat(bench): prepare real GSE236581 sparse inputs`; `feat(bench): run single-cell tasks with GPT 6.1 Sol`; `docs(bench): record v0.3 real-data benchmark results`.

## 1. Executive Summary

This project will evaluate whether **gptr**, an R-native agent harness operating against a live R workspace, delivers measurable advantages over a conventional external coding-agent workflow for biomedical data analysis. The principal comparison is between **gptr with a persistent R session** and **Codex CLI executing R through shell commands and RDS files**. We aim to isolate execution architecture from model code-writing ability.

The benchmark will have two complementary modes. First, a **Real Provider** run will give each agent a genuine biomedical task and measure end-to-end completion time, model waiting, tool use, and token consumption. Second, a **deterministic replay** will record observable model outputs and execution steps, then reproduce the work without additional live model calls. This separates inference variability from execution and data movement.

Five biomedical task families will provide coverage: clinical trials, bulk genomics, human genetics, single-cell genomics, and protein variant analysis. We will begin with one vertical slice before expanding to all five. Deliverables include reproducible traces, metrics, and plots.

## 2. Research Questions and Hypotheses

The benchmark addresses three questions:

1. **End-to-end efficiency:** Does gptr complete a multi-step biomedical analysis faster than an external coding agent when both are allowed to use their normal workflows?
2. **Execution efficiency:** Holding the actual R operations constant, how much time and memory does a persistent R workspace save relative to restarting R and restoring objects from RDS between steps?
3. **Reasoning overhead:** Does gptr's prompting, tool interface, or interaction pattern cause more model calls or longer model waiting, potentially offsetting savings from reduced data loading?

We hypothesize that persistence reduces repeated loading costs, while end-to-end benefits remain task-dependent. A well-optimized external agent may batch work into a single Rscript invocation, which can eliminate much of the apparent advantage of persistence. A batched-script reference prevents that misinterpretation.

## 3. Experimental Arms

The first release will use the following execution arms:

| Arm | Model behavior | Execution strategy | Primary purpose |
|---|---|---|---|
| **A1: gptr Real** | Live model | Native gptr agent; persistent R workspace | Real user-facing performance |
| **C1: Codex Real** | Live model | Codex CLI; shell/Rscript and RDS/files as needed | Real product-level comparison |
| **A2: gptr Replay** | Recorded model responses via `gptr_fake_provider()` | Actual gptr agent/tool loop; persistent R workspace | Repeatable gptr execution measurement |
| **C2: RDS Tool Replay** | No live model | Recorded or canonical R steps run in fresh Rscript processes, restoring required state | Stateless file-based execution cost |
| **C3: Batched Rscript** | No live model | Equivalent steps in one R process, loading data once | Controls for batching and process startup |

A1/C1 compare products, not isolated harness effects. A2/C2 compare the gptr execution system with deliberately stateless execution; gptr's permission checks, checkpoints, capture and other harness work remain part of its measured cost. C3 tests avoidable overhead. We will also use a **canonical execution trace**—identical R computations on both paths—to reduce differences in model-generated algorithms. Codex replay covers tools, not its complete harness.

The initial pilot runs these five arms as defined. Separately attributing every harness cost, adding a persistent Codex bridge and refining the statistical design are follow-up experiments, not prerequisites for collecting the first results.

A future arm, **Codex with a persistent R bridge**, can test whether gptr retains an advantage after both agents receive comparable workspace access. The bridge is deferred.

**Current model:** every v0.3 real arm explicitly selects `gpt-6.1-sol` (GPT 6.1 Sol): A1 uses `codex/gpt-6.1-sol`, C1 passes `-m gpt-6.1-sol` to the same Codex CLI. Do not resolve the global default alias. CLI default reasoning is shared and recorded. Historical v0.2 results used `gpt-6-sol` and are not pooled with v0.3. Captured A1 R operations are replayed through the actual fake-provider loop; internal CLI request grouping remains synthetic.

## 4. Real Provider → Capture → Replay

### 4.1 Real runs

Each task begins with a specified dataset, package environment, initial state, user prompt, and required artifacts. The agent is allowed to plan, call tools, inspect errors, and revise code naturally. Multi-turn tasks will include at least three successive requests so that reuse of datasets and intermediate results is observable.

For gptr, we will use a pinned development commit and a documented real provider configuration. For Codex, we will pin the CLI version, model selection, reasoning setting where configurable, and workspace permissions. We will match underlying models as closely as the interfaces permit; unmatched settings will be disclosed. Agents receive equivalent task and data access.

A recorder will preserve the user messages, observable assistant responses, tool calls, tool inputs and outputs, error statuses, timestamps, and usage reports. Hidden reasoning is not required. "Model time" measures request wall time, not pure thinking.

### 4.2 Trace normalization

We will translate each real run into a versioned neutral schema containing task ID, dataset checksum, code revision, model configuration, turn index, ordered tool calls, visible responses, status, and timing spans. For gptr, the adapter will convert compatible captured assistant responses into the scripted response structure accepted by `gptr_fake_provider()`. Raw session traces are not assumed to be valid fake-provider input.

For Codex, the adapter will extract observable R commands and dependencies from structured CLI traces. Unclear commands or dependencies fail replay compatibility. A separate canonical trace will serve the controlled execution comparison.

Validate the captured R steps and required artifacts from a clean state before converting the compatible gptr responses into a fake-provider script. The pilot assumes its selected workflow state can be restored through RDS; support for arbitrary R session state and unusual object types is deferred.

### 4.3 Deterministic replay

Replay begins from an identical, clean data state. The gptr runner supplies recorded responses to its real agent loop and verifies the number and order of expected calls. The RDS runner executes the corresponding steps in independent R processes, restoring only objects required for each step. The batched runner executes equivalent code in a single process. No live provider request is permitted during replay. Unexpected calls or mismatched outputs invalidate replay.

Check that the fake-provider script is consumed exactly once in full: the provider itself repeats its last reply after exhaustion. This is a small runner check, not a new general-purpose replay framework.

This is **agent-trajectory replay for performance testing**, not the same feature as gptr's document-oriented `gptr_source()` history replay. The latter belongs primarily to a separate reproducibility benchmark.

## 5. Biomedical Task Portfolio

Each task family includes a small smoke test and a real performance dataset. Synthetic inputs remain implementation diagnostics and do not substitute for real-data performance evidence. v0.3 uses the public processed GSE236581 single-cell counts and accompanying annotations. This extends the task portfolio; the clinical survival task remains a regression check.
| Family | Candidate public source | Illustrative multi-step workflow | Persistent state of interest |
|---|---|---|---|
| **Clinical trials** | R `survival::veteran` trial data | QC → Kaplan–Meier/Cox analysis → covariate revision/subgroup comparison | Clean cohort, fitted models, survival summaries |
| **Bulk genomics** | Bioconductor [`airway`](https://bioconductor.org/packages/airway/) | Count QC → normalization → differential expression → revised filtering | Expression data, design matrix, model results |
| **Human genetics** | [1000 Genomes Phase 3](https://www.internationalgenome.org/data-portal/data-collection/phase3) | Variant/sample QC → allele-frequency filtering → PCA → modified thresholds | Genotype representation, filters, PCA objects |
| **Single-cell genomics** | Bioconductor [`TENxPBMCData`](https://bioconductor.org/packages/TENxPBMCData/) | Cell QC → normalization → dimensionality reduction → reclustering | Sparse counts, normalized assays, embeddings |
| **Protein variant analysis** | [ProteinGym](https://proteingym.org/download) DMS assays | Mutation QC → feature engineering → fitness modeling → candidate reranking | Variant features, model, candidate scores |

The small `veteran` dataset tests functionality. The v0.3 performance tier uses real cells without duplication or synthetic enlargement. HDF5/GDS-backed data require explicit storage classification: reading an RDS wrapper is not loading the full matrix.

Each family has three to five requests, reusable artifacts, and a validity test. Protein tasks will concern variant analysis and prioritization, not GPU-intensive de novo structure generation.

## 6. Timing and Tracing Architecture

A **Python orchestration layer** will launch isolated runs, control repetition, assign run IDs, measure process-level wall time, and collect memory samples. Lightweight **R instrumentation** will measure data loading and computation inside the process. gptr's documented session hooks and fake-provider support are candidate integration points; the exact hook payload and response contract will be verified against a pinned commit before implementation.

The trace schema records:

- `startup_ms`: start of child process until R runner initialization;
- `dataset_load_ms`: time spent restoring the input into its declared representation;
- `model_wait_ms`: elapsed real-provider request time, including transport;
- `tool_wall_ms`: elapsed invocation time including harness and execution;
- `r_compute_ms`: time spent evaluating the R computation itself;
- `serialization_ms`: timed serialization or deserialization where instrumented;
- `total_wall_ms`: user-visible elapsed time from defined task entry to completion.

Tool spans already contain compute spans; never sum them. A monotonic timer defines total wall time. Also capture tool counts, tokens, I/O bytes, warnings, exit codes, and sampled RSS. We will distinguish sampled RSS from exact OS-level peak memory and record machine configuration, storage medium, process isolation, package versions, and cache policy.

Real mode will emphasize total time, provider wait, and token cost. Replay mode will emphasize execution and loading time, memory, and variation across repetitions. A no-op workflow estimates instrumentation overhead.

For the pilot, end-to-end wall time is authoritative and includes agent preparation, permission handling and normal harness work; do not subtract these phases. Fine-grained spans are approximate and their boundaries must be documented. Existing hook/evaluator elapsed fields are not assumed to be pure R computation time. Unavailable provider timing or usage stays unknown. Detailed overhead attribution and the no-op calibration can follow the first five-arm run.

## 7. Fairness and Validity Controls

The benchmark must not turn an artificially inefficient baseline into a general claim about Codex. In real runs, Codex may create scripts, cache intermediate objects, or combine operations when that is its natural choice. In controlled replay, the stateless RDS condition is deliberately constrained and clearly labeled; the batched reference exposes the cost of that constraint.

Match data, R versions, computations, hardware, and budgets. Exclude downloads and preparation. Report cold/warm cache separately. Input preparation, one-time loading, repeated loading, and computation must be shown separately rather than hidden within one aggregate number.

Preparation excluded here means dataset download/generation and environment installation before the task starts, not the agent's own preparation during a task. Declare whether the initial data load is inside the timed interval; report it separately when the task starts with an already loaded workspace.

**Run workspace isolation is required for the pilot.** Keep benchmark source under `dev/bench/biomedical/`, but create each task's working directory outside the gptr repository. Give both agents equivalent task instructions, input data and allowed files. Keep this plan, evaluators and expected answers outside agent-accessible files. Isolate user/project configuration, keep one agent session across the successive requests of a task, and use a fresh task workspace for each independent trial.

**Correctness will be a validity gate, not the primary leaderboard.** A task must create the required artifacts and pass independent checks before its runtime is treated as a successful execution. Predefine numerical tolerances and random seeds. Failed attempts still count toward product-level failure rates and consumed time. The benchmark will not reward an agent for finishing faster by skipping necessary work.

## 8. Evaluation and Statistical Analysis

Initially run **three independent real trials** per agent/task and **ten replays** per valid trajectory, with scope to increase real trials. Replays of the same trajectory estimate execution variability; they do not count as independent model trials.

First validate one run of every arm on the clinical workflow, then collect the pilot repetitions. Alternate real-agent order between trials (A1 then C1, followed by C1 then A1), running one benchmark arm at a time. Before execution, record a per-task wall-time limit and token/cost ceilings in the run manifest. Keep timeout, failure, elapsed time and available usage for every attempt. Report successful runtimes alongside success counts and replay compatibility counts. These initial trials are exploratory; stronger uncertainty estimates and additional repetitions can follow.

Primary figures will be (1) end-to-end time decomposition for real runs, (2) replay execution time versus data size and number of steps, and (3) cumulative data-loading overhead and memory footprint. Tables will include per-task completion status, tokens, model wait, tool invocations, and speed ratios with uncertainty intervals. We will summarize distributions using medians and spread, avoid averaging incompatible tasks blindly, and stratify results by task family and storage backend.

Accounting identity:

`total_wall ≈ setup + model_wait + execution/tools + orchestration`

Not all phases are separately observable, especially provider-side thinking. If gptr saves I/O time but increases model waiting more, the end-to-end finding should say so explicitly.

## 9. Implementation Plan and Deliverables

**Milestone 1 — Vertical slice.** Pin the gptr commit, R environment, Codex version, and model settings. Implement one clinical-trial workflow and validate one real run per agent. Build the common task specification and correctness checks.

**Milestone 2 — Capture and conversion.** Export gptr and Codex traces into a neutral schema. Implement `trace_to_fake()` for compatible gptr responses, plus strict replay divergence detection. Extract R steps and dependencies for the file-based replay.

**Milestone 3 — Measurement harness.** Add Python wall timers, R phase timers, memory sampling, structured JSONL/CSV output, and no-op instrumentation checks. Run gptr replay, stateless RDS replay, and batched Rscript on an identical canonical R trace.

**Milestone 4 — Domain expansion.** Add bulk genomics, human genetics, single-cell genomics, and protein variants. Introduce controlled size tiers, verify actual memory residency, and preflight dataset licenses and download reliability.

**Milestone 5 — Reporting.** Publish run manifests, environment locks, trace schemas, reproducible plotting scripts, a concise methodology, and a results report distinguishing product-level findings from execution-only results.

Initial repository layout (add runner files and task directories as they are implemented):

```text
dev/bench/biomedical/
  README.md
  plan.md
  run.py                   # orchestration and run manifests
  runner.R                 # R execution and instrumentation
  tasks/                   # begin with the clinical workflow
  adapters/                # gptr, Codex, Rscript, capture conversion
  evaluators/              # artifact and numerical checks
  reports/                 # reviewed summaries, methodology and plots
  data/                    # downloaded/generated inputs; ignored by Git
  runs/                    # raw traces and run outputs; ignored by Git
```

Only source, task definitions and reviewed report artifacts belong in Git. Per-run task workspaces live outside this tree. Development dependencies stay outside the package Imports; real provider runs require explicit live mode (`GPTR_LIVE_TESTS=true`), while replay uses offline fake providers.

## 10. Risks, Interpretation, and Completion Criteria

The main risks are **trace incompatibility**, **provider variability**, **different code paths**, **storage-backend confounding**, and **overstated causal claims**. We will mitigate these with strict replay checks, pinned versions, canonical traces, backend documentation, and explicit separation of real-agent and controlled-execution conclusions. Use properly licensed, authorized public data.

The MVP is complete when one real gptr run and one real Codex run can be captured, their observable execution can be reconstructed or explicitly declared non-replayable, all three controlled execution paths produce equivalent required artifacts, and a single command exports timing and memory summaries. The larger v1 milestone is complete when the same pipeline runs across all five biomedical families with reproducible plots and documented limitations.

**Success means obtaining credible evidence, not necessarily showing that gptr wins.** The benchmark should reveal when persistent R state matters, when an external agent can match it through batching, and when model interaction costs dominate the overall workflow.

## Reference Resources

- [gptr repository and development documentation](https://github.com/Broccolito/gptr)
- [R `survival` package](https://cran.r-project.org/package=survival)
- [Bioconductor `airway`](https://bioconductor.org/packages/airway/)
- [1000 Genomes Project](https://www.internationalgenome.org/)
- [Bioconductor `TENxPBMCData`](https://bioconductor.org/packages/TENxPBMCData/)
- [ProteinGym data downloads](https://proteingym.org/download)
