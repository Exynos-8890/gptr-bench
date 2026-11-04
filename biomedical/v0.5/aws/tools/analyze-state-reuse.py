"""Derive wall-time accounting from immutable completed run records, including async R.

This is descriptive accounting, not a scientific correctness checker or causal claim.
The input directory must contain results.json and A1-*/C1-* raw records.
"""
import argparse
import collections
import csv
import hashlib
import json
from pathlib import Path
import re


def union(spans):
    merged = []
    for start, end in sorted(spans):
        if end <= start:
            continue
        if merged and start <= merged[-1][1]:
            merged[-1][1] = max(merged[-1][1], end)
        else:
            merged.append([start, end])
    return merged


def seconds(spans):
    return sum(end-start for start, end in union(spans))


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('run', type=Path)
    args = parser.parse_args()
    root = args.run.resolve()
    destination = root/'derived-performance'
    destination.mkdir(exist_ok=True)
    provenance = {}

    def load(path, lines=False):
        data = path.read_bytes()
        provenance[str(path)] = hashlib.sha256(data).hexdigest()
        return [json.loads(line) for line in data.splitlines()] if lines else json.loads(data)

    rows = []
    details = []
    for summary in load(root/'results.json'):
        arm, trial = summary['arm'], summary['trial']
        directory = root/f'{arm}-{trial}'
        events = load(directory/'trace.jsonl', True)
        io = load(directory/'io.jsonl', True)
        start = summary['run_started_unix']
        finish = start + summary['total_wall_ms']/1000
        def clip(spans):
            return [(max(start, a), min(finish, b)) for a, b in spans]
        def io_spans(selected):
            return clip([(e['started_unix'], e['finished_unix']) for e in selected])
        serial = [e for e in io if e['operation'] in ('readRDS', 'saveRDS')]
        inputs = [e for e in serial if e['operation']=='readRDS' and Path(e['file']).name=='input.rds']
        input_spans = io_spans(inputs)
        serial_spans = io_spans(serial)
        complete = summary['status'] == 'ok' or (summary['status'] == 'budget' and
                    sum(e['type']=='request_end' for e in events)==3)
        unfinished = []
        coverage_notes = []
        calls_available = True
        if arm == 'A1':
            calls = [e for e in events if e['type']=='tool_execution_start']
            counts = collections.Counter(e['data']['tool_name'] for e in calls)
            # Peter restarts tool_call_id numbering in each request.
            ends = {(e['turn'], e['data']['tool_call_id']):e for e in events if e['type']=='tool_execution_end'}
            execution = []
            for e in calls:
                if e['data']['tool_name'] == 'r':
                    end = ends.get((e['turn'], e['data']['tool_call_id']))
                    if end is None:
                        unfinished.append(dict(request=e['turn'],tool_call_id=e['data']['tool_call_id']))
                        complete = False
                        continue
                    assert end['data']['ts'] >= e['data']['ts']
                    execution.append((e['data']['ts'], end['data']['ts']))
            scope = 'A1 R-tool dispatch through return (includes framework overhead)'
        else:
            counts = collections.Counter()
            calls = []
            native = sorted((directory/'native-sessions').glob('*.jsonl'))
            if not native:
                if summary['status']=='ok':
                    raise ValueError('Cannot report actual C1 calls without captured native sessions')
                calls_available = False
                complete = False
            for path in native:
                for e in load(path, True):
                    payload = e.get('payload', {})
                    if e.get('type')!='response_item' or payload.get('type') not in ('custom_tool_call','function_call'):
                        continue
                    name = payload.get('name')
                    code = payload.get('input', payload.get('arguments', ''))
                    inner = re.findall(r'\btools\.(\w+)\s*\(', code) if name=='exec' else [name]
                    counts.update(inner)
                    calls.append(dict(timestamp=e.get('timestamp'), name=name, inner=inner,
                                      call_id=payload.get('call_id'), code=code))
                    if 'bench-rscript' in code and re.search(r'[\"\']?tty[\"\']?\s*:\s*true', code):
                        # A PTY-backed R service can span model waits, and CLI shutdown
                        # can remove it before its final rscript event is flushed.
                        complete = False
                        coverage_notes.append('PTY-backed R lifecycle is not a measured compute interval; completion/idle boundaries require separate audit')
            # Full Rscript intervals continue across exec_command returns and polling gaps.
            execution = [(e['started_unix'], e['finished_unix']) for e in io if e['operation']=='rscript']
            scope = 'C1 instrumented Rscript program start through finish (includes async execution)'
        serial_time = seconds(serial_spans)
        input_time = seconds(input_spans)
        execution_time = seconds(clip(execution)+serial_spans)
        wall = summary['total_wall_ms']/1000
        components = dict(input_read_s=input_time, other_serialization_s=serial_time-input_time,
                          r_execution_outside_serialization_s=execution_time-serial_time,
                          remaining_wall_s=wall-execution_time)
        assert all(value >= -0.02 for value in components.values()), components
        assert abs(sum(components.values())-wall)<1e-6
        if not complete:
            # An interrupted async program/tool has no reliable end boundary.
            # Keep measured IO but never mislabel its missing execution as model time.
            components['r_execution_outside_serialization_s'] = None
            components['remaining_wall_s'] = None
        starts = {e['turn']:e for e in events if e['type']=='request_start'}
        requests = {str(e['turn']):(e['time_ms']-starts[e['turn']]['time_ms'])/1000
                    for e in events if e['type']=='request_end'}
        row = dict(arm=arm, trial=trial, status=summary['status'], wall_s=wall,
                   eligible_performance_comparison=summary['status']=='ok', decomposition_complete=complete,
                   actual_calls=sum(counts.values()) if calls_available else None,
                   input_read_attempts=len(inputs), input_reads=sum(e.get('success',True) for e in inputs),
                   input_tokens=summary['input_tokens'], output_tokens=summary['output_tokens'],
                   **components)
        rows.append(row)
        details.append(dict(**row, calls_by_tool=dict(counts), request_seconds=requests,
                            unfinished_tools=unfinished,
                            execution_coverage_notes=sorted(set(coverage_notes)),
                            execution_scope=scope, native_calls=calls if arm=='C1' else None,
                            input_read_seconds=[e['duration_ms']/1000 for e in inputs]))
    with (destination/'runs.csv').open('w') as stream:
        writer = csv.DictWriter(stream, fieldnames=list(rows[0]))
        writer.writeheader(); writer.writerows(rows)
    (destination/'details.json').write_text(json.dumps(details, indent=2)+'\n')
    (destination/'provenance.json').write_text(json.dumps(provenance, indent=2)+'\n')
    print(json.dumps(rows, indent=2))
    print('Actual C1 calls use native tool source; inspect details.json for dynamic/ambiguous calls.')
    print('Remaining wall time includes model/network/framework/startup; it is not pure reasoning.')
    print('Execution boundaries differ by adapter; this decomposition does not prove a causal benefit.')


if __name__ == '__main__':
    main()
