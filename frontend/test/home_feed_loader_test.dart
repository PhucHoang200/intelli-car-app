import 'package:flutter_test/flutter_test.dart';
import 'package:online_car_marketplace_app/models/post_model.dart';
import 'package:online_car_marketplace_app/repositories/home_feed_loader.dart';

class FakeFeed extends HomeFeedSource {
  FakeFeed({this.count = 6, this.sharedCar = false});
  final int count;
  final bool sharedCar;
  int active = 0, maxActive = 0;
  final calls = <String, int>{};
  final completedCars = <int>{};
  final failures = <String>{};
  int? requestedLimit;
  String? requestedAfter;
  Future<T> request<T>(String kind, T value) async {
    calls.update(kind, (n) => n + 1, ifAbsent: () => 1);
    active++;
    if (active > maxActive) maxActive = active;
    try {
      // Deterministic async overlap, rather than a wall-clock performance assertion.
      await Future<void>.delayed(Duration.zero);
      if (failures.contains(kind)) throw StateError(kind);
      return value;
    } finally {
      active--;
    }
  }

  @override
  Future<HomePostSlice> readPosts({int? limit, String? after}) async {
    requestedLimit = limit;
    requestedAfter = after;
    final start = after == null ? 0 : int.parse(after);
    final end = limit == null || start + limit > count ? count : start + limit;
    return request(
        'posts',
        HomePostSlice([
          for (var i = start; i < end; i++)
            Post(
                id: i,
                userId: 'same-seller',
                carId: sharedCar ? 0 : i,
                title: 'post $i',
                description: '',
                creationDate: DateTime.utc(2026)),
        ], cursor: '$end', hasMore: end < count));
  }

  @override
  Future<Map<String, dynamic>?> readCar(int id) async {
    final data = await request('cars', <String, dynamic>{
      'id': id,
      'userId': 'same-seller',
      'modelId': 7,
      'fuelType': 'Xăng',
      'transmission': 'Tự động',
      'year': 2020,
      'mileage': 10,
      'location': 'Hà Nội',
      'price': 100,
      'condition': 'used',
      'origin': 'local'
    });
    completedCars.add(id);
    return data;
  }

  @override
  Future<Map<String, dynamic>?> readModel(int id) {
    expect(completedCars, isNotEmpty,
        reason: 'Model cannot be requested before car result');
    return request(
        'models', {'id': id, 'name': 'Camry', 'brandId': 1, 'carTypeId': 1});
  }

  @override
  Future<Map<String, dynamic>?> readUser(String id) =>
      request('users', {'name': 'Seller', 'phone': '0123456789'});
  @override
  Future<List<String>> readImages(int carId) =>
      request('images', ['image-$carId']);
}

void main() {
  test('A baseline has 25 reads for six posts and no parallel related calls',
      () async {
    final source = FakeFeed();
    final page = await HomeFeedLoader(source,
            options: const HomeFeedOptions(variant: 'A'))
        .load();
    expect(source.calls.values.reduce((a, b) => a + b), 25);
    expect(source.maxActive, 1);
    expect(page.items.map((e) => e.post.id), [0, 1, 2, 3, 4, 5]);
  });
  test(
      'B overlaps independent calls, respects limit, preserves order and values',
      () async {
    final source = FakeFeed();
    final page = await HomeFeedLoader(source,
            options: const HomeFeedOptions(variant: 'B', concurrency: 3))
        .load();
    expect(source.maxActive, inInclusiveRange(2, 3));
    expect(source.calls.values.reduce((a, b) => a + b), 25);
    expect(page.items.map((e) => e.post.id), [0, 1, 2, 3, 4, 5]);
    expect(
        page.items.every(
            (e) => e.carModelName == 'Camry' && e.sellerName == 'Seller'),
        isTrue);
  });
  test(
      'C shares in-flight model and seller reads, but not stale results across loads',
      () async {
    final source = FakeFeed();
    final loader =
        HomeFeedLoader(source, options: const HomeFeedOptions(variant: 'C'));
    await loader.load();
    expect(source.calls,
        {'posts': 1, 'cars': 6, 'models': 1, 'users': 1, 'images': 6});
    await loader.load();
    expect(source.calls['models'], 2);
    expect(source.calls['users'], 2);
  });
  test('D deduplicates car/image too and only hydrates the requested page',
      () async {
    final source = FakeFeed(count: 23, sharedCar: true);
    final loader =
        HomeFeedLoader(source, options: const HomeFeedOptions(pageSize: 20));
    final first = await loader.load();
    expect(first.items, hasLength(20));
    expect(first.hasMore, isTrue);
    expect(source.calls,
        {'posts': 1, 'cars': 1, 'models': 1, 'users': 1, 'images': 1});
    final second = await loader.load(after: first.cursor);
    expect(source.requestedLimit, 20);
    expect(source.requestedAfter, '20');
    expect(second.items.map((e) => e.post.id), [20, 21, 22]);
    expect(second.hasMore, isFalse);
  });
  test('optional model/user failure preserves listing', () async {
    final source = FakeFeed()..failures.addAll(['models', 'users']);
    final page = await HomeFeedLoader(source).load();
    expect(page.items, hasLength(6));
    expect(
        page.items.every((e) => e.carModelName == null && e.sellerName == null),
        isTrue);
    expect(source.active, 0);
  });
  for (final failure in ['posts', 'cars', 'images']) {
    test('required $failure failure propagates and drains outstanding work',
        () async {
      final source = FakeFeed()..failures.add(failure);
      await expectLater(HomeFeedLoader(source).load(), throwsStateError);
      expect(source.active, 0);
    });
  }
  test('empty page has no related reads', () async {
    final source = FakeFeed(count: 0);
    final page = await HomeFeedLoader(source).load();
    expect(page.items, isEmpty);
    expect(page.hasMore, isFalse);
    expect(source.calls, {'posts': 1});
  });
  test('invalid concurrency fails early instead of deadlocking', () async {
    final source = FakeFeed();
    await expectLater(
        HomeFeedLoader(source, options: const HomeFeedOptions(concurrency: 0))
            .load(),
        throwsArgumentError);
    expect(source.calls, isEmpty);
  });
}
