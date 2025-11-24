import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:online_car_marketplace_app/providers/brand_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../widgets/user/sell_bottom_navigation_bar.dart';

class SellScreen extends StatefulWidget {
  const SellScreen({super.key});

  @override
  State<SellScreen> createState() => _SellScreenState();
}

class _SellScreenState extends State<SellScreen> {
  // UserId không cần thiết ở đây nếu không được sử dụng trực tiếp trong State
  // late String userId;

  @override
  void initState() {
    super.initState();
    // userId = widget.uid; // Không có uid trong constructor của SellScreen nữa
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<BrandProvider>(context, listen: false).fetchBrands();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Đặt màu nền trắng cho toàn bộ Scaffold
      body: CustomScrollView(
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
              preferredSize: const Size.fromHeight(60), // Chiều cao cho phần button
              child: Container(
                color: Colors.white, // Nền trắng cho phần này
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    onPressed: () {
                      final String? currentUserId = FirebaseAuth.instance.currentUser?.uid;
                      if (currentUserId != null) {
                        context.go('/buy', extra: currentUserId);
                      } else {
                        context.go('/buy', extra: '');
                      }
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                    child: const Text("Chuyển sang mua", style: TextStyle(color: Colors.white, fontSize: 16)),
                  ),
                ),
              ),
            ),
          ),
          // Thanh ngang phân cách 1 (giữa AppBar và Banner)
          SliverToBoxAdapter(
            child: Container(
              height: 8, // Chiều cao của thanh phân cách
              color: Colors.grey[100], // Màu nền của thanh phân cách
            ),
          ),
          SliverList(
            delegate: SliverChildListDelegate(
              [
                Padding(
                  padding: const EdgeInsets.all(16.0), // Padding cho banner
                  child: _buildBanner(),
                ),
                // Thanh ngang phân cách 2 (giữa Banner và Brand Selector)
                Container(
                  height: 8,
                  color: Colors.grey[100],
                  margin: const EdgeInsets.symmetric(vertical: 16.0), // Khoảng cách trên dưới
                ),
                _buildBrandSelector(),
                const SizedBox(height: 80), // Khoảng trống cho BottomNavigationBar
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: const SellBottomNavigationBar(currentIndex: 0),
    );
  }

  Widget _buildBanner() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Stack(
        alignment: Alignment.bottomLeft,
        children: [
          Image.asset('assets/images/car mask.png', height: 180, width: double.infinity, fit: BoxFit.cover),
          const Padding(
            padding: EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Sell your car at", style: TextStyle(color: Colors.white, fontSize: 18)),
                Text("Best price", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBrandSelector() {
    return Consumer<BrandProvider>(
      builder: (context, brandProvider, child) {
        if (brandProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final brands = brandProvider.brands;

        if (brands.isEmpty) {
          return const Center(child: Text('No brands available'));
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(left: 16.0, bottom: 8.0),
              child: Text(
                'Chọn hãng xe để đăng tin',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 12.0,
                mainAxisSpacing: 12.0,
                childAspectRatio: 1.0,
              ),
              itemCount: brands.length,
              itemBuilder: (context, index) {
                final brand = brands[index];
                final brandName = brand.name.toUpperCase();
                final brandAvatarPath = 'assets/brands/${brand.name.toLowerCase()}.png';

                return GestureDetector(
                  onTap: () {
                    debugPrint('Brand clicked: $brandName');
                    debugPrint('Brand ID: ${brand.id}, Type: ${brand.id.runtimeType}');
                    debugPrint('Brand Name: $brandName');

                    context.push(
                      '/sell/models',
                      extra: {
                        'brandId': brand.id.toString(),
                        'brandName': brand.name,
                      },
                    );
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8.0),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.2),
                          spreadRadius: 0.5,
                          blurRadius: 2,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 50,
                          height: 50,
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Image.asset(
                              brandAvatarPath,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                return const Icon(Icons.error_outline, size: 40, color: Colors.grey);
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          brandName,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 14),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }
}