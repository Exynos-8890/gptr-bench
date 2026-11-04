"""Export aggregate dev.20 T01 measurements and real median-run timelines.

Raw records remain in their original ignored directory. No session text, patient
records, credentials or machine-specific paths are copied into public artifacts.
"""
import argparse
import csv
import hashlib
import json
from pathlib import Path
import shutil
import statistics

HERE = Path(__file__).resolve().parent
REPO = HERE.parents[3]
RUN_ID = 'v05-T01-dev20-one-shot-confirmation-20261104T065528Z'


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--run', type=Path, default=REPO / 'biomedical/runs' / RUN_ID)
    args = parser.parse_args()
    root = args.run.resolve()
    sources = {}

    def load(name, lines=False):
        path = root / name
        data = path.read_bytes()
        sources[name] = hashlib.sha256(data).hexdigest()
        return [json.loads(x) for x in data.splitlines()] if lines else json.loads(data)

    rows = load('formal/results.json')
    assert len(rows) == 6 and all(r['status'] == 'ok' for r in rows)
    manifest = load('formal/manifest.json')
    review = load('derived-scientific-review/acceptance-review.json')
    design = load('design.json')
    source_manifest = root / 'source-manifest.txt'
    benchmark_sha = hashlib.sha256(source_manifest.read_bytes()).hexdigest()
    sources[source_manifest.name] = benchmark_sha
    assert benchmark_sha == design['benchmark_sha256']
    assert review['accepted_for_T01_A1_C1_comparison']
    spans = []
    representatives = {}
    for arm in ['A1', 'C1']:
        group = [r for r in rows if r['arm'] == arm]
        median = statistics.median(r['total_wall_ms'] for r in group)
        row = next(r for r in group if r['total_wall_ms'] == median)
        representatives[arm] = row['trial']
        origin = row['run_started_unix']
        folder = f"formal/{arm}-{row['trial']}"
        events = load(folder + '/trace.jsonl', True)
        io = load(folder + '/io.jsonl', True)

        def add(kind, start, finish, label=''):
            assert finish >= start
            spans.append(dict(arm=arm, kind=kind, start=start-origin,
                              finish=finish-origin, label=label))

        starts = {e['turn']: e for e in events if e['type'] == 'request_start'}
        for e in events:
            if e['type'] == 'request_end':
                add('request', starts[e['turn']]['data']['unix'], e['data']['unix'], str(e['turn']))
        if arm == 'A1':
            ends = {(e['turn'], e['data']['tool_call_id']): e for e in events
                    if e['type'] == 'tool_execution_end'}
            for e in events:
                if e['type'] == 'tool_execution_start' and e['data']['tool_name'] == 'r':
                    end = ends[(e['turn'], e['data']['tool_call_id'])]
                    add('execution', e['data']['ts'], end['data']['ts'])
        else:
            for e in io:
                if e['operation'] == 'rscript':
                    add('execution', e['started_unix'], e['finished_unix'])
        for e in io:
            if e['operation'] == 'readRDS' and Path(e['file']).name == 'input.rds':
                add('read', e['started_unix'], e['finished_unix'])
    with (HERE / 'timeline.csv').open('w') as stream:
        writer = csv.DictWriter(stream, fieldnames=list(spans[0]), lineterminator='\n')
        writer.writeheader()
        writer.writerows(spans)
    for name in ['group-statistics.csv', 'additive-mean-differences.csv', 'all-attempts.csv']:
        source = root / 'derived-confirmation' / name
        sources[str(source.relative_to(root))] = hashlib.sha256(source.read_bytes()).hexdigest()
        (HERE / name).write_text(source.read_text())
    prompt = root / 'shared-prompts.json'
    sources[prompt.name] = hashlib.sha256(prompt.read_bytes()).hexdigest()
    assert sources[prompt.name] == manifest['prompt_sha256']
    shutil.copyfile(prompt, HERE / prompt.name)
    provenance = dict(run_id=root.name, measured_benchmark_version=manifest['benchmark_version'],
        benchmark_source_sha256=benchmark_sha,
        combined_benchmark_and_gptr_source_sha256=manifest['source_sha256'],
        gptr_source_sha256=manifest['gptr_source_sha256'],
        dataset_sha256=manifest['dataset_sha256'], prompt_sha256=manifest['prompt_sha256'],
        representative_trials=representatives,
        postcollection_review=dict(accepted=True, scope=review['scope']),
        source_files=sources,
        note='Measured dev.20 source is preserved in the local source archive. The current cleaned runner is dev.21; this report contains no dev.21 measurements. Public CSV line endings are normalized to LF; source hashes refer to the unchanged originals.')
    (HERE / 'provenance.json').write_text(json.dumps(provenance, indent=2) + '\n')
    print(f'Exported six attempts, group summaries and median-run timelines from {root.name}')


if __name__ == '__main__':
    main()
