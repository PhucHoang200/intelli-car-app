import 'package:go_router/go_router.dart';
import 'package:online_car_marketplace_app/ui/screen/admin/login_admin_screen.dart';
import 'package:online_car_marketplace_app/ui/screen/admin/dashboard_screen.dart';
import 'package:online_car_marketplace_app/ui/screen/admin/overview_screen.dart';
import 'package:online_car_marketplace_app/ui/screen/admin/user_management_screen.dart';
import 'package:online_car_marketplace_app/ui/screen/admin/post_management_screen.dart';
import 'package:online_car_marketplace_app/ui/screen/admin/category_management_screen.dart';

final adminRouter = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const AdminLoginScreen(),
    ),
    GoRoute(
      path: '/dashboard',
      builder: (context, state) => const AdminDashboardScreen(),
    ),
    GoRoute(
      path: '/overview',
      builder: (context, state) => const OverviewScreen(),
    ),
    GoRoute(
      path: '/users',
      builder: (context, state) => const UserManagementScreen(),
    ),
    GoRoute(
      path: '/posts',
      builder: (context, state) => const PostManagementScreen(),
    ),
    GoRoute(
      path: '/categories',
      builder: (context, state) => const CategoryManagementScreen(),
    ),
  ],
);
