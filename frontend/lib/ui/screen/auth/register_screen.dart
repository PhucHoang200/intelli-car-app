import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../providers/user_provider.dart';
import '../../../utils/validators/auth_validator.dart';
import '../../../utils/constants/app_constants.dart';
import '../../widgets/user/auth_text_field.dart';
import '../../widgets/user/auth_dropdown_field.dart';
import '../../../utils/validators/auth_validator.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  String? _selectedProvince;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Đăng ký tài khoản', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 10),
              const Text('OTO', style: TextStyle(fontSize: 72, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 8)),
              const SizedBox(height: 20),

              Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(30.0)),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
                child: _buildForm(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Consumer<UserProvider>(
      builder: (context, userProvider, _) {
        return Form(
          key: userProvider.formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Tạo tài khoản mới', textAlign: TextAlign.center, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 30),

              AuthTextField(
                controller: userProvider.nameController,
                label: 'Họ và tên',
                prefixIcon: Icons.person_outline,
                validator: (v) => AuthValidator.validateRequired(v, 'họ và tên'),
              ),
              const SizedBox(height: 20),

              AuthTextField(
                controller: userProvider.emailController,
                label: 'Email',
                prefixIcon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                validator: AuthValidator.validateEmail,
              ),
              const SizedBox(height: 20),

              AuthTextField(
                controller: userProvider.phoneController,
                label: 'Số điện thoại',
                prefixIcon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                validator: AuthValidator.validatePhone,
              ),
              const SizedBox(height: 20),

              AuthDropdownField(
                label: 'Địa chỉ (Tỉnh/Thành phố)',
                value: _selectedProvince,
                items: AppConstants.provinces,
                onChanged: (val) {
                  setState(() => _selectedProvince = val);
                  userProvider.selectedProvince = val;
                },
                validator: (v) => AuthValidator.validateRequired(v, 'địa chỉ'),
              ),
              const SizedBox(height: 20),

              AuthTextField(
                controller: userProvider.passwordController,
                label: 'Mật khẩu',
                prefixIcon: Icons.lock_outline,
                obscureText: !userProvider.isPasswordVisible,
                suffixIcon: IconButton(
                  icon: Icon(userProvider.isPasswordVisible ? Icons.visibility : Icons.visibility_off),
                  onPressed: () => userProvider.isPasswordVisible = !userProvider.isPasswordVisible,
                ),
                validator: AuthValidator.validatePassword,
              ),
              const SizedBox(height: 20),

              AuthTextField(
                controller: userProvider.confirmPasswordController,
                label: 'Xác nhận mật khẩu',
                prefixIcon: Icons.lock_outline,
                obscureText: !userProvider.isConfirmPasswordVisible,
                suffixIcon: IconButton(
                  icon: Icon(userProvider.isConfirmPasswordVisible ? Icons.visibility : Icons.visibility_off),
                  onPressed: () => userProvider.isConfirmPasswordVisible = !userProvider.isConfirmPasswordVisible,
                ),
                validator: (v) => AuthValidator.validateConfirmPassword(v, userProvider.passwordController.text),
              ),

              const SizedBox(height: 30),
              if (userProvider.errorMessage != null) _buildErrorBox(userProvider.errorMessage!),
              _buildRegisterButton(userProvider),

              const SizedBox(height: 20),
              _buildLoginLink(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRegisterButton(UserProvider provider) {
    return ElevatedButton(
      onPressed: provider.isLoading ? null : () async {
        if (provider.formKey.currentState!.validate()) {
          final success = await provider.registerUser(context);
          if (success && mounted) context.go('/register-success');
        }
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: provider.isLoading
          ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
          : const Text('Đăng ký', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildErrorBox(String error) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.red.shade200)),
      child: Text(error, style: const TextStyle(color: Colors.red), textAlign: TextAlign.center),
    );
  }

  Widget _buildLoginLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('Đã có tài khoản?', style: TextStyle(color: Colors.grey)),
        TextButton(onPressed: () => context.go('/login'), child: const Text('Đăng nhập', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold))),
      ],
    );
  }
}