# v0.5 16GiB execution proposal, derived from v0.4

Plan version: **0.5.0-draft.11**. Updated UTC: **2026-11-02T18:39:08+00:00**.
Base: **v0.4 draft.6 / implementation dev.2**. Registry: `v05-tasks.json`.
Status: **versioned code and local offline acceptance available; AWS deployment, full-input resource pilots and real v0.5 collection pending**.
On2026-11-01 the user explicitly authorized one AWS host and execution of T01.
Instance i-0ba4000b77160da53 is running with the selected16GiB profile; SSH and the new data volume
have passed verification. Linux setup and exact-input transfer are in progress. The user now selects one16GiB AWS host; retain larger-host compatibility. The user
chose capacity accounting and instance selection now, deferring a full250000-cell matrix trial.
Historical runs remain immutable. Current T01 preparation/pilot/formal stages must be completed
before reporting a new scientific result. This execution revision adds a thin detached-job wrapper
with atomic JSON state and PID/create-time inspection, without changing the scientific methods.
The common v0.6 methodology is adopted for T01–T10 here: publication-grounded scientific questions,
three connected requests, independent numerical checking, profile/resource gates and separated
request/tool/provider/I/O evidence. T11–T30 remain a later v0.6 proposal, not part of this run.

## Current execution policy (maintainer simplification request)

The current runner directly executes prepare/import/offline/pilot/formal. Remove the
freeze command and runtime/source/environment lock gates, metadata/profile admission
checks, memory guards, capacity diagnostics and background-job state machines. Keep
source/input hashes, scientific computations, measured request/tool/I/O boundaries and
per-trial outcomes. The 150000-cell T01 input is the default. Linux installation is an
explicit setup script; normal missing-dependency errors replace custom error layers.
The former resource/freeze requirements below describe the earlier experiment and no
longer govern this implementation. No new live experiment is launched by this change.
Scientific result checking is separate from deployment/identity checking and remains
in the existing runner. Native-document collection and prompt alignment are not changed.

## 1. Preserve the v0.4 experiment

All ten biomedical tasks, their three scientific requests,18–24 substantive reference R blocks,
artifacts, statistical methods and independent correctness checks derive from `tasks/v04/`.
The registry retains all218 reference blocks. Do not replace these tasks with the simpler v0.3 QC
workflow. Change input scope, scope wording, local memory guards and pilot-derived time budgets.
Checks must recompute expected results against the actual selected input, not the original cohort.
Historical v0.3 supplies a read-time reference, not the scientific task definition.

Keep A1 live gptr/persistent R, C1 live Codex/ordinary scripts, A2 real fake-provider gptr replay,
C2 fresh R per user request with declared state restoration, and C3 one batched R process.
Both real arms retain `gpt-6.1-sol`/`low`. Keep three independent real trials per arm, ten canonical
repetitions per A2/C2/C3, and ten replays per compatible A1 trajectory. Reference block counts are
not observed model function-call counts. Keep failures, interrupted attempts and incompatible traces.
Only create fake-provider inputs after clean-state execution and scientific validation pass.

## 2. Real input profiles

| Task | Change from v0.4 | Scientific work retained |
|---|---|---|
| T01 |975275 source cells to250000 target; all36027 genes | QC, patient/lineage composition, paired tissue effects,1000 patient bootstraps, longitudinal analysis, QC/denominator sensitivity, marker evidence |
| T02 | Keep all2509 real patient rows | Survival QC, Cox models, KM/risk tables, diagnostics, patient bootstrap and sensitivity |
| T03 | Restore the v0.4 input: all576 samples,59 Normal/517 Tumor, all60660 genes | TMM, batch-adjusted edgeR QL, pathway enrichment, paired-patient and filtering sensitivity |
| T04 | Keep v0.4:2504 individuals and5000–10000 chr22 SNPs | QC, within-population HWE, LD pruning, PCA, Hudson Fst and sensitivity |
| T05 | Attempt full source eight-field input with streaming preparation and guarded preflight; chr1–3 is a labeled fallback | QC, calibration, candidate regions, TSS annotation, tested-gene background and sensitivity |
| T06 | Keep v0.4 processed intervals and annotations | Replicate agreement, matched background and enrichment |
| T07 | Keep149360 real GB1 variants and sparse features | Validation-only tuning, additive/pairwise models, heldout evaluation, constrained candidates and uncertainty |
| T08 | Keep processed protein matrix and subtype/batch mapping | Normalization, subtype contrasts, enrichment and missingness sensitivity |
| T09 | Keep968 samples and189 metabolites | Nested prediction validation, calibration and permutations |
| T10 | Keep3813 tissue spots; retain sparse input/top500 analysis genes | Spatial domains, Moran I,199 permutations and graph/QC sensitivity |

