import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:online_car_marketplace_app/providers/user_provider.dart';

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

  // --- Logic xử lý ---
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
    // Lưu ý: Không dùng Provider.of<UserProvider>(context) ở đây để tránh lag khi gõ phím
    return Scaffold(
      backgroundColor: Colors.blue,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildHeader(),
              _buildLoginForm(),
            ],
          ),
        ),
      ),
    );
  }

  // --- UI Components ---

  Widget _buildHeader() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 40),
      child: Text(
        'OTO',
        style: TextStyle(
          fontSize: 72,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          letterSpacing: 8,
        ),
      ),
    );
  }

  Widget _buildLoginForm() {
    return Container(
      constraints: BoxConstraints(
        // Thiết lập chiều cao tối thiểu tại đây
        minHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            Text('Chào mừng trở lại!', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 40),

            // Email Field
            _buildTextField(
              controller: _emailController,
              label: 'Email',
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 20),

            // Password Field
            _buildTextField(
              controller: _passwordController,
              label: 'Mật khẩu',
              icon: Icons.lock_outline,
              isPassword: true,
              obscureText: !_isPasswordVisible,
              onToggleVisibility: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
            ),

            _buildForgotRow(),
            const SizedBox(height: 25),

            // Chỉ lắng nghe lỗi và trạng thái loading để tránh re-build toàn bộ màn hình
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

            _buildRegisterLink(),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
    bool obscureText = false,
    VoidCallback? onToggleVisibility,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.blue),
        suffixIcon: isPassword
            ? IconButton(
          icon: Icon(obscureText ? Icons.visibility_off : Icons.visibility, color: Colors.grey),
          onPressed: onToggleVisibility,
        )
            : null,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      validator: (val) => (val == null || val.isEmpty) ? 'Vui lòng điền thông tin' : null,
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
            : const Text('Đăng nhập', style: TextStyle(fontSize: 18, color: Colors.white)),
      ),
    );
  }

  // --- Các widget nhỏ khác tách ra để code clear hơn ---
  Widget _buildErrorBox(String error) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(10)),
      child: Text(error, style: const TextStyle(color: Colors.red)),
    );
  }

  Widget _buildForgotRow() {
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

  Widget _buildRegisterLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'Chưa có tài khoản?',
          style: TextStyle(color: Colors.grey),
        ),
        TextButton(
          onPressed: () => context.go('/register'),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap, // Giúp nút gọn hơn
          ),
          child: const Text(
            'Tạo ngay',
            style: TextStyle(
              color: Colors.blue, // Đổi sang màu xanh dương giống "Quên mật khẩu"
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}