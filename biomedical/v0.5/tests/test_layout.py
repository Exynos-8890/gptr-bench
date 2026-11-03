"""Canonical AWS source layout and reproducible source inventory."""
import importlib.util
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest

AWS = Path(__file__).resolve().parents[1] / "aws"
REPO = AWS.parents[2]


class SourceLayoutTest(unittest.TestCase):
    def test_canonical_and_compatibility_entry_points_load(self):
        for entry in (AWS / "run.py", AWS.parent / "run.py",
                      AWS / "shared/execute.py", AWS / "shared/process.py"):
            with self.subTest(entry=entry):
                result = subprocess.run([sys.executable, str(entry), "--help"],
                    cwd=REPO, capture_output=True, text=True)
                self.assertEqual(result.returncode, 0, result.stderr)
        self.assertTrue((AWS.parent / "run.py").is_symlink())
        self.assertFalse((AWS / "tasks").exists())
        self.assertTrue((AWS / "peter.R").is_file())

    def test_inventory_detects_code_and_configuration_changes_but_ignores_results(self):
        spec = importlib.util.spec_from_file_location("aws_code_test", AWS / "code.py")
        module = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(module)
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            aws = root / "biomedical/v0.5/aws"
            aws.mkdir(parents=True)
            (aws / "links.tsv").write_text("")
            (aws / "run.py").write_text("pass\n")
            (aws / "tasks.json").write_text("{}\n")
            before = module.manifest(root, "benchmark")
            results = root / "biomedical/runs/example"
            results.mkdir(parents=True)
            (results / "result.json").write_text('{"status":"ok"}')
            (aws / "FILES.zh-CN.html").write_text("local view")
            self.assertEqual(before, module.manifest(root, "benchmark"))
            (aws / "tasks.json").write_text('{"model":"changed"}\n')
            self.assertNotEqual(before, module.manifest(root, "benchmark"))
            (aws / "links.tsv").write_text("biomedical/run.py\tbiomedical/v0.5/aws/run.py\n")
            with self.assertRaises(FileNotFoundError):
                module.manifest(root, "benchmark")

    def test_all_compatibility_links_are_relative_and_resolve_to_canonical_source(self):
        links = (AWS / "links.tsv").read_text().splitlines()
        self.assertGreater(len(links), 10)
        for line in links:
            old, new = line.split("\t")
            with self.subTest(old=old):
                path = REPO / old
                self.assertTrue(path.is_symlink())
                self.assertFalse(path.readlink().is_absolute())
                self.assertEqual(path.resolve(), (REPO / new).resolve())
                self.assertTrue(path.exists())


if __name__ == "__main__":
    unittest.main()