T01 is the primary loading-pressure experiment. The other tasks retain biological coverage without
being padded to a common file size. Input sizes and statistical power may differ from v0.4; do not
claim full-cohort replication or compare the cropped scientific estimates as if their cohorts matched.

T01: stratify on Patient×Tissue×Treatment×MajorCellType, treating missing labels as explicit selection
strata without rewriting source values. Retain at least one real cell per nonempty stratum, then
allocate the remaining quota proportionally by largest remainders subject to stratum capacities.
Within strata rank original barcodes by SHA256(seed|barcode), with ID ties. Save all quotas, exact
barcodes, inclusion fractions and hashes. The estimand is the declared selected cohort; preserved
rare strata do not make its proportions identical to the source population. Never duplicate cells,
change counts or densify the full matrix. Predeclare safety tiers200000 and150000. The300000-cell optional tier is suspended on this16GiB
profile. All retained tiers remain real subsets.

T03: restore the existing576-sample v0.4 input, including59 Normal,517 Tumor and58 complete
patient pairs; all60660 genes and1240 pathways remain. The96-sample draft.1/draft.2 profile is a
historical proposal, not the new default. The interrupted full-input A1 pilot reached3.006GiB sampled
RSS before an1800s timeout in edgeR fitting. That is not a completed-run memory bound. Follow the
existing budget review: begin a new equal-arm pilot proposal at14400s, then freeze measured limits.

T05: first attempt all source rows and the eight v0.4 fields, using streaming preparation rather
than loading the full textual table twice. Do not move P/SE/coordinate/allele QC, duplicate handling,
sorting or gene-background construction from timed analysis into preparation. Keep source row counts
and invalid rows. Full-source preparation and whole-workflow/C2 serialization must pass the16GiB
host gate before formal adoption. This is an unvalidated capacity candidate, not a promise of fit.
The previous8–32GiB full-source planning range remains uncertainty evidence. If the full profile
fails, retain the failed record and explicitly freeze chr1–3, then chr1 only if necessary. Never
silently relabel a subset as full source, select rows by significance or pad data to consume RAM.
T08 data-use authorization and T10 genuine-source requirements remain those of v0.4.

## 3. Memory budget and16GiB host gates

Run one task and one arm at a time (`jobs=1`) on `r6a.large`,2vCPU/16GiB. Use the same fixed
BLAS/thread configuration across arms. Restore cautious planning envelopes: T01:8–12GiB,
T02:2–4, T03:4–8, T04:4–8, T05 full candidate:8–32, T06:4–8, T07:4–8, T08:4–8,
T09:2–4 and T10:8–16. These are estimates, not measured peaks or allocations that must be used.
T05 and T10 ranges explicitly overlap/exceed the16GiB host envelope; do not mark them validated.
The former lower budgets for T04/T06/T07/T08/T10 had no full-data measurement supporting the reduction.
Seven T02–T10 input scopes were unchanged in draft.1/2; changing a budget did not remove observations.

Prefer at least12GiB currently available RAM before a heavy pilot. The start threshold is
min(12, the planned upper working estimate+3)GiB; light T02/T09 thus require7GiB. Reserve3GiB for the
host; warn at10GiB and terminate at11GiB sampled task-process-tree RSS, or earlier if available
host RAM falls below3GiB. Record pressure/swap and keep all terminated attempts. These supervisors
are implemented and tested on local child processes; sampling is not a hard kernel memory cap. Require successful
preparation, complete canonical workflows, all execution paths and C2 serialization before freezing
an input. A low peak from an interrupted run is insufficient. If a complete profile fails, use a
predeclared real subset or report it as unsupported on this host; do not silently simplify the science.

