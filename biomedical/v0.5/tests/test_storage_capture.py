"""Keep native evidence when a terminated CLI never flushes thread.started."""
import importlib.util
import json
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch


class NativeCaptureTest(unittest.TestCase):
    def test_terminated_trace_uses_exact_session_workspace(self):
        script = Path(__file__).resolve().parents[1]/'aws/experiments/t01-state-reuse/storage-pilot.py'
        spec = importlib.util.spec_from_file_location('storage_pilot_test', script)
        module = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(module)
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            output = root/'run'
            arm = output/'C1-1'
            (arm/'workspace').mkdir(parents=True)
            (arm/'trace.jsonl').write_text(json.dumps({'type':'request_start','data':{}})+'\n')
            sessions = root/'.codex/sessions/2026/11/04'
            sessions.mkdir(parents=True)
            matched = sessions/'rollout-match.jsonl'
            matched.write_text(json.dumps({'type':'session_meta','payload':{
                'cwd':str(arm/'workspace'),'id':'match'}})+'\n')
            (sessions/'rollout-other.jsonl').write_text(json.dumps({'type':'session_meta',
                'payload':{'cwd':str(root/'another-workspace'),'id':'other'}})+'\n')
            with patch.object(module.Path, 'home', return_value=root):
                module.capture_native(output)
            capture = json.loads((output/'native-capture.json').read_text())
            self.assertEqual(len(capture), 1)
            self.assertEqual(capture[0]['thread_id'], 'match')
            self.assertEqual(capture[0]['status'], 'captured')
            self.assertEqual(Path(capture[0]['copied_path']).read_bytes(), matched.read_bytes())
            self.assertEqual(capture[0]['sha256'], module.sha(matched))
