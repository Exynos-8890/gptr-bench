"""Offline RPC integration: one server, three turns, failures and cumulative usage."""
import importlib.util
import json
from pathlib import Path
import sys
import tempfile
import threading
import unittest
from unittest.mock import patch

import psutil


SCRIPT = Path(__file__).resolve().parents[1]/"aws/shared/codex_app.py"
FAKE = r'''import json,os,sys,subprocess,time
from pathlib import Path
mode=sys.argv[1]
count=0
def out(x): print(json.dumps(x),flush=True)
for line in sys.stdin:
 message=json.loads(line)
 with Path('calls.jsonl').open('a') as f:f.write(json.dumps(dict(pid=os.getpid(),message=message))+'\n')
 method=message['method'];ident=message.get('id')
 if method=='initialize':out(dict(id=ident,result=dict(userAgent='offline-fake')))
 elif method=='thread/start':
  Path('native.jsonl').write_text(json.dumps(dict(type='session_meta',payload={}))+'\n')
  out(dict(id=ident,result=dict(thread=dict(id='offline-thread',path=str(Path('native.jsonl').resolve())),model=message['params']['model'])))
 elif method=='turn/start':
  count+=1;turn='turn-'+str(count)
  if mode=='r_pending' and count==1:
   Path('io.jsonl').write_text(json.dumps(dict(operation='rscript_start',program_id='still-running'))+'\n')
  if mode=='child' and count==1:
   child=subprocess.Popen([sys.executable,'-c',"from pathlib import Path; import os,time; data=bytearray(64*1024*1024); Path('child-ready').write_text(str(os.getpid())); time.sleep(120)"],stdin=subprocess.DEVNULL,stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL,start_new_session=True)
   while not Path('child-ready').exists(): time.sleep(.005)
   Path('child.json').write_text(json.dumps(dict(pid=child.pid)))
  if mode=='hang' and count==2:
   out(dict(id=ident,result=dict(turn=dict(id=turn,status='inProgress'))));continue
  usage=dict(inputTokens=count*10,cachedInputTokens=count*8,cacheWriteInputTokens=0,outputTokens=count,reasoningOutputTokens=count,totalTokens=count*11)
  out(dict(method='thread/tokenUsage/updated',params=dict(threadId='offline-thread',turnId=turn,tokenUsage=dict(total=usage,last=usage))))
  # A fast completion can precede its request response: the client must not lose it.
  out(dict(method='turn/completed',params=dict(threadId='offline-thread',turn=dict(id=turn,status='failed' if mode=='fail' and count==2 else 'completed'))))
  out(dict(id=ident,result=dict(turn=dict(id=turn,status='inProgress'))))
'''


def module():
    spec=importlib.util.spec_from_file_location("codex_app_test",SCRIPT)
    loaded=importlib.util.module_from_spec(spec);spec.loader.exec_module(loaded)
    return loaded


