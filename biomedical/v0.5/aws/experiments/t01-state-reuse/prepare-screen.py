"""Prepare a larger stratified genuine-cell input, then apply the unchanged read gate."""
import argparse
import importlib.util
import json
import os
from pathlib import Path
import subprocess
import sys

HERE = Path(__file__).resolve().parent
AWS = HERE.parents[1]
REPO = AWS.parents[2]
spec = importlib.util.spec_from_file_location('read_screen', HERE/'read-screen.py')
reader = importlib.util.module_from_spec(spec)
spec.loader.exec_module(reader)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--source', type=Path, required=True)
    parser.add_argument('--cells', type=int, required=True)
    parser.add_argument('--input-root', type=Path, required=True)
    parser.add_argument('--gzip-root', type=Path, required=True)
    parser.add_argument('--output', type=Path, required=True)
    args = parser.parse_args()
    args.output.mkdir(parents=True)
    reader.write(args.output/'design.json', dict(cells=args.cells, source=str(args.source),
          input_root=str(args.input_root), gzip_root=str(args.gzip_root),
          selection='Existing Patient/Tissue/Treatment/MajorCellType stratified real-cell selection',
          no_synthetic_expansion=True, min_available_gib=12, stop_rss_gib=11,
          stop_available_gib=3, read_requirement='All three standard-gzip readRDS probes >20 seconds',
          supervisor_pid=os.getpid()))
    command = [sys.executable, str(AWS/'run.py'), 'prepare', '--task', 'T01',
               '--source', str(args.source), '--cells', str(args.cells),
               '--input-root', str(args.input_root), '--output', str(args.output/'preparation')]
    result = reader.measure(command, args.output/'preparation.log', timeout=3600)
    reader.write(args.output/'preparation-process.json', result)
    if result['exit_code']:
        raise RuntimeError('Preparation failed or hit its resource gate; preserve evidence')
    subprocess.run([sys.executable, str(HERE/'read-screen.py'), '--source', str(args.input_root/'T01'),
                    '--compressed', str(args.gzip_root/'T01'), '--output', str(args.output/'read-screen')],
                   cwd=REPO, check=True)
    reader.write(args.output/'completed.json', dict(success=True, review_status='input-screen-only'))


if __name__ == '__main__':
    main()
