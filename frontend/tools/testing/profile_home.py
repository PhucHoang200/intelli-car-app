"""Run the app and save homepage timing JSON plus raw Flutter output."""
import argparse
from datetime import datetime
import json
from pathlib import Path
import queue
import shutil
import subprocess
import sys
import threading
import time
import uuid
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from urllib.parse import urlsplit

from run_tests import ROOT, stop_process


def start_collector(lines):
    """Loopback-only, session-token protected receiver for web profile builds."""
    route = '/report/' + uuid.uuid4().hex

    class Handler(BaseHTTPRequestHandler):
        def log_message(self, *_):
            pass

        def allowed(self):
            origin = self.headers.get('Origin', '')
            parsed = urlsplit(origin)
            return (self.path == route and parsed.scheme in ('http', 'https')
                    and parsed.hostname in ('localhost', '127.0.0.1', '::1'))

        def respond(self, status):
            self.send_response(status)
            if self.allowed():
                self.send_header('Access-Control-Allow-Origin', self.headers['Origin'])
                self.send_header('Vary', 'Origin')
                self.send_header('Access-Control-Allow-Methods', 'POST, OPTIONS')
                self.send_header('Access-Control-Allow-Headers', 'Content-Type')
                self.send_header('Access-Control-Allow-Private-Network', 'true')
            self.send_header('Content-Length', '0')
            self.end_headers()

        def do_OPTIONS(self):
            self.respond(204 if self.allowed() else 403)

        def do_POST(self):
            try:
                length = int(self.headers.get('Content-Length', '0'))
                if not 0 < length <= 16384:
                    self.respond(413)
                    return
                self.connection.settimeout(3)
                body = self.rfile.read(length)
                # Drain bounded bodies before closing so Windows clients receive
                # the HTTP error rather than a TCP reset with unread input.
                if not self.allowed():
                    self.respond(403)
                    return
                report = parse_home_report('[HOME_PERF] ' + body.decode('utf-8'))
                if report is None or not isinstance(report.get('run_id'), str):
                    self.respond(400)
                    return
                lines.put('[HOME_PERF] ' + json.dumps(report) + '\n')
                self.respond(204)
            except (ValueError, OSError):
                self.respond(400)

    server = ThreadingHTTPServer(('127.0.0.1', 0), Handler)
    thread = threading.Thread(target=server.serve_forever, daemon=True)
    thread.start()
    return server, f'http://127.0.0.1:{server.server_port}{route}'


def parse_home_report(line):
    marker = '[HOME_PERF] '
    if marker not in line:
        return None
    try:
        value = json.loads(line.split(marker, 1)[1].strip())
    except (ValueError, TypeError):
        return None
    if isinstance(value, dict) and value.get('schema_version') == 1 and value.get('screen') == '/buy':
        return value
    return None