Keep T01 at250000 target cells initially. Its3.756GiB core capacity is not a complete peak, and its
8–12GiB estimate overlaps the11GiB stop threshold. Use existing200000/150000 fallback tiers only
if the target fails; record the selected scope. The optional300000-cell pressure tier is suspended
for this16GiB profile. Do not use swap to manufacture slow reads.

The v0.4 full-T01 guards (975275 cells,64GiB host,40.057GB preparation reservation) remain valid.
Implement separate versioned input profiles and host-aware gates; do not disable the old full guard.
Each arm receives identical fully resident input. Preparation streaming is outside measured analysis,
not an arm-specific lazy-input substitute. Registry `input_profile` replaces the historical
`local32_profile` field because scientific input scope is independent of host capacity.

## 4. Make loading cost visible

The historical v0.3 input is100000 real cells,1636075918bytes. Its five fresh-process read probes
had median2.28seconds (`REPORT-v0.3-read-probe.zh-CN.json`). Formal A1 input reads were2.274,
2.334 and2.122seconds; these are distinct measurement series.

A250000-cell subset is roughly2.5times that cell count. A planning estimate is3.5–4.5GB RDS,
with a simple proportional read-time estimate around5.7seconds. This is not an observed result:
stratification, nonzero counts, deserialization, runtime and OS cache affect actual loading.

Before formal freeze, alternate five fresh Rscript --vanilla read probes of the unchanged100000-cell
reference and the candidate input. Time readRDS only, matching the old probe's namespace-loading
semantics. Record all probes, files, checksums, size, memory and uncontrolled cache state. Aim for
candidate median>=2times the matched reference, with the historical2.28seconds shown separately.
If250000 cells meet memory gates but miss the loading-pressure target, do not increase the tier on the16GiB host; the former optional300000-cell profile is suspended. Do not tune against A1/C1 performance.
If no safe tier reaches the target, report that limitation; do not manufacture a slower input.

Formal totals include initial loading. Report original-input read count/time, RDS state restore/save
count/time/bytes, R-process starts, tool execution and end-to-end time separately. Request/tool/I/O
spans overlap and are not additive; gaps are not pure thinking time. readRDS includes deserialization,
not measured physical disk transfer. C1 may batch or reuse files naturally. C2 restores actual declared
dependencies (T01 currently needs raw in requests1 and3), not a forced reload on every R block.
A1/C3 normally load raw once; actual C1 events decide its count. Retain the C3 batching control.

## 5. Implementation and collection order

1. Use implemented profile-aware T01 preparation, the full T03 input and streaming eight-field T05 preparation.
   Reuse v0.4 logic; preserve default full-profile behavior and old provenance.
2. Use the versioned runner and explicit input profiles. Reuse v0.4 science, artifacts,
   metrics, fake provider and checkers. Adapt only scope-dependent expectations and user wording.
   Record task/profile versions, source/selected IDs, dataset hash and memory/timing configuration.
3. Re-run the supplied offline acceptance on Linux. Tests cover real-row subsetting, ID alignment, sparse representation,
   complete workflow correctness, changed scientific scope, and memory-stop record retention.
4. Perform local memory and matched read calibration, then one complete five-arm pilot per task.
   Inspect model extra work and I/O instrumentation. Freeze only successful pilots and actual limits.
5. Collect fresh v0.5 results sequentially T01→T10, report/open HTML after each task. Initial timeout
   proposals are14400seconds for restored-full T03,3600 for T01/T04/T05/T07 and1800 for the others; finalize equally across
   arms from the pilots. Keep the existing token ceiling and unknown subscription-cost accounting.

Implemented paths: `data/v05/Txx`, `runs/v05-*`, runner `v0.5/run.py`.
Commands are in `v0.5/aws/RUNBOOK.md`; ready code does not imply all genuine inputs or remote pilots are ready. Calling v04.py on a cropped T01 input
will correctly fail its old full-tier guard. Do not overwrite v0.3/v0.4 datasets, locks or results.

