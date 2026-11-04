"""Collection helpers used by the final dev.20 T01 confirmation controller.

The historical filename is retained for the recorded controller import. The old
multi-storage pilot CLI and unselected scientific workload variants are removed.
"""
import hashlib
import json
import os
from pathlib import Path
import shutil
import signal
import subprocess
import sys
import time

import psutil

HERE = Path(__file__).resolve().parent
AWS = HERE.parents[1]
REPO = AWS.parents[2]
GiB = 1024 ** 3


def write(path, value):
    path.write_text(json.dumps(value, indent=2) + '\n')


def sha(path):
    with path.open('rb') as stream:
        return hashlib.file_digest(stream, 'sha256').hexdigest()


def inventory():
    content = subprocess.check_output([sys.executable, str(AWS/'code.py'), 'benchmark'], text=True)
    return hashlib.sha256(content.encode()).hexdigest()


def capture_native(output):
    records = []
    for trace in output.glob('C1-*/trace.jsonl'):
        threads = {e['data']['thread_id'] for e in map(json.loads, trace.read_text().splitlines())
                   if e['type'] == 'thread.started'}
        # A killed CLI can leave its buffered outer trace without thread.started.
        # Native session metadata is already flushed; match the exact workspace.
        if not threads:
            workspace = str((trace.parent/'workspace').resolve())
            for candidate in (Path.home()/'.codex/sessions').rglob('*.jsonl'):
                with candidate.open() as stream:
                    first = stream.readline()
                if not first:
                    continue
                metadata = json.loads(first).get('payload', {})
                if metadata.get('cwd') and str(Path(metadata['cwd']).resolve()) == workspace and metadata.get('id'):
                    threads.add(metadata['id'])
        for thread in threads:
            candidates = list((Path.home()/'.codex/sessions').rglob(f'*{thread}.jsonl'))
            if len(candidates) != 1:
                records.append(dict(thread_id=thread, status='missing_or_ambiguous', matches=len(candidates)))
                continue
            original = candidates[0]
            destination = trace.parent/'native-sessions'/original.name
            destination.parent.mkdir(exist_ok=True)
            checksum = sha(original)
            shutil.copyfile(original, destination)
            assert sha(destination) == checksum
            records.append(dict(thread_id=thread, status='captured', original_path=str(original),
                                copied_path=str(destination), sha256=checksum))
    write(output/'native-capture.json', records)


def guarded(command, log, status, timeout=3000):
    if psutil.virtual_memory().available < 12*GiB:
        raise RuntimeError('Live pilot requires at least 12 GiB available RAM')
    started = time.monotonic()
    peak = 0
    seen = {}
    failure = None
    with log.open('w') as handle:
        child = subprocess.Popen(command, cwd=REPO, stdout=handle, stderr=subprocess.STDOUT,
                                 start_new_session=True)
        process = psutil.Process(child.pid)
        created = process.create_time()
        last_saved = 0
        while child.poll() is None:
            try:
                members = [process, *process.children(recursive=True)]
                rss = 0
                for member in members:
                    seen[member.pid] = member.create_time()
                    rss += member.memory_info().rss
                peak = max(peak, rss)
            except psutil.NoSuchProcess:
                pass
            available = psutil.virtual_memory().available
            if peak >= 11*GiB or available < 3*GiB:
                failure = 'memory_gate'
            if time.monotonic()-started > timeout:
                failure = 'controller_timeout'
            if failure:
                # Kill only descendants with matching creation times; nested CLI groups are included.
                for pid, birth in reversed(list(seen.items())):
                    try:
                        target = psutil.Process(pid)
                        if target.create_time() == birth:
                            target.kill()
                    except psutil.NoSuchProcess:
                        pass
                child.wait()
                break
            if time.monotonic()-last_saved >= 2:
                write(status, dict(pid=child.pid, create_time=created, running=True,
                                   sampled_peak_rss_bytes=peak, available_bytes=available))
                last_saved = time.monotonic()
            time.sleep(.1)
    result = dict(pid=child.pid, create_time=created, running=False, exit_code=child.returncode,
                  sampled_peak_rss_bytes=peak, failure=failure,
                  elapsed_seconds=time.monotonic()-started)
    write(status, result)
    return result
