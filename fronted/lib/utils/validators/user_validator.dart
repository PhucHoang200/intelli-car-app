
class UserValidator {
  static String validateName(String name) {
    if (name.isEmpty || name.length < 1 || name.length > 50) {
      throw Exception('Tên tài khoản không hợp lệ');
    }
    return name;
  }

  static String validateStatus(String status) {
    const allowedStatuses = ['Hoạt động', 'Khóa'];
    if (!allowedStatuses.contains(status)) {
      throw Exception('Trạng thái không hợp lệ');
    }
    return status;
  }

}
