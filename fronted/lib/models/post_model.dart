import 'package:cloud_firestore/cloud_firestore.dart';

class Post {
  final int id;
  final String? userId;
  final int carId;
  final String title;
  final String description;
  final DateTime creationDate;

  Post({
    required this.id,
    required this.userId,
    required this.carId,
    required this.title,
    required this.description,
    required this.creationDate,
  });

  factory Post.fromMap(Map<String, dynamic> map) {
    // Logic xử lý creationDate linh hoạt
    dynamic rawCreationDate = map['creationDate'];
    DateTime parsedCreationDate;

    if (rawCreationDate is Timestamp) {
      // Nếu dữ liệu từ Firestore (Timestamp)
      parsedCreationDate = rawCreationDate.toDate();
    } else if (rawCreationDate is String) {
      // Nếu dữ liệu từ Django API (String ISO 8601)
      parsedCreationDate = DateTime.parse(rawCreationDate);
    } else {
      // Xử lý trường hợp không mong muốn hoặc giá trị null
      // Bạn có thể chọn trả về một DateTime mặc định, ném lỗi, hoặc null
      // Tốt nhất là in một cảnh báo để debug
      print('Warning: Unexpected type for creationDate: ${rawCreationDate.runtimeType}');
      // Fallback: có thể là DateTime.now() hoặc ném lỗi tùy thuộc vào yêu cầu của bạn
      parsedCreationDate = DateTime.now(); // Ví dụ: giá trị mặc định
    }
    return Post(
      id: map['id'] as int,
      userId: map['userId'] as String?,
      carId: map['carId'] as int,
      title: map['title'] as String,
      description: map['description'] as String,
      creationDate: parsedCreationDate,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'userId': userId,
    'carId': carId,
    'title': title,
    'description': description,
    'creationDate': Timestamp.fromDate(creationDate),
  };
}