class PostValidator {
  static const List<String> validStatuses = ['Chờ duyệt', 'Đã duyệt', 'Từ chối'];

  static String validateStatus(String status) {
    if (!validStatuses.contains(status)) {
      throw Exception('Trạng thái bài đăng không hợp lệ');
    }
    return status;
  }

  static String get defaultStatus => 'Chờ duyệt';
}
