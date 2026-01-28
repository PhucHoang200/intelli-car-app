import 'package:flutter/material.dart';
import 'package:online_car_marketplace_app/repositories/image_repository.dart';
import 'package:online_car_marketplace_app/models/image_model.dart';
import 'package:image_picker/image_picker.dart';

class ImageProvider extends ChangeNotifier {
  final ImageRepository _imageRepository = ImageRepository();

  // Dữ liệu ảnh của xe
  List<String> _carImages = [];
  List<String> get carImages => _carImages;

  // Tải ảnh của xe từ Firestore
  Future<void> loadCarImages(int carId) async {
    _carImages = await _imageRepository.getCarImages(carId);
    notifyListeners();
  }

  // Upload ảnh của xe lên Cloud và lưu vào Firestore
  Future<void> uploadCarImages(int carId, List<XFile> images) async {
    await _imageRepository.uploadCarImages(carId, images);
    await loadCarImages(carId); // Tải lại danh sách ảnh sau khi upload
  }

  // Thêm ảnh vào Firestore (dùng cho dữ liệu khởi tạo)
  Future<void> addImage(ImageModel image) async {
    await _imageRepository.addImage(image);
    await loadCarImages(image.carId); // Tải lại ảnh sau khi thêm
  }

  // Xóa ảnh của xe
  Future<void> deleteCarImages(int carId) async {
    await _imageRepository.deleteCarImages(carId);
    await loadCarImages(carId); // Tải lại danh sách ảnh sau khi xóa
  }
}
