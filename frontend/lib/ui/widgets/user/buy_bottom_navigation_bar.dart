import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BuyBottomNavigationBar extends StatelessWidget {
  final int currentIndex;

  const BuyBottomNavigationBar({super.key, required this.currentIndex});

  void _onItemTapped(BuildContext context, int index) {
    switch (index) {
      case 0:
        GoRouter.of(context).go('/buy', extra: FirebaseAuth.instance.currentUser?.uid ?? '');
        break;
      case 1:
        final firebaseUser = FirebaseAuth.instance.currentUser;
        if (firebaseUser != null) {
          GoRouter.of(context).go('/favorites');
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Bạn cần đăng nhập để xem bài đăng đã lưu.')),
          );
        }
        break;
      case 2:
      // Điều hướng đến màn hình Thông báo
        GoRouter.of(context).go('/notifications/1'); // Đảm bảo bạn có route '/notifications'
        break;
      case 3:
        final firebaseUser = FirebaseAuth.instance.currentUser;
        if (firebaseUser != null) {
          GoRouter.of(context).go('/profile/1', extra: firebaseUser.uid);
        }
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: currentIndex,
      selectedItemColor: Colors.orange,
      unselectedItemColor: Colors.grey,
      onTap: (index) => _onItemTapped(context, index),
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.directions_car), label: 'Trang mua'),
        BottomNavigationBarItem(icon: Icon(Icons.bookmark_border), label: 'Tin lưu'),
        BottomNavigationBarItem(icon: Icon(Icons.notifications_none), label: 'Thông báo'),
        BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Tài khoản'),
      ],
    );
  }
}