"""Screen genuine inputs for >20s reads, explicitly separating a standard gzip format factor."""
import argparse
import gzip
import hashlib
import json
import os
from pathlib import Path
import signal
import subprocess
import time

import psutil

HERE = Path(__file__).resolve().parent
GiB = 1024 ** 3


def write(path, value):
    path.write_text(json.dumps(value, indent=2) + '\n')


def sha(path):
    with path.open('rb') as stream:
        return hashlib.file_digest(stream, 'sha256').hexdigest()


def measure(command, log, timeout=900):
    if psutil.virtual_memory().available < 12 * GiB:
        raise RuntimeError('Read probe requires at least 12 GiB available RAM')
    started = time.monotonic()
    peak = 0
    with log.open('w') as handle:
        child = subprocess.Popen(command, stdout=handle, stderr=subprocess.STDOUT,
                                 start_new_session=True)
        process = psutil.Process(child.pid)
        failure = None
        while child.poll() is None:
            try:
                rss = sum(p.memory_info().rss for p in [process, *process.children(recursive=True)])
                peak = max(peak, rss)
            except psutil.NoSuchProcess:
                pass
            if peak >= 11 * GiB or psutil.virtual_memory().available < 3 * GiB:
                failure = 'memory_gate'
            if time.monotonic() - started > timeout:
                failure = 'timeout'
            if failure:
                os.killpg(child.pid, signal.SIGKILL)
                child.wait()
                break
            time.sleep(.05)
    return dict(exit_code=child.returncode, elapsed_seconds=time.monotonic()-started,
                sampled_peak_rss_bytes=peak, failure=failure)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--source', type=Path, required=True)
    parser.add_argument('--compressed', type=Path, required=True)
    parser.add_argument('--output', type=Path, required=True)
    parser.add_argument('--repeats', type=int, default=3)
    args = parser.parse_args()
    if args.repeats < 1:
        parser.error('--repeats must be positive')
    args.output.mkdir(parents=True)
    args.compressed.mkdir(parents=True)
    source = args.source / 'input.rds'
    original = json.loads((args.source / 'dataset.json').read_text())
    checksum = sha(source)
    assert checksum == original['input_sha256']
    manifest = dict(source=str(source), source_sha256=checksum, dataset=original,
                    cache_policy='OS cache not cleared; fresh process for every read; no artificial waits',
                    format_factor='Uncompressed RDS vs standard gzip -6 of the exact serialized stream; not a new cohort',
                    threshold_seconds=20, repeats=args.repeats)
    write(args.output / 'manifest.json', manifest)
    rows = []

    def probes(path, name):
        for repeat in range(1, args.repeats + 1):
            measured = measure(['Rscript', '--vanilla', str(HERE/'read-probe.R'), str(path)],
                               args.output/f'{name}-{repeat}.log')
            row = dict(format=name, repeat=repeat, path=str(path), bytes=path.stat().st_size, **measured)
            if measured['exit_code'] == 0:
                text = (args.output/f'{name}-{repeat}.log').read_text().splitlines()
                row.update(json.loads(next(line for line in reversed(text) if line.startswith('{'))))
            rows.append(row)
            write(args.output/'results.json', rows)
            print(json.dumps(row), flush=True)
            if measured['exit_code']:
                raise RuntimeError('Read probe failed; see retained log')

    probes(source, 'uncompressed')
    target = args.compressed / 'input.rds'
    # gzip -6 is a standard storage representation; do not use xz/extreme levels to manufacture delay.
    started = time.monotonic()
    with target.open('xb') as handle:
        subprocess.run(['gzip', '-6', '-c', str(source)], stdout=handle, check=True, timeout=900)
    with gzip.open(target, 'rb') as stream:
        decompressed_sha = hashlib.file_digest(stream, 'sha256').hexdigest()
    assert decompressed_sha == checksum
    prepared = {**original, 'input_sha256':sha(target), 'rds_bytes':target.stat().st_size,
                'profile':str(original.get('profile', 'T01'))+'-gzip6',
                'inherited_provenance_file':str(args.source/'dataset.json'),
                'serialized_stream_sha256':checksum, 'storage_encoding':'gzip -6',
                'same_scientific_observations':True}
    write(args.compressed/'dataset.json', prepared)
    write(args.output/'encoding.json', dict(preparation_seconds=time.monotonic()-started,
          compressed_sha256=prepared['input_sha256'], decompressed_sha256=decompressed_sha,
          source_sha256=checksum, byte_identical_serialized_stream=True))
    probes(target, 'gzip6')
    write(args.output/'completed.json', dict(success=True,
          all_gzip_reads_over_20s=all(r['read_seconds']>20 for r in rows if r['format']=='gzip6')))


if __name__ == '__main__':
    main()
