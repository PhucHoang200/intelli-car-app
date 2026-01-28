import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:online_car_marketplace_app/providers/favorite_provider.dart';
import 'package:online_car_marketplace_app/models/post_with_car_and_images.dart';
import 'post_detail_screen.dart';

class FavoritePostsScreen extends StatefulWidget {
  final String uid;
  const FavoritePostsScreen({super.key, required this.uid});

  @override
  State<FavoritePostsScreen> createState() => _FavoritePostsScreenState();
}

class _FavoritePostsScreenState extends State<FavoritePostsScreen> {
  late String userId;

  @override
  void initState() {
    super.initState();
    userId = widget.uid;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // final favoriteProvider = Provider.of<FavoriteProvider>(context, listen: false);
      // final currentUser = FirebaseAuth.instance.currentUser;
      // if (currentUser != null) {
      //   favoriteProvider.fetchFavoritePosts(currentUser.uid);
      // }
    });
  }

  String _truncateText(String text, int maxLength) {
    if (text.length <= maxLength) {
      return text;
    } else {
      return '${text.substring(0, maxLength)}...';
    }
  }

  Widget _buildFavoritePostItem(BuildContext context, PostWithCarAndImages postWithDetails) {
    final post = postWithDetails.post;
    final car = postWithDetails.car;
    final imageUrl = postWithDetails.imageUrls.isNotEmpty ? postWithDetails.imageUrls.first : null;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      elevation: 1,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PostDetailScreen(postWithDetails: postWithDetails),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 12, top: 12, right: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      _truncateText(post.title, 25),
                      style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16, color: Colors.blueAccent),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (car != null)
                    Text(
                      '${car.price?.toStringAsFixed(0)} \Triệu',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent, fontSize: 16),
                    ),
                ],
              ),
            ),
            if (imageUrl != null)
              Padding(
                padding: const EdgeInsets.only(left: 12, right: 12, top: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          imageUrl,
                          width: double.infinity,
                          height: 70,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 3,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _truncateText(post.description ?? 'N/A', 50), // Thêm ?? 'N/A'
                              style: TextStyle(color: Colors.grey[600], fontSize: 14),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            if (car != null)
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '• ${car.transmission ?? 'N/A'}',
                                          style: TextStyle(color: Colors.grey[600], fontSize: 14),
                                        ),
                                        Text(
                                          '• Máy ${car.fuelType ?? 'N/A'}',
                                          style: TextStyle(color: Colors.grey[600], fontSize: 14),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '• ${car.condition ?? 'N/A'}',
                                          style: TextStyle(color: Colors.grey[600], fontSize: 14),
                                        ),
                                        Text(
                                          '• ${car.mileage != null ? '${car.mileage} km' : 'N/A'}',
                                          style: TextStyle(color: Colors.grey[600], fontSize: 14),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              )
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            const Padding(
              padding: EdgeInsets.only(top: 12),
              child: Divider(height: 1, color: Colors.grey),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column( // Changed Row to Column
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.person_outline, size: 16, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(postWithDetails.sellerName ?? 'N/A', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                      if (postWithDetails.sellerPhone != null && postWithDetails.sellerPhone!.isNotEmpty)
                        Row(
                          children: [
                            const Icon(Icons.phone_outlined, size: 16, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(postWithDetails.sellerPhone!, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                          ],
                        ),
                    ],
                  ),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(postWithDetails.sellerAddress ?? 'N/A', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                  // Icon dấu trang đã lưu và chức năng xóa
                  IconButton(
                    icon: const Icon(
                        Icons.bookmark,
                        color: Colors.amber,
                    ), // Icon dấu trang đã lưu
                    onPressed: () async {
                      final favoriteProvider = Provider.of<FavoriteProvider>(context, listen: false);
                      final currentUser = FirebaseAuth.instance.currentUser;
                      if (currentUser != null) {
                        await favoriteProvider.removeFavorite(currentUser.uid, post.id);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Bạn cần đăng nhập.')),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: const Text('Bài đăng đã lưu'),
        centerTitle: true,
        titleTextStyle: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
      ),
      body: Consumer<FavoriteProvider>(
        builder: (context, favoriteProvider, child) {
          if (favoriteProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final favoritePostsWithDetails = favoriteProvider.favoritePostsWithDetails;

          if (favoritePostsWithDetails.isEmpty) {
            return const Center(
              child: Text('Chưa có bài đăng nào được lưu.'),
            );
          }

          return ListView.builder(
            itemCount: favoritePostsWithDetails.length,
            itemBuilder: (context, index) {
              return _buildFavoritePostItem(context, favoritePostsWithDetails[index]);
            },
          );
        },
      ),
    );
  }
}