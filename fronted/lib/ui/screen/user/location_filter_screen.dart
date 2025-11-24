import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:online_car_marketplace_app/providers/post_provider.dart';

class LocationFilterScreen extends StatelessWidget {
  final List<String> provinces = const [
    'Toàn quốc', 'Hà Nội', 'Hồ Chí Minh', 'Đà Nẵng', 'Hải Phòng', 'Cần Thơ',
    'An Giang', 'Bà Rịa - Vũng Tàu', 'Bắc Giang', 'Bắc Kạn', 'Bạc Liêu',
    'Bắc Ninh', 'Bến Tre', 'Bình Định', 'Bình Dương', 'Bình Phước',
    'Bình Thuận', 'Cà Mau', 'Cao Bằng', 'Đắk Lắk', 'Đắk Nông', 'Điện Biên',
    'Đồng Nai', 'Đồng Tháp', 'Gia Lai', 'Hà Giang', 'Hà Nam', 'Hà Tĩnh',
    'Hải Dương', 'Hậu Giang', 'Hòa Bình', 'Hưng Yên', 'Khánh Hòa', 'Kiên Giang',
    'Kon Tum', 'Lai Châu', 'Lâm Đồng', 'Lạng Sơn', 'Lào Cai', 'Long An',
    'Nam Định', 'Nghệ An', 'Ninh Bình', 'Ninh Thuận', 'Phú Thọ', 'Phú Yên',
    'Quảng Bình', 'Quảng Nam', 'Quảng Ngãi', 'Quảng Ninh', 'Quảng Trị',
    'Sóc Trăng', 'Sơn La', 'Tây Ninh', 'Thái Bình', 'Thái Nguyên', 'Thanh Hóa',
    'Thừa Thiên Huế', 'Tiền Giang', 'TP.HCM', 'Trà Vinh', 'Tuyên Quang',
    'Vĩnh Long', 'Vĩnh Phúc', 'Yên Bái'
  ];

  const LocationFilterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Lấy provider mà không lắng nghe sự thay đổi để tránh rebuild không cần thiết
    final postProvider = Provider.of<PostProvider>(context, listen: false);

    return Container(
      height: MediaQuery.of(context).size.height * 0.75, // Chiều cao của modal
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.0)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Chọn Tỉnh/Thành phố',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView.builder(
              itemCount: provinces.length,
              itemBuilder: (context, index) {
                final province = provinces[index];
                return ListTile(
                  title: Text(province),
                  onTap: () {
                    // Áp dụng bộ lọc địa điểm khi người dùng chọn
                    // postProvider.filterPostsByLocation(province);
                    Navigator.pop(context, province); // Trả về tỉnh thành đã chọn
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}