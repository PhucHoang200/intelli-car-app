import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String errorMessage = '';

  // Hàm mã hóa mật khẩu
  String hashPassword(String password) {
    return sha256.convert(utf8.encode(password)).toString();
  }

  // Hàm đăng nhập
  Future<void> login() async {
    try {
      // Lấy dữ liệu người dùng từ Firestore
      final querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: _emailController.text.trim())
          .limit(1)
          .get();

      // Kiểm tra nếu không tìm thấy người dùng
      if (querySnapshot.docs.isEmpty) {
        setState(() {
          errorMessage = 'Tài khoản không tồn tại';
        });
        return;
      }

      final userData = querySnapshot.docs.first.data();
      final hashedInputPassword = hashPassword(_passwordController.text.trim());

      // Kiểm tra mật khẩu đã mã hóa
      if (userData['password'] == hashedInputPassword) {
        // Lấy roleId của người dùng (là số nguyên)
        final roleId = userData['roleId'] as int; // Đảm bảo roleId là số nguyên

        // Lấy thông tin vai trò từ Firestore
        final roleSnapshot = await FirebaseFirestore.instance
            .collection('roles')
            .doc(roleId.toString()) // Chuyển roleId thành chuỗi khi truy vấn
            .get();

        if (roleSnapshot.exists) {
          final roleData = roleSnapshot.data();
          if (roleData != null && roleData['name'] == 'admin') {
            // Đăng nhập thành công, chuyển đến trang Dashboard
            context.go('/dashboard');
          } else {
            setState(() {
              errorMessage = 'Bạn không có quyền truy cập admin!';
            });
          }
        } else {
          setState(() {
            errorMessage = 'Không tìm thấy vai trò của người dùng';
          });
        }
      } else {
        setState(() {
          errorMessage = 'Sai mật khẩu';
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Đăng nhập thất bại';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Đăng nhập Admin")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Mật khẩu'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: login,
              child: const Text('Đăng nhập'),
            ),
            if (errorMessage.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(errorMessage, style: const TextStyle(color: Colors.red)),
              ),
          ],
        ),
      ),
    );
  }
}