## 6. Acceptance and version history

Acceptance requires all ten v0.4 task families and218 reference blocks retained; genuine, immutable
subsets and correct cohort-specific outputs; safe measured memory on this16GiB host; explicit loading
calibration outcomes; complete prescribed trials with failures retained; and per-task Chinese HTML.
If the loading target is missed within the safe envelope, the report must say so, not silently narrow
scope or classify a desired read-time target as already achieved. The250000-cell barcode selection is audited, but its full count matrix has not yet been prepared
or measured. The100000-cell reference capacity probe is not a formal v0.5 collection or a
250000-cell result. Update version/time and log on every subsequent plan edit.

| Version | UTC | Change |
|---|---|---|
|0.5.0-draft.1|2026-10-31T06:12:40Z|Derive local32 profiles from v0.4 draft.6; retain all science/arms/repeats; crop T01/T03/T05 and add safe loading-pressure calibration.|
|0.5.0-draft.2|2026-10-31T06:45:03Z|Renew AWS host planning; audit250000 genuine cell IDs/metadata; measure100000-cell reference capacity; recommend32GiB r6a.xlarge using read-only AWS pricing checks. Full250000-cell trial deferred by user.|
|0.5.0-draft.3|2026-10-31T07:47:11Z|Select16GiB r6a.large; restore full576-sample T03 and cautious estimates; attempt full-source streaming T05 with explicit fallbacks; add11GiB RSS/3GiB host-headroom gates. Thirty-task expansion is a separate v0.6 proposal.|
|0.5.0-draft.4|2026-10-31T23:10:05Z|Prioritize T01–T10 as v0.5 using the common v0.6 method; implement versioned runner/profiles/resource guards/read probes/reports; verify AWS reads and launch-permission DryRun; add complete deployment/run/stop runbook. Remote inputs/pilots remain pending.|
|0.5.0-draft.5|2026-10-31T23:32:54Z|Fix the inherited T09 author-file URL after a real404; prepare and shape-check all968samples/189metabolites without model calls. Include available v0.5 inputs in delivery manifests. Shared preparation source changes, so prior source locks must not be reused; historical results remain untouched.|
|0.5.0-draft.6|2026-11-01T18:39:41+00:00|User authorizes one AWS host and T01 first; record actual launch/SSH/data-volume acceptance. Add detached atomic job status with hourly active-agent inspection, fix fresh-Linux package detection and manifest implementation labels. Scientific scopes/arms/repeats unchanged; runtime-only journal is separate from the design report.|
|0.5.0-draft.7|2026-11-01T18:56:07+00:00|Fix T01 preparation in a fresh R process by loading the Matrix namespace before constructing dgCMatrix. Add a cold-process regression test. Preserve the intentionally stopped first preparation attempt and rerun with fresh evidence. Scientific input scope, arms, model/reasoning and repetitions are unchanged.|
|0.5.0-draft.8|2026-11-01T19:42:08+00:00|Make the exact required artifact filenames visible to both real agents. Repair the Ubuntu Codex sandbox environment through a binary-specific userns profile; keep sandboxing enabled. Per user instruction skip standalone offline acceptance and run the real pilot immediately after preparation; perform matched read calibration after pilot and before freeze. Preserve all earlier failed trials; numerical checks, input, model and repeats unchanged.|
|0.5.0-draft.9|2026-11-01T19:54:38+00:00|State the existing T01 reference sensitivity output contract explicitly for both real agents: two exact setting labels, eight lineage/setting rows, time-I tissue contrast and BH across eight P values. Preserve all previous pilot outputs; no checker, biological method, input, model or repeat count is changed.|
|0.5.0-draft.10|2026-11-01T20:00:27+00:00|Expose existing required CSV column names to both real agents, including marker-evidence.csv gene/value columns. This closes output-schema ambiguity observed in C1 without altering the evaluator, numerical methods or data. Preserve earlier pilots and collect fresh results after deployment.|

