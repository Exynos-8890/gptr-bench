# Biomedical benchmark v0.5

Implementation: **0.5.0-dev.16**. Current workflow: two live arms, shared prompts, manual review.
This maintainer-directed simplification supersedes the reference/replay/scoring workflow in older plans and reports.

- [Latest T01 experiment report](docs/REPORT-T01-live.en.html)
- [Current source and run instructions](aws/README.md)
- [Operator commands](aws/RUNBOOK.md)
- [Current developer tests](tests/)
- [Local historical references, excluded from AWS](reference/README.md)

The active AWS tree contains no task reference solutions or automated scientific checkers.
Peter and Codex generate their own artifacts. Codex reviews those artifacts with the user;
`status=ok` only means execution completed, and scientific review starts as `pending`.
Original input data remains in place; superseded T01 results were deleted at the maintainer’s request. Native R document replay is still separate work.
