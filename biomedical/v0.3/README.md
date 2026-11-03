# v0.3: real single-cell experiment

Status: completed on 100,000 real GSE236581 cells and all 36,027 genes; 66 valid formal executions.

| Path | Contents |
|---|---|
| [plan.md](plan.md) | Scientific plan, version and dated change history |
| [results/](results/report.md) | Reviewed report, 66-row summary, input provenance, manifests and captured trajectories |
| [real-data-source-review.md](real-data-source-review.md) | Public real-data source selection |
| `docs/REPORT-v0.3-full.zh-CN.html` | Local full Chinese report, request diagrams and loading-time analysis |
| `docs/RESULTS-v0.3-detailed.zh-CN.html` | Local experimental-design explanation |
| `docs/REPORT-v0.3-*.zh-CN.*` | Timing tables, read probes, figures and supporting evidence |

Runtime: [../run.py](../run.py), [single-cell task](../tasks/single-cell.R),
[preparation](../prepare-single-cell.R). Inputs remain under
`../data/gse236581/` and `../data/gse236581-100000/`; original runs remain in
`../runs/gse236581-v0.3/` and the separately frozen capture collections.
Chinese documents and their figures remain Git ignored. Frozen result files keep their original bytes.

Directory layout revision: 1. Updated UTC: 2026-10-31T06:24:20Z. No scientific protocol change.
