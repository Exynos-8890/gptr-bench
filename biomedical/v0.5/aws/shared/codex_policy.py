"""User-required C1 execution condition, separate from shared scientific prompts."""
import json
from pathlib import Path


NAME = "one-shot-rscript"
INSTRUCTIONS = (
    "C1 benchmark execution condition required by the user: perform R calculations "
    "only with ordinary, finite, one-shot Rscript processes. Use "
    "./instrumentation/bench-rscript --vanilla FILE.R (or -e CODE), which runs Rscript "
    "and records timing. Each R execution must finish and exit; its in-memory objects "
    "must not survive to another execution. Do not start interactive R, use a PTY for R, "
    "read R commands from stdin, or create an R server, daemon or command loop. "
    "Do not send R code through write_stdin. Empty-output polling of a finite Rscript "
    "job is allowed. Wait for all Rscript jobs to finish before completing a request. "
    "Reuse completed files between scripts when useful. The Codex conversation may "
    "retain text history, but must not retain a live R session. Do not bypass the "
    "instrumented Rscript launcher or its closed stdin. These are execution conditions; "
    "all shared scientific requests and statistical definitions still apply."
)


def audit_io(path):
    """Reject a request that leaves an instrumented R program running."""
    events = []
    if path and Path(path).exists():
        events = [json.loads(line) for line in Path(path).read_text().splitlines()]
    starts = [e for e in events if e["operation"] == "rscript_start"]
    ends = [e for e in events if e["operation"] == "rscript"]
    launched = {e.get("program_id") for e in starts}
    finished = {e.get("program_id") for e in ends}
    violations = []
    if (starts or ends) and (None in launched or "" in launched or None in finished or "" in finished):
        violations.append("Rscript instrumentation lacks a unique program identity")
    if len(launched) != len(starts) or len(finished) != len(ends):
        violations.append("Duplicate Rscript program identity")
    if finished-launched:
        violations.append("Rscript completed without a recorded launch")
    if launched-finished:
        violations.append("Rscript is still active at request completion")
    return dict(policy=NAME, compliant=not violations, scripts_started=len(starts),
                scripts_finished=len(ends), violations=violations)
