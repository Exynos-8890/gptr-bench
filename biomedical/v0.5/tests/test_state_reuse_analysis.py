"""Wall accounting must tolerate reused tool IDs and asynchronous R execution."""
import json
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest


class StateReuseAnalysisTest(unittest.TestCase):
    def test_persistent_pty_r_is_not_mislabeled_as_uncovered_model_time(self):
        script=Path(__file__).resolve().parents[1]/'tools/analyze-state-reuse.py'
        with tempfile.TemporaryDirectory() as temporary:
            root=Path(temporary);arm=root/'C1-1';native=arm/'native-sessions';native.mkdir(parents=True)
            (root/'results.json').write_text(json.dumps([dict(arm='C1',trial=1,status='ok',
                run_started_unix=100,total_wall_ms=5000,input_tokens=1,output_tokens=1)]))
            (arm/'trace.jsonl').write_text('')
            (arm/'io.jsonl').write_text('')
            event=dict(type='response_item',payload=dict(type='custom_tool_call',name='exec',
                input='text(await tools.exec_command({cmd:"./instrumentation/bench-rscript --vanilla server.R",tty:true}));'))
            (native/'session.jsonl').write_text(json.dumps(event)+'\n')
            subprocess.run([sys.executable,str(script),str(root)],check=True,capture_output=True,text=True)
            row=json.loads((root/'derived-performance/details.json').read_text())[0]
            self.assertTrue(row['eligible_performance_comparison'])
            self.assertFalse(row['decomposition_complete'])
            self.assertIsNone(row['remaining_wall_s'])
            self.assertTrue(row['execution_coverage_notes'])

    def test_timeout_retained_without_inventing_tool_end_or_model_time(self):
        script = Path(__file__).resolve().parents[1]/'tools/analyze-state-reuse.py'
        with tempfile.TemporaryDirectory() as temporary:
            root=Path(temporary);arm=root/'A1-1';arm.mkdir()
            (root/'results.json').write_text(json.dumps([dict(arm='A1',trial=1,status='timeout',
                run_started_unix=100,total_wall_ms=5000,input_tokens=None,output_tokens=None)]))
            (arm/'trace.jsonl').write_text(json.dumps(dict(type='tool_execution_start',turn=3,
                data=dict(tool_name='r',tool_call_id='mcp_2',ts=102)))+'\n')
            (arm/'io.jsonl').write_text(json.dumps(dict(operation='readRDS',file='/input.rds',
                started_unix=100,finished_unix=100.5,duration_ms=500,success=True))+'\n')
            subprocess.run([sys.executable,str(script),str(root)],check=True,capture_output=True,text=True)
            row=json.loads((root/'derived-performance/details.json').read_text())[0]
            self.assertEqual(row['status'],'timeout')
            self.assertEqual(row['input_read_s'],.5)
            self.assertFalse(row['eligible_performance_comparison'])
            self.assertFalse(row['decomposition_complete'])
            self.assertIsNone(row['r_execution_outside_serialization_s'])
            self.assertIsNone(row['remaining_wall_s'])
            self.assertEqual(row['unfinished_tools'],[dict(request=3,tool_call_id='mcp_2')])

    def test_request_local_tool_ids_and_async_program_intervals(self):
        script = Path(__file__).resolve().parents[1]/'tools/analyze-state-reuse.py'
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            summaries = []
            for arm in ['A1','C1']:
                p = root/f'{arm}-1'
                p.mkdir()
                summaries.append(dict(arm=arm,trial=1,status='ok',run_started_unix=100,
                                      total_wall_ms=5000,input_tokens=1,output_tokens=1))
                io = [dict(operation='readRDS',file='/input.rds',started_unix=100,
                           finished_unix=100.5,duration_ms=500)]
                events = []
                if arm == 'A1':
                    for turn, start in [(1,101),(2,103)]:
                        for kind, time in [('start',start),('end',start+1)]:
                            events.append(dict(type='tool_execution_'+kind,turn=turn,
                                data=dict(tool_name='r',tool_call_id='mcp_2',ts=time)))
                else:
                    # exec may return in .1s while its R process runs for two seconds.
                    io.append(dict(operation='rscript',file='/script.R',started_unix=101,
                                   finished_unix=103,duration_ms=2000))
                    native = p/'native-sessions'
                    native.mkdir()
                    (native/'session.jsonl').write_text(json.dumps(dict(type='response_item',
                        payload=dict(type='custom_tool_call',name='exec',input='text(await tools.exec_command({}));',call_id='one')))+'\n')
                (p/'trace.jsonl').write_text(''.join(json.dumps(e)+'\n' for e in events))
                (p/'io.jsonl').write_text(''.join(json.dumps(e)+'\n' for e in io))
            (root/'results.json').write_text(json.dumps(summaries))
            subprocess.run([sys.executable,str(script),str(root)],check=True,capture_output=True,text=True)
            rows=json.loads((root/'derived-performance/details.json').read_text())
            for row in rows:
                self.assertEqual(row['input_read_s'],.5)
                self.assertEqual(row['r_execution_outside_serialization_s'],2)
                self.assertEqual(row['remaining_wall_s'],2.5)
            self.assertEqual(rows[0]['actual_calls'],2)
            self.assertEqual(rows[1]['actual_calls'],1)
