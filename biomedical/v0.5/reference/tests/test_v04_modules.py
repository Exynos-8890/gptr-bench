"""Every scientific task must survive the actual grouped-process protocol, offline."""
import hashlib
import importlib.util
from pathlib import Path
import subprocess
import tempfile
import unittest

BENCH = Path(__file__).resolve().parents[1]


class ScientificProtocolTest(unittest.TestCase):
    def test_all_ten_modules_in_three_offline_execution_protocols(self):
        spec = importlib.util.spec_from_file_location("v04_module_protocol", BENCH / "v04.py")
        runner = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(runner)
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            made = subprocess.run(["Rscript", "--vanilla", "make-v04-fixtures.R", str(root / "inputs")],
                cwd=BENCH / "tests", text=True, capture_output=True, timeout=60)
            self.assertEqual(made.returncode, 0, made.stdout + made.stderr)
            for task_id in runner.TASKS:
                prepared = root / "inputs" / task_id
                checksum = hashlib.sha256((prepared / "input.rds").read_bytes()).hexdigest()
                (prepared / "dataset.sha256").write_text(checksum)
                output = root / task_id
                output.mkdir()
                for arm in ["A2", "C2", "C3"]:
                    with self.subTest(task=task_id, arm=arm):
                        row = runner.run_arm(arm, 1, prepared, output, 120)
                        diagnostic = ""
                        for path in (output / f"{arm}-1").glob("*.log"):
                            diagnostic += path.read_text()[-4000:]
                        self.assertEqual(row["status"], "ok", str(row) + diagnostic)
                        self.assertEqual(row["r_processes"], 3 if arm == "C2" else 1)
                        self.assertEqual(row["tool_calls"], runner.TASKS[task_id]["reference_calls"])


if __name__ == "__main__":
    unittest.main()
