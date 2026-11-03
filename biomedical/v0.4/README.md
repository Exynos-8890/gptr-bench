# v0.4: ten-task biomedical suite

Status: implementation available; T02 formal collection completed; T03 interrupted.
Execution is paused by the user. The local-host adaptation is [v0.5](../v0.5/README.md).

| Path | Contents |
|---|---|
| [plan.md](plan.md) | Versioned execution contract, scientific tasks and validation gates |
| [tasks.json](tasks.json) | Ten-task registry and reference block counts |
| `docs/SCALEUP-v0.4-plan.zh-CN.html` | Local Chinese ten-task design and paper comparison |
| `docs/IMPLEMENTATION-v0.4.zh-CN.html` | Local implementation and offline validation report |
| `docs/RESULTS-v0.4-T02.zh-CN.html` | Local T02 results and timing diagrams |
| `docs/RUN-v0.4.zh-CN.html` | Local execution journal, interruptions and evidence links |
| `aws/` | Superseded AWS study and pricing evidence; local Chinese artifacts |

Runtime remains [../v04.py](../v04.py), [task modules](../tasks/v04/),
`../prepare-v04-*` and [tests](../tests/). Registry module/prepare paths are relative to
`dev/bench/biomedical/`, not this version directory. Prepared inputs remain in `../data/v04/`.
Original measured evidence stays in `../runs/v04-*`; do not relocate or rewrite frozen collections.
The original plan and registry aliases remain available at `../v04-plan.md` and `../v04-tasks.json`.

Directory layout revision: 1. Updated UTC: 2026-10-31T06:24:20Z. No scientific protocol change.
