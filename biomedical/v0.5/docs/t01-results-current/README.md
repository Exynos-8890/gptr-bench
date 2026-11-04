# Latest T01 public report assets

These are aggregate measurements from
`v05-T01-dev20-one-shot-confirmation-20261104T065528Z`.
The measured benchmark source is dev.20. The current cleaned runner is dev.21;
no new live measurements were made for this publication cleanup.

- `all-attempts.csv`: all six planned runs, including elapsed time, actual tool
  calls, input reads, token totals and sampled memory.
- `group-statistics.csv`: median, minimum and maximum per arm.
- `additive-mean-differences.csv`: additive mean C1-minus-A1 time components.
- `timeline.csv`: real median-run request/R execution/input-read spans.
- `shared-prompts.json`: exact frozen profile received by both arms.
- `provenance.json`: original source/data/prompt hashes, source file checksums
  and postcollection review scope.
- `comparison.png`, `signed-time.png`, `gantt.png`: figures in the English report.

Raw records, their original paths and hashes are preserved locally under
`biomedical/runs/`; raw session transcripts, patient records and runtime packages
are not published. The exact pre-cleanup source is retained in local archives.

## Rebuild without running an experiment

From the repository root, with the original local records available:

```bash
python3 biomedical/v0.5/docs/t01-results-current/prepare-report.py
Rscript --vanilla biomedical/v0.5/docs/t01-results-current/plot.R biomedical/v0.5/docs/t01-results-current
```

The plot step needs only the public CSVs. To render with the installed
`answer-me-with-html` CLI and retain raster chart fullscreen/pan/zoom controls:

```bash
node /path/to/answer-me-with-html/scripts/am.mjs render biomedical/v0.5/docs/REPORT-T01-live.en.md --no-open -o biomedical/v0.5/docs/REPORT-T01-live.en.html
python3 biomedical/v0.5/docs/t01-results-current/enable-image-viewer.py biomedical/v0.5/docs/REPORT-T01-live.en.html
```

The HTML embeds its figures and opens offline as a single file. It uses no
external script or image requests. GitHub's repository viewer shows HTML source;
download the HTML to use its interactive controls.
