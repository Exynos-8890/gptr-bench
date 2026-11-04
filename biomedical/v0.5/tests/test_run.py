"""Essential input identity and the direct serial execution interface."""
import hashlib
import importlib.util
import json
from pathlib import Path
import sys
import tempfile
import unittest
from unittest.mock import patch

HERE = Path(__file__).resolve().parents[1]


def module():
    spec = importlib.util.spec_from_file_location("v05_run_test", HERE / "aws/run.py")
    loaded = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(loaded)
    return loaded


class RunnerTest(unittest.TestCase):
    def test_input_needs_only_its_declared_hash(self):
        m = module()
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            (root / "input.rds").write_bytes(b"fixture")
            checksum = hashlib.sha256(b"fixture").hexdigest()
            (root / "dataset.json").write_text(json.dumps({"input_sha256": checksum}))
            self.assertEqual(m.read_input("T01", root)[1], checksum)
            (root / "input.rds").write_bytes(b"changed")
            with self.assertRaisesRegex(ValueError, "SHA"):
                m.read_input("T01", root)

    def test_pilot_dispatches_directly_with_the150k_default(self):
        m = module()
        with tempfile.TemporaryDirectory() as temporary:
            output = Path(temporary) / "run"
            args = ["run.py", "pilot", "--task", "T01", "--output", str(output),
                    "--token-limit", "2000000"]
            with patch.object(sys, "argv", args), patch.object(m, "collect", return_value=0) as run:
                self.assertEqual(m.main(), 0)
            config, destination = run.call_args.args
            self.assertEqual(config["input_root"], str((m.BENCH / "data/v05-150000").resolve()))
            self.assertEqual(config["phase"], "pilot")
            self.assertEqual(config["token_limit"], 2000000)
            self.assertEqual(config["codex_transport"], "app-server")
            self.assertEqual(destination, output.resolve())
            self.assertFalse((output / "control.json").exists())


if __name__ == "__main__":
    unittest.main()
