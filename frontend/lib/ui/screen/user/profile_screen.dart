import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:online_car_marketplace_app/providers/user_provider.dart';
import 'package:online_car_marketplace_app/models/user_model.dart';
import 'package:online_car_marketplace_app/services/storage_service.dart';

class ProfileScreen extends StatefulWidget {
  final String uid;
  const ProfileScreen({required this.uid, super.key});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late String userId;
  bool _isEditing = false;
  final _formKey = GlobalKey<FormState>();
  TextEditingController? _nameController;
  TextEditingController? _phoneController;
  TextEditingController? _emailController;
  TextEditingController? _addressController;
  String? _avatarUrl;
  XFile? _selectedImage;
  final ImagePicker _picker = ImagePicker();
  final StorageService _storageService = StorageService();

  @override
  void initState() {
    super.initState();
    userId = widget.uid;
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final userData = await _getUserData();
    if (userData != null) {
      setState(() {
        _nameController = TextEditingController(text: userData['name'] ?? '');
        _phoneController = TextEditingController(text: userData['phone'] ?? '');
        _emailController = TextEditingController(text: userData['email'] ?? '');
        _addressController = TextEditingController(text: userData['address'] ?? '');
        _avatarUrl = userData['avatarUrl'];
      });
    }
  }

  Future<Map<String, dynamic>?> _getUserData() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('uid', isEqualTo: widget.uid)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return snapshot.docs.first.data();
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    setState(() {
      _selectedImage = pickedFile;
    });
  }

  Future<void> _toggleEdit(UserProvider userProvider) async {
    if (_isEditing) {
      await _saveChanges(userProvider);
    }
    setState(() {
      _isEditing = !_isEditing;
    });
  }

  Future<void> _saveChanges(UserProvider userProvider) async {
    if (_formKey.currentState!.validate()) {
      String? newAvatarUrl = _avatarUrl;
      if (_selectedImage != null) {
        try {
          newAvatarUrl = await _storageService.uploadImage(_selectedImage!);
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error uploading image: $e')),
          );
          return;
        }
      }

      final updatedUser = User(
        id: 0,
        uid: widget.uid,
        name: _nameController!.text.trim(),
        email: _emailController!.text.trim(),
        phone: _phoneController!.text.trim(),
        address: _addressController!.text.trim(),
        avatarUrl: newAvatarUrl,
        roleId: 1,
        status: 'Hoạt động',
        creationDate: Timestamp.now(),
        updateDate: Timestamp.now(),
      );

      await userProvider.updateUserProfile(context, updatedUser);
      _loadUserData();
    }
  }

  // Thêm hàm này vào trong class _ProfileScreenState
  Future<void> _handleLogout(UserProvider userProvider) async {
    // Hiển thị hộp thoại xác nhận trước khi đăng xuất
    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận'),
        content: const Text('Bạn có chắc chắn muốn đăng xuất không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Đăng xuất', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    ) ?? false;

    if (confirm && mounted) {
      // Gọi hàm logout từ UserProvider (Đảm bảo trong UserProvider đã có hàm logout)
      await userProvider.logout();

      // Điều hướng về trang Login
      if (mounted) {
        GoRouter.of(context).go('/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    return FutureBuilder<Map<String, dynamic>?>(
      future: _getUserData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        if (snapshot.hasError) {
          return const Scaffold(body: Center(child: Text("Error loading user data")));
        }

        if (!snapshot.hasData || snapshot.data == null) {
          return const Scaffold(body: Center(child: Text("No user data found")));
        }

        return Scaffold(
          backgroundColor: Colors.white, // Đổi màu nền tổng thể thành trắng
          appBar: AppBar(
            title: const Text('Thông tin tài khoản'),
            titleTextStyle: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),// Đổi màu tiêu đề
            backgroundColor: Colors.blue, // Đổi màu nền appbar
            centerTitle: true,
            iconTheme: const IconThemeData(color: Colors.black), // Đổi màu icon appbar
            elevation: 0, // Loại bỏ bóng đổ dưới appbar
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Avatar
                Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundColor: Colors.grey[300],
                        backgroundImage: _selectedImage != null
                            ? FileImage(File(_selectedImage!.path)) as ImageProvider<Object>?
                            : NetworkImage(_avatarUrl ?? ''),
                      ),
                      if (_isEditing)
                        GestureDetector(
                          onTap: _pickImage,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                            ),
                            child: const Icon(Icons.camera_alt, size: 20, color: Colors.grey),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Thông tin người dùng
                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildTextField(
                        controller: _nameController,
                        labelText: 'Tên liên hệ',
                        enabled: _isEditing,
                        validator: (value) => value == null || value.isEmpty ? 'Vui lòng nhập tên liên hệ!' : null,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _phoneController,
                        labelText: 'Số điện thoại',
                        enabled: _isEditing,
                        keyboardType: TextInputType.phone,
                        validator: (value) => value == null || value.isEmpty ? 'Vui lòng nhập số điện thoại!' : null,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _emailController,
                        labelText: 'Tên tài khoản đăng nhập',
                        enabled: false,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _addressController,
                        labelText: 'Tỉnh/Thành phố',
                        enabled: _isEditing,
                        validator: (value) => value == null || value.isEmpty ? 'Vui lòng nhập tỉnh/thành phố!' : null,
                      ),
                      const SizedBox(height: 32),

                      // Edit/Save Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => _toggleEdit(userProvider),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isEditing ? Colors.green : Colors.blue, // Đổi màu button
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), // Bo góc
                          ),
                          child: Text(
                            _isEditing ? 'Lưu lại' : 'Chỉnh sửa',
                            style: const TextStyle(fontSize: 18, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Profile Options List
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!), // Thêm border cho container
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _ProfileOptionItem(
                        icon: Icons.list_alt,
                        label: "Quản lý tin rao",
                        onTap: () {
                          // Navigate to manage listings screen
                        },
                      ),
                      const Divider(height: 1, color: Colors.grey),
                      _ProfileOptionItem(
                        icon: Icons.lock_outline,
                        label: "Thay đổi mật khẩu",
                        onTap: () {
                          // Navigate to change password screen
                        },
                      ),
                      const Divider(height: 1, color: Colors.grey),
                      _ProfileOptionItem(
                        icon: Icons.logout,
                        label: "Đăng xuất",
                        onTap: () => _handleLogout(userProvider),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTextField({
    required TextEditingController? controller,
    required String labelText,
    bool enabled = true,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: TextStyle(color: Colors.grey[600]),
        border: const UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.grey),
        ),
        enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.grey),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.blue),
        ),
        filled: false,
        suffixIcon: enabled && controller?.text.isNotEmpty == true
            ? IconButton(
          icon: const Icon(Icons.clear, color: Colors.grey),
          onPressed: () {
            controller?.clear();
            setState(() {}); // Cập nhật giao diện khi xóa text
          },
        )
            : null,
      ),
      validator: validator,
    );
  }
}

class _ProfileOptionItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _ProfileOptionItem({
    required this.icon,
    required this.label,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: Colors.grey[600]), // Đổi màu icon
            const SizedBox(width: 16),
            Text(label, style: const TextStyle(fontSize: 16, color: Colors.black)), // Đổi màu text
          ],
        ),
      ),
    );
  }
}