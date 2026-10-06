import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

/// Opt-in for release; enabled by default in debug/profile.
const homePerformanceEnabled =
    bool.fromEnvironment('HOME_PERF', defaultValue: !kReleaseMode);

/// One /buy visit. Durations use a monotonic clock, not wall-clock subtraction.
/// SDK timings include cache/SDK work and are NOT HTTP network timings.
class HomeLoadTrace {
  HomeLoadTrace({
    void Function(Map<String, Object?>)? onReport,
    Duration timeout = const Duration(seconds: 60),
  }) : _onReport = onReport ?? HomePerformanceStore.record {
    _watch.start();
    _timer = Timer(timeout, () => finish('timeout'));
  }

  final String runId = DateTime.now().microsecondsSinceEpoch.toString();
  final DateTime startedAt = DateTime.now().toUtc();
  final Stopwatch _watch = Stopwatch();
  final Map<String, double> _milestones = {};
  Map<String, Object?> _feedMetadata = {};
  void setFeedMetadata(Map<String, Object?> metadata) {
    if (!_closed) _feedMetadata = Map.of(metadata);
  }

  final Map<String, Map<String, num>> _operations = {};
  final void Function(Map<String, Object?>) _onReport;
  Timer? _timer;
  bool _closed = false;
  bool _failed = false;
  bool _contentFrame = false;
  bool _thumbnailSettled = false;
  String _thumbnailStatus = 'pending';
  bool? _synchronousImageFrame;
  int? _postCount;

  bool get isClosed => _closed;

  void mark(String name) {
    if (!_closed) {
      _milestones.putIfAbsent(name, () => _watch.elapsedMicroseconds / 1000);
    }
  }

  Future<T> measure<T>(String name, Future<T> Function() action) async {
    if (_closed) return action();
    final operation = _operations.putIfAbsent(
        name,
        () => {
              'started': 0,
              'completed': 0,
              'errors': 0,
              'total_ms': 0.0,
              'max_ms': 0.0,
            });
    operation['started'] = operation['started']! + 1;
    final watch = Stopwatch()..start();
    var failed = false;
    try {
      return await action();
    } catch (_) {
      failed = true;
      rethrow;
    } finally {
      watch.stop();
      if (!_closed) {
        final ms = watch.elapsedMicroseconds / 1000;
        operation['completed'] = operation['completed']! + 1;
        operation['errors'] = operation['errors']! + (failed ? 1 : 0);
        operation['total_ms'] = operation['total_ms']! + ms;
        if (ms > operation['max_ms']!) operation['max_ms'] = ms;
        _failed = _failed || failed;
      }
    }
  }

  void postsSettled({required int count, required bool succeeded}) {
    _postCount = count;
    _failed = _failed || !succeeded;
    mark(succeeded ? 'posts_ready' : 'posts_failed');
  }

  void contentFrame() {
    mark('content_frame');
    _contentFrame = true;
    _tryFinish();
  }

  void thumbnailReady({required bool synchronous}) {
    if (_thumbnailSettled || _closed) return;
    _synchronousImageFrame = synchronous;
    _thumbnailStatus = 'frame_ready';
    _thumbnailSettled = true;
    mark('first_thumbnail_frame');
    _tryFinish();
  }

  void thumbnailFailed() {
    if (_thumbnailSettled || _closed) return;
    _failed = true;
    _thumbnailStatus = 'error';
    _thumbnailSettled = true;
    mark('first_thumbnail_error');
    _tryFinish();
  }

  void noThumbnail() {
    if (_thumbnailSettled || _closed) return;
    _thumbnailStatus = 'not_applicable';
    _thumbnailSettled = true;
    _tryFinish();
  }

  void _tryFinish() {
    if (_contentFrame && _thumbnailSettled) {
      finish(_failed ? 'partial_error' : 'ready');
    }
  }

  void finish(String status) {
    if (_closed) return;
    _closed = true;
    _timer?.cancel();
    _watch.stop();
    final report = <String, Object?>{
      'schema_version': 1,
      'run_id': runId,
      'screen': '/buy',
      'feed': _feedMetadata,
      'cache_state': const String.fromEnvironment('HOME_CACHE_STATE',
          defaultValue: 'unknown'),
      'experiment_label': const String.fromEnvironment('HOME_EXPERIMENT_LABEL',
          defaultValue: ''),
      'started_at_utc': startedAt.toIso8601String(),
      'mode': kReleaseMode ? 'release' : (kProfileMode ? 'profile' : 'debug'),
      'platform': kIsWeb ? 'web' : defaultTargetPlatform.name,
      'status': status,
      'elapsed_ms': _watch.elapsedMicroseconds / 1000,
      'post_count': _postCount,
      'milestones_ms': Map<String, double>.from(_milestones),
      'operations': _operations
          .map((key, value) => MapEntry(key, Map<String, num>.from(value))),
      'thumbnail_status': _thumbnailStatus,
      'synchronous_image_frame': _synchronousImageFrame,
    };
    // Diagnostics must never break application behavior.
    try {
      _onReport(report);
    } catch (_) {
      debugPrint('[HOME_PERF] report sink failed');
    }
  }
}

/// Bounded local history; serialized writes prevent visits from overwriting one another.
class HomePerformanceStore {
  static const storageKey = 'home_performance_reports_v1';
  static Future<void> _pending = Future<void>.value();

  static void record(Map<String, Object?> report) {
    final encoded = jsonEncode(report);
    debugPrint('[HOME_PERF] $encoded');
    const endpoint = String.fromEnvironment('HOME_PERF_ENDPOINT');
    if (kIsWeb && endpoint.isNotEmpty) {
      unawaited(_sendToLocalCollector(endpoint, encoded));
    }
    _pending = _pending.then((_) async {
      final preferences = await SharedPreferences.getInstance();
      final reports = preferences.getStringList(storageKey) ?? [];
      reports.add(encoded);
      if (reports.length > 20) reports.removeRange(0, reports.length - 20);
      final saved = await preferences.setStringList(storageKey, reports);
      if (!saved) debugPrint('[HOME_PERF] local history write failed');
    }).catchError((Object _) {
      debugPrint('[HOME_PERF] local history unavailable; use console capture');
    });
  }

  static Future<void> _sendToLocalCollector(
      String endpoint, String body) async {
    try {
      final uri = Uri.parse(endpoint);
      if (uri.scheme != 'http' || uri.host != '127.0.0.1') return;
      final response = await http
          .post(uri, headers: {'Content-Type': 'application/json'}, body: body)
          .timeout(const Duration(seconds: 3));
      if (response.statusCode != 204) {
        debugPrint('[HOME_PERF] local collector rejected report');
      }
    } catch (_) {
      debugPrint(
          '[HOME_PERF] local collector unavailable; history still saved');
    }
  }

  static Future<List<String>> readReports() async {
    await _pending;
    final preferences = await SharedPreferences.getInstance();
    return preferences.getStringList(storageKey) ?? [];
  }
}
