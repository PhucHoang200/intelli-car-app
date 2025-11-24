
import 'package:flutter/material.dart';
import 'package:online_car_marketplace_app/models/post_model.dart';
import 'package:online_car_marketplace_app/repositories/post_repository.dart';
import 'package:online_car_marketplace_app/models/post_with_car_and_images.dart';
import 'package:online_car_marketplace_app/models/car_model.dart';

class PostProvider with ChangeNotifier {
  final PostRepository _postRepository = PostRepository();
  List<PostWithCarAndImages> _posts = [];
  List<PostWithCarAndImages> get posts => _posts;
  bool _isLoading = false;
  bool get isLoading => _isLoading;
  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // BIẾN MỚI CHO LỌC ĐỊA ĐIỂM
  String _locationFilter = ''; // Lưu trữ tỉnh/thành phố được chọn
  String get currentLocationFilter => _locationFilter; // Getter cho UI

  Future<void> fetchPosts() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final rawData = await _postRepository.getPostsWithCarAndImages();
      _posts = rawData.map((item) {
        return PostWithCarAndImages(
          post: item['post'],
          car: item['car'],
          sellerName: item['sellerName'] as String?,
          sellerPhone: item['sellerPhone'] as String?,
          sellerAddress: item['sellerAddress'] as String?,
          carLocation: item['carLocation'] as String?,
          imageUrls: List<String>.from(item['images']),
          carModelName: item['carModelName'] as String?,
        );
      }).toList();
    } catch (error) {
      _errorMessage = error.toString();
      _posts = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addPostAutoIncrement(Post post) async {
    await _postRepository.addPostAutoIncrement(post);
    await fetchPosts();
  }

  void clearPosts() {
    _posts = [];
    _locationFilter = '';
    notifyListeners();
  }

  Future<PostWithCarAndImages?> getPostWithDetailsById(String postId) async {
    try {
      final postWithDetails = await _postRepository.getPostWithCarAndImagesById(postId);
      return postWithDetails;
    } catch (error) {
      print('Error fetching post details by ID: $error');
      return null;
    }
  }

  // Phương thức mới để tìm kiếm, giờ trả về Future<void>
  Future<void> searchPosts(String query) async {
    _isLoading = true; // Bật loading trong provider
    notifyListeners(); // Thông báo cho Consumers rằng trạng thái đã thay đổi

    try {
      // Lắng nghe Stream từ repository và xử lý dữ liệu
      // Bạn chỉ cần take(1) nếu bạn mong đợi Stream chỉ phát ra một lần cho kết quả tìm kiếm
      // Hoặc xử lý theo cách Stream có thể phát ra nhiều lần (ví dụ: Live search)
      await _postRepository.searchPosts(query).first.then((postList) {
        _posts = postList;
        _isLoading = false; // Tắt loading khi dữ liệu đã được nhận
        notifyListeners(); // Cập nhật Consumers với dữ liệu mới
      }).catchError((error) {
        _isLoading = false; // Tắt loading nếu có lỗi
        print('Error searching posts: $error');
        notifyListeners(); // Thông báo cho Consumers ngay cả khi có lỗi
      });
    } catch (e) {
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
