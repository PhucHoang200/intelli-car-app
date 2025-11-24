import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:online_car_marketplace_app/models/favorite_model.dart';
import 'package:online_car_marketplace_app/providers/favorite_provider.dart';
import 'package:online_car_marketplace_app/providers/post_provider.dart';
import 'package:online_car_marketplace_app/models/post_with_car_and_images.dart';
import 'package:online_car_marketplace_app/ui/screen/user/post_detail_screen.dart';
import 'package:online_car_marketplace_app/providers/brand_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:online_car_marketplace_app/ui/widgets/user/buy_bottom_navigation_bar.dart';
import 'package:go_router/go_router.dart';

import 'location_filter_screen.dart';

class BuyScreen extends StatefulWidget {
  final String uid;
  const BuyScreen({required this.uid, super.key});

  @override
  State<BuyScreen> createState() => _BuyScreenState();
}

class _BuyScreenState extends State<BuyScreen> {
  bool _isSearching = false;
  late String userId;
  String? _selectedSortOption;
  String? _currentLocation = 'Toàn quốc'; // Giá trị mặc định
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    userId = widget.uid;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<PostProvider>(context, listen: false).fetchPosts();
      Provider.of<BrandProvider>(context, listen: false).fetchBrands();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Hàm này sẽ được gọi khi người dùng nhấn Enter trên bàn phím
  void _onSearchSubmitted(String query) async { // Thêm async
    setState(() {
      _isSearching = true; // Bắt đầu hiển thị loading
    });
    // Đảm bảo PostProvider có hàm searchPosts và hàm đó có thể được await
    await Provider.of<PostProvider>(context, listen: false).searchPosts(query);
    setState(() {
      _isSearching = false; // Kết thúc loading
    });
  }


