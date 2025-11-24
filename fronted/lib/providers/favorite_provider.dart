
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:online_car_marketplace_app/models/car_model.dart';
import 'package:online_car_marketplace_app/models/favorite_model.dart';
import 'package:online_car_marketplace_app/models/post_model.dart';
import 'package:online_car_marketplace_app/models/post_with_car_and_images.dart';
import 'package:online_car_marketplace_app/repositories/favorite_repository.dart';
import 'package:online_car_marketplace_app/repositories/post_repository.dart';

class FavoriteProvider extends ChangeNotifier {
  final FavoriteRepository _favoriteRepository = FavoriteRepository();
  final PostRepository _postRepository = PostRepository();

  List<Favorite> _favorites = [];
  List<Favorite> get favorites => _favorites;
  List<PostWithCarAndImages> _favoritePostsWithDetails = [];
  List<PostWithCarAndImages> get favoritePostsWithDetails => _favoritePostsWithDetails;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // Map để theo dõi trạng thái yêu thích cục bộ (không cần gọi API ngay)
  final Map<int, bool> _localFavoriteStatus = {};

  // Lấy trạng thái yêu thích cục bộ
  bool isPostLocallyFavorite(int postId) {
    return _localFavoriteStatus[postId] ?? false;
  }

  // Thay đổi trạng thái yêu thích cục bộ
  void toggleFavoriteLocal(int postId) {
    _localFavoriteStatus[postId] = !isPostLocallyFavorite(postId);
    notifyListeners(); // Báo cho các widget đang lắng nghe biết trạng thái đã thay đổi
  }

  Future<void> fetchFavorites() async {
    _isLoading = true;
    notifyListeners();

    try {
      _favorites = await _favoriteRepository.getFavorites();
    } catch (e) {
      print('Error fetching favorites: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Future<void> fetchFavoritePosts(String userId) async {
  //   _isLoading = true;
  //   notifyListeners();
  //   _favoritePostsWithDetails.clear();
  //   try {
  //     final favoriteList = await _favoriteRepository.getFavoritesByUserId(userId);
  //     for (final favorite in favoriteList) {
  //       final postDoc = await _postRepository.getPostDetails(favorite.postId.toString()); // Sử dụng PostRepository
  //
  //       if (postDoc.exists) {
  //         final post = Post.fromMap(postDoc.data() as Map<String, dynamic>);
  //         Car? car;
  //         String? sellerName;
  //         String? sellerPhone;
  //         String? sellerAddress;
  //         String? carLocation;
  //         List<String> imageUrls = [];
  //
  //         // Lấy thông tin xe
  //         final carDoc = await _postRepository.getCarDetails(post.carId.toString()); // Sử dụng PostRepository
  //         if (carDoc.exists) {
  //           final carData = carDoc.data() as Map<String, dynamic>;
  //           car = Car.fromMap(carData);
  //           carLocation = carData['location'] as String?;
  //
  //           // Lấy ảnh theo carId (tương tự PostRepository)
  //           final imagesSnapshot = await FirebaseFirestore.instance
  //               .collection('images')
  //               .where('carId', isEqualTo: post.carId)
  //               .get();
  //           imageUrls = imagesSnapshot.docs.map((e) => e['url'] as String).toList();
  //         }
  //
  //         // Lấy thông tin người dùng (tương tự PostRepository)
  //         if (post.userId != null) {
  //           final String sellerId = post.userId!;
  //           final userDoc = await FirebaseFirestore.instance.collection('users').doc(sellerId).get();
  //           if (userDoc.exists) {
  //             final userData = userDoc.data() as Map<String, dynamic>;
  //             sellerName = userData['name'] as String?;
  //             sellerPhone = userData['phone'] as String?;
  //             sellerAddress = userData['address'] as String?;
  //           }
  //         }
  //
  //         final postWithDetails = PostWithCarAndImages(
  //           post: post,
  //           car: car,
  //           sellerName: sellerName,
  //           sellerPhone: sellerPhone,
  //           sellerAddress: sellerAddress,
  //           carLocation: carLocation,
  //           imageUrls: imageUrls,
  //         );
  //         _favoritePostsWithDetails.add(postWithDetails);
  //       } else {
  //       }
  //     }
  //   } catch (e) {
  //     print('Error fetching favorite posts with details: $e');
  //   } finally {
  //     _isLoading = false;
  //     notifyListeners();
  //   }
  // }

  Future<void> fetchFavoritePosts(String userId) async {
    _isLoading = true;
    notifyListeners();
    _favoritePostsWithDetails.clear(); // Xóa dữ liệu cũ trước khi fetch mới

    try {
      final favoriteList = await _favoriteRepository.getFavoritesByUserId(userId);

      for (final favorite in favoriteList) {
        // Gọi hàm getPostDetails đã được sửa đổi
        final postDetails = await _postRepository.getPostDetails(favorite.postId.toString());

        // Kiểm tra xem postDetails có rỗng không (nghĩa là post không tồn tại)
        if (postDetails.isNotEmpty) {
          final post = postDetails['post'] as Post;
          final car = postDetails['car'] as Car?;
          final sellerName = postDetails['sellerName'] as String?;
          final sellerPhone = postDetails['sellerPhone'] as String?;
          final sellerAddress = postDetails['sellerAddress'] as String?;
          final carLocation = postDetails['carLocation'] as String?;
          final imageUrls = postDetails['images'] as List<String>;
          final carModelName = postDetails['carModelName'] as String?; // Lấy carModelName

          final postWithDetails = PostWithCarAndImages(
            post: post,
            car: car,
            sellerName: sellerName,
            sellerPhone: sellerPhone,
            sellerAddress: sellerAddress,
            carLocation: carLocation,
            imageUrls: imageUrls,
            carModelName: carModelName, // Gán carModelName vào PostWithCarAndImages
          );
          _favoritePostsWithDetails.add(postWithDetails);
        } else {
          // Xử lý trường hợp bài đăng không tồn tại (ví dụ: in ra log)
          print('Post with ID ${favorite.postId} not found or details empty.');
        }
      }
    } catch (e) {
      print('Error fetching favorite posts with details: $e');
      // Có thể hiển thị SnackBar hoặc thông báo lỗi cho người dùng
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> removeFavorite(String userId, int postId) async {
    try {
      await _favoriteRepository.removeFavorite(userId, postId);
      _favoritePostsWithDetails.removeWhere((item) => item.post.id == postId);
      notifyListeners();
    } catch (e) {
      print('Error removing favorite: $e');
    }
  }

  Future<void> addFavorite(Favorite favorite) async {
    try {
      await _favoriteRepository.addFavorite(favorite);
      _favorites.add(favorite);
      notifyListeners();
    } catch (e) {
      print('Error adding favorite: $e');
    }
  }

  // Gọi phương thức addFavoriteAutoIncrement từ repository
  Future<void> addFavoriteAutoIncrement(Favorite favorite) async {
    try {
      await _favoriteRepository.addFavoriteAutoIncrement(favorite);
      _favorites.add(favorite);
      notifyListeners();
    } catch (e) {
      print('Error adding favorite with auto-increment ID: $e');
    }
  }

  Future<bool> isPostFavorite(String userId, int postId) async {
    try {
      final favoriteList = await _favoriteRepository.getFavoritesByUserIdAndPostId(userId, postId);
      return favoriteList.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

}
