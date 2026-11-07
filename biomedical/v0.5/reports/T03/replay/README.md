# T03: trace and code only

Start with **A1-2**, the A1 run shown in the Gantt. This bundle contains no input dataset and no final scientific result tables.

- [Model messages](A1-2/messages.md): recorded model text and tool-call blocks.
- [Event trace (public copy)](A1-2/trace.jsonl): prompts, messages, tool inputs/returns and timestamps.
- [Original file-read trace](A1-2/io.jsonl).
- [Readable ordinary R](A1-2/ordinary.R).
- [Peter replay document](A1-2/recorded.R).
- [Tool timing](tool-timing.csv) and [Gantt intervals](timeline.csv).
- [Version](gptr-version.json): gptr 1.0.1 commit `5e2992b13824fbf5218428d379a336dd44acddbb`.

All six formal runs' public trace copies are retained; all three A1 runs include code and replay documents. Messages are the outputs captured by the benchmark, not a token-by-token stream or a guarantee of unrecorded internal reasoning.

## Replay

With the original inputs and R dependencies already available:

```bash
export GPTR_SOURCE=/path/to/gptr-1.0.1-5e2992b
Rscript --vanilla replay.R /path/to/original/T03 /path/to/new-work A1-2
```

The script links input files into the new work directory and replays recorded code without a model. It naturally writes the outputs requested by that code; no further output verification is required to inspect or profile it.

## What replay means here

The original experiment saved events, not a native `gptr_doc()` document. `recorded.R` is a derived Peter document made from unchanged original tool inputs using an offline provider. Document generation used checkpoint off after a default-checkpoint recording attempt exceeded the memory guard. The original trace and historical timings remain unchanged.

The native document path has already run successfully for all three A1 trials. A1-1 also needs its recorded non-R write effect, restored by the wrapper. Replaying code does not recreate model thinking, network waits or the historical end-to-end wall time. Use the original trace for those observations; use replay to inspect/profile the code.

Do not pool derived/offline timings with the original formal experiment. Public copies omit internal system/developer instruction content and account identifiers. Redundant native session/transport logs are omitted. Original records remain archived privately; see ../PROVENANCE.json for hashes.
