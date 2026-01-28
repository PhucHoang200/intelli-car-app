import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:online_car_marketplace_app/repositories/car_repository.dart';
import 'package:online_car_marketplace_app/repositories/image_repository.dart';
import 'package:online_car_marketplace_app/repositories/model_repository.dart';
import 'package:online_car_marketplace_app/repositories/post_repository.dart';
import 'package:online_car_marketplace_app/repositories/user_repository.dart';
import 'package:online_car_marketplace_app/services/storage_service.dart';
import 'package:provider/provider.dart';
import 'package:online_car_marketplace_app/providers/post_provider.dart';
import 'package:online_car_marketplace_app/providers/brand_provider.dart';
import 'package:online_car_marketplace_app/providers/user_provider.dart';
import 'package:online_car_marketplace_app/services/firebase_options.dart';
import 'package:online_car_marketplace_app/navigation/app_router.dart';
import 'package:online_car_marketplace_app/providers/model_provider.dart';
import 'package:online_car_marketplace_app/providers/car_provider.dart';
import 'package:online_car_marketplace_app/providers/favorite_provider.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => FavoriteProvider()),
        ChangeNotifierProvider(create: (_) => CarProvider()),
        ChangeNotifierProvider(create: (_) => PostProvider()),
        Provider<PostRepository>(create: (_) => PostRepository()),
        ChangeNotifierProvider(create: (_) => BrandProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => ModelProvider()),
        Provider<StorageService>(create: (_) => StorageService()),
        Provider<CarRepository>(create: (_) => CarRepository()),
        Provider<ImageRepository>(create: (_) => ImageRepository()),
        Provider<ModelRepository>(create: (_) => ModelRepository()),
        Provider<UserRepository>(create: (_) => UserRepository()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerConfig: appRouter,
      debugShowCheckedModeBanner: false,
    );
  }
}