## 7. AWS capacity and purchasing proposal

Read-only AWS CLI Pricing and instance-type queries reconfirm `r6a.large`:2vCPU,16GiB, x86_64,
Linux/Shared in `us-east-1`, USD0.1134/hour on demand. The previous32GiB r6a.xlarge is a larger
fallback reference, not the current purchase target. One host for T01 is now authorized and launched; additional hosts are outside this goal.

Retain the200GiB total gp3 proposal:40GiB system/environment and160GiB data/results. At the same
USD0.08/GiB-month and one USD0.005/hour public IPv4,168 active hours with matching disk/address
retention cost about USD23.57. Retaining disks through an entire budget month costs USD16 even
while compute is stopped; snapshots cost extra. This is not a thirty-task completion-cost estimate.
The requested two encrypted gp3 volumes were created with the host. No AMI or snapshot has been created.

Capacity audit selects250000 actual source IDs across912 nonempty strata, retaining22 patients.
Their source annotations sum to336007617 nonzero entries, giving4033091408 bytes (3.756GiB)
for double values, integer row indices and column pointers, plus38021128 bytes of selected metadata.
This is source-annotation-derived capacity, not a resident-matrix peak. Whole-source annotation
nonzeros match the source Matrix Market header; selected counts still require independent verification.

One isolated100000-real-cell run executes all20 v0.4 T01 reference blocks and its scientific checker.
It passes18 scientific checks and exact annotation comparison. Sampled process-tree peak is2.860GiB;
readRDS takes2.566s in that one probe. It is a reference diagnostic, not a live agent trial or a new
five-repeat read calibration. Proportional nonzero-based extrapolation gives about7.16GiB, while the
original8–12GiB working budget remains a planning range with margin; neither is a250000-cell peak.
The user now selects16GiB. These earlier reference results support only guarded preflight, not
a claim that the full250000-cell task or every task fits. Apply the new11GiB stop/3GiB headroom gates.

Memory/selection evidence: `runs/v05-capacity-250000/`; diagnostic source: `v0.5/tools/`.
Current pricing evidence: `v0.5/aws/AWS-16G-v3.zh-CN.json`. Previous32GiB pricing/report remain
historical. Scope audit: `v0.5/aws/SCOPE-16G-AUDIT-v1.zh-CN.md`; expansion proposal:
`v0.6/plan.md`. Local Chinese artifacts remain ignored.
AWS EBS limits and filesystem cache differ from this Mac: repeat the five matched read probes on
whichever host is eventually authorized. Do not convert the local2.566s or historical2.28s into an
AWS loading-time claim. Scientific task scope, arms, model/reasoning and repetitions remain unchanged.

## 8. AWS execution plan and actual CLI verification

Use `v0.5/aws/RUNBOOK.md` as the executable operator sequence; it includes the source/input transfer,
Linux installation, model login, preparation, offline execution, real pilot, freeze, formal collection,
report retrieval and Stop/AMI steps. The current2026-11-01 user goal authorizes T01 launch and execution, not a promise to finish all ten tasks.

Current read-only verifier: `python3 dev/bench/biomedical/v0.5/aws/verify.py --output NEW.json`.
It supports only listed Get/Describe operations, hashes identity and cannot create/start/stop/delete
resources or run a launch DryRun. All15 read operations passed in the stored implementation check:
identity, pricing,2vCPU/16GiB/x86_64 type, AZ offerings, quota, default network components, keys,
instances, public Canonical SSM image parameter and verified image. The local R environment and
Codex login also passed when process supervision was permitted. These are not remote checks.

A separate one-off RunInstances request with mandatory `--dry-run` returned `DryRunOperation`:
r6a.large in1a, encrypted40GiB root+160GiB data gp3, automatic IPv4 and tags. It created no resources.
The final keypair/security-group/subnet request must still be rechecked on launch day. DryRun proves
permissions for its request, not instantaneous capacity, SSH or remote R/model operation.

