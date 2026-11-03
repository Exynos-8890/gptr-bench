import importlib.util
import hashlib
import json
import os
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch


BENCH = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location("biomedical_run", BENCH / "run.py")
runner = importlib.util.module_from_spec(spec)
spec.loader.exec_module(runner)


class CaptureTest(unittest.TestCase):
    def test_plain_r_replay_disables_inherited_live_mode(self):
        with tempfile.TemporaryDirectory() as root:
            directory = Path(root)
            config = {"input": str(directory / "input.rds"), "rows": None,
                      "task": str(directory / "task.json"),
                      "environment": str(directory / "environment.json"),
                      "session_info": str(directory / "session-info.txt")}
            prepared = runner.run_r("prepare", config, directory, 30)
            self.assertEqual(prepared.returncode, 0, prepared.stderr)
            task = json.loads((directory / "task.json").read_text())
            task["steps"] = [{"code": "stopifnot(Sys.getenv('GPTR_REPLAY') == 'replay', "
                             "Sys.getenv('GPTR_LIVE_TESTS') == 'false')"}]
            runner.write_json(directory / "task.json", task)
            config.update(arm="C3", workspace=root)
            with patch.dict(os.environ, {"GPTR_REPLAY": "live", "GPTR_LIVE_TESTS": "true"}):
                measured = runner.execute(config, directory, 30)
            self.assertEqual(measured["status"], "ok")

    def test_cli_r_calls_become_replay_replies_with_explicit_grouping(self):
        task = {"prompts": ["Compute"]}
        events = [
            {"turn": 1, "type": "tool_execution_start", "data": {
                "tool_name": "r", "tool_call_id": "mcp_1", "input": {"code": "x = 1"}}},
            {"turn": 1, "type": "tool_execution_end", "data": {
                "tool_name": "r", "tool_call_id": "mcp_1", "is_error": False}},
            {"turn": 1, "type": "message_end", "data": {"role": "assistant", "message": {
                "content": [{"type": "text", "text": "Done"}], "stop_reason": "stop"}}},
        ]
        trajectory = runner.capture_trajectory(events, task)
        self.assertTrue(trajectory["synthetic_request_grouping"])
        self.assertEqual(trajectory["turns"][0]["replies"][0]["input"]["code"], "x = 1")
        self.assertEqual(trajectory["turns"][0]["replies"][-1]["text"], "Done")
        events[1]["data"]["is_error"] = True
        with self.assertRaises(ValueError):
            runner.capture_trajectory(events, task)

    def test_conversion_checks_computation_before_writing_fake_input(self):
        with tempfile.TemporaryDirectory() as root:
            output = Path(root)
            source = runner.subprocess.run(
                ["python3", str(BENCH / "run.py"), "--arms", "A2", "--output", str(output / "source")],
                capture_output=True, text=True, timeout=120,
            )
            self.assertEqual(source.returncode, 0, source.stdout + source.stderr)
            trace = output / "source/A2-1/trace.jsonl"
            replayed = runner.subprocess.run(
                ["python3", str(BENCH / "run.py"), "--arms", "A2", "--replay", str(trace),
                 "--output", str(output / "replay")], capture_output=True, text=True, timeout=120,
            )
            self.assertEqual(replayed.returncode, 0, replayed.stdout + replayed.stderr)
            self.assertTrue((output / "replay/capture/fake.json").exists())
            self.assertTrue(json.loads((output / "replay/capture/compatibility.json").read_text())["ok"])
            events = [json.loads(line) for line in trace.read_text().splitlines()]
            first = next(e for e in events if e["type"] == "tool_execution_start")
            first["data"]["input"]["code"] += "\ngptr_return(cohort)"
            for event in events:
                if event["type"] == "message_end":
                    for block in event["data"]["message"]["content"]:
                        if block["type"] == "tool_call" and block["id"] == first["data"]["tool_call_id"]:
                            block["arguments"] = first["data"]["input"]
            with_helper = output / "with-helper.jsonl"
            with_helper.write_text("\n".join(json.dumps(e) for e in events) + "\n")
            helper_replay = runner.subprocess.run(
                ["python3", str(BENCH / "run.py"), "--arms", "A2", "--replay", str(with_helper),
                 "--output", str(output / "helper-replay")], capture_output=True, text=True, timeout=120,
            )
            self.assertEqual(helper_replay.returncode, 0, helper_replay.stdout + helper_replay.stderr)
            fake = json.loads((output / "helper-replay/capture/fake.json").read_text())
            self.assertTrue(fake["steps"][0]["code"].endswith("gptr_return(cohort)"))
            manifest = json.loads((output / "helper-replay/manifest.json").read_text())
            self.assertEqual(manifest["replay_trace_sha256"],
                             hashlib.sha256(with_helper.read_bytes()).hexdigest())
            first["data"]["input"]["code"] = "stop('broken captured computation')"
            damaged = output / "damaged.jsonl"
            damaged.write_text("\n".join(json.dumps(e) for e in events) + "\n")
            rejected = runner.subprocess.run(
                ["python3", str(BENCH / "run.py"), "--arms", "A2", "--replay", str(damaged),
                 "--output", str(output / "rejected")], capture_output=True, text=True, timeout=120,
            )
            self.assertNotEqual(rejected.returncode, 0)
            self.assertFalse((output / "rejected/capture/fake.json").exists())


if __name__ == "__main__":
    unittest.main()
