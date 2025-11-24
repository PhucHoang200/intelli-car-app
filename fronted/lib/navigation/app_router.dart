import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:online_car_marketplace_app/ui/screen/auth/register_screen.dart';
import 'package:online_car_marketplace_app/ui/screen/user/sell_screen.dart';
import 'package:online_car_marketplace_app/ui/screen/user/buy_screen.dart';
import 'package:online_car_marketplace_app/ui/screen/user/profile_screen.dart';
import 'package:online_car_marketplace_app/ui/screen/auth/login_user_screen.dart';
import 'package:online_car_marketplace_app/ui/screen/user/introduction.dart';
import 'package:online_car_marketplace_app/ui/screen/user/model_list_screen.dart';
import 'package:provider/provider.dart';

import 'package:online_car_marketplace_app/providers/brand_provider.dart';
import 'package:online_car_marketplace_app/providers/model_provider.dart';
import 'package:online_car_marketplace_app/ui/screen/auth/register_success_screen.dart';
import 'package:online_car_marketplace_app/ui/screen/user/condition_origin_screen.dart';
import 'package:online_car_marketplace_app/ui/screen/user/confirm_post_screen.dart';
import 'package:online_car_marketplace_app/ui/screen/user/favorite_screen.dart';
import 'package:online_car_marketplace_app/ui/screen/user/fuel_transmission_screen.dart';
import 'package:online_car_marketplace_app/ui/screen/user/image_upload_screen.dart';
import 'package:online_car_marketplace_app/ui/screen/user/price_title_description_screen.dart';
import 'package:online_car_marketplace_app/ui/screen/user/year_selection_screen.dart';

import 'package:online_car_marketplace_app/ui/widgets/user/buy_app_screen.dart';

import '../providers/favorite_provider.dart';
import '../ui/screen/user/my_post_screen.dart';
import '../ui/screen/user/notifications_screen.dart';
import '../ui/screen/user/post_detail_screen.dart';
import '../ui/widgets/user/sell_app_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

