"""Regression tests for runner reporting and local HTTP smoke checks."""
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
import json
from pathlib import Path
import subprocess
import sys
import tempfile
import threading
import unittest

from network_checks import api_request, percentile, validate_api_url
from profile_home import parse_home_report, start_collector
from summarize_home import summarize, describe

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[1]


class MeasurementSummaryTests(unittest.TestCase):
    def test_statistics_and_separation_of_conditions(self):
        reports = []
        for i, (cache, status, value) in enumerate([('cold', 'ready', 10), ('cold', 'ready', 20),
                                                  ('warm', 'ready', 1), ('cold', 'timeout', 60000)]):
            reports.append({'run_id': str(i), 'cache_state': cache, 'status': status,
                            'feed': {'variant': 'D'}, 'milestones_ms': {'posts_ready': value}})
        summary = summarize(reports + [reports[0]])
        self.assertEqual(summary['unique_visits'], 4)
        self.assertEqual(len(summary['groups']), 2)
        cold = next(g for g in summary['groups'] if g['conditions']['cache_state'] == 'cold')
        self.assertEqual(cold['metrics_ms']['posts_ready']['mean'], 15)
        self.assertEqual(cold['metrics_ms']['posts_ready']['n'], 2)
        self.assertEqual(cold['statuses']['timeout'], 1)
        self.assertEqual(describe([10, 20])['stddev'], 5)

    def test_variants_are_not_pooled_and_missing_metrics_are_not_zero(self):
        summary = summarize([{'run_id': 'a', 'status': 'ready', 'feed': {'variant': 'A'}, 'milestones_ms': {}},
                             {'run_id': 'b', 'status': 'ready', 'feed': {'variant': 'B'},
                              'milestones_ms': {'posts_ready': 5}}])
        self.assertEqual(len(summary['groups']), 2)
        self.assertEqual(summary['groups'][0]['metrics_ms'], {})


class HomepageCaptureTests(unittest.TestCase):
    def test_web_collector_accepts_preflight_and_delivers_report(self):
        import queue
        from urllib.request import Request, urlopen
        lines = queue.Queue()
        server, endpoint = start_collector(lines)
        try:
            headers = {'Origin': 'http://localhost:54321', 'Content-Type': 'application/json'}
            with urlopen(Request(endpoint, method='OPTIONS', headers=headers), timeout=3) as response:
                self.assertEqual(response.status, 204)
                self.assertEqual(response.headers['Access-Control-Allow-Origin'], headers['Origin'])
            report = {'schema_version': 1, 'screen': '/buy', 'run_id': 'browser-test', 'status': 'ready'}
            with urlopen(Request(endpoint, data=json.dumps(report).encode(), headers=headers), timeout=3) as response:
                self.assertEqual(response.status, 204)
            self.assertEqual(parse_home_report(lines.get(timeout=3)), report)
        finally:
            server.shutdown()
            server.server_close()

    def test_web_collector_rejects_external_origin(self):
        import queue
        from urllib.request import Request, urlopen
        from urllib.error import HTTPError
        lines = queue.Queue()
        server, endpoint = start_collector(lines)
        try:
            with self.assertRaises(HTTPError) as caught:
                urlopen(Request(endpoint, data=b'{}', headers={'Origin': 'https://example.com'}), timeout=3)
            self.assertEqual(caught.exception.code, 403)
            self.assertTrue(lines.empty())
        finally:
            server.shutdown()
            server.server_close()

    def test_android_log_prefix_is_supported(self):
        report = {'schema_version': 1, 'screen': '/buy', 'run_id': 'test', 'status': 'ready'}
        self.assertEqual(parse_home_report('I/flutter (123): [HOME_PERF] ' + json.dumps(report)), report)

    def test_non_report_and_invalid_output_are_ignored(self):
        for line in ['ordinary log', '[HOME_PERF] local history unavailable',
                     '[HOME_PERF] {"screen": "/other", "schema_version": 1}',
                     '[HOME_PERF] {broken']:
            with self.subTest(line=line):
                self.assertIsNone(parse_home_report(line))


