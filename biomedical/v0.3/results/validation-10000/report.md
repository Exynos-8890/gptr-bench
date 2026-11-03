# Biomedical benchmark pilot

Exploratory results; repeats of one trajectory are not independent model trials.

| Arm / source | Success / attempts | Median wall (s) | Min–max (s) |
|---|---:|---:|---:|
| A1 / live | 1 / 1 | 52.982 | 52.982–52.982 |
| C1 / live | 1 / 1 | 62.188 | 62.188–62.188 |
| A2 / canonical | 1 / 1 | 7.976 | 7.976–7.976 |
| C2 / canonical | 1 / 1 | 3.215 | 3.215–3.215 |
| C3 / canonical | 1 / 1 | 1.329 | 1.329–1.329 |
| A2 / A1-1 | 1 / 1 | 8.353 | 8.353–8.353 |

[Wall-time plot](wall-time.svg)

Total time includes initial loading and agent overhead. Download/generation, environment setup and evaluation are outside the timed interval.
R evaluation and tool spans overlap and must not be added. CLI provider turns include tool work; pure model waiting is unknown.
Memory is sampled RSS summed over the process tree, not exact peak or unique memory. Blank values are unknown.
Input/artifact byte counts describe files, not measured device I/O. OS cache state is uncontrolled; no cold-cache claim is made.
Codex costs may be unavailable. Token ceilings are checked at turn boundaries; unknown cost is not a measured zero.

Manifests, traces, per-run evaluations and summary.csv accompany this report.

Reviewed summary copy. Full traces and per-run checks remain in `../../../runs/gse236581-v0.3-validation/`.
