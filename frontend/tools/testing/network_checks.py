"""Opt-in read-only API/image checks and small bounded HTTP load test."""
import argparse
from concurrent.futures import ThreadPoolExecutor
import json
import math
from pathlib import Path
import statistics
import sys
import time
from urllib.parse import parse_qsl, urlencode, urlsplit, urlunsplit
from urllib.request import build_opener, HTTPRedirectHandler, Request


class NoRedirect(HTTPRedirectHandler):
    def redirect_request(self, req, fp, code, msg, headers, newurl):
        return None


def validate_api_url(url, allow_remote=False):
    parts = urlsplit(url)
    if parts.scheme not in ('http', 'https') or not parts.hostname or parts.username or parts.password:
        raise ValueError('API URL must be HTTP(S) without embedded credentials')
    if not allow_remote and parts.hostname not in ('127.0.0.1', 'localhost', '::1'):
        raise ValueError('Remote API requires --allow-remote-api and a test environment')
    return parts


def api_request(config, allow_remote):
    parts = validate_api_url(config['api_url'], allow_remote)
    query = dict(parse_qsl(parts.query))
    query['query'] = config['api_query']
    url = urlunsplit((parts.scheme, parts.netloc, parts.path, urlencode(query), ''))
    started = time.perf_counter()
    with build_opener(NoRedirect).open(Request(url, headers={'Accept': 'application/json'}),
                                      timeout=float(config['api_timeout_seconds'])) as response:
        if response.status != 200:
            raise ValueError('Expected HTTP 200')
        if response.headers.get_content_type() != 'application/json':
            raise ValueError('Expected application/json')
        payload = response.read(5_000_001)
        if len(payload) > 5_000_000:
            raise ValueError('API response exceeded 5 MB limit')
    rows = json.loads(payload)
    if not isinstance(rows, list):
        raise ValueError('Expected a JSON list')
    required = {'post', 'car', 'carModel', 'brand', 'imageUrls',
                'sellerName', 'sellerPhone', 'sellerAddress', 'carLocation'}
    for row in rows:
        if not isinstance(row, dict) or not required.issubset(row):
            raise ValueError('Search response is missing expected fields')
        if not isinstance(row['post'], dict) or not isinstance(row['car'], dict):
            raise ValueError('Invalid post/car object')
        if not isinstance(row['imageUrls'], list):
            raise ValueError('imageUrls must be an array')
    return {'milliseconds': (time.perf_counter() - started) * 1000, 'rows': len(rows), 'bytes': len(payload)}


def percentile(values, percent):
    return sorted(values)[max(0, math.ceil(len(values) * percent / 100) - 1)]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('mode', choices=['api', 'cloudinary', 'load'])
    parser.add_argument('--config', type=Path, required=True)
    parser.add_argument('--allow-remote-api', action='store_true')
    args = parser.parse_args()
    config = json.loads(args.config.read_text(encoding='utf-8-sig'))
    try:
        if float(config['api_timeout_seconds']) <= 0:
            raise ValueError('api_timeout_seconds must be positive')
        if args.mode == 'cloudinary':
            parts = urlsplit(config['cloudinary_image_url'])
            if (parts.scheme != 'https' or parts.hostname != 'res.cloudinary.com'
                    or parts.username or parts.password):
                raise ValueError('Set cloudinary_image_url to an HTTPS res.cloudinary.com test image')
            with build_opener(NoRedirect).open(Request(config['cloudinary_image_url'], method='GET'),
                                              timeout=float(config['api_timeout_seconds'])) as response:
                if response.status != 200 or not response.headers.get_content_type().startswith('image/'):
                    raise ValueError('Expected HTTP 200 with image content type')
                sample = response.read(1024)
                if not sample:
                    raise ValueError('Empty image response')
                print(json.dumps({'status': 'PASS', 'content_type': response.headers.get_content_type(),
                                  'sample_bytes': len(sample)}))
            return 0
        validate_api_url(config['api_url'], args.allow_remote_api)
        if args.mode == 'api':
            print(json.dumps(api_request(config, args.allow_remote_api), indent=2))
            return 0
        count, workers = int(config['load_requests']), int(config['load_workers'])
        if not 1 <= count <= 200 or not 1 <= workers <= 10:
            raise ValueError('Small load test supports 1..200 requests and 1..10 workers')
        if float(config['load_max_p95_ms']) <= 0:
            raise ValueError('load_max_p95_ms must be positive')
        def sample(_):
            started = time.perf_counter()
            try:
                return True, api_request(config, args.allow_remote_api)['milliseconds']
            except Exception:
                return False, (time.perf_counter() - started) * 1000
        started = time.perf_counter()
        with ThreadPoolExecutor(max_workers=workers) as pool:
            samples = list(pool.map(sample, range(count)))
        elapsed = time.perf_counter() - started
        timings = [duration for _, duration in samples]
        failures = sum(not ok for ok, _ in samples)
        metrics = {'requests': count, 'workers': workers, 'failures': failures,
                   'error_rate': failures / count, 'requests_per_second': count / elapsed,
                   'mean_ms': statistics.mean(timings), 'p50_ms': percentile(timings, 50),
                   'p95_ms': percentile(timings, 95), 'p99_ms': percentile(timings, 99),
                   'note': 'Nearest-rank latency across all attempts, including failures; small smoke sample.'}
        print(json.dumps(metrics, indent=2))
        return int(failures > 0 or metrics['p95_ms'] > float(config['load_max_p95_ms']))
    except Exception as error:
        # Do not log response bodies, account details, or signed URLs.
        print('FAIL: ' + type(error).__name__)
        if isinstance(error, ValueError) and not isinstance(error, json.JSONDecodeError):
            print(str(error))
        return 1


if __name__ == '__main__':
    sys.exit(main())
