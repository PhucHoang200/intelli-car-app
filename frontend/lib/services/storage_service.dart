import 'dart:io';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class StorageService {
  final cloudinary = CloudinaryPublic('doohwusyf', 'car_image', cache: false);
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String> uploadImage(XFile image) async {
    try {
      final response = await cloudinary.uploadFile(
        CloudinaryFile.fromFile(image.path, resourceType: CloudinaryResourceType.Image),
      );
      return response.secureUrl; // URL của ảnh trên Cloudinary
    } catch (e) {
      throw Exception('Error uploading image: $e');
    }
  }

  Future<void> deleteImage(String imageUrl) async {
    try {
      // Reference from URL
      Reference ref = _storage.refFromURL(imageUrl);
      await ref.delete();
      print('Image deleted successfully from Storage: $imageUrl');
    } catch (e) {
      print('Error deleting image from Storage: $e');
      // Tùy chọn: ném lại lỗi nếu bạn muốn xử lý nó ở cấp cao hơn
      // rethrow;
    }
  }
  // Sửa hàm uploadImage để nhận thêm tham số carId
  Future<String?> uploadImageForUpdate(XFile imageFile, int carId) async { // <-- THAY ĐỔI Ở ĐÂY
    try {
      // Tạo tên file duy nhất dựa trên thời gian
      final String fileName = '${DateTime.now().millisecondsSinceEpoch}_${imageFile.name}';
      // Tạo đường dẫn lưu trữ trên Firebase Storage, ví dụ: 'cars/123/image_name.jpg'
      final String path = 'cars/$carId/$fileName'; // <-- SỬ DỤNG carId Ở ĐÂY

      UploadTask uploadTask = _storage.ref().child(path).putFile(File(imageFile.path));
      TaskSnapshot snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }

}