# Clinical benchmark pilot

Exploratory results; repeats of one trajectory are not independent model trials.

| Arm / source | Success / attempts | Median wall (s) | Min–max (s) |
|---|---:|---:|---:|
| A2 / canonical | 1 / 1 | 8.117 | 8.117–8.117 |
| C2 / canonical | 1 / 1 | 2.562 | 2.562–2.562 |
| C3 / canonical | 1 / 1 | 1.512 | 1.512–1.512 |

[Wall-time plot](wall-time.svg)

Total time includes initial loading and agent overhead. Download/generation, environment setup and evaluation are outside the timed interval.
R evaluation and tool spans overlap and must not be added. CLI provider turns include tool work; pure model waiting is unknown.
Memory is sampled RSS summed over the process tree, not exact peak or unique memory. Blank values are unknown.
Input/artifact byte counts describe files, not measured device I/O. OS cache state is uncontrolled; no cold-cache claim is made.
Codex costs may be unavailable. Token ceilings are checked at turn boundaries; unknown cost is not a measured zero.

Manifests, traces, per-run evaluations and summary.csv accompany this report.

A1 uses the configured Codex provider through gptr and its live R bridge; C1 uses the same Codex CLI/model without that bridge.
Tool counts are interface-specific: A1/A2 count R calls, C1 counts native CLI tools, and C2/C3 count canonical steps.
This reviewed summary omits machine-local workspace paths. Raw run workspaces, CLI traces and evaluations remain in the ignored runs directory.
