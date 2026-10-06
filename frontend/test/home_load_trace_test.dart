import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:online_car_marketplace_app/services/home_load_trace.dart';
import 'package:online_car_marketplace_app/ui/widgets/user/home_measured_image.dart';

class _ImmediateImage extends ImageProvider<_ImmediateImage> {
  _ImmediateImage(this.data);
  final ui.Image data;
  @override
  Future<_ImmediateImage> obtainKey(ImageConfiguration configuration) =>
      SynchronousFuture(this);
  @override
  ImageStreamCompleter loadImage(
          _ImmediateImage key, ImageDecoderCallback decode) =>
      OneFrameImageStreamCompleter(SynchronousFuture(ImageInfo(image: data)));
}

void main() {
  test('finishes once only after both content and first thumbnail', () {
    final reports = <Map<String, Object?>>[];
    final trace = HomeLoadTrace(onReport: reports.add);
    addTearDown(() => trace.finish('cleanup'));
    trace.postsSettled(count: 3, succeeded: true);
    trace.contentFrame();
    expect(reports, isEmpty);
    trace.thumbnailReady(synchronous: true);
    trace.thumbnailReady(synchronous: false);
    trace.finish('abandoned');
    expect(reports, hasLength(1));
    expect(reports.single['status'], 'ready');
    expect(reports.single['post_count'], 3);
    expect(reports.single['synchronous_image_frame'], true);
  });

  test('empty data needs no thumbnail, but still waits for content frame', () {
    final reports = <Map<String, Object?>>[];
    final trace = HomeLoadTrace(onReport: reports.add);
    addTearDown(() => trace.finish('cleanup'));
    trace.postsSettled(count: 0, succeeded: true);
    trace.noThumbnail();
    expect(reports, isEmpty);
    trace.contentFrame();
    expect(reports.single['status'], 'ready');
    expect(reports.single['thumbnail_status'], 'not_applicable');
  });

  test('SDK errors are counted and rethrown; do not become successful loads',
      () async {
    final reports = <Map<String, Object?>>[];
    final trace = HomeLoadTrace(onReport: reports.add);
    addTearDown(() => trace.finish('cleanup'));
    expect(await trace.measure('cars_sdk', () async => 7), 7);
    await expectLater(
        trace.measure('cars_sdk', () async => throw StateError('test')),
        throwsStateError);
    trace.postsSettled(count: 0, succeeded: false);
    trace.noThumbnail();
    trace.contentFrame();
    expect(reports.single['status'], 'partial_error');
    final operation = (reports.single['operations'] as Map)['cars_sdk'] as Map;
    expect(operation['started'], 2);
    expect(operation['completed'], 2);
    expect(operation['errors'], 1);
    expect(operation['total_ms'], greaterThanOrEqualTo(0));
  });

  testWidgets('deadline reports timeout with pending image, never ready',
      (tester) async {
    final reports = <Map<String, Object?>>[];
    final trace = HomeLoadTrace(
        onReport: reports.add, timeout: const Duration(seconds: 1));
    trace.contentFrame();
    await tester.pump(const Duration(seconds: 1));
    expect(reports.single['status'], 'timeout');
    expect(reports.single['thumbnail_status'], 'pending');
  });

  test('late completion cannot mutate a published report', () async {
    final reports = <Map<String, Object?>>[];
    final trace = HomeLoadTrace(onReport: reports.add);
    final pending = Completer<int>();
    final action = trace.measure('posts_sdk', () => pending.future);
    trace.finish('abandoned');
    final original = jsonEncode(reports.single);
    pending.complete(1);
    expect(await action, 1);
    expect(jsonEncode(reports.single), original);
    expect(await trace.measure('late', () async => 2), 2);
    expect(jsonEncode(reports.single), original);
  });

  test('diagnostic sink failure never propagates to application', () {
    final trace = HomeLoadTrace(onReport: (_) => throw StateError('sink'));
    expect(() => trace.finish('abandoned'), returnsNormally);
    expect(trace.isClosed, isTrue);
  });

  testWidgets(
      'image completion is recorded after its frame, including synchronous cache hits',
      (tester) async {
    final reports = <Map<String, Object?>>[];
    final trace = HomeLoadTrace(onReport: reports.add);
    addTearDown(() => trace.finish('cleanup'));
    final recorder = ui.PictureRecorder();
    Canvas(recorder).drawColor(Colors.green, BlendMode.src);
    final picture = recorder.endRecording();
    final image = picture.toImageSync(1, 1);
    picture.dispose();
    trace.postsSettled(count: 1, succeeded: true);
    trace.contentFrame();
    await tester.pumpWidget(MaterialApp(
        home: HomeMeasuredImage(image: _ImmediateImage(image), trace: trace)));
    await tester.pump();
    expect(reports, hasLength(1));
    expect(reports.single['status'], 'ready');
    expect(
        (reports.single['milestones_ms'] as Map)
            .containsKey('first_thumbnail_frame'),
        isTrue);
    await tester.pumpWidget(const SizedBox());
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
  });

  test('local history preserves ordering and retains only twenty visits',
      () async {
    SharedPreferences.setMockInitialValues({});
    for (var i = 0; i < 23; i++) {
      HomePerformanceStore.record({'run_id': '$i'});
    }
    final reports = await HomePerformanceStore.readReports();
    expect(reports, hasLength(20));
    expect(jsonDecode(reports.first)['run_id'], '3');
    expect(jsonDecode(reports.last)['run_id'], '22');
  });
}
