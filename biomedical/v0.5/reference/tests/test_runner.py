import csv
import json
from pathlib import Path
import subprocess
import tempfile
import unittest


BENCH = Path(__file__).resolve().parents[1]


class ReplayIntegrationTest(unittest.TestCase):
    def test_three_execution_paths_produce_valid_artifacts(self):
        with tempfile.TemporaryDirectory() as output:
            result = subprocess.run(
                ["python3", str(BENCH / "run.py"), "--output", output],
                text=True, capture_output=True, timeout=120,
            )
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
            with (Path(output) / "summary.csv").open() as handle:
                rows = list(csv.DictReader(handle))
            self.assertEqual([r["arm"] for r in rows], ["A2", "C2", "C3"])
            self.assertTrue(all(r["status"] == "ok" for r in rows), rows)
            self.assertTrue(all(float(r["total_wall_ms"]) > 0 for r in rows))
            self.assertEqual([int(r["r_processes"]) for r in rows], [1, 3, 1])
            self.assertEqual(int(rows[0]["tool_calls"]), 3)
            manifest = json.loads((Path(output) / "manifest.json").read_text())
            self.assertEqual(manifest["task"], "clinical")
            self.assertEqual(len(manifest["dataset_sha256"]), 64)
            self.assertFalse(manifest["live"])
            for row in rows:
                workspace = Path(row["workspace"])
                self.assertFalse(workspace.is_relative_to(BENCH.parents[2]))
                self.assertTrue((workspace / "revised.csv").exists())

    def test_single_cell_input_uses_all_three_paths_and_task_validator(self):
        with tempfile.TemporaryDirectory() as root:
            directory = Path(root)
            data = directory / "input.rds"
            code = """
              counts = Matrix::sparseMatrix(i = rep(1:1008, 6), j = rep(1:6, each = 1008),
                                             x = 3, dims = c(1008L, 6L))
              rownames(counts) = paste0('id', 1:1008)
              colnames(counts) = paste0('cell', 1:6)
              symbols = c('CD3D', 'CD3E', 'CD8A', 'MS4A1', 'LYZ', 'NKG7', 'EPCAM',
                          'COL1A1', paste0('gene', 1:1000))
              raw = list(counts = counts, metadata = data.frame(barcode = colnames(counts),
                Patient = rep(c('P1', 'P2'), each = 3), Tissue = 'Tumor', Treatment = 'I'),
                features = data.frame(gene_id = rownames(counts), gene_symbol = symbols))
              saveRDS(raw, commandArgs(TRUE)[1], compress = FALSE)
            """
            made = subprocess.run(["Rscript", "--vanilla", "-e", code, str(data)],
                                  text=True, capture_output=True)
            self.assertEqual(made.returncode, 0, made.stderr)
            result = subprocess.run(["python3", str(BENCH / "run.py"), "--task", "single-cell",
                                     "--input", str(data), "--output", str(directory / "run")],
                                    text=True, capture_output=True, timeout=120)
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
            manifest = json.loads((directory / "run/manifest.json").read_text())
            self.assertEqual(manifest["task"], "single-cell")
            self.assertTrue(manifest["benchmark_version"].startswith("0.3."))
            with (directory / "run/summary.csv").open() as handle:
                rows = list(csv.DictReader(handle))
            self.assertEqual([r["status"] for r in rows], ["ok"] * 3)
            for row in rows:
                self.assertTrue((Path(row["workspace"]) / "baseline.csv").exists())
                evaluation = json.loads((directory / "run" / f"{row['arm']}-1/evaluation.json").read_text())
                self.assertTrue(evaluation["ok"])

    def test_explicit_sol_model_is_resolved_offline_without_global_alias(self):
        import importlib.util
        spec = importlib.util.spec_from_file_location("bench_model_test", BENCH / "run.py")
        runner = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(runner)
        with tempfile.TemporaryDirectory() as root:
            path = Path(root)
            result = runner.run_r("model", {"model": "gpt-6.1-sol", "result": str(path / "model.json")},
                                  path, 30)
            self.assertEqual(result.returncode, 0, result.stderr)
            model = json.loads((path / "model.json").read_text())
            self.assertEqual(model["gptr"], "codex/gpt-6.1-sol")
            self.assertEqual(model["codex"], "gpt-6.1-sol")


if __name__ == "__main__":
    unittest.main()
