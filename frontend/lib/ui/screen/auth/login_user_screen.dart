import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import '../../../providers/user_provider.dart';
import '../../../utils/validators/auth_validator.dart';
import '../../widgets/user/auth_text_field.dart';
import '../auth/widgets/auth_header.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _rememberMe = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final userProvider = context.read<UserProvider>();
    userProvider.clearError();

    final success = await userProvider.login(
      _emailController.text.trim(),
      _passwordController.text.trim(),
    );

    if (success && mounted) {
      final user = auth.FirebaseAuth.instance.currentUser;
      if (user != null) context.go('/buy', extra: user.uid);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // 1. Header giữ màu xanh
              const SizedBox(height: 40),
              const Text('OTO', style: TextStyle(fontSize: 72, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 8)),
              const SizedBox(height: 40),

              // 2. White Box chứa Form
              Container(
                constraints: BoxConstraints(minHeight: MediaQuery.of(context).size.height * 0.7),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      const Text('Chào mừng trở lại!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 40),

                      AuthTextField(
                        controller: _emailController,
                        label: 'Email',
                        prefixIcon: Icons.email_outlined,
                        validator: AuthValidator.validateEmail,
                      ),
                      const SizedBox(height: 20),

                      AuthTextField(
                        controller: _passwordController,
                        label: 'Mật khẩu',
                        prefixIcon: Icons.lock_outline,
                        obscureText: !_isPasswordVisible,
                        suffixIcon: IconButton(
                          icon: Icon(_isPasswordVisible ? Icons.visibility : Icons.visibility_off),
                          onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                        ),
                        validator: AuthValidator.validatePassword,
                      ),

                      _buildOptionsRow(),
                      const SizedBox(height: 30),

                      // Consumer chỉ bọc phần cần thay đổi trạng thái
                      Consumer<UserProvider>(
                        builder: (context, provider, _) {
                          return Column(
                            children: [
                              if (provider.errorMessage != null) _buildErrorBox(provider.errorMessage!),
                              _buildLoginButton(provider.isLoading),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 20),
                      _buildRegisterLink(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Các widget phụ trợ nội bộ ---
  Widget _buildOptionsRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Checkbox(value: _rememberMe, onChanged: (v) => setState(() => _rememberMe = v!), activeColor: Colors.blue),
            const Text('Ghi nhớ', style: TextStyle(color: Colors.grey)),
          ],
        ),
        TextButton(onPressed: () {}, child: const Text('Quên mật khẩu?', style: TextStyle(color: Colors.blue))),
      ],
    );
  }

  Widget _buildLoginButton(bool isLoading) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isLoading ? null : _handleLogin,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: isLoading
            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : const Text('Đăng nhập', style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildErrorBox(String error) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.red.shade100)),
      child: Text(error, style: const TextStyle(color: Colors.red), textAlign: TextAlign.center),
    );
  }

  Widget _buildRegisterLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('Chưa có tài khoản?', style: TextStyle(color: Colors.grey)),
        TextButton(onPressed: () => context.go('/register'), child: const Text('Tạo ngay', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold))),
      ],
    );
  }
}