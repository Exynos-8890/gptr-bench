# GPT-R Bench

Keep the benchmark independent of the gptr package repository.
The active implementation is biomedical/v0.5/aws; older versions and reference/ are historical.
Read README.md and biomedical/v0.5/aws/RUNBOOK.md before running experiments.
Set GPTR_SOURCE to the external gptr source checkout; never vendor its source or credentials.
Keep prompts shared by A1 and C1. Prioritize elapsed time and actual tool calls in reports.
C1 must use finite one-shot native Rscript processes for all new experiments.
Do not allow interactive/persistent R, PTY R command loops, or R services in C1.
Each Rscript must finish and exit; cross-execution reuse uses files, not a live R heap.
Keep this C1 execution condition separate from the shared scientific user prompts and record it.
Use Rscript --vanilla, R assignment =, and offline fake-provider tests.
Live runs require GPTR_LIVE_TESTS=true. Do not put data, runs, runtime packages or credentials in Git.
Preserve raw experimental records, including their original paths and hashes.
