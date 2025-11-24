import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:online_car_marketplace_app/providers/user_provider.dart';
import 'package:provider/provider.dart';

class RegisterSuccessScreen extends StatefulWidget {
  const RegisterSuccessScreen({super.key});

  @override
  State<RegisterSuccessScreen> createState() => _RegisterSuccessScreenState();
}

class _RegisterSuccessScreenState extends State<RegisterSuccessScreen> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _checkVerificationAndNavigate(BuildContext context, UserProvider userProvider) async {
    final verificationResult = await userProvider.checkEmailVerification(context);
    if (verificationResult['success']) {
      if (mounted) {
        context.go('/login');
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(verificationResult['message']),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    return Scaffold(
      backgroundColor: Colors.blue, // Đặt nền màu xanh dương cho toàn bộ Scaffold
      appBar: AppBar(
        backgroundColor: Colors.transparent, // Nền trong suốt
        elevation: 0, // Bỏ đổ bóng
        automaticallyImplyLeading: false, // Ngăn người dùng quay lại màn hình đăng ký
        title: const Text(
          'Đăng ký thành công',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold), // Tiêu đề màu trắng, in đậm
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 30), // Khoảng trống từ AppBar xuống logo
              // Logo "OTO"
              const Text(
                'OTO',
                style: TextStyle(
                  fontSize: 72, // Phóng to chữ
                  fontWeight: FontWeight.bold,
                  color: Colors.white, // Màu trắng
                  letterSpacing: 8, // Khoảng cách giữa các chữ cái
                ),
              ),
              const SizedBox(height: 30), // Khoảng trống từ logo đến form
              // Nội dung thành công trong Container nền trắng
              Container(
                decoration: const BoxDecoration(
                  color: Colors.white, // Nền trắng cho phần nội dung
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30.0), // Bo tròn góc trên bên trái
                    topRight: Radius.circular(30.0), // Bo tròn góc trên bên phải
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0), // Padding cho nội dung
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.check_circle_outline, size: 100, color: Colors.blue), // Changed to Colors.blue
                    const SizedBox(height: 30),
                    Text(
                      'Chúc mừng bạn đã đăng ký thành công!',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.black87, // Đổi màu chữ sang đen
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 15),
                    Text(
                      'Một email xác thực đã được gửi đến hộp thư của bạn.',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey[700]),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Vui lòng kiểm tra email và nhấp vào liên kết để xác thực tài khoản của bạn. (Kiểm tra cả thư mục Spam/Junk)',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 40),

                    ElevatedButton(
                      onPressed: () async {
                        await _checkVerificationAndNavigate(context, userProvider);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue, // Changed to Colors.blue
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 3,
                      ),
                      child: const Text(
                        'Tiếp tục đăng nhập',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Consumer<UserProvider>(
                      builder: (context, userProvider, child) {
                        return TextButton(
                          onPressed: userProvider.isLoadingResendEmail
                              ? null
                              : () async {
                            await userProvider.resendVerificationEmail(context);
                            if (userProvider.resendEmailMessage != null && mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(userProvider.resendEmailMessage!),
                                  backgroundColor: userProvider.resendEmailMessage!.contains('gửi lại thành công') ? Colors.green : Colors.red,
                                ),
                              );
                            }
                          },
                          child: userProvider.isLoadingResendEmail
                              ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.grey,
                              strokeWidth: 2,
                            ),
                          )
                              : const Text(
                            'Không nhận được email? Gửi lại',
                            style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold), // Changed to Colors.blue
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}