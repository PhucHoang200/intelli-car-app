import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'overview_screen.dart';
import 'user_management_screen.dart';
import 'post_management_screen.dart';
import 'category_management_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int selectedIndex = 0;

  final List<Widget> screens = const [
    OverviewScreen(),
    UserManagementScreen(),
    PostManagementScreen(),
    CategoryManagementScreen(),
  ];

  final List<String> titles = [
    "Thống kê",
    "Người dùng",
    "Bài đăng xe",
    "Danh mục xe",
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final isMobile = constraints.maxWidth < 600;
      return Scaffold(
        appBar: AppBar(
          title: Text(titles[selectedIndex]),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () {
                // TODO: Xử lý đăng xuất bằng AuthService
                context.go('/');  // Chuyển về trang đăng nhập khi logout
              },
            )
          ],
        ),
        drawer: isMobile ? _buildDrawer() : null,
        body: Row(
          children: [
            if (!isMobile) _buildDrawer(),
            Expanded(child: screens[selectedIndex]),
          ],
        ),
      );
    });
  }

  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(color: Colors.blueAccent),
            child: Text("Admin Panel", style: TextStyle(color: Colors.white)),
          ),
          _buildDrawerItem("Thống kê", 0, '/overview'),
          _buildDrawerItem("Người dùng", 1, '/users'),
          _buildDrawerItem("Bài đăng xe", 2, '/posts'),
          _buildDrawerItem("Danh mục xe", 3, '/categories'),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(String title, int index, String route) {
    return ListTile(
      title: Text(title),
      selected: selectedIndex == index,
      onTap: () {
        setState(() => selectedIndex = index);
        context.go(route); // Điều hướng bằng GoRouter đến route tương ứng
        Navigator.pop(context); // Đóng drawer khi mobile
      },
    );
  }
}
