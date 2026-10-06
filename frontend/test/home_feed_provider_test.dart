import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:online_car_marketplace_app/models/post_model.dart';
import 'package:online_car_marketplace_app/models/post_with_car_and_images.dart';
import 'package:online_car_marketplace_app/providers/post_provider.dart';
import 'package:online_car_marketplace_app/repositories/post_repository.dart';
import 'package:online_car_marketplace_app/repositories/home_feed_loader.dart';
import 'package:online_car_marketplace_app/services/home_load_trace.dart';

HomeFeedPage page(List<int> ids, {bool more = false, String? cursor}) =>
    HomeFeedPage([
      for (final id in ids)
        PostWithCarAndImages(
            post: Post(
                id: id,
                userId: null,
                carId: id,
                title: 'post',
                description: '',
                creationDate: DateTime.utc(2026)),
            car: null,
            imageUrls: []),
    ], cursor: cursor, hasMore: more);

class StubRepository extends PostRepository {
  final requests = <Completer<HomeFeedPage>>[];
  final cursors = <String?>[];
  final searches = StreamController<List<PostWithCarAndImages>>();
  @override
  Future<HomeFeedPage> getHomePage({String? after, HomeLoadTrace? trace}) {
    cursors.add(after);
    final result = Completer<HomeFeedPage>();
    requests.add(result);
    return result.future;
  }

  @override
  Stream<List<PostWithCarAndImages>> searchPosts(String query) =>
      searches.stream;
}

void main() {
  test('load-more coalesces taps, appends unique IDs and stops at end',
      () async {
    final repo = StubRepository();
    final provider = PostProvider(repository: repo);
    addTearDown(provider.dispose);
    final first = provider.fetchPosts();
    repo.requests[0].complete(page([1, 2], more: true, cursor: '2'));
    await first;
    final more = provider.loadMore();
    await provider.loadMore();
    expect(repo.requests, hasLength(2));
    expect(repo.cursors.last, '2');
    repo.requests[1].complete(page([2, 3]));
    await more;
    expect(provider.posts.map((e) => e.post.id), [1, 2, 3]);
    await provider.loadMore();
    expect(repo.requests, hasLength(2));
  });
  test('failed page retains items/cursor and can retry', () async {
    final repo = StubRepository();
    final provider = PostProvider(repository: repo);
    addTearDown(provider.dispose);
    final first = provider.fetchPosts();
    repo.requests[0].complete(page([1], more: true, cursor: '1'));
    await first;
    final more = provider.loadMore();
    repo.requests[1].completeError(StateError('network'));
    await more;
    expect(provider.posts, hasLength(1));
    expect(provider.loadMoreError, isNotNull);
    final retry = provider.loadMore();
    expect(repo.cursors.last, '1');
    repo.requests[2].complete(page([2]));
    await retry;
    expect(provider.loadMoreError, isNull);
    expect(provider.posts, hasLength(2));
  });
  test('old page cannot overwrite a refreshed first page', () async {
    final repo = StubRepository();
    final provider = PostProvider(repository: repo);
    addTearDown(provider.dispose);
    final old = provider.fetchPosts();
    final fresh = provider.fetchPosts();
    repo.requests[1].complete(page([9]));
    await fresh;
    repo.requests[0].complete(page([1], more: true));
    await old;
    expect(provider.posts.single.post.id, 9);
    expect(provider.hasMore, isFalse);
  });
  test('search invalidates pending page and disables feed pagination',
      () async {
    final repo = StubRepository();
    final provider = PostProvider(repository: repo);
    addTearDown(provider.dispose);
    final old = provider.fetchPosts();
    final search = provider.searchPosts('Toyota');
    repo.searches.add(page([8]).items);
    await search;
    repo.requests[0].complete(page([1], more: true));
    await old;
    await provider.loadMore();
    expect(provider.posts.single.post.id, 8);
    expect(repo.requests, hasLength(1));
    await repo.searches.close();
  });
  test(
      'disposing during fetch ignores late result and avoids notifying listeners',
      () async {
    final repo = StubRepository();
    final provider = PostProvider(repository: repo);
    final task = provider.fetchPosts();
    provider.dispose();
    repo.requests.single.complete(page([1]));
    await task;
    expect(provider.posts, isEmpty);
  });
}