  Future<void> _showFilterModal(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
            child: const AdvancedFilterScreen(), // Widget cho bộ lọc nâng cao
          ),
        );
      },
    );
  }

  // Phương thức mới để hiển thị màn hình chọn địa điểm
  Future<void> _showLocationFilter(BuildContext context) async {
    final selectedProvince = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true, // Cho phép kéo modal lên hết màn hình
      builder: (BuildContext context) {
        return const LocationFilterScreen();
      },
    );

    if (selectedProvince != null) {
      setState(() {
        _currentLocation = selectedProvince; // Cập nhật địa điểm hiện tại
      });
      // Logic lọc đã được gọi trong LocationFilterScreen, không cần gọi lại ở đây
    }
  }

  @override
  Widget build(BuildContext context) {
    final posts = Provider.of<PostProvider>(context).posts;
    List<PostWithCarAndImages> sortedPosts = List.from(posts);

    if (_selectedSortOption == 'Tin mới nhất') {
      sortedPosts.sort((a, b) => b.post.creationDate.compareTo(a.post.creationDate));
    } else if (_selectedSortOption == 'Giá tăng dần') {
      sortedPosts.sort((a, b) => (a.car?.price ?? 0).compareTo(b.car?.price ?? 0));
    } else if (_selectedSortOption == 'Giá giảm dần') {
      sortedPosts.sort((a, b) => (b.car?.price ?? 0).compareTo(a.car?.price ?? 0));
    } else if (_selectedSortOption == 'Năm sản xuất cũ nhất') {
      sortedPosts.sort((a, b) => (a.car?.year ?? 0).compareTo(b.car?.year ?? 0));
    } else if (_selectedSortOption == 'Năm sản xuất mới nhất') {
      sortedPosts.sort((a, b) => (b.car?.year ?? 0).compareTo(a.car?.year ?? 0));
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        // Không cần controller nữa nếu AppBar được pinned
        // controller: _scrollController,
        slivers: <Widget>[
          SliverAppBar(
            pinned: true, // Đặt thành true để AppBar được giữ cố định
            floating: false, // Không cần floating khi pinned
            backgroundColor: Colors.blue, // Nền màu xanh dương
            elevation: 1,
            title: const Text(
              'OTO', // Đổi chữ thành "OTO"
              style: TextStyle(
                fontSize: 40,
                color: Colors.white, // Chữ màu trắng
                fontWeight: FontWeight.bold, // Chữ in đậm
              ),
            ),
            centerTitle: true, // Căn giữa tiêu đề
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(110), // Increased height for the button
              child: Container( // Sử dụng Container để làm nền trắng cho phần bottom
                color: Colors.white, // Nền trắng cho thanh tìm kiếm và nút
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          InkWell(
                            onTap: () => _showFilterModal(context),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.green,
                                borderRadius: BorderRadius.circular(25),
                                border: Border.all(color: Colors.grey[300]!),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.tune, color: Colors.white),
                                  SizedBox(width: 4),
                                  Text('Tìm nâng cao', style: TextStyle(color: Colors.white, fontSize: 16)),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              onSubmitted: _onSearchSubmitted,
                              // Thêm onChanged để theo dõi việc xóa nội dung
                              onChanged: (value) {
                                if (value.isEmpty) {
                                  // Nếu người dùng xóa hết nội dung tìm kiếm, reset bài đăng
                                  Provider.of<PostProvider>(context, listen: false).resetPosts();
                                }
                              },
                              decoration: InputDecoration(
                                hintText: "Tìm theo hãng, dòng",
                                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                                // // Thêm icon X nếu có nội dung trong thanh tìm kiếm
                                // suffixIcon: _searchController.text.isNotEmpty
                                //     ? IconButton(
                                //   icon: const Icon(Icons.clear, color: Colors.grey),
                                //   onPressed: () {
                                //     _searchController.clear(); // Xóa nội dung
                                //     // Reset bài đăng khi nhấn nút X
                                //     Provider.of<PostProvider>(context, listen: false).resetPosts();
                                //   },
                                // )
                                //     : null,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(25)),
                                contentPadding: const EdgeInsets.symmetric(vertical: 5, horizontal: 3),
                                filled: true,
                                fillColor: Colors.grey[100],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton(
                          onPressed: () => context.go('/sell'),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                          child: const Text('Chuyển sang bán', style: TextStyle(color: Colors.white, fontSize: 16)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Thêm thanh ngang phân cách 1
          SliverToBoxAdapter(
            child: Container(
              height: 8, // Chiều cao của thanh phân cách
              color: Colors.grey[100], // Màu nền của thanh phân cách
            ),
          ),
          SliverSafeArea(
            top: false,
            sliver: SliverPadding(
              padding: const EdgeInsets.all(12),
              sliver: SliverList(
                delegate: SliverChildListDelegate(
                  [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // InkWell để mở màn hình chọn địa điểm
                        InkWell(
                          onTap: () => _showLocationFilter(context),
                          child: Row(
                            children: [
                              const Icon(Icons.location_on_outlined, color: Colors.black),
                              const SizedBox(width: 4),
                              Text(_currentLocation!, style: const TextStyle(fontSize: 16, color: Colors.black)),
                              const Icon(Icons.arrow_drop_down, color: Colors.black), // Thêm icon mũi tên
                            ],
                          ),
                        ),
                        _buildSortDropdown(),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Thêm thanh ngang phân cách 2
                    Container(
                      height: 1, // Chiều cao của thanh phân cách
                      color: Colors.grey[300], // Màu nền của thanh phân cách
                      margin: const EdgeInsets.symmetric(vertical: 8), // Khoảng cách trên dưới
                    ),
                    _buildBrandSelector(),
                    // Thêm thanh ngang phân cách 3
                    Container(
                      height: 8, // Chiều cao của thanh phân cách
                      color: Colors.grey[100], // Màu nền của thanh phân cách
                      margin: const EdgeInsets.symmetric(vertical: 8), // Khoảng cách trên dưới
                    ),
                    if (_isSearching) // Nếu đang tìm kiếm...
                      const Center(child: CircularProgressIndicator())
                    else if (posts.isEmpty) // ...và không tìm kiếm, nhưng danh sách rỗng
                      const Center(child: Text('Không tìm thấy bài đăng nào.'))
                    else // ...và không tìm kiếm, và có bài đăng
                    _buildPostList(sortedPosts),
                    const SizedBox(height: 80), // Khoảng trống cho BottomNavigationBar
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const BuyBottomNavigationBar(currentIndex: 0),
    );
  }

  Widget _buildSortDropdown() {
    return DropdownButton<String>(
      value: _selectedSortOption,
      hint: const Text('Sắp xếp tin rao', style: TextStyle(fontSize: 16, color: Colors.black)),
      icon: const Icon(Icons.arrow_drop_down, color: Colors.black),
      elevation: 2,
      style: const TextStyle(color: Colors.black, fontSize: 16),
      underline: Container(height: 1, color: Colors.grey[300]),
      onChanged: (String? newValue) {
        setState(() {
          _selectedSortOption = newValue;
        });
      },
      items: <String>['Mặc định', 'Tin mới nhất', 'Giá tăng dần', 'Giá giảm dần', 'Năm sản xuất cũ nhất', 'Năm sản xuất mới nhất']
          .map<DropdownMenuItem<String>>((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(value),
        );
      }).toList(),
    );
  }

  Widget _buildBrandSelector() {
    return Consumer<BrandProvider>(
      builder: (context, brandProvider, child) {
        // if (brandProvider.isLoading) {
        //   return const Center(child: CircularProgressIndicator());
        // }

        final brands = brandProvider.brands;

        if (brands.isEmpty) {
          return const SizedBox.shrink();
        }

        return SizedBox(
          height: 90, // Increased height to match the design
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: brands.length,
            separatorBuilder: (context, index) => const SizedBox(width: 12), // Spacing between logos
            itemBuilder: (context, index) {
              final brand = brands[index];
              final brandName = brand.name.toUpperCase();
              final brandAvatarPath = 'assets/brands/${brand.name.toLowerCase()}.png';

              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 60, // Increased logo size
                    height: 60,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white, // Added white background for logos
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0), // Added padding to the image
                      child: Image.asset(
                        brandAvatarPath,
                        fit: BoxFit.contain, // Ensure full logo visibility
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    brandName,
                    style: const TextStyle(fontSize: 14), // Increased font size
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  String _truncateText(String text, int maxLength) {
    if (text.length <= maxLength) {
      return text;
    } else {
      return '${text.substring(0, maxLength)}...';
    }
  }

  Widget _buildPostList(List<PostWithCarAndImages> posts) {
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: posts.length,
      itemBuilder: (context, index) {
        final postWithDetails = posts[index];
        final post = postWithDetails.post;
        final car = postWithDetails.car;
        final imageUrl = postWithDetails.imageUrls.isNotEmpty ? postWithDetails.imageUrls.first : null;
        Provider.of<FavoriteProvider>(context, listen: false);

        return InkWell( // Sử dụng InkWell trực tiếp để có hiệu ứng onTap
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PostDetailScreen(postWithDetails: postWithDetails),
              ),
            );
          },
          child: Container( // Sử dụng Container làm background cho mỗi bài post
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.white, // Đặt màu nền trắng cho mỗi bài post
              borderRadius: BorderRadius.circular(8),
              boxShadow: [ // Thêm hiệu ứng đổ bóng nhẹ nếu muốn
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 1,
                  blurRadius: 3,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
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
                          style: const TextStyle(fontSize: 16, color: Colors.blueAccent), // Loại bỏ fontWeight: FontWeight.w500
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (car != null)
                        Text(
                          '${car.price?.toStringAsFixed(0)} Triệu',
                          style: const TextStyle(color: Colors.redAccent, fontSize: 16), // Loại bỏ fontWeight: FontWeight.bold
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
                                  _truncateText(post.description ?? '', 50),
                                  style: const TextStyle(color: Colors.grey, fontSize: 14), // Loại bỏ Colors.grey[600]
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
                                              style: const TextStyle(color: Colors.grey, fontSize: 14), // Loại bỏ Colors.grey[600]
                                            ),
                                            Text(
                                              '• Máy ${car.fuelType ?? 'N/A'}',
                                              style: const TextStyle(color: Colors.grey, fontSize: 14), // Loại bỏ Colors.grey[600]
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
                                              style: const TextStyle(color: Colors.grey, fontSize: 14), // Loại bỏ Colors.grey[600]
                                            ),
                                            Text(
                                              '• ${car.mileage != null ? '${car.mileage} km' : 'N/A'}',
                                              style: const TextStyle(color: Colors.grey, fontSize: 14), // Loại bỏ Colors.grey[600]
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
                      Column(
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
                      Consumer<FavoriteProvider>(
                        builder: (context, favoriteProvider, child) {
                          final currentUser = FirebaseAuth.instance.currentUser;
                          // Sử dụng FutureBuilder để kiểm tra trạng thái yêu thích hiện tại của bài đăng
                          return FutureBuilder<bool>(
                            future: currentUser != null
                                ? favoriteProvider.isPostFavorite(currentUser.uid, post.id)
                                : Future.value(false),
                            builder: (context, snapshot) {
                              final isCurrentlyFavorite = snapshot.data ?? false;
                              return IconButton(
                                icon: Icon(
                                  isCurrentlyFavorite ? Icons.bookmark : Icons.bookmark_border,
                                  color: isCurrentlyFavorite ? Colors.amber : null, // Màu vàng khi đã đánh dấu
                                ),
                                onPressed: () async {
                                  if (currentUser != null) {
                                    final userId = currentUser.uid;
                                    if (isCurrentlyFavorite) {
                                      await favoriteProvider.removeFavorite(userId, post.id);
                                    } else {
                                      final favorite = Favorite(
                                        id: 0, // Id tự tăng, có thể không cần thiết nếu backend tự xử lý
                                        userId: userId,
                                        postId: post.id,
                                      );
                                      await favoriteProvider.addFavoriteAutoIncrement(favorite);
                                    }
                                    // Gọi hàm fetchFavoritePosts để làm mới dữ liệu sau khi thêm/xóa thành công
                                    await favoriteProvider.fetchFavoritePosts(userId);

                                    // favoriteProvider.toggleFavoriteLocal(post.id); // Bạn có thể bỏ dòng này nếu fetchFavoritePosts đã làm mới toàn bộ list
                                    // hoặc giữ lại nếu bạn muốn cập nhật UI ngay lập tức trước khi fetch hoàn tất
                                    // nhưng việc fetchFavoritePosts sau đó sẽ đảm bảo tính nhất quán.
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Bạn cần đăng nhập để thêm vào yêu thích.')),
                                    );
                                  }
                                },
                              );
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

}

class AdvancedFilterScreen extends StatelessWidget {
  const AdvancedFilterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Tìm kiếm nâng cao', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text('Hãng - Dòng - Phiên bản:', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ListTile(
            title: const Text('Hãng xe'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              // Xử lý chọn hãng xe
            },
          ),
          ListTile(
            title: const Text('Dòng xe'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              // Xử lý chọn dòng xe
            },
          ),
          ListTile(
            title: const Text('Năm sản xuất'),
            trailing: const Text('Tất cả', style: TextStyle(color: Colors.grey)),
            onTap: () {
              // Xử lý chọn năm sản xuất
            },
          ),
          ListTile(
            title: const Text('Phiên bản'),
            trailing: const Text('Phiên bản', style: TextStyle(color: Colors.grey)),
            onTap: () {
              // Xử lý chọn phiên bản
            },
          ),
          const SizedBox(height: 16),
          const Text('Khoảng giá:', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          // Thêm widget chọn khoảng giá (ví dụ: Slider hoặc các button khoảng giá)
          const Text('Tình trạng:', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(
            children: [
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.blue, // Đổi màu chữ thành blue
                ),
                child: const Text('Xe cũ'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.blue, // Đổi màu chữ thành blue
                ),
                child: const Text('Xe mới'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text('Xuất xứ:', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(
            children: [
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.blue, // Đổi màu chữ thành blue
                ),
                child: const Text('Tất cả'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.blue, // Đổi màu chữ thành blue
                ),
                child: const Text('Trong nước'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.blue, // Đổi màu chữ thành blue
                ),
                child: const Text('Nhập khẩu'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              TextButton(
                onPressed: () {
                  // Xử lý xóa bộ lọc
                },
                child: const Text('Xóa bộ lọc', style: TextStyle(color: Colors.grey)),
              ),
              ElevatedButton(
                onPressed: () {
                  // Xử lý xem kết quả lọc
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                child: const Text('Xem kết quả', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}