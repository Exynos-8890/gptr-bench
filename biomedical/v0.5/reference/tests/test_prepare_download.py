"""Public download requests identify the benchmark rather than use Python's default agent."""
import hashlib
import importlib.util
import io
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch
import urllib.request


class DownloadTest(unittest.TestCase):
    def test_gdc_reactome_download_identifies_client_and_preserves_hashes(self):
        path = Path(__file__).resolve().parents[1] / 'prepare-v04-t03.py'
        spec = importlib.util.spec_from_file_location('t03_download_test', path)
        module = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(module)
        payload = b'public mapping fixture\n'
        def response(request, timeout):
            self.assertIsInstance(request, urllib.request.Request)
            self.assertEqual(request.get_header('User-agent'), 'gptr-biomedical-benchmark/0.4')
            return io.BytesIO(payload)
        with tempfile.TemporaryDirectory() as directory, patch.object(module.urllib.request, 'urlopen', side_effect=response):
            target = Path(directory) / 'mapping.txt'
            record = module.download('https://reactome.org/public-fixture', target,
                                     hashlib.md5(payload).hexdigest())
            self.assertEqual(target.read_bytes(), payload)
            self.assertEqual(record['sha256'], hashlib.sha256(payload).hexdigest())
            self.assertEqual(record['bytes'], len(payload))


if __name__ == '__main__':
    unittest.main()
