import 'package:flutter/material.dart';
import 'package:online_car_marketplace_app/models/user_model.dart';
import 'package:online_car_marketplace_app/repositories/user_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;

class UserProvider with ChangeNotifier {
  final UserRepository _userRepository = UserRepository();
  List<User> _users = [];
  List<User> get users => _users;
  User? _currentUser;
  User? get currentUser => _currentUser;
  bool _isLoading = false;
  bool get isLoading => _isLoading;
  String? _errorMessage;
  String? get errorMessage => _errorMessage;
  bool _isAuthenticated = false;
  bool get isAuthenticated => _isAuthenticated;
  auth.User? _authUser;
  auth.User? get authUser => _authUser;
  String? _selectedProvince;
  String? get selectedProvince => _selectedProvince;
  set selectedProvince(String? value) {
    _selectedProvince = value;
    notifyListeners();
  }

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  GlobalKey<FormState> get formKey => _formKey;
  final TextEditingController _nameController = TextEditingController();
  TextEditingController get nameController => _nameController;
  final TextEditingController _emailController = TextEditingController();
  TextEditingController get emailController => _emailController;
  final TextEditingController _phoneController = TextEditingController();
  TextEditingController get phoneController => _phoneController;
  final TextEditingController _passwordController = TextEditingController();
  TextEditingController get passwordController => _passwordController;
  final TextEditingController _confirmPasswordController = TextEditingController();
  TextEditingController get confirmPasswordController => _confirmPasswordController;
  final TextEditingController _addressController = TextEditingController();
  TextEditingController get addressController => _addressController;

  bool _isPasswordVisible = false;
  bool get isPasswordVisible => _isPasswordVisible;
  set isPasswordVisible(bool value) {
    _isPasswordVisible = value;
    notifyListeners();
  }

  bool _isConfirmPasswordVisible = false;
  bool get isConfirmPasswordVisible => _isConfirmPasswordVisible;
  set isConfirmPasswordVisible(bool value) {
    _isConfirmPasswordVisible = value;
    notifyListeners();
  }

  // Trạng thái và thông báo cho việc gửi lại email xác thực
  bool _isLoadingResendEmail = false;
  bool get isLoadingResendEmail => _isLoadingResendEmail;
  set isLoadingResendEmail(bool value) {
    _isLoadingResendEmail = value;
    notifyListeners();
  }

  String? _resendEmailMessage;
  String? get resendEmailMessage => _resendEmailMessage;
  set resendEmailMessage(String? value) {
    _resendEmailMessage = value;
    notifyListeners();
  }

  UserProvider() {
    _userRepository.authStateChanges.listen((auth.User? user) {
      _authUser = user;
      _isAuthenticated = user != null;
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> fetchUsers() async {
    _isLoading = true;
    notifyListeners();

    try {
      _users = await _userRepository.getUsers();
    } catch (e) {
      _errorMessage = 'Lỗi khi tải danh sách người dùng: $e';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> addUser(User user) async {
    try {
      await _userRepository.addUserWithAutoIncrementAndUid(user);
      await fetchUsers();
    } catch (e) {
      _errorMessage = 'Lỗi khi thêm người dùng: $e';
    }
  }

  Future<void> updateUser(User user) async {
    try {
      await _userRepository.updateUser(user);
      await fetchUsers();
    } catch (e) {
      _errorMessage = 'Lỗi khi cập nhật người dùng: $e';
    }
  }

  Future<void> deleteUser(int id) async {
    try {
      await _userRepository.deleteUser(id);
      _users.removeWhere((u) => u.id == id);
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Lỗi khi xóa người dùng: $e';
    }
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;

    try {
      final result = await _userRepository.login(email, password);
      _isLoading = false;

      if (result['success']) {
        _currentUser = result['user'];
        _isAuthenticated = true;
      } else {
        _errorMessage = result['message'];
      }
      notifyListeners();
      return result['success'];
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Email hoặc mật khẩu không chính xác. Vui lòng nhập lại!';
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _userRepository.logout();
    _currentUser = null;
    _isAuthenticated = false;
    notifyListeners();
  }

  Future<bool> sendPasswordResetEmail(String email) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _userRepository.resetPasswordWithEmail(email);

      if (!result['success']) {
        _errorMessage = result['message'];
      }

      _isLoading = false;
      notifyListeners();
      return result['success'];
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Lỗi gửi email đặt lại mật khẩu: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> registerUser(BuildContext context) async {
    clearError();
    if (_formKey.currentState!.validate()) {
      setLoading(true);
      final result = await _userRepository.registerUser(
        User(
          id: 0,
          uid: '',
          name: _nameController.text.trim(),
          email: _emailController.text.trim(),
          phone: _phoneController.text.trim(),
          address: _selectedProvince!,
          avatarUrl: null,
          roleId: 1,
          status: 'Hoạt động',
          creationDate: Timestamp.now(),
          updateDate: Timestamp.now(),
        ),
        _passwordController.text.trim(),
      );
      setLoading(false);

      if (result['success']) {
        // Đăng ký thành công, hiển thị thông báo yêu cầu xác thực email
        // ScaffoldMessenger.of(context).showSnackBar(
        //   const SnackBar(
        //     content: Text('Đăng ký thành công! Vui lòng kiểm tra email để xác thực.'),
        //     backgroundColor: Colors.green,
        //     duration: Duration(seconds: 5),
        //   ),
        // );
        return true; // Trả về true để UI có thể chuyển sang trạng thái chờ xác thực
      } else {
        _errorMessage = result['message'];
        notifyListeners();
        return false;
      }
    }
    return false;
  }

  Future<Map<String, dynamic>> checkEmailVerification(BuildContext context) async {
    setLoading(true);
    final result = await _userRepository.checkEmailVerification();
    setLoading(false);

    if (!result['success']) {
      _errorMessage = result['message'];
      notifyListeners();
    }
    return result; // Trả về toàn bộ map kết quả
  }

  Future<void> resendVerificationEmail(BuildContext context) async {
    clearError();
    setLoadingResendEmail(true);
    _resendEmailMessage = null;
    final result = await _userRepository.resendVerificationEmail();
    setLoadingResendEmail(false);

    if (result['success']) {
      _resendEmailMessage = result['message'];
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_resendEmailMessage!)),
      );
    } else {
      _errorMessage = result['message'];
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_errorMessage!)),
      );
    }
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  auth.User? getCurrentAuthUser() {
    return _userRepository.getCurrentAuthUser();
  }

  void setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void setLoadingResendEmail(bool value) {
    _isLoadingResendEmail = value;
    notifyListeners();
  }


  Future<void> updateUserProfile(BuildContext context, User user) async {
    setLoading(true);
    clearError();
    try {
      await _userRepository.updateUser(user);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Lưu thông tin thành công!',
            style: TextStyle(color: Colors.white), // Chữ màu trắng
          ),
          backgroundColor: Colors.grey, // Màu xám nhạt
        ),
      );
    } catch (e) {
      _errorMessage = 'Lỗi khi lưu thông tin: $e';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _errorMessage!,
            style: const TextStyle(color: Colors.white), // Chữ màu trắng
          ),
          backgroundColor: Colors.grey, // Màu xám nhạt
        ),
      );
    } finally {
      setLoading(false);
    }
  }

}
