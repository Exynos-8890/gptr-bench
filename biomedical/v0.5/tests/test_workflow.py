"""Both live adapters retain evidence for manual review; tests never contact a model."""
import importlib.util
import json
import os
from pathlib import Path
import subprocess
import tempfile
import unittest
from unittest.mock import patch

AWS = Path(__file__).resolve().parents[1] / "aws"
REPO = AWS.parents[2]


def runner():
    spec = importlib.util.spec_from_file_location("live_runner", AWS / "run.py")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


class WorkflowTest(unittest.TestCase):
    def test_collect_runs_only_two_live_arms_without_scoring(self):
        m = runner()
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            source = root / "T01"
            source.mkdir()
            (source / "input.rds").write_bytes(b"fixture")
            (source / "dataset.json").write_text(json.dumps({"input_sha256": m.digest(source / "input.rds")}))
            output = root / "results"
            output.mkdir()
            config = dict(task="T01", input_root=str(root), phase="pilot", timeout=30, token_limit=1000, cost_limit=5)
            with patch.dict(os.environ, GPTR_LIVE_TESTS="true"), \
                 patch.object(m.execution, "run_arm", return_value=dict(arm="test", trial=1, status="ok", review_status="pending")) as run, \
                 patch.object(m.platform, "platform", return_value="test-platform"), \
                 patch.object(m.subprocess, "check_output", return_value="test-codex"):
                self.assertEqual(m.collect(config, output), 0)
            self.assertEqual([c.args[0] for c in run.call_args_list], ["A1", "C1"])
            self.assertEqual(json.loads((output / "manifest.json").read_text())["review_status"], "pending")
            self.assertFalse((output / "prepared/task.json").exists())

    def test_codex_uses_shared_prompts_and_leaves_outputs_pending_review(self):
        m = runner()
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            source = root / "source"
            source.mkdir()
            (source / "input.rds").write_bytes(b"fixture")
            prompts = []
            def measured(*args, **kwargs):
                prompts.append(kwargs["prompt"])
                Path(kwargs["cwd"], "plot.svg").write_text("fixture plot")
                for event in [dict(type="thread.started", thread_id="test"),
                              dict(type="turn.completed", usage=dict(input_tokens=10 * len(prompts), output_tokens=len(prompts)))]:
                    kwargs["events"].append((1, json.dumps(event)))
                return dict(status="ok", sampled_peak_rss_bytes=1, memory_scope="process_tree", exit_code=0)
            settings = dict(task_id="T01", dataset_sha256="test", codex_model="test", token_limit=1000)
            with patch.object(m.process, "measure", side_effect=measured):
                row = m.execution.run_arm("C1", 1, source, root, 30, settings)
            self.assertEqual(prompts, json.loads((AWS / "prompts.json").read_text())["T01"])
            self.assertEqual(row["input_tokens"], 30)
            self.assertEqual(row["review_status"], "pending")
            self.assertEqual(row["status"], "ok")
            self.assertTrue(Path(row["workspace"], "plot.svg").exists())
            self.assertFalse((root / "C1-1/evaluation.json").exists())

    def test_peter_adapter_with_fake_provider_and_no_reference_modules(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            config = dict(gptr_source=os.environ["GPTR_SOURCE"], aws=str(AWS), task_id="T01", prompt_file=str(AWS / "prompts.json"),
                workspace=str(root), input=str(root / "input.rds"), private=str(root / "private"),
                trace=str(root / "trace.jsonl"), io_events=str(root / "io.jsonl"),
                ready=str(root / "ready.json"), result=str(root / "result.json"),
                timeout=30, token_limit=1000000, cost_limit=5, model="codex/gpt-6.1-sol", dataset_sha256="test")
            (root / "config.json").write_text(json.dumps(config))
            script = root / "test.R"
            script.write_text('''args = commandArgs(TRUE)
local({
  scope = new.env(parent = globalenv())
  source(args[[1]], local = scope)
  cfg = jsonlite::read_json(args[[2]])
  saveRDS(list(value = 42), cfg$input)
  scope$commandArgs = function(...) c("execute", args[[2]])
  scope$peter = function(..., model = NULL) {
    if (is.null(model)) return(gptr::peter(...))
    fake = gptr::gptr_fake_provider(function(request) {
      if (request$n %% 2L) list(tool = "r", input = list(code =
        "write.csv(data.frame(value = raw$value), 'result.csv', row.names = FALSE)"))
      else list(text = "Done")
    })
    gptr::peter(..., model = fake)
  }
  scope$bench_main()
})
''')
            result = subprocess.run(["Rscript", "--vanilla", str(script), str(AWS / "peter.R"), str(root / "config.json")],
                env={**os.environ, "GPTR_LIVE_TESTS": "false"}, text=True, capture_output=True, timeout=90)
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
            metrics = json.loads((root / "result.json").read_text())
            self.assertEqual(metrics["tool_calls"], 3)
            self.assertEqual(metrics["review_status"], "pending")
            trace = [json.loads(line) for line in (root / "trace.jsonl").read_text().splitlines()]
            self.assertEqual([e["data"]["prompt"] for e in trace if e["type"] == "request_start"],
                             json.loads((AWS / "prompts.json").read_text())["T01"])
            self.assertIn("42", (root / "result.csv").read_text())


if __name__ == "__main__":
    unittest.main()
