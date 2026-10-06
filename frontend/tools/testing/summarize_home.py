"""Summarize captured homepage measurements without mixing test conditions."""
import argparse
from collections import defaultdict, Counter
from datetime import datetime
import glob
import json
import math
from pathlib import Path
import statistics

METRICS = ('posts_ready', 'content_frame', 'first_thumbnail_frame')


def describe(values):
    ordered = sorted(values)
    def percentile(p):
        return ordered[max(0, math.ceil(len(ordered) * p / 100) - 1)]
    return {'n': len(values), 'min': min(values), 'max': max(values),
            'mean': statistics.mean(values), 'p50': statistics.median(values),
            'p90': percentile(90), 'p95': percentile(95), 'p99': percentile(99),
            'stddev': statistics.pstdev(values)}


def summarize(reports):
    groups = defaultdict(list)
    seen = set()
    invalid = 0
    for report in reports:
        run = report.get('run_id')
        if not isinstance(run, str):
            invalid += 1
            continue
        if run in seen:
            continue
        seen.add(run)
        feed = report.get('feed') or {}
        key = json.dumps({
            'variant': feed.get('variant', 'legacy'), 'cache_state': report.get('cache_state', 'unknown'),
            'mode': report.get('mode'), 'platform': report.get('platform'), 'post_count': report.get('post_count'),
            'concurrency': feed.get('concurrency'), 'page_size': feed.get('page_size'),
            'label': report.get('experiment_label', ''),
        }, sort_keys=True)
        groups[key].append(report)
    result = []
    for key, samples in sorted(groups.items()):
        metrics = {}
        for metric in METRICS:
            values = [sample.get('milestones_ms', {}).get(metric) for sample in samples if sample.get('status') == 'ready']
            values = [float(value) for value in values if isinstance(value, (int, float))
                      and not isinstance(value, bool) and math.isfinite(value) and value >= 0]
            if values:
                metrics[metric] = describe(values)
        result.append({'conditions': json.loads(key), 'statuses': dict(Counter(s.get('status', 'unknown') for s in samples)),
                       'metrics_ms': metrics})
    return {'invalid_records': invalid, 'unique_visits': len(seen), 'groups': result}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('inputs', nargs='+', help='JSONL files, directories or glob patterns')
    parser.add_argument('--output', type=Path)
    args = parser.parse_args()
    files = set()
    for item in args.inputs:
        for name in glob.glob(item, recursive=True):
            path = Path(name)
            files.update(path.rglob('homepage.jsonl') if path.is_dir() else [path])
    if not files:
        parser.error('No input files matched')
    reports = []
    malformed = 0
    for file in sorted(files):
        for line in file.read_text(encoding='utf-8-sig').splitlines():
            try:
                item = json.loads(line)
                if not isinstance(item, dict):
                    raise ValueError('Expected report object')
                reports.append(item)
            except ValueError:
                malformed += 1
    result = summarize(reports)
    result['malformed_lines'] = malformed
    folder = args.output or Path(__file__).resolve().parents[2] / 'test-results' / ('comparison-' + datetime.now().strftime('%Y%m%d-%H%M%S'))
    folder.mkdir(parents=True, exist_ok=True)
    (folder / 'summary.json').write_text(json.dumps(result, indent=2, ensure_ascii=False), encoding='utf-8')
    lines = ['# Homepage comparison', '',
             'Units: ms. Ready visits only for latency; all statuses counted separately. '
             'Cache labels are supplied by operator, not verified automatically. '
             'Do not compare different datasets/devices/network/cache conditions.', '',
             f"Unique visits: {result['unique_visits']}; malformed lines: {malformed}.", '']
    for group in result['groups']:
        lines += ['## Conditions', '', '```json', json.dumps(group['conditions'], ensure_ascii=False), '```',
                  '', 'Statuses: ' + json.dumps(group['statuses']), '',
                  '| Metric | n | min | max | mean | p50 | p90 | p95 | p99 | stddev |',
                  '| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |']
        for metric, stats in group['metrics_ms'].items():
            lines.append('| ' + metric + ' | ' + ' | '.join(str(round(stats[k], 3)) for k in
                         ('n', 'min', 'max', 'mean', 'p50', 'p90', 'p95', 'p99', 'stddev')) + ' |')
        lines += ['', 'p50 is the median; p90/p95/p99 use nearest rank. With 10–30 samples, '
                  'upper percentiles are coarse (p99 often equals max), not stable production SLO estimates.', '']
    (folder / 'REPORT.md').write_text('\n'.join(lines), encoding='utf-8')
    print(folder / 'REPORT.md')


if __name__ == '__main__':
    main()