def main():
    if hasattr(sys.stdout, 'reconfigure'):
        sys.stdout.reconfigure(encoding='utf-8', errors='replace')
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--device', required=True, help='ID from flutter devices, e.g. chrome or emulator-5554')
    parser.add_argument('--mode', choices=['profile', 'debug', 'release'], default='profile')
    parser.add_argument('--duration', type=int, default=0, help='Stop capture after N seconds; 0 waits for Ctrl+C')
    parser.add_argument('--variant', choices=['A', 'B', 'C', 'D'], default='D')
    parser.add_argument('--cache-state', choices=['unknown', 'cold', 'warm'], default='unknown',
                        help='Operator label only; does not clear caches')
    parser.add_argument('--label', default='', help='Dataset/device/network experiment label')
    args = parser.parse_args()
    if args.duration < 0:
        parser.error('--duration must be nonnegative')
    stamp = datetime.now().strftime('%Y%m%d-%H%M%S') + '-' + uuid.uuid4().hex[:6]
    folder = ROOT / 'test-results' / ('homepage-' + stamp)
    folder.mkdir(parents=True)
    command = ['flutter', 'run', '--' + args.mode, '-d', args.device, '--dart-define=HOME_PERF=true']
    command += ['--dart-define=HOME_VARIANT=' + args.variant,
                '--dart-define=HOME_CACHE_STATE=' + args.cache_state,
                '--dart-define=HOME_EXPERIMENT_LABEL=' + args.label]
    process = None
    collector = None
    lines = queue.Queue()
    reports = []
    seen = set()
    outcome = 'not_started'
    exit_code = 0
    print('Capture: ' + str(folder), flush=True)
    print('Open /buy after logging in. Wait for HOME_PERF output; Ctrl+C ends capture.', flush=True)
    try:
        if args.device in ('chrome', 'edge', 'web-server'):
            collector, endpoint = start_collector(lines)
            command.append('--dart-define=HOME_PERF_ENDPOINT=' + endpoint)
            print('Web timing collector ready. Keep this terminal open while using the app.', flush=True)
        executable = shutil.which('flutter')
        if not executable:
            raise FileNotFoundError('flutter not found in PATH')
        command[0] = executable
        import os
        process = subprocess.Popen(command, cwd=ROOT, stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                                   stdin=subprocess.PIPE, text=True, encoding='utf-8', errors='replace',
                                   start_new_session=os.name != 'nt',
                                   creationflags=subprocess.CREATE_NO_WINDOW if os.name == 'nt' else 0)
        def read_lines():
            for line in process.stdout:
                lines.put(line)
            lines.put(None)
        reader = threading.Thread(target=read_lines, daemon=True)
        reader.start()
        started = time.monotonic()
        with (folder / 'flutter.log').open('w', encoding='utf-8') as raw, \
                (folder / 'homepage.jsonl').open('w', encoding='utf-8') as jsonl:
            while True:
                if args.duration and time.monotonic() - started >= args.duration:
                    outcome = 'duration_reached'
                    break
                try:
                    line = lines.get(timeout=0.5)
                except queue.Empty:
                    continue
                if line is None:
                    code = process.wait()
                    exit_code = int(code != 0)
                    outcome = 'app_exited' if code == 0 else 'flutter_failed'
                    break
                raw.write(line)
                raw.flush()
                print(line, end='', flush=True)
                report = parse_home_report(line)
                if report and report.get('run_id') not in seen:
                    seen.add(report.get('run_id'))
                    reports.append(report)
                    jsonl.write(json.dumps(report, ensure_ascii=False) + '\n')
                    jsonl.flush()
    except KeyboardInterrupt:
        outcome = 'user_stopped'
    except OSError as error:
        outcome = 'launch_failed'
        exit_code = 1
        (folder / 'launch-error.log').write_text(str(error), encoding='utf-8')
    finally:
        if process:
            stop_process(process)
            if process.stdin:
                process.stdin.close()
        if collector:
            collector.shutdown()
            collector.server_close()
        summary = ['# Homepage measurement capture', '', f'Capture outcome: {outcome}',
                   f'Mode: {args.mode}; device: {args.device}', f'Reports captured: {len(reports)}', '',
                   '| Visit | Status | Posts ready ms | Content frame ms | First thumbnail frame ms |',
                   '| --- | --- | ---: | ---: | ---: |']
        for report in reports:
            marks = report.get('milestones_ms', {})
            summary.append(f"| {report.get('run_id')} | {report.get('status')} | "
                           f"{marks.get('posts_ready', '')} | {marks.get('content_frame', '')} | "
                           f"{marks.get('first_thumbnail_frame', '')} |")
        summary += ['', 'Blank metrics mean not observed, not zero. '
                    'No reports means no measurement was captured, not a performance pass.',
                    'Post-frame callbacks do not establish raster/GPU completion. '
                    'First thumbnail is not all images or a web LCP measurement.']
        (folder / 'REPORT.md').write_text('\n'.join(summary), encoding='utf-8')
        print('\nReport: ' + str(folder / 'REPORT.md'))
        if not reports:
            print('No homepage measurement captured. Build completion is not a homepage measurement.')
    return exit_code if reports else 1


if __name__ == '__main__':
    sys.exit(main())
