import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../providers/user_provider.dart';

class RegisterSuccessScreen extends StatefulWidget {
  const RegisterSuccessScreen({super.key});

  @override
  State<RegisterSuccessScreen> createState() => _RegisterSuccessScreenState();
}

class _RegisterSuccessScreenState extends State<RegisterSuccessScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Tự động kiểm tra mỗi 3 giây
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      _checkVerification(isAuto: true);
    });
  }

  @override
  void dispose() {
    _timer?.cancel(); // Hủy timer khi thoát màn hình để tránh leak bộ nhớ
    super.dispose();
  }

  Future<void> _checkVerification({bool isAuto = false}) async {
    final userProvider = context.read<UserProvider>();
    // checkEmailVerification đã có lệnh user.reload() như chúng ta đã sửa ở UserProvider
    final result = await userProvider.checkEmailVerification(context);

    if (result['success'] && mounted) {
      _timer?.cancel();
      context.go('/login');
    } else if (!isAuto && mounted) {
      // Chỉ hiện SnackBar nếu người dùng nhấn nút thủ công mà chưa xác thực
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message']), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Giữ nguyên phần UI cũ của bạn, chỉ thay đổi hàm gọi ở nút bấm
    return Scaffold(
      backgroundColor: Colors.blue,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 30),
              const Text('OTO', style: TextStyle(fontSize: 72, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 8)),
              const SizedBox(height: 30),
              Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(30.0)),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
                child: Column(
                  children: [
                    const Icon(Icons.mark_email_read_outlined, size: 100, color: Colors.blue),
                    const SizedBox(height: 30),
                    const Text('Kiểm tra email', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 15),
                    const Text(
                      'Chúng tôi đã gửi link xác thực đến email của bạn.\nApp sẽ tự động chuyển hướng sau khi bạn xác thực thành công.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 40),

                    // Nút nhấn thủ công (Cứu cánh)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => _checkVerification(isAuto: false),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Tôi đã xác thực', style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildResendSection(context),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResendSection(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, provider, _) {
        return TextButton(
          onPressed: provider.isLoadingResendEmail ? null : () => provider.resendVerificationEmail(context),
          child: provider.isLoadingResendEmail
              ? const CircularProgressIndicator()
              : const Text('Gửi lại email xác thực', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
        );
      },
    );
  }
}