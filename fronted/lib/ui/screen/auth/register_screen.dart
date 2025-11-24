import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:online_car_marketplace_app/providers/user_provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  String? _selectedProvince;
  final List<String> _provinces = [
    'An Giang', 'Bà Rịa - Vũng Tàu', 'Bạc Liêu', 'Bắc Giang', 'Bắc Kạn', 'Bắc Ninh',
    'Bến Tre', 'Bình Định', 'Bình Dương', 'Bình Phước', 'Bình Thuận', 'Cà Mau',
    'Cao Bằng', 'Cần Thơ', 'Đà Nẵng', 'Đắk Lắk', 'Đắk Nông', 'Điện Biên',
    'Đồng Nai', 'Đồng Tháp', 'Gia Lai', 'Hà Giang', 'Hà Nam', 'Hà Nội',
    'Hà Tĩnh', 'Hải Dương', 'Hải Phòng', 'Hậu Giang', 'Hòa Bình', 'Hưng Yên',
    'Khánh Hòa', 'Kiên Giang', 'Kon Tum', 'Lai Châu', 'Lạng Sơn', 'Lào Cai',
    'Lâm Đồng', 'Long An', 'Nam Định', 'Nghệ An', 'Ninh Bình', 'Ninh Thuận',
    'Phú Thọ', 'Phú Yên', 'Quảng Bình', 'Quảng Nam', 'Quảng Ngãi', 'Quảng Ninh',
    'Quảng Trị', 'Sóc Trăng', 'Sơn La', 'Tây Ninh', 'Thái Bình', 'Thái Nguyên',
    'Thanh Hóa', 'Thừa Thiên Huế', 'Tiền Giang', 'Trà Vinh', 'Tuyên Quang',
    'Vĩnh Long', 'Vĩnh Phúc', 'Yên Bái', 'Phú Quốc',
  ];

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    return Scaffold(
      backgroundColor: Colors.blue, // Đặt nền màu xanh dương cho toàn bộ Scaffold
      appBar: AppBar(
        backgroundColor: Colors.transparent, // Nền trong suốt
        elevation: 0, // Bỏ đổ bóng
        title: const Text(
          'Đăng ký tài khoản',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold), // Tiêu đề màu trắng, in đậm
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 10), // Khoảng trống từ AppBar xuống logo
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
              const SizedBox(height: 10), // Khoảng trống từ logo đến form
              // Form đăng ký trong Container nền trắng
              Container(
                decoration: const BoxDecoration(
                  color: Colors.white, // Nền trắng cho form
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30.0), // Bo tròn góc trên bên trái
                    topRight: Radius.circular(30.0), // Bo tròn góc trên bên phải
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0), // Padding cho form
                child: _buildRegistrationForm(userProvider),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRegistrationForm(UserProvider userProvider) {
    return Form(
      key: userProvider.formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Text(
            'Tạo tài khoản mới',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.black87, // Đổi màu chữ sang đen
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Text(
            'Vui lòng điền đầy đủ thông tin bên dưới để đăng ký',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey[700]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 30),
          // Name field
          TextFormField(
            controller: userProvider.nameController,
            decoration: InputDecoration(
              labelText: 'Họ và tên',
              hintText: 'VD: Nguyễn Văn A',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.0),
                borderSide: const BorderSide(color: Colors.grey),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.0),
                borderSide: BorderSide(color: Colors.grey.shade300, width: 1.0),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.0),
                borderSide: const BorderSide(color: Colors.blue, width: 2.0), // Changed to Colors.blue
              ),
              prefixIcon: const Icon(Icons.person_outline, color: Colors.blue), // Changed to Colors.blue
              contentPadding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
            ),
            validator: (value) => value == null || value.isEmpty ? 'Vui lòng nhập họ và tên' : null,
          ),
          const SizedBox(height: 20),
          // Email field
          TextFormField(
            controller: userProvider.emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: 'Email',
              hintText: 'VD: example@gmail.com',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.0),
                borderSide: const BorderSide(color: Colors.grey),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.0),
                borderSide: BorderSide(color: Colors.grey.shade300, width: 1.0),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.0),
                borderSide: const BorderSide(color: Colors.blue, width: 2.0), // Changed to Colors.blue
              ),
              prefixIcon: const Icon(Icons.email_outlined, color: Colors.blue), // Changed to Colors.blue
              contentPadding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) return 'Vui lòng nhập email';
              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) return 'Email không hợp lệ';
              return null;
            },
          ),
          const SizedBox(height: 20),
          // Phone number field
          TextFormField(
            controller: userProvider.phoneController,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              labelText: 'Số điện thoại',
              hintText: 'VD: 0987654321',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.0),
                borderSide: const BorderSide(color: Colors.grey),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.0),
                borderSide: BorderSide(color: Colors.grey.shade300, width: 1.0),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.0),
                borderSide: const BorderSide(color: Colors.blue, width: 2.0), // Changed to Colors.blue
              ),
              prefixIcon: const Icon(Icons.phone_outlined, color: Colors.blue), // Changed to Colors.blue
              contentPadding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Vui lòng nhập số điện thoại';
              }
              if (!RegExp(r'^0\d{9}$').hasMatch(value)) {
                return 'Số điện thoại không hợp lệ (phải bắt đầu bằng 0 và có 10 số)';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),
          // Address (Province) dropdown
          DropdownButtonFormField<String>(
            decoration: InputDecoration(
              labelText: 'Địa chỉ (Tỉnh/Thành phố)',
              hintText: 'Chọn Tỉnh/Thành phố của bạn',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.0),
                borderSide: const BorderSide(color: Colors.grey),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.0),
                borderSide: BorderSide(color: Colors.grey.shade300, width: 1.0),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.0),
                borderSide: const BorderSide(color: Colors.blue, width: 2.0), // Changed to Colors.blue
              ),
              prefixIcon: const Icon(Icons.location_on_outlined, color: Colors.blue), // Changed to Colors.blue
              contentPadding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
            ),
            value: _selectedProvince,
            menuMaxHeight: 200,
            items: _provinces.map((province) {
              return DropdownMenuItem<String>(
                value: province,
                child: Text(province),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedProvince = value;
              });
              userProvider.selectedProvince = value;
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Vui lòng chọn địa chỉ';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),
          // Password field
          TextFormField(
            controller: userProvider.passwordController,
            obscureText: !userProvider.isPasswordVisible,
            decoration: InputDecoration(
              labelText: 'Mật khẩu',
              hintText: 'Nhập mật khẩu (ít nhất 8 ký tự)',
              helperText: 'Mật khẩu phải có ít nhất 8 ký tự, bao gồm chữ cái, số và ký tự đặc biệt',
              helperMaxLines: 2,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.0),
                borderSide: const BorderSide(color: Colors.grey),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.0),
                borderSide: BorderSide(color: Colors.grey.shade300, width: 1.0),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.0),
                borderSide: const BorderSide(color: Colors.blue, width: 2.0), // Changed to Colors.blue
              ),
              prefixIcon: const Icon(Icons.lock_outline, color: Colors.blue), // Changed to Colors.blue
              suffixIcon: IconButton(
                icon: Icon(userProvider.isPasswordVisible ? Icons.visibility : Icons.visibility_off, color: Colors.grey),
                onPressed: () => userProvider.isPasswordVisible = !userProvider.isPasswordVisible,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) return 'Vui lòng nhập mật khẩu';
              if (value.length < 8) return 'Mật khẩu phải có ít nhất 8 ký tự';
              if (!RegExp(r'^(?=.*[A-Za-z])(?=.*\d)[A-Za-z\d@$!%*?&]{8,}$').hasMatch(value)) return 'Mật khẩu phải chứa chữ cái, số và ký tự đặc biệt';
              return null;
            },
          ),
          const SizedBox(height: 20),
          // Confirm Password field
          TextFormField(
            controller: userProvider.confirmPasswordController,
            obscureText: !userProvider.isConfirmPasswordVisible,
            decoration: InputDecoration(
              labelText: 'Xác nhận mật khẩu',
              hintText: 'Nhập lại mật khẩu',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.0),
                borderSide: const BorderSide(color: Colors.grey),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.0),
                borderSide: BorderSide(color: Colors.grey.shade300, width: 1.0),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.0),
                borderSide: const BorderSide(color: Colors.blue, width: 2.0), // Changed to Colors.blue
              ),
              prefixIcon: const Icon(Icons.lock_outline, color: Colors.blue), // Changed to Colors.blue
              suffixIcon: IconButton(
                icon: Icon(userProvider.isConfirmPasswordVisible ? Icons.visibility : Icons.visibility_off, color: Colors.grey),
                onPressed: () => userProvider.isConfirmPasswordVisible = !userProvider.isConfirmPasswordVisible,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) return 'Vui lòng xác nhận mật khẩu';
              if (value != userProvider.passwordController.text) return 'Mật khẩu không khớp';
              return null;
            },
          ),
          const SizedBox(height: 30),

          // Hiển thị thông báo lỗi (nếu có)
          if (userProvider.errorMessage != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Text(
                  userProvider.errorMessage!,
                  style: const TextStyle(color: Colors.red, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ),
            ),

          // Register button
          ElevatedButton(
            onPressed: userProvider.isLoading
                ? null
                : () async {
              if (userProvider.formKey.currentState!.validate()) {
                final success = await userProvider.registerUser(context);
                if (success && mounted) {
                  GoRouter.of(context).go('/register-success');
                }
              }
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
            child: userProvider.isLoading
                ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            )
                : const Text(
              'Đăng ký',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 20),

          // Login link
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Đã có tài khoản?', style: TextStyle(color: Colors.grey)),
              TextButton(
                onPressed: () => context.go('/login'),
                child: const Text(
                  'Đăng nhập',
                  style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold), // Changed to Colors.blue
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}