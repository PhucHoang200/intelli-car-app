import 'package:flutter/material.dart';
import 'package:online_car_marketplace_app/models/post_with_car_and_images.dart';
import 'package:url_launcher/url_launcher.dart' as launcher;

class PostDetailScreen extends StatefulWidget {
  final PostWithCarAndImages postWithDetails;

  const PostDetailScreen({super.key, required this.postWithDetails});

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.postWithDetails.post;
    final car = widget.postWithDetails.car;
    final imageUrls = widget.postWithDetails.imageUrls;
    final sellerName = widget.postWithDetails.sellerName ?? 'N/A';
    final sellerPhone = widget.postWithDetails.sellerPhone ?? 'N/A';
    final carLocation = widget.postWithDetails.carLocation ?? 'N/A';
    final sellerAddress = widget.postWithDetails.sellerAddress ?? 'N/A';

    // Lấy tên kiểu dáng trực tiếp từ PostWithCarAndImages
    final carModelDisplayName = widget.postWithDetails.carModelName ?? 'N/A';


    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text('Chi tiết xe ', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              // Handle share action
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image Carousel Section
                  Stack(
                    children: [
                      SizedBox(
                        height: 250,
                        child: PageView.builder(
                          controller: _pageController,
                          itemCount: imageUrls.length,
                          onPageChanged: (index) {
                            setState(() {
                              _currentPage = index;
                            });
                          },
                          itemBuilder: (context, index) {
                            return Image.network(
                              imageUrls[index],
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return const Center(child: Icon(Icons.broken_image, size: 50));
                              },
                            );
                          },
                        ),
                      ),
                      if (imageUrls.isNotEmpty)
                        Positioned(
                          bottom: 10,
                          right: 10,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.6),
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: Text(
                              '${_currentPage + 1}/${imageUrls.length}',
                              style: const TextStyle(color: Colors.white, fontSize: 12),
                            ),
                          ),
                        ),
                      Positioned.fill(
                        child: Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 30),
                              onPressed: () {
                                _pageController.previousPage(
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeIn,
                                );
                              },
                            ),
                            const Spacer(),
                            IconButton(
                              icon: const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 30),
                              onPressed: () {
                                _pageController.nextPage(
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeIn,
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          post.title,
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        if (car != null)
                          Text(
                            '${car.price.toStringAsFixed(0)} triệu',
                            style: const TextStyle(fontSize: 20, color: Colors.red, fontWeight: FontWeight.bold),
                          ),
                        const SizedBox(height: 16),
                        // Car specifications grid
                        GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: 2,
                          childAspectRatio: 4,
                          mainAxisSpacing: 10,
                          crossAxisSpacing: 10,
                          children: [
                            _buildInfoRow(Icons.calendar_today, 'Năm SX', car?.year?.toString() ?? 'N/A'),
                            _buildInfoRow(Icons.location_on_outlined, 'Nơi bán', sellerAddress),
                            _buildInfoRow(Icons.speed, 'Số ODO', '${car?.mileage?.toString() ?? 'N/A'} km'),
                            _buildInfoRow(Icons.local_gas_station, 'Nhiên liệu', car?.fuelType ?? 'N/A'),
                            _buildInfoRow(Icons.settings, 'Hộp số', car?.transmission ?? 'N/A'),
                            _buildInfoRow(Icons.category, 'Kiểu dáng', carModelDisplayName), // Sử dụng tên kiểu dáng
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Tabs for Mô tả and Chi phí trả góp
                        TabBar(
                          controller: _tabController,
                          labelColor: Colors.black,
                          unselectedLabelColor: Colors.grey,
                          indicatorColor: Colors.blue,
                          tabs: const [
                            Tab(text: 'Mô tả'),
                            Tab(text: 'Chi phí trả góp'),
                          ],
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          height: 200, // Adjust height as needed
                          child: TabBarView(
                            controller: _tabController,
                            children: [
                              // Mô tả Tab Content
                              SingleChildScrollView(
                                child: Text(
                                  post.description,
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ),
                              // Chi phí trả góp Tab Content (Placeholder)
                              const Center(
                                child: Text(
                                  'Chưa có thông tin chi phó trả góp.',
                                  style: TextStyle(fontSize: 16),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Seller Information Section
                        Container(
                          padding: const EdgeInsets.all(16.0),
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Thông tin người bán',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              _buildSellerInfoRow('Tên:', sellerName),
                              _buildSellerInfoRow('SĐT:', sellerPhone),
                              _buildSellerInfoRow('Địa chỉ:', sellerAddress),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        Center(
                          child: ElevatedButton(
                            onPressed: () {
                              // Handle "Chi tiết liên hệ" button - bạn có thể làm nút này gọi điện/zalo
                              // hoặc hiển thị modal chứa thông tin liên hệ chi tiết hơn.
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text(
                              'Chi tiết liên hệ',
                              style: TextStyle(fontSize: 18, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Fixed Bottom Navigation Bar for Call and Zalo
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.3),
                  spreadRadius: 2,
                  blurRadius: 5,
                  offset: const Offset(0, 3), // changes position of shadow
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      if (sellerPhone != 'N/A' && sellerPhone.isNotEmpty) {
                        _launchPhoneCall(sellerPhone);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Không có số điện thoại để gọi.')),
                        );
                      }
                    },
                    icon: const Icon(Icons.phone, color: Colors.white),
                    label: const Text('Gọi điện', style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      if (sellerPhone != 'N/A' && sellerPhone.isNotEmpty) {
                        _launchZalo(sellerPhone);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Không có số điện thoại để mở Zalo.')),
                        );
                      }
                    },
                    icon: Image.asset('assets/images/zalo_icon.png', height: 24, width: 24),
                    label: const Text('Zalo', style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.grey, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              Text(
                value,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSellerInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  void _launchPhoneCall(String phoneNumber) async {
    final Uri url = Uri.parse('tel:$phoneNumber');
    // `canLaunchUrl` kiểm tra xem có ứng dụng nào có thể xử lý URI này không.
    // Trên máy ảo, ứng dụng dialer có tồn tại, nên nó sẽ trả về true.
    if (await launcher.canLaunchUrl(url)) {
      await launcher.launchUrl(url);
    } else {
      // Thông báo này sẽ chỉ hiển thị nếu không có ứng dụng nào trên thiết bị (kể cả máy ảo)
      // có thể xử lý URI 'tel:'. Điều này ít khi xảy ra với máy ảo có dialer.
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không thể mở ứng dụng gọi điện.')),
      );
    }
  }

  void _launchZalo(String phoneNumber) async {
    final Uri url = Uri.parse('zalo://chat?phone=$phoneNumber');
    // Tương tự cho Zalo. Nếu ứng dụng Zalo không được cài đặt (hoặc không có deep link handler),
    // thì `canLaunchUrl` sẽ trả về false.
    if (await launcher.canLaunchUrl(url)) {
      await launcher.launchUrl(url);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không thể mở Zalo. Đảm bảo ứng dụng Zalo đã được cài đặt.')),
      );
    }
  }
}