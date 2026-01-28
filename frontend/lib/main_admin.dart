import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:online_car_marketplace_app/navigation/admin_router.dart';
import 'package:online_car_marketplace_app/services/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const AdminApp());
}

class AdminApp extends StatelessWidget {
  const AdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Admin Panel',
      theme: ThemeData(primarySwatch: Colors.indigo),
      routerConfig: adminRouter,
    );
  }
}
