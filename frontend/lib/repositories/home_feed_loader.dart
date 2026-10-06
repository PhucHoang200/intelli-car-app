import 'dart:async';
import 'dart:collection';

import 'package:online_car_marketplace_app/models/car_model.dart';
import 'package:online_car_marketplace_app/models/model_model.dart';
import 'package:online_car_marketplace_app/models/post_model.dart';
import 'package:online_car_marketplace_app/models/post_with_car_and_images.dart';
import 'package:online_car_marketplace_app/services/home_load_trace.dart';

/// A = sequential, B = bounded parallel, C = B + request-scoped dedup,
/// D = C + cursor pagination. No cross-request cache hides updated listings.
class HomeFeedOptions {
  const HomeFeedOptions(
      {this.variant = 'D', this.concurrency = 4, this.pageSize = 20});
  static const current = HomeFeedOptions(
    variant: String.fromEnvironment('HOME_VARIANT', defaultValue: 'D'),
    concurrency: int.fromEnvironment('HOME_CONCURRENCY', defaultValue: 4),
    pageSize: int.fromEnvironment('HOME_PAGE_SIZE', defaultValue: 20),
  );
  final String variant;
  final int concurrency;
  final int pageSize;
  bool get parallel => variant != 'A';
  bool get deduplicate => variant == 'C' || variant == 'D';
  bool get paginated => variant == 'D';
  void validate() {
    if (!['A', 'B', 'C', 'D'].contains(variant) ||
        concurrency < 1 ||
        concurrency > 16 ||
        pageSize < 1 ||
        pageSize > 100) {
      throw ArgumentError('Invalid home feed options');
    }
  }
}

class HomePostSlice {
  const HomePostSlice(this.posts, {this.cursor, this.hasMore = false});
  final List<Post> posts;
  final String? cursor;
  final bool hasMore;
}

class HomeFeedPage {
  const HomeFeedPage(this.items, {this.cursor, this.hasMore = false});
  final List<PostWithCarAndImages> items;
  final String? cursor;
  final bool hasMore;
}

abstract class HomeFeedSource {
  Future<HomePostSlice> readPosts({int? limit, String? after});
  Future<Map<String, dynamic>?> readCar(int id);
  Future<Map<String, dynamic>?> readModel(int id);
  Future<Map<String, dynamic>?> readUser(String id);
  Future<List<String>> readImages(int carId);
}

class _ReadPool {
  _ReadPool(this.limit);
  final int limit;
  int active = 0;
  final Queue<Completer<void>> waiting = Queue();
  Future<T> run<T>(Future<T> Function() action) async {
    if (active >= limit) {
      final slot = Completer<void>();
      waiting.add(slot);
      await slot.future;
    } else {
      active++;
    }
    try {
      return await action();
    } finally {
      if (waiting.isEmpty) {
        active--;
      } else {
        waiting.removeFirst().complete();
      }
    }
  }
}

class HomeFeedLoader {
  HomeFeedLoader(this.source, {this.options = HomeFeedOptions.current});
  final HomeFeedSource source;
  final HomeFeedOptions options;

  Future<HomeFeedPage> load({String? after, HomeLoadTrace? trace}) async {
    options.validate();
    trace?.setFeedMetadata({
      'variant': options.variant,
      'concurrency': options.parallel ? options.concurrency : 1,
      'page_size': options.paginated ? options.pageSize : null,
      'dedup_scope': options.deduplicate ? 'page_request' : 'none',
      'landing_prefetch': false,
    });
    final pool = _ReadPool(options.parallel ? options.concurrency : 1);
    Future<T> read<T>(String label, Future<T> Function() action) =>
        pool.run(() => trace == null ? action() : trace.measure(label, action));
    final slice = await read(
        'posts_sdk',
        () => source.readPosts(
            limit: options.paginated ? options.pageSize : null,
            after: options.paginated ? after : null));

    // Cache futures, including in-flight requests, rather than only finished values.
    final cars = <int, Future<Car?>>{};
    final models = <int, Future<String?>>{};
    final users = <String, Future<Map<String, dynamic>?>>{};
    final images = <int, Future<List<String>>>{};
    Future<V> cached<K, V>(
            Map<K, Future<V>> cache, K key, Future<V> Function() action) =>
        options.deduplicate ? cache.putIfAbsent(key, action) : action();

    Future<Car?> carFor(int id) => cached(cars, id, () async {
          final data = await read('cars_sdk', () => source.readCar(id));
          return data == null ? null : Car.fromMap(data);
        });
    Future<String?> modelFor(int id) => cached(models, id, () async {
          try {
            final data = await read('models_sdk', () => source.readModel(id));
            return data == null ? null : CarModel.fromMap(data).name;
          } catch (_) {
            // Preserve existing optional model behavior.
            return null;
          }
        });
    Future<Map<String, dynamic>?> userFor(String id) =>
        cached(users, id, () async {
          try {
            return await read('users_sdk', () => source.readUser(id));
          } catch (_) {
            return null;
          }
        });
    Future<List<String>> imagesFor(int id) => cached(images, id,
        () => read('images_metadata_sdk', () => source.readImages(id)));

    Future<PostWithCarAndImages> assemble(Post post) async {
      Car? car;
      String? modelName;
      String? sellerName;
      String? sellerPhone;
      String? sellerAddress;
      List<String> urls = [];
      Future<void> carAndModel() async {
        car = await carFor(post.carId);
        if (car != null) modelName = await modelFor(car!.modelId);
      }

      Future<void> seller() async {
        if (post.userId == null) return;
        try {
          final user = await userFor(post.userId!);
          sellerName = user?['name'] as String?;
          sellerPhone = user?['phone'] as String?;
          sellerAddress = user?['address'] as String?;
        } catch (_) {
          sellerName = sellerPhone = sellerAddress = null;
        }
      }

      Future<void> thumbnails() async {
        urls = await imagesFor(post.carId);
      }

      if (options.parallel) {
        // Only car -> model is a real dependency. Seller and images use post IDs.
        // Future.wait waits for all branches on error, avoiding orphan rejections.
        await Future.wait([carAndModel(), seller(), thumbnails()]);
      } else {
        await carAndModel();
        await seller();
        await thumbnails();
      }
      return PostWithCarAndImages(
          post: post,
          car: car,
          carModelName: modelName,
          sellerName: sellerName,
          sellerPhone: sellerPhone,
          sellerAddress: sellerAddress,
          carLocation: car?.location,
          imageUrls: urls);
    }

    final results =
        List<PostWithCarAndImages?>.filled(slice.posts.length, null);
    var next = 0;
    Future<void> worker() async {
      while (next < slice.posts.length) {
        final index = next++;
        results[index] = await assemble(slice.posts[index]);
      }
    }

    final workers = options.parallel ? options.concurrency : 1;
    await Future.wait(List.generate(
        workers > slice.posts.length ? slice.posts.length : workers,
        (_) => worker()));
    return HomeFeedPage(results.cast<PostWithCarAndImages>(),
        cursor: slice.cursor, hasMore: slice.hasMore);
  }
}
