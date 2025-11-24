import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:online_car_marketplace_app/models/car_model.dart';
import 'package:online_car_marketplace_app/models/post_model.dart';
import 'package:online_car_marketplace_app/models/image_model.dart';
import 'package:online_car_marketplace_app/models/model_model.dart'; // Import CarModel (for model name)
import 'package:online_car_marketplace_app/repositories/post_repository.dart';
import 'package:online_car_marketplace_app/repositories/car_repository.dart';
import 'package:online_car_marketplace_app/repositories/image_repository.dart';
import 'package:online_car_marketplace_app/repositories/model_repository.dart'; // Import ModelRepository
import '../../../services/storage_service.dart';
import '../../widgets/user/sell_bottom_navigation_bar.dart';
import 'package:provider/provider.dart';

class MyPostsScreen extends StatefulWidget {
  const MyPostsScreen({super.key});

  @override
  State<MyPostsScreen> createState() => _MyPostsScreenState();
}

class _MyPostsScreenState extends State<MyPostsScreen> {
  final User? currentUser = FirebaseAuth.instance.currentUser;
  List<PostDisplayData> _userPosts = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchUserPosts();
  }

  Future<void> _fetchUserPosts() async {
    if (currentUser == null) {
      setState(() {
        _errorMessage = 'Bạn cần đăng nhập để xem tin đăng của mình.';
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final postRepository = Provider.of<PostRepository>(context, listen: false);
      final carRepository = Provider.of<CarRepository>(context, listen: false);
      final imageRepository = Provider.of<ImageRepository>(context, listen: false);
      final modelRepository = Provider.of<ModelRepository>(context, listen: false); // Get ModelRepository

      final List<Post> posts = await postRepository.getPostsByUserId(currentUser!.uid);

      List<PostDisplayData> fetchedPosts = [];
      for (Post post in posts) {
        final Car? car = await carRepository.getCarById(post.carId);
        if (car != null) {
          final List<ImageModel> images = await imageRepository.getImagesByCarId(car.id!);
          final String? imageUrl = images.isNotEmpty ? images.first.url : null;

          CarModel? carModel;
          int brandId = -1; // Khởi tạo brandId với giá trị mặc định (ví dụ: -1 hoặc 0)

          if (car.modelId != null) {
            carModel = await modelRepository.getModelById(car.modelId!);
            if (carModel != null) {
              brandId = carModel.brandId; // Gán giá trị nếu tìm thấy carModel
            }
          }

          fetchedPosts.add(PostDisplayData(
            post: post,
            car: car,
            imageUrl: imageUrl,
            modelName: carModel?.name, // Truyền model name
            brandId: brandId, // brandId giờ luôn được gán
            allImageUrls: images.map((e) => e.url).toList(), // Truyền tất cả các URL ảnh
          ));
        }
      }

      setState(() {
        _userPosts = fetchedPosts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Không thể tải tin đăng: $e';
        _isLoading = false;
      });
      print('Error fetching user posts: $e');
    }
  }

  Future<void> _deletePost(int postId, int carId, List<String> imageUrls) async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Xác nhận xóa'),
          content: const Text('Bạn có chắc chắn muốn xóa tin đăng này?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Hủy'),
              onPressed: () => Navigator.of(dialogContext).pop(false),
            ),
            TextButton(
              child: const Text('Xóa', style: TextStyle(color: Colors.red)),
              onPressed: () => Navigator.of(dialogContext).pop(true),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      try {
        final postRepository = Provider.of<PostRepository>(context, listen: false);
        final carRepository = Provider.of<CarRepository>(context, listen: false);
        final imageRepository = Provider.of<ImageRepository>(context, listen: false);
        final storageService = Provider.of<StorageService>(context, listen: false);

        // 1. Delete associated images from storage
        for (String url in imageUrls) {
          if (url.startsWith('https://firebasestorage.googleapis.com')) {
            await storageService.deleteImage(url);
          }
        }
        // 2. Delete images from Firestore
        await imageRepository.deleteImagesByCarId(carId);
        // 3. Delete the post from Firestore
        await postRepository.deletePost(postId);
        // 4. Delete the car from Firestore
        await carRepository.deleteCar(carId);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã xóa tin đăng thành công!')),
        );
        _fetchUserPosts(); // Refresh the list
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi xóa tin đăng: $e')),
        );
        print('Error deleting post: $e');
      }
    }
  }

  void _editPost(PostDisplayData postData) {
    context.push('/sell/confirm-post', extra: {
      'brandId': postData.brandId.toString(), // Chuyển int sang String để truyền qua GoRouter
      'modelId': postData.car.modelId,
      'modelName': postData.modelName ?? 'Unknown Model', // Truyền model name
      'selectedYear': postData.car.year.toString(),
      'condition': postData.car.condition,
      'origin': postData.car.origin,
      'mileage': postData.car.mileage,
      'fuelType': postData.car.fuelType,
      'transmission': postData.car.transmission,
      'price': postData.car.price,
      'title': postData.post.title,
      'description': postData.post.description,
      'selectedImages': <XFile>[], // Khi sửa, không có XFile mới ban đầu
      'initialData': {
        'isEditing': true, // Đánh dấu đây là thao tác sửa
        'postId': postData.post.id,
        'carId': postData.car.id,
        'existingImageUrls': postData.allImageUrls, // Truyền tất cả các URL ảnh hiện có
      }
    });
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: const Text('Quản lý tin rao', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(child: Text(_errorMessage!))
          : _userPosts.isEmpty
          ? const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.description_outlined, size: 80, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Bạn chưa có tin đăng nào.',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              'Bắt đầu đăng bán xe ngay!',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(8.0),
        itemCount: _userPosts.length,
        itemBuilder: (context, index) {
          final postData = _userPosts[index];
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 8.0),
            elevation: 3,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8.0),
                        child: postData.imageUrl != null
                            ? Image.network(
                          postData.imageUrl!,
                          width: 100,
                          height: 80,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 100,
                              height: 80,
                              color: Colors.grey[300],
                              child: const Icon(Icons.broken_image, size: 40, color: Colors.grey),
                            );
                          },
                        )
                            : Container(
                          width: 100,
                          height: 80,
                          color: Colors.grey[300],
                          child: const Icon(Icons.car_rental, size: 40, color: Colors.grey),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              postData.post.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16.0,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${postData.car.price} TRIỆU VND',
                              style: const TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                                fontSize: 15.0,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${postData.car.year} | ${postData.car.mileage} km',
                              style: const TextStyle(color: Colors.grey, fontSize: 13.0),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Trạng thái: Đang hiển thị',
                              style: TextStyle(color: Colors.green, fontSize: 13.0, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 20, thickness: 1),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildActionButton(
                        icon: Icons.edit,
                        label: 'Sửa tin',
                        onTap: () => _editPost(postData),
                      ),
                      _buildActionButton(
                        icon: Icons.refresh,
                        label: 'Đẩy tin',
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Tính năng đẩy tin đang phát triển.')),
                          );
                        },
                      ),
                      _buildActionButton(
                        icon: Icons.sell,
                        label: 'Đã bán',
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Tính năng đánh dấu đã bán đang phát triển.')),
                          );
                        },
                      ),
                      _buildActionButton(
                        icon: Icons.delete_outline,
                        label: 'Xóa tin',
                        onTap: () => _deletePost(postData.post.id!, postData.car.id!, postData.allImageUrls),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
      // bottomNavigationBar: const SellBottomNavigationBar(currentIndex: 1),
    );
  }

  Widget _buildActionButton({required IconData icon, required String label, required VoidCallback onTap}) {
    return Column(
      children: [
        IconButton(
          icon: Icon(icon, color: Colors.blue),
          onPressed: onTap,
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.blue),
        ),
      ],
    );
  }
}

// Helper class to combine Post, Car, and Image data for display
class PostDisplayData {
  final Post post;
  final Car car;
  final String? imageUrl;
  final String? modelName;
  final String? location;
  final int brandId; // Vẫn là int như bạn đã định nghĩa
  final List<String> allImageUrls;

  PostDisplayData({
    required this.post,
    required this.car,
    this.imageUrl,
    this.modelName,
    this.location,
    required this.brandId, // brandId là bắt buộc (non-nullable)
    required this.allImageUrls,
  });
}