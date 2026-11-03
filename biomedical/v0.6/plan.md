# v0.6: thirty-task biomedical benchmark proposal

Plan version: **0.6.0-draft.2**. Updated UTC: **2026-10-31T23:10:05Z**.
Base: **v0.5.0-draft.4**, itself derived from v0.4 draft.6 scientific workflows.
Registry: `tasks.json` in this directory. Status: **proposal only; twenty added tasks are not implemented**.
The current host proposal is one `r6a.large` (2vCPU/16GiB), running tasks/arms serially.
Resource creation/startup, live model execution and full250000-cell calibration remain unauthorized
or deferred as recorded in v0.5. Writing this proposal does not start them.

## 1. Scope and task accounting

Target30 scientific tasks: retain T01–T10 and add20 independent research questions, T11–T30.
A task includes one defined scientific question, a fixed genuine-input profile, three connected user
requests, required artifacts, substantive reference calculations and an independent numerical checker.
Do not count individual requests, code blocks, repeats or changed seeds as additional tasks.
A second task may reuse a cohort only if its scientific objective, expected artifacts and checks differ.
Report both task count and underlying source/cohort families;30 tasks do not imply30 independent datasets.

Fifty tasks is a later extension target. Do not count20 reserve ideas or unimplemented modules as
finished tasks. Advance toward50 only after30 task definitions and data manifests are reviewed and
representative families pass correctness/resource pilots. This proposal does not promise a completion
date or that every full input fits16GiB before measurement.

## 2. Retained design and new scientific coverage

Retain all ten parent task families and218 reference blocks. Parent T03 returns to all576 samples;
T05 first attempts the full source with guarded preparation/workflow validation; T01 keeps250000
as a memory-gated target. Other parent input ranges were not further cropped in v0.5.
The registry groups30 tasks into19 named source families, not19 verified independent cohorts.
It lists20 proposed additions with distinct objectives, primary-source links, three request
stages, checkable outputs, provisional memory envelopes and explicit implementation/data-size status.

Borrow the reference benchmark's publication-grounded, multi-step workflow and process evidence.
The authors' public Hugging Face card states50 released tasks out of100 and82.9GB total repository
files. That file total is not per-task resident memory. Access to the actual task files is gated;
this proposal does not copy inaccessible rubrics or claim its call counts match unread traces.
Source: <https://huggingface.co/datasets/phylobio/BiomniBench-DA>.

## 3. Inputs and16GiB resource gate

Use genuine public processed data with exact release/file URLs, checksums, units, sample IDs and
source terms recorded before preparation. A dataset landing-page link is a research candidate,
not proof of an acquired or licensed input. Any access-gated source remains blocked until separately
resolved; do not silently substitute synthetic data or accept conditions automatically.
No unverified GB/file-size estimate should be presented as observed. Record compressed download bytes,
prepared RDS bytes, dimensions/nonzeros, actual input-read time and full sampled process-tree peak.

Use the parent's proposed available-RAM gate>=12GiB,3GiB host headroom,10GiB RSS warning and11GiB
RSS stop; stop earlier if available host RAM drops below3GiB. The parent v0.5 guards are implemented and locally tested; remote acceptance is still required.
The start gate is min(12, planned upper working memory+3)GiB, with12GiB preferred for heavy tasks. Run all folds, permutations, tasks and arms serially unless explicitly frozen
otherwise. Sparse representation and normal feature/model choices are legitimate scientific design;
do not pad input or inflate allocations to force a persistence benefit.

If a full candidate exceeds the host gate, preserve evidence and freeze a justified genuine subset
with scope/version disclosure, or mark it unsupported and revise the candidate list. Sampling must
preserve patient/group structure and avoid selection on desired outcomes. Every arm receives the
same fully resident input and scientific question. Stream preparation outside measurement; keep the
originally timed scientific QC and data transformations inside the measured workflow.

## 4. Implementation gates

1. Freeze dataset manifests and scientific specifications for T11–T30. Review task distinction,
   access, realistic dimensions, statistical units, leakage control and required independent checks.
2. Generalize the existing registry/runner beyond the current T01–T10 ID restrictions. Reuse the
   execution protocols, metrics and fake provider. Do not expose reference code or evaluators to agents.
3. Implement each preparation adapter, reference workflow and independent checker; write meaningful
   offline tests first. Pin train/test/patient splits; keep feature selection/tuning within training.
4. Validate canonical A2/C2/C3 on genuine prepared inputs, including state serialization and the
  11GiB guard. Run matched input-read probes and inspect request/tool/I/O boundaries.
5. After explicit execution authorization, run live pilots on representative families and validate
   captured trajectories from a clean state. Only convert correct compatible trajectories to fake input.
6. Freeze budgets, settings and manifests, then collect serially in10-task batches with per-task HTML.
   Keep failures, quota retries, interruptions and incompatible captures in the report.

New-task planned reference work is18–30 substantive blocks per task, finalized from actual science.
Reference blocks are not observed tool calls. Report actual R execution calls, native CLI tools,
provider requests, user requests, I/O and statistical operations in their own units.
The20 additions currently plan502 blocks; together with218 implemented parent blocks this would
be720. The current proposal does not claim the new502 blocks already exist.

## 5. Repetitions, aggregation and feasibility

Both live arms use `gpt-6.1-sol`/`low`. Retain three real trials per A1 and C1; ten canonical repeats
for each of A2/C2/C3; ten fake replays per validated compatible A1 trajectory, at most three sources.
Per-task counts are6 real+30 canonical+0–30 captured replays, excluding diagnostics and failed retries.

| Scientific tasks | Real trajectories | Canonical repeats | Compatible captures at most | Planned successful collections |
|---|---:|---:|---:|---:|
|10|60|300|300|360–660|
|30|180|900|900|1080–1980|
|50|300|1500|1500|1800–3300|

Interpret captured repeats conditional on capture compatibility; do not fill skipped captures with
fabricated rows. Keep existing completed v0.3/v0.4 results historical, not relabeled v0.6 trials.
Aggregate paired task-level timing ratios and correctness with a source/cohort-family view so that
three questions from one cohort are not treated as three independent datasets. Report heavy-loading,
moderate-input and naturally small tasks separately. More tasks increase wall time and validation
work, not simultaneous memory when execution is serial.

The2vCPU host may make fits/permutations slower. Restored T03 starts from the existing14400s budget
proposal, finalized equally across arms after pilot measurement. Total runtime, model subscription
quota and cost are unknown until pilot evidence; an active-week AWS quote is not a30-task budget.

## 6. Acceptance and version history

A completed30-task suite requires30 reviewed scientific specifications, verified genuine manifests,
implemented preparation/reference/checker paths, offline gates and resource-valid pilots, then the
prescribed collection with transparent failures and missing/incompatible cases. A30-row proposal
alone does not satisfy completion. Scale toward50 by adding distinct scientific coverage after this gate.

| Version | UTC | Change |
|---|---|---|
|0.6.0-draft.1|2026-10-31T07:49:56Z|Propose30 tasks from v0.5 draft.3: retain10 and add20 distinct research questions;16GiB serial host;50 deferred to a later reviewed extension.|
|0.6.0-draft.2|2026-10-31T23:10:05Z|Prioritize execution of the first ten tasks as v0.5 draft.4; synchronize shared host/resource method; keep twenty additions unimplemented and deferred.|