Verified facts: Standard regional quota256vCPU; no regional instances observed in the initial
snapshot; default VPC/public-network components present; r6a.large offered in1a/1b/1c/1d/1f, not1e.
Canonical Ubuntu24.04amd64gp3 resolved to ami-0d6dd9e8265d48906 in today's check; re-resolve and
freeze the actual AMI on launch day. Never assume the floating current parameter is a frozen image.

Under the explicit T01 authorization, the reviewed launch request was filled with final network/key values.
For any future authorized launch,
perform a final DryRun, then create exactly one instance and the two volumes. Use client-restricted
SSH and existing public networking; no NAT Gateway/load balancer/Elastic IP is needed. Verify the
new blank data volume by volume ID before formatting; mount at `/data` and place source/data there.
The runtime wrapper places workspaces/R temporary files on `/data/gptr-tmp`, not the small root disk.
Do not transfer local secrets, AWS/Codex credential files or the Mac R library. A local source archive
and checksum manifest can be prepared without creating cloud storage or uploading anything.

`setup-linux.sh --install` installs only on an authorized Ubuntu24.04x86_64 host. It has local syntax
validation, not a completed cloud-install test. The operator uses interactive model login on the
host; environment images should be taken before embedding runtime credentials. Freeze actual Linux
R/package/Codex/Python versions after offline acceptance; never reuse Mac timing as an AWS result.
Initialize restored snapshot volumes before I/O calibration. Workspace staging/scope audits are
outside measured arm time and can affect cache; initial measured RDS loads remain inside each arm.

The latest user instruction selects T01 first. Perform Linux acceptance and T01 subset/resource
validation, then its complete pilot/freeze/formal sequence. Do not start T02–T10 under this goal. Use `offline`, then `pilot --live`, `freeze`, `formal --live`. Real commands require
GPTR_LIVE_TESTS=true; the registry/source/input/host/runtime/thread lock is checked before formal
collection. T01 freeze also requires five matched reference/candidate read probes with the same
candidate hash and original100000-cell reference. A ratio miss is recorded, not fabricated away.
Keep each failed/quota/timeout/memory attempt; never overwrite directories or mix pilots into formal
rows. Report/open HTML after each task before proceeding. The full975275-cell T01 remains held.

Today's local evidence includes30 task/protocol fixture combinations through inherited A2/C2/C3,
version-specific input/safety tests and a genuine-input T02 offline smoke with all three arms passing.
That smoke is a development diagnostic on the Mac, not a16GiB AWS pilot or a formal v0.5 sample.
Prepared genuine inputs currently available are full T02, full T03 and full T09. T01 raw sources/selected IDs
exist but its250000-cell matrix is deferred; other task source preparation/access and all remote
full-workflow resource gates remain to be completed before their real collection.

See `runs/v05-aws-preflight-20261031/`, `runs/v05-code-smoke-T02/` and the local test logs named in
this revision's Chinese execution report. Stop only after results are written/retrieved; EBS and
snapshots remain billable. Long-storage AMI/snapshot creation and releasing originals require their
own authorized execution and restoration checks, not an accidental Terminate.

## 9. Active T01 execution journal and inspection

Use `v0.5/tools/job.py run` behind a detached process for long work; read its small JSON status with
`job.py status`. PID and create-time must still match; a stale running file is orphaned, not complete.
The active agent inspects long scientific jobs hourly after confirming launch; installation, transfer
and completion transitions are reported when observed. Keep every attempt and source/input identity.

The user explicitly requests a new `v0.5/docs/RUN-T01.zh-CN.html` run report, appended by UTC stage
and opened in VS Code after updates. It records actual process/transfer/resource/errors/results only;
retain `REPORT.zh-CN.html` for the comprehensive design. No external notification service is required.
The Linux installer failed once because find.package returned character(0) for absent packages;
retain setup.log/exit1 and the independently logged retry. No formal pilot has yet been accepted.

Execution revision 0.5.0-draft.11 / 0.5.0-dev.10 · 2026-11-02T18:39:08+00:00: apply the maintainer’s direct-run simplification; remove outer guards and obsolete control utilities, retain input hashes and scientific evaluation, prepare the existing AWS environment and synchronize code.
