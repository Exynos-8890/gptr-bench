"""Real offline Rscript executions: no retained heap or stdin command service."""
import importlib.util
import json
import os
from pathlib import Path
import subprocess
import tempfile
import unittest


AWS = Path(__file__).resolve().parents[1]/"aws"


def load():
    spec=importlib.util.spec_from_file_location("one_shot_execution",AWS/"shared/execute.py")
    module=importlib.util.module_from_spec(spec);spec.loader.exec_module(module)
    return module


class OneShotRscriptTest(unittest.TestCase):
    def test_fresh_heap_file_reuse_closed_stdin_and_recorded_exit(self):
        m=load()
        with tempfile.TemporaryDirectory() as temporary:
            root=Path(temporary)
            runtime=root/"instrumentation"
            env={**os.environ,**m.launchers(root/"launchers",runtime,one_shot=True)}
            events=root/"io.jsonl";env["GPTR_BENCH_IO_EVENTS"]=str(events)
            commands=[
                'sentinel = 42; saveRDS(list(value = sentinel), "cache.rds")',
                'stopifnot(!exists("sentinel", envir = globalenv()), readRDS("cache.rds")$value == 42); '
                'con = file("stdin", "r"); incoming = readLines(con, n = 1); '
                'stopifnot(length(incoming) == 0); cat("fresh heap and EOF\\n")',
            ]
            for program in commands:
                result=subprocess.run([str(runtime/"bench-rscript"),"--vanilla","-e",program],
                    cwd=root,env=env,input='stop("stdin commands must not execute")\n',
                    capture_output=True,text=True,timeout=30)
                self.assertEqual(result.returncode,0,result.stdout+result.stderr)
            rows=[json.loads(line) for line in events.read_text().splitlines()]
            starts=[e for e in rows if e["operation"]=="rscript_start"]
            ends=[e for e in rows if e["operation"]=="rscript"]
            self.assertEqual(len(starts),2)
            self.assertEqual(len(ends),2)
            self.assertEqual(len({e["program_id"] for e in starts}),2)
            self.assertEqual({e["program_id"] for e in starts},{e["program_id"] for e in ends})
            self.assertTrue(all(e["success"] for e in ends))
            self.assertTrue(m.process.codex_policy.audit_io(events)["compliant"])
            # Standard Rscript also uses the same adapter; interactive R is rejected.
            result=subprocess.run([str(root/"launchers/Rscript"),"--vanilla","-e","stopifnot(!exists('sentinel'))"],
                cwd=root,env=env,capture_output=True,text=True,timeout=30)
            self.assertEqual(result.returncode,0,result.stdout+result.stderr)
            result=subprocess.run([str(root/"launchers/R"),"--interactive"],env=env,capture_output=True,text=True)
            self.assertEqual(result.returncode,64)
