# Clinical benchmark pilot

Exploratory results; repeats of one trajectory are not independent model trials.

| Arm / source | Success / attempts | Median wall (s) | Min–max (s) |
|---|---:|---:|---:|
| A1 / live | 3 / 3 | 47.956 | 45.809–50.071 |
| C1 / live | 3 / 3 | 69.019 | 60.104–73.010 |
| A2 / canonical | 10 / 10 | 8.065 | 8.039–8.626 |
| C2 / canonical | 10 / 10 | 2.011 | 1.972–2.144 |
| C3 / canonical | 10 / 10 | 0.830 | 0.820–0.899 |
| A2 / A1-1 | 10 / 10 | 8.341 | 8.313–8.381 |
| A2 / A1-2 | 10 / 10 | 7.825 | 7.512–9.505 |
| A2 / A1-3 | 10 / 10 | 7.643 | 7.503–7.791 |

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
