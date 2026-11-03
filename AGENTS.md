# GPT-R Bench

Keep the benchmark independent of the gptr package repository.
The active implementation is biomedical/v0.5/aws; older versions and reference/ are historical.
Read README.md and biomedical/v0.5/aws/RUNBOOK.md before running experiments.
Set GPTR_SOURCE to the external gptr source checkout; never vendor its source or credentials.
Keep prompts shared by A1 and C1. Prioritize elapsed time and actual tool calls in reports.
Use Rscript --vanilla, R assignment =, and offline fake-provider tests.
Live runs require GPTR_LIVE_TESTS=true. Do not put data, runs, runtime packages or credentials in Git.
Preserve raw experimental records, including their original paths and hashes.