final GoRouter appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const LandingPage(),
    ),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterScreen(),
    ),
    GoRoute(
      path: '/register-success',
      builder: (BuildContext context, GoRouterState state) => const RegisterSuccessScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/profile/1',
      builder: (context, state) {
        final uId = state.extra as String;
        return BuyAppScreen(currentIndex: 3, child: ProfileScreen(uid: uId));
      },
    ),
    GoRoute(
      path: '/profile/2',
      builder: (context, state) {
        final uId = state.extra as String;
        return SellAppScreen(currentIndex: 3, child: ProfileScreen(uid: uId));
      },
    ),
    GoRoute(
      path: '/buy',
      builder: (context, state) {
        // Lấy tham số từ extra
        final uId = state.extra as String;  // Truyền qua extra
        return BuyScreen(uid: uId);  // Truyền userId vào BuyScreen
      },
    ),
    GoRoute(
      path: '/sell',
      builder: (context, state) {
        // Fetch brands before building SellScreen
        final brandProvider =
        Provider.of<BrandProvider>(context, listen: false);
        // Call fetchBrands() here, before returning SellScreen
        return FutureBuilder(
          future: brandProvider.fetchBrands(), // Await the future
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                  child: CircularProgressIndicator()); // Show loading
            } else if (snapshot.hasError) {
              return Center(
                  child: Text(
                      'Error: ${snapshot.error}')); // Show error
            } else {
              // Data is loaded, build SellScreen
              return const SellScreen();
            }
          },
        );
      },
      routes: [
        GoRoute(
          path: 'models',
          builder: (context, state) {
            final extra = state.extra as Map<String, dynamic>?;
            final brandId = extra?['brandId'] as String?;
            final brandName = extra?['brandName'] as String?;
            if (brandId == null || brandName == null) {
              return const Center(
                  child:
                  Text('Error: Missing brandId or brandName'));
            }
            // Fetch models before building ModelListScreen
            final modelProvider =
            Provider.of<ModelProvider>(context, listen: false);
            return FutureBuilder(
              // Sử dụng lại logic fetchModelsByBrandId từ ModelListScreen
              future: modelProvider.fetchModelsByBrandId(brandId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child:
                      CircularProgressIndicator()); // Show loading indicator
                } else if (snapshot.hasError) {
                  return Center(
                    child: Text(
                        'Error: ${snapshot.error}'),); // Show error message
                } else {
                  // Truyền dữ liệu đã fetch vào ModelListScreen
                  return ModelListScreen(
                    brandId: brandId,
                    name: brandName,
                    initialData: extra, // Pass the whole map
                  );
                }
              },
            );
          },
        ),
        GoRoute(
          path: 'year',
          builder: (context, state) {
            final extra = state.extra as Map<String, dynamic>?;
            final initialYear = extra?['initialYear'] as String?;

            return YearSelectionScreen(
              brandId: extra?['brandId'] as String ?? '',
              modelId: extra?['modelId'] as int ?? 0,
              modelName: extra?['modelName'] as String ?? '',
              initialYear: initialYear,
              initialData: extra, // Pass the whole map
            );
          },
        ),
        GoRoute(
          path: 'condition-origin',
          builder: (context, state) {
            final extra = state.extra as Map<String, dynamic>?;
            // Handle nulls
            final initialCondition = extra?['initialCondition'] as String?;
            final initialOrigin = extra?['initialOrigin'] as String?;
            final initialMileage = extra?['initialMileage'] as int?;
            return ConditionOriginScreen(
              brandId: extra?['brandId'] as String ?? '',
              modelId: extra?['modelId'] as int ?? 0,
              modelName: extra?['modelName'] as String ?? '',
              selectedYear: extra?['selectedYear'] as String ?? '',
              initialData: extra, // Pass the whole map
              initialCondition: initialCondition,
              initialOrigin: initialOrigin,
              initialMileage: initialMileage,
            );
          },
        ),
        GoRoute(
          path: 'fuel-transmission',
          builder: (context, state) {
            final extra = state.extra as Map<String, dynamic>?;
            final initialFuelType = extra?['initialFuelType'] as String?; // Make nullable
            final initialTransmission =
            extra?['initialTransmission'] as String?; // Make nullable
            return FuelTransmissionScreen(
              brandId: extra?['brandId'] as String ?? '',
              modelId: extra?['modelId'] as int ?? 0,
              modelName: extra?['modelName'] as String ?? '',
              selectedYear: extra?['selectedYear'] as String ?? '',
              condition: extra?['condition'] as String ??
                  '', // Keep as non-nullable, passed from previous screen
              origin: extra?['origin'] as String ??
                  '', // Keep as non-nullable, passed from previous screen
              mileage: extra?['mileage'] as int ??
                  0, // Keep as non-nullable, passed from previous screen
              initialData: extra, // Pass the whole map
              initialFuelType: initialFuelType, // Use nullable
              initialTransmission: initialTransmission, // Use nullable
            );
          },
        ),
        GoRoute(
          path: 'price-title-description',
          builder: (context, state) {
            final extra = state.extra as Map<String, dynamic>?;
            final initialPrice = extra?['initialPrice'] as double?; // Make nullable
            final initialTitle = extra?['initialTitle'] as String?; // Make nullable
            final initialDescription =
            extra?['initialDescription'] as String?; // Make nullable
            return PriceTitleDescriptionScreen(
              brandId: extra?['brandId'] as String ?? '',
              modelId: extra?['modelId'] as int ?? 0,
              modelName: extra?['modelName'] as String ?? '',
              selectedYear: extra?['selectedYear'] as String ?? '',
              condition: extra?['condition'] as String ??
                  '', // Keep non-nullable, passed from previous
              origin: extra?['origin'] as String ??
                  '', // Keep non-nullable, passed from previous
              mileage: extra?['mileage'] as int ??
                  0, // Keep non-nullable, passed from previous
              fuelType: extra?['fuelType'] as String ??
                  '', // Keep non-nullable, passed from previous
              transmission: extra?['transmission'] as String ??
                  '', // Keep non-nullable, passed from previous
              initialData: extra, // Pass the whole map
              initialPrice: initialPrice, // Use nullable
              initialTitle: initialTitle, // Use nullable
              initialDescription: initialDescription, // Use nullable
            );
          },
        ),
        GoRoute(
          path: 'image-upload',
          builder: (context, state) {
            final extra = state.extra as Map<String, dynamic>?;
            // Changed from initialImage to initialImages
            final initialImages = extra?['initialImages'] as List<XFile>?;
            return ImageUploadScreen(
              brandId: extra?['brandId'] as String ?? '',
              modelId: extra?['modelId'] as int ?? 0,
              modelName: extra?['modelName'] as String ?? '',
              selectedYear: extra?['selectedYear'] as String ?? '',
              condition: extra?['condition'] as String ?? '',
              origin: extra?['origin'] as String ?? '',
              mileage: extra?['mileage'] as int ?? 0,
              fuelType: extra?['fuelType'] as String ?? '',
              transmission: extra?['transmission'] as String ?? '',
              price: extra?['price'] as double ?? 0.0,
              title: extra?['title'] as String ?? '',
              description: extra?['description'] as String ?? '',
              initialImages: initialImages, // Pass the list
              initialData: extra, // Pass the whole map
            );
          },
        ),
        GoRoute(
          path: 'confirm-post',
          builder: (context, state) {
            final extra = state.extra as Map<String, dynamic>?;
            // Changed from selectedImage to selectedImages
            final selectedImages = extra?['selectedImages'] as List<XFile>?;
            return ConfirmPostScreen(
              brandId: extra?['brandId'] as String ?? '',
              modelId: extra?['modelId'] as int ?? 0,
              modelName: extra?['modelName'] as String ?? '',
              selectedYear: extra?['selectedYear'] as String ?? '',
              condition: extra?['condition'] as String ?? '',
              origin: extra?['origin'] as String ?? '',
              mileage: extra?['mileage'] as int ?? 0,
              fuelType: extra?['fuelType'] as String ?? '',
              transmission: extra?['transmission'] as String ?? '',
              price: extra?['price'] as double ?? 0.0,
              title: extra?['title'] as String ?? '',
              description: extra?['description'] as String ?? '',
              selectedImages: selectedImages, // Pass the list
              initialData: extra, // Pass initialData here as well
            );
          },
        ),

      ],
    ),
    GoRoute(
      path: '/favorites',
      builder: (context, state) =>
      const BuyAppScreen(currentIndex: 1, child: FavoritePostsScreen(uid: '')),
    ),
    GoRoute(
      path: '/my_posts', // Route cho màn hình quản lý tin rao
      builder: (context, state) => const SellAppScreen(currentIndex: 1, child: MyPostsScreen()),
    ),
    GoRoute(
      path: '/notifications/2', // Đường dẫn bạn muốn
      builder: (context, state) => const SellAppScreen(currentIndex: 2, child: NotificationsScreen()),
    ),
    GoRoute(
      path: '/notifications/1', // Đường dẫn bạn muốn
      builder: (context, state) => const BuyAppScreen(currentIndex: 2, child: NotificationsScreen()),
    ),
  ],
);