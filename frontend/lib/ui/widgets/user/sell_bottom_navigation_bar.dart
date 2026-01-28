import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SellBottomNavigationBar extends StatelessWidget {
  final int currentIndex;

  const SellBottomNavigationBar({super.key, required this.currentIndex});

  void _onItemTapped(BuildContext context, int index) {
    switch (index) {
      case 0:
      // Điều hướng đến màn hình Sell (trang chính)
        GoRouter.of(context).go('/sell'); // Đảm bảo bạn có route '/sell'
        break;
      case 1:
      // Điều hướng đến màn hình Quản lý tin rao
        GoRouter.of(context).go('/my_posts'); // <-- Cập nhật route tại đây
        break;
      case 2:
      // Điều hướng đến màn hình Thông báo
        GoRouter.of(context).go('/notifications/2'); // Đảm bảo bạn có route '/notifications'
        break;
      case 3:
        final firebaseUser = FirebaseAuth.instance.currentUser;
        if (firebaseUser != null) {
          GoRouter.of(context).go('/profile/2', extra: firebaseUser.uid);
        }
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: currentIndex,
      selectedItemColor: Colors.blue, // Chọn màu sắc khác nếu muốn
      unselectedItemColor: Colors.grey,
      onTap: (index) => _onItemTapped(context, index),
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.add_circle_outline), label: 'Trang bán'),
        BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: 'QL tin rao'),
        BottomNavigationBarItem(icon: Icon(Icons.notifications_none), label: 'Thông báo'),
        BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Tài khoản'),
      ],
    );
  }
}