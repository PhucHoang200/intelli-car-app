class UserValidator {
  static String validateName(String name) {
    final trimmedName = name.trim(); // Loại bỏ khoảng trắng thừa
    if (trimmedName.isEmpty || trimmedName.length > 50) {
      throw Exception('Tên tài khoản không hợp lệ (1-50 ký tự)');
    }
    return trimmedName;
  }

  static String validateStatus(String status) {
    // Thêm 'Chờ xác thực' vào danh sách cho phép
    const allowedStatuses = ['Hoạt động', 'Khóa', 'Chờ xác thực'];

    if (!allowedStatuses.contains(status)) {
      // Log ra giá trị thực tế đang bị lỗi để dễ debug nếu vẫn lỗi
      print("Giá trị status không hợp lệ: '$status'");
      throw Exception('Trạng thái không hợp lệ');
    }
    return status;
  }
}