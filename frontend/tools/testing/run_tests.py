"""Local test orchestrator; no production cloud access in the default run."""
import argparse
from datetime import datetime
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import time
import uuid

ROOT = Path(__file__).resolve().parents[2]
HERE = Path(__file__).resolve().parent


def stop_process(process):
    if process.poll() is not None:
        return
    if os.name == 'nt':
        subprocess.run(['taskkill', '/PID', str(process.pid), '/T', '/F'],
                       stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
                       creationflags=subprocess.CREATE_NO_WINDOW)
    else:
        import signal
        os.killpg(process.pid, signal.SIGKILL)
    process.wait(timeout=15)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--config', type=Path, help='JSON overrides; relative paths use frontend root')
    parser.add_argument('--backend-only', action='store_true', help='Run isolated backend tests only')
    parser.add_argument('--skip-backend', action='store_true')
    parser.add_argument('--web', action='store_true', help='Build web, without deploying')
    parser.add_argument('--apk', action='store_true', help='Build debug APK')
    parser.add_argument('--api', action='store_true', help='Read-only smoke against configured running API')
    parser.add_argument('--cloudinary', action='store_true', help='Read-only image delivery smoke')
    parser.add_argument('--load', action='store_true', help='Small HTTP load test against configured API')
    parser.add_argument('--firebase', action='store_true', help='Start demo Firestore emulator and run isolated integration tests')
    parser.add_argument('--allow-remote-api', action='store_true', help='Explicitly allow non-loopback API target')
    parser.add_argument('--inventory', action='store_true', help='Also record flutter doctor/devices')
    args = parser.parse_args()
    if args.backend_only and args.skip_backend:
        parser.error('--backend-only and --skip-backend cannot be combined')

    stamp = datetime.now().strftime('%Y%m%d-%H%M%S') + '-' + uuid.uuid4().hex[:6]
    output = ROOT / 'test-results' / stamp
    output.mkdir(parents=True)
    stages = []
    interrupted = False

    def report():
        data = {'run': stamp, 'root': str(ROOT), 'interrupted': interrupted, 'stages': stages}
        (output / 'results.json').write_text(json.dumps(data, indent=2), encoding='utf-8')
        rows = ['# Test run ' + stamp, '',
                'PASS = command succeeded; FAIL = nonzero exit; BLOCKED = missing prerequisite; '
                'TIMEOUT/INTERRUPTED = incomplete. Unrequested optional stages are SKIP.', '',
                '| Stage | Result | Exit | Seconds | Log |', '| --- | --- | --- | --- | --- |']
        for item in stages:
            rows.append(f"| {item['name']} | {item['status']} | {item.get('exit_code', '')} | "
                        f"{item.get('seconds', '')} | [{item['log']}]({item['log']}) |")
        rows += ['', 'Backend tests mock Firestore and use minimal Django settings. They do not validate '
                 'real Firebase permissions, deployed settings, authentication, or data.',
                 'Build success does not establish device/E2E correctness. '
                 'HTTP load metrics describe this run only, not homepage rendering.', '']
        coverage = output / 'lcov.info'
        if coverage.exists():
            hits = total = 0
            for line in coverage.read_text(encoding='utf-8').splitlines():
                if line.startswith('DA:'):
                    total += 1
                    hits += int(line.split(',')[1]) > 0
            rows += [f'LCOV recorded lines: {hits}/{total} '
                     f'({100 * hits / total if total else 0:.2f}%). '
                     'This denominator includes only files represented in LCOV, not necessarily all source.', '']
        (output / 'REPORT.md').write_text('\n'.join(rows), encoding='utf-8')
        (ROOT / 'test-results' / 'LATEST.txt').write_text(str(output), encoding='utf-8')

    def record(name, status, message):
        log = name + '.log'
        (output / log).write_text(message + '\n', encoding='utf-8')
        stages.append({'name': name, 'status': status, 'log': log})
        report()

    def run(name, command, timeout, extra_env=None):
        nonlocal interrupted
        print(f'[{name}] Running; log: {output / (name + ".log")}', flush=True)
        item = {'name': name, 'log': name + '.log', 'status': 'RUNNING'}
        stages.append(item)
        report()
        started = time.monotonic()
        process = None
        try:
            with (output / item['log']).open('w', encoding='utf-8') as log:
                env = os.environ.copy()
                env['PYTHONIOENCODING'] = 'utf-8'
                env.update(extra_env or {})
                command = list(map(str, command))
                executable = shutil.which(command[0])
                if not executable:
                    raise FileNotFoundError('Executable unavailable: ' + command[0])
                command[0] = executable
                process = subprocess.Popen(command, cwd=ROOT, stdout=log, stderr=subprocess.STDOUT,
                                           env=env, start_new_session=os.name != 'nt',
                                           creationflags=subprocess.CREATE_NO_WINDOW if os.name == 'nt' else 0)
                while True:
                    remaining = timeout - (time.monotonic() - started)
                    if remaining <= 0:
                        raise subprocess.TimeoutExpired(command, timeout)
                    try:
                        code = process.wait(timeout=min(15, remaining))
                        break
                    except subprocess.TimeoutExpired:
                        print(f'[{name}] Still running ({int(time.monotonic() - started)}s); '
                              'see log for details.', flush=True)
                item.update(exit_code=code, status='PASS' if code == 0 else 'FAIL')
        except subprocess.TimeoutExpired:
            stop_process(process)
            item['status'] = 'TIMEOUT'
            with (output / item['log']).open('a', encoding='utf-8') as log:
                log.write(f'\nRunner stopped this process tree after {timeout} seconds.\n')
        except KeyboardInterrupt:
            interrupted = True
            if process:
                stop_process(process)
            item['status'] = 'INTERRUPTED'
            raise
        except OSError as error:
            item['status'] = 'BLOCKED'
            with (output / item['log']).open('a', encoding='utf-8') as log:
                log.write(str(error) + '\n')
        finally:
            item['seconds'] = round(time.monotonic() - started, 2)
            report()
            print(f"[{name}] {item['status']}", flush=True)

    print('Results: ' + str(output), flush=True)
    try:
        config = json.loads((HERE / 'config.json').read_text(encoding='utf-8-sig'))
        override = args.config or HERE / 'config.local.json'
        if args.config and not override.is_absolute():
            override = ROOT / override
        if override.exists():
            config.update(json.loads(override.read_text(encoding='utf-8-sig')))
        elif args.config:
            raise ValueError('Requested configuration file does not exist')
        timeout = int(config['timeout_seconds'])
        build_timeout = int(config['build_timeout_seconds'])
        emulator_timeout = int(config['emulator_timeout_seconds'])
        if timeout <= 0 or build_timeout <= 0 or emulator_timeout <= 0:
            raise ValueError('Timeouts must be positive')
        python = config.get('python') or sys.executable
        flutter = config['flutter']
        if args.inventory:
            run('doctor', [flutter, 'doctor', '-v'], timeout)
            run('devices', [flutter, 'devices'], timeout)
        if not args.backend_only:
            run('analyze', [flutter, 'analyze', '--no-pub'], timeout)
            run('flutter-tests', [flutter, 'test', '--no-pub', '--reporter', 'expanded',
                                 '--coverage', '--coverage-path=' + str(output / 'lcov.info')], timeout)
        else:
            record('frontend', 'SKIP', '--backend-only selected')
        if not args.skip_backend:
            run('backend-tests', [python, HERE / 'backend_tests.py', '--backend', config['backend_path']], timeout)
        else:
            record('backend-tests', 'SKIP', '--skip-backend selected')
        for enabled, name, command in [
            (args.web, 'build-web', [flutter, 'build', 'web', '--no-pub']),
            (args.apk, 'build-apk', [flutter, 'build', 'apk', '--debug', '--no-pub']),
        ]:
            if enabled:
                run(name, command, build_timeout)
            else:
                record(name, 'SKIP', 'Optional build was not requested')
        if args.firebase:
            run('firebase-emulator', ['firebase', 'emulators:exec', '--only', 'firestore',
                '--project', 'demo-intelli-car-tests', '--config', HERE / 'firebase.json',
                'python tools/testing/emulator_tests.py'], emulator_timeout,
                {'TEST_BACKEND_PATH': config['backend_path'], 'GCLOUD_PROJECT': 'demo-intelli-car-tests'})
        else:
            record('firebase-emulator', 'SKIP', 'Local Firestore integration was not requested')
        for enabled, name in [(args.api, 'api'), (args.cloudinary, 'cloudinary'), (args.load, 'load')]:
            if enabled:
                # Pass config via environment-independent temporary file; never copy account credentials.
                smoke_config = {key: config[key] for key in (
                    'api_url', 'api_query', 'api_timeout_seconds', 'cloudinary_image_url',
                    'load_requests', 'load_workers', 'load_max_p95_ms')}
                smoke_path = output / 'network-config.json'
                smoke_path.write_text(json.dumps(smoke_config), encoding='utf-8')
                command = [python, HERE / 'network_checks.py', name, '--config', smoke_path]
                if args.allow_remote_api:
                    command.append('--allow-remote-api')
                run(name, command, timeout)
            else:
                record(name, 'SKIP', 'Opt-in network check was not requested')
    except KeyboardInterrupt:
        print('Interrupted. Partial results preserved.', flush=True)
    except (ValueError, KeyError, OSError, TypeError) as error:
        record('configuration', 'BLOCKED', str(error))
    finally:
        report()
        print('Report: ' + str(output / 'REPORT.md'), flush=True)
    if interrupted:
        return 130
    return int(any(item['status'] not in ('PASS', 'SKIP') for item in stages))


if __name__ == '__main__':
    sys.exit(main())
