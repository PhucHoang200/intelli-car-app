import 'package:flutter/material.dart';
import 'package:online_car_marketplace_app/services/home_load_trace.dart';
import 'package:online_car_marketplace_app/models/post_model.dart';
import 'package:online_car_marketplace_app/repositories/post_repository.dart';
import 'package:online_car_marketplace_app/models/post_with_car_and_images.dart';
import 'package:online_car_marketplace_app/repositories/home_feed_loader.dart';

class PostProvider with ChangeNotifier {
  PostProvider({PostRepository? repository})
      : _postRepository = repository ?? PostRepository();
  final PostRepository _postRepository;
  String? _cursor;
  bool _hasMore = false;
  bool get hasMore => _hasMore;
  bool _isLoadingMore = false;
  bool get isLoadingMore => _isLoadingMore;
  String? _loadMoreError;
  String? get loadMoreError => _loadMoreError;
  bool _searchMode = false;
  int _generation = 0;
  bool _disposed = false;
  bool _current(int generation) => !_disposed && generation == _generation;

  @override
  void dispose() {
    _disposed = true;
    _generation++;
    super.dispose();
  }

  List<PostWithCarAndImages> _posts = [];
  List<PostWithCarAndImages> get posts => _posts;
  bool _isLoading = false;
  bool get isLoading => _isLoading;
  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // BIẾN MỚI CHO LỌC ĐỊA ĐIỂM
  String _locationFilter = ''; // Lưu trữ tỉnh/thành phố được chọn
  String get currentLocationFilter => _locationFilter; // Getter cho UI

  Future<void> fetchPosts({HomeLoadTrace? trace}) async {
    final generation = ++_generation;
    _searchMode = false;
    _cursor = null;
    _hasMore = false;
    _isLoadingMore = false;
    _loadMoreError = null;
    trace?.mark('posts_fetch_start');
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final page = await _postRepository.getHomePage(trace: trace);
      if (!_current(generation)) {
        trace?.finish('superseded');
        return;
      }
      _posts = page.items;
      _cursor = page.cursor;
      _hasMore = page.hasMore;
      trace?.postsSettled(count: _posts.length, succeeded: true);
    } catch (error) {
      if (!_current(generation)) {
        trace?.finish('superseded');
        return;
      }
      _errorMessage = error.toString();
      _posts = [];
      trace?.postsSettled(count: 0, succeeded: false);
    } finally {
      if (_current(generation)) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> loadMore() async {
    if (_disposed || _isLoading || _isLoadingMore || !_hasMore || _searchMode) {
      return;
    }
    final generation = _generation;
    _isLoadingMore = true;
    _loadMoreError = null;
    notifyListeners();
    try {
      final HomeFeedPage page =
          await _postRepository.getHomePage(after: _cursor);
      if (!_current(generation)) return;
      final ids = _posts.map((item) => item.post.id).toSet();
      _posts = [
        ..._posts,
        ...page.items.where((item) => ids.add(item.post.id))
      ];
      _cursor = page.cursor;
      _hasMore = page.hasMore;
    } catch (error) {
      if (_current(generation)) _loadMoreError = error.toString();
    } finally {
      if (_current(generation)) {
        _isLoadingMore = false;
        notifyListeners();
      }
    }
  }

  Future<void> addPostAutoIncrement(Post post) async {
    await _postRepository.addPostAutoIncrement(post);
    await fetchPosts();
  }

  void clearPosts() {
    _generation++;
    _cursor = null;
    _hasMore = false;
    _searchMode = false;
    _isLoading = _isLoadingMore = false;
    _errorMessage = _loadMoreError = null;
    _posts = [];
    _locationFilter = '';
    notifyListeners();
  }

  Future<PostWithCarAndImages?> getPostWithDetailsById(String postId) async {
    try {
      final postWithDetails =
          await _postRepository.getPostWithCarAndImagesById(postId);
      return postWithDetails;
    } catch (error) {
      print('Error fetching post details by ID: $error');
      return null;
    }
  }

  // Phương thức mới để tìm kiếm, giờ trả về Future<void>
  Future<void> searchPosts(String query) async {
    if (query.trim().isEmpty) {
      await fetchPosts();
      return;
    }
    final generation = ++_generation;
    _searchMode = true;
    _hasMore = false;
    _isLoadingMore = false;
    _errorMessage = _loadMoreError = null;
    _isLoading = true; // Bật loading trong provider
    notifyListeners(); // Thông báo cho Consumers rằng trạng thái đã thay đổi

    try {
      // Lắng nghe Stream từ repository và xử lý dữ liệu
      // Bạn chỉ cần take(1) nếu bạn mong đợi Stream chỉ phát ra một lần cho kết quả tìm kiếm
      // Hoặc xử lý theo cách Stream có thể phát ra nhiều lần (ví dụ: Live search)
      await _postRepository.searchPosts(query).first.then((postList) {
        if (!_current(generation)) return;
        _posts = postList;
        _isLoading = false; // Tắt loading khi dữ liệu đã được nhận
        notifyListeners(); // Cập nhật Consumers với dữ liệu mới
      }).catchError((error) {
        if (!_current(generation)) return;
        _errorMessage = error.toString();
        _isLoading = false; // Tắt loading nếu có lỗi
        print('Error searching posts: $error');
        notifyListeners(); // Thông báo cho Consumers ngay cả khi có lỗi
      });
    } catch (e) {
      if (!_current(generation)) return;
      _errorMessage = e.toString();
      _isLoading = false; // Tắt loading nếu có lỗi ở mức cao hơn
      print('Error during searchPosts call: $e');
      notifyListeners();
    }
  }

  Future<void> resetPosts() async {
    _isLoading = true;
    notifyListeners();
    // Đặt lại danh sách bài đăng về rỗng trước khi fetch mới
    _posts = [];
    notifyListeners();
    // Sau đó gọi lại hàm fetchPosts để lấy tất cả bài đăng ban đầu
    await fetchPosts();
  }
}
