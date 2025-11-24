// lib/screens/notifications_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart'; // Để dùng context.pop()

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // Màu nền AppBar theo ảnh (có thể là màu primary của theme hoặc tùy chỉnh)
        backgroundColor: Colors.blue,
        elevation: 0.5, // Có một chút đổ bóng nhẹ
        title: const Text(
          'Thông báo',
          style: TextStyle(
            color: Colors.white, // Tiêu đề màu đen
            fontWeight: FontWeight.bold,
            fontSize: 20
          ),
        ),
        centerTitle: true,
      ),
      body: Center( // Thay thế ListView bằng Center
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notifications_off_outlined, // Icon thông báo tắt
              size: 80,
              color: Colors.grey[400], // Màu xám nhạt hơn
            ),
            const SizedBox(height: 16),
            Text(
              'Bạn chưa có thông báo nào.',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600], // Màu xám đậm hơn một chút
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Kiểm tra lại sau nhé!',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600], // Màu xám đậm hơn một chút
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget để tạo phần tiêu đề danh sách (HÔM NAY, HÔM QUA, TRƯỚC ĐÓ)
  Widget _buildNotificationSection(BuildContext context, String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Text(
            title,
            style: TextStyle(
              color: Colors.grey[600],
              fontWeight: FontWeight.bold,
              fontSize: 14.0,
            ),
          ),
        ),
        ...children, // Dùng spread operator để thêm các NotificationItem vào đây
      ],
    );
  }

  // Widget để tạo mỗi mục thông báo
  Widget _buildNotificationItem(
      BuildContext context, {
        required IconData icon,
        required Color iconColor,
        required String title,
        required String subtitle,
        required String time,
        required bool isRead,
      }) {
    return Container(
      color: isRead ? Colors.white : Colors.blue.withOpacity(0.05), // Nền xanh nhạt nếu chưa đọc
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon thông báo
          Container(
            padding: const EdgeInsets.all(10.0),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1), // Nền icon màu nhạt hơn
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 24.0,
            ),
          ),
          const SizedBox(width: 12.0),
          // Nội dung thông báo
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: isRead ? FontWeight.normal : FontWeight.bold, // In đậm nếu chưa đọc
                    fontSize: 16.0,
                    color: isRead ? Colors.grey[800] : Colors.black,
                  ),
                ),
                const SizedBox(height: 4.0),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 14.0,
                    color: isRead ? Colors.grey[600] : Colors.black87,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4.0),
                Text(
                  time,
                  style: const TextStyle(
                    fontSize: 12.0,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          // Chấm tròn chưa đọc (nếu có)
          if (!isRead)
            Padding(
              padding: const EdgeInsets.only(left: 8.0, top: 5.0),
              child: Container(
                width: 8.0,
                height: 8.0,
                decoration: const BoxDecoration(
                  color: Colors.blue, // Màu xanh của chấm tròn
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    );
  }
}