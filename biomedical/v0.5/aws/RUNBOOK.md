# Operator commands

Run from `/data/gptr` on AWS. See [README.md](README.md) for output locations and review policy.

```bash
export GPTR_SOURCE=/absolute/path/to/gptr
b=biomedical/v0.5/aws
bash "$b/with-env.sh" python3 "$b/run.py" preflight
GPTR_LIVE_TESTS=true bash "$b/with-env.sh" python3 "$b/run.py" pilot
GPTR_LIVE_TESTS=true bash "$b/with-env.sh" python3 "$b/run.py" formal
```

Only A1/Peter and C1/Codex run. There is no `offline` benchmark command or automatic scientific checker.
After execution, review model-generated tables, plots, report and trace manually; execution success is not correctness.
For a detached run, apply the same command with `nohup` and redirect output to the chosen run log.

Offline developer tests (no real model requests):

```bash
bash "$b/with-env.sh" python3 -m unittest discover -s biomedical/v0.5/tests -p 'test_*.py'
```