class AppServerTest(unittest.TestCase):
    def exercise(self,mode='ok',timeout=5,budget=1000):
        temporary=tempfile.TemporaryDirectory()
        self.addCleanup(temporary.cleanup)
        root=Path(temporary.name)
        directory=root/'C1-1';directory.mkdir()
        work=directory/'workspace';work.mkdir()
        fake=root/'fake.py';fake.write_text(FAKE)
        prompts=root/'prompts.json';prompts.write_text(json.dumps(dict(T01=['first','second','third'])))
        config=dict(workspace=str(work),prompt_file=str(prompts),task_id='T01',
                    dataset_sha256='offline',codex_model='offline-model',token_limit=budget,
                    io_events=str(work/'io.jsonl'))
        result=module().run(config,directory,timeout,command=[sys.executable,str(fake),mode])[0]
        calls=[json.loads(line) for line in (work/'calls.jsonl').read_text().splitlines()]
        trace=[json.loads(line) for line in (directory/'trace.jsonl').read_text().splitlines()]
        if mode=='child':
            pid=json.loads((work/'child.json').read_text())['pid']
            try:
                child=psutil.Process(pid)
                birth=child.create_time()
                def cleanup_child():
                    try:
                        p=psutil.Process(pid)
                        if p.create_time()==birth: p.kill()
                    except psutil.NoSuchProcess: pass
                self.addCleanup(cleanup_child)
            except psutil.NoSuchProcess: pass
        return result,calls,trace,directory

    def test_three_requests_share_one_server_and_usage_is_not_double_counted(self):
        result,calls,trace,directory=self.exercise()
        self.assertEqual(result['status'],'ok')
        self.assertEqual(result['agent_turns'],3)
        self.assertEqual(result['input_tokens'],30)
        self.assertEqual(result['cached_input_tokens'],24)
        self.assertEqual(result['output_tokens'],3)
        self.assertEqual(len({c['pid'] for c in calls}),1)
        self.assertEqual([c['message']['method'] for c in calls],
                         ['initialize','initialized','thread/start','turn/start','turn/start','turn/start'])
        turns=[c['message']['params'] for c in calls if c['message']['method']=='turn/start']
        self.assertEqual([t['input'][0]['text'] for t in turns],['first','second','third'])
        self.assertEqual({t['threadId'] for t in turns},{'offline-thread'})
        settings=next(c['message']['params'] for c in calls if c['message']['method']=='thread/start')
        self.assertIn('one-shot Rscript',settings['developerInstructions'])
        self.assertEqual([e['turn'] for e in trace if e['type']=='request_end'],[1,2,3])
        self.assertEqual(json.loads((directory/'native-capture.json').read_text())['status'],'captured')
        self.assertIsNone(result['all_tool_calls'])
        if result['sampled_peak_rss_bytes'] is None:
            self.assertEqual(result['memory_scope'],'unavailable')
        else:
            self.assertGreater(result['sampled_peak_rss_bytes'],0)

    def test_failed_turn_does_not_submit_later_requests(self):
        result,calls,trace,_=self.exercise('fail')
        self.assertEqual(result['status'],'error')
        self.assertEqual(result['agent_turns'],1)
        self.assertEqual(len([c for c in calls if c['message']['method']=='turn/start']),2)
        self.assertEqual([e['data']['status'] for e in trace if e['type']=='request_end'],['ok','error'])

    def test_retained_r_process_rejects_completion_and_stops_later_requests(self):
        result,calls,trace,directory=self.exercise('r_pending')
        self.assertEqual(result['status'],'error')
        self.assertEqual(result['agent_turns'],0)
        self.assertEqual(len([c for c in calls if c['message']['method']=='turn/start']),1)
        audit=json.loads((directory/'r-execution-policy-1.json').read_text())
        self.assertFalse(audit['compliant'])
        self.assertEqual(audit['scripts_started'],1)
        self.assertEqual(audit['scripts_finished'],0)
        self.assertEqual([e['data']['status'] for e in trace if e['type']=='request_end'],['error'])

    def test_total_deadline_stops_an_unfinished_turn(self):
        result,calls,trace,_=self.exercise('hang',timeout=.5)
        self.assertEqual(result['status'],'timeout')
        self.assertEqual(result['agent_turns'],1)
        self.assertEqual([e['data']['status'] for e in trace if e['type']=='request_end'],['ok','timeout'])

    def test_cumulative_budget_is_checked_before_next_turn(self):
        result,calls,trace,_=self.exercise(budget=15)
        self.assertEqual(result['status'],'budget')
        self.assertEqual(result['input_tokens'],20)
        self.assertEqual(result['agent_turns'],2)
        self.assertEqual(len([c for c in calls if c['message']['method']=='turn/start']),2)

    def test_close_waits_for_detached_tool_memory_to_be_released(self):
        # Delay delivery to expose the real gap between sending a signal and
        # the descendant exiting. The tool uses its own process group.
        kill = psutil.Process.kill
        timers = []
        def delayed_kill(process):
            timer=threading.Timer(.2,lambda: kill(process) if process.is_running() else None)
            timers.append(timer);timer.start()
        with patch.object(psutil.Process,'kill',delayed_kill):
            result,_,_,directory=self.exercise('child')
        for timer in timers: timer.join()
        if result['memory_scope']!='process_tree':
            self.skipTest('Host sandbox prevents descendant enumeration; run on AWS or with process observation permitted')
        self.assertEqual(result['status'],'ok')
        cleanup=json.loads((directory/'cleanup.json').read_text())
        self.assertTrue(cleanup['complete'])
        self.assertFalse(cleanup['remaining'])
        pid=json.loads((directory/'workspace/child.json').read_text())['pid']
        try:
            process=psutil.Process(pid)
            self.assertIn(process.status(),('zombie','dead'))
            self.assertEqual(process.memory_info().rss,0)
        except psutil.NoSuchProcess:
            pass