class RunnerReportingTests(unittest.TestCase):
    def invoke(self, content):
        with tempfile.TemporaryDirectory() as temporary:
            config = Path(temporary) / 'config.json'
            config.write_text(content, encoding='utf-8')
            result = subprocess.run([sys.executable, HERE / 'run_tests.py', '--backend-only',
                                     '--config', config], cwd=ROOT, capture_output=True,
                                    encoding='utf-8', timeout=30)
            report_line = next(line for line in result.stdout.splitlines() if line.startswith('Report: '))
            report = Path(report_line[len('Report: '):])
            data = json.loads(report.with_name('results.json').read_text(encoding='utf-8'))
            self.assertTrue(report.exists())
            for stage in data['stages']:
                self.assertTrue((report.parent / stage['log']).exists())
            return result, data

    def test_bad_json_preserves_failure_report(self):
        result, data = self.invoke('{invalid')
        self.assertEqual(result.returncode, 1)
        self.assertEqual(data['stages'][0]['status'], 'BLOCKED')

    def test_missing_backend_fails_and_preserves_log(self):
        result, data = self.invoke(json.dumps({'backend_path': str(HERE / 'missing-backend')}))
        self.assertEqual(result.returncode, 1)
        backend = next(stage for stage in data['stages'] if stage['name'] == 'backend-tests')
        self.assertEqual(backend['status'], 'FAIL')
        self.assertNotEqual(backend['exit_code'], 0)
        self.assertTrue(any(stage['status'] == 'SKIP' for stage in data['stages']))

    def test_missing_python_is_blocked(self):
        result, data = self.invoke(json.dumps({'python': 'nonexistent-testing-python-executable'}))
        self.assertEqual(result.returncode, 1)
        backend = next(stage for stage in data['stages'] if stage['name'] == 'backend-tests')
        self.assertEqual(backend['status'], 'BLOCKED')


class LocalHTTPTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        class Handler(BaseHTTPRequestHandler):
            def log_message(self, *_):
                pass

            def do_GET(self):
                if self.path.startswith('/redirect'):
                    self.send_response(302)
                    self.send_header('Location', '/valid')
                    self.end_headers()
                    return
                self.send_response(200)
                self.send_header('Content-Type', 'application/json')
                self.end_headers()
                data = [{'post': {'id': 1}, 'car': {'id': 2}, 'carModel': None,
                         'brand': None, 'imageUrls': [], 'sellerName': None,
                         'sellerPhone': None, 'sellerAddress': None, 'carLocation': None}]
                self.wfile.write(json.dumps(data if self.path.startswith('/valid') else {}).encode())

        cls.server = ThreadingHTTPServer(('127.0.0.1', 0), Handler)
        cls.thread = threading.Thread(target=cls.server.serve_forever, daemon=True)
        cls.thread.start()

    @classmethod
    def tearDownClass(cls):
        cls.server.shutdown()
        cls.server.server_close()
        cls.thread.join(timeout=5)

    def config(self, path):
        return {'api_url': f'http://127.0.0.1:{self.server.server_port}/{path}',
                'api_query': 'A&B Việt Nam', 'api_timeout_seconds': 2}

    def test_valid_response_produces_metrics(self):
        result = api_request(self.config('valid'), False)
        self.assertEqual(result['rows'], 1)
        self.assertGreater(result['bytes'], 0)
        self.assertGreaterEqual(result['milliseconds'], 0)

    def test_invalid_response_fails_contract(self):
        with self.assertRaises(ValueError):
            api_request(self.config('invalid'), False)

    def test_redirect_is_not_followed(self):
        from urllib.error import HTTPError
        with self.assertRaises(HTTPError) as caught:
            api_request(self.config('redirect'), False)
        self.assertEqual(caught.exception.code, 302)

    def test_remote_and_embedded_credentials_rejected(self):
        for url in ['https://example.com', 'http://user:secret@localhost', 'file:///tmp/test']:
            with self.subTest(url=url), self.assertRaises(ValueError):
                validate_api_url(url)

    def test_nearest_rank_percentiles(self):
        self.assertEqual(percentile(list(range(1, 101)), 50), 50)
        self.assertEqual(percentile(list(range(1, 101)), 95), 95)
        self.assertEqual(percentile([7], 99), 7)


if __name__ == '__main__':
    unittest.main()
