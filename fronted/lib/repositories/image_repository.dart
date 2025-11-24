import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:online_car_marketplace_app/services/storage_service.dart';
import 'package:online_car_marketplace_app/models/image_model.dart';

class ImageRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final StorageService _storageService = StorageService();

  // Upload ảnh lên Cloudinary và lưu URL vào Firestore
  Future<void> uploadCarImages(int carId, List<XFile> images) async {
    for (var image in images) {
      // Upload ảnh lên Cloudinary
      final imageUrl = await _storageService.uploadImage(image);
      // Lưu URL vào Firestore
      await _firestore.collection('images').add({
        'carId': carId,
        'url': imageUrl,
        'creationDate': Timestamp.now(),
      });
    }
  }

  // Thêm ảnh vào Firestore (dùng cho dữ liệu khởi tạo)
  Future<void> addImage(ImageModel image) async {
    await _firestore.doc('images/${image.id}').set(image.toMap());
  }

  // Thêm ảnh vào Firestore với ID tự động tăng
  Future<void> addImageAutoIncrement(ImageModel image) async {
    // Lấy ảnh cuối cùng theo ID giảm dần
    final snapshot = await _firestore
        .collection('images')
        .orderBy('id', descending: true)
        .limit(1)
        .get();

    int nextId = 1;
    if (snapshot.docs.isNotEmpty) {
      final lastImage = ImageModel.fromMap(snapshot.docs.first.data());
      nextId = lastImage.id + 1;
    }

    final newImage = ImageModel(
      id: nextId,
      carId: image.carId,
      url: image.url,
      creationDate: image.creationDate,
    );

    await _firestore
        .collection('images')
        .doc(newImage.id.toString())
        .set(newImage.toMap());
  }

  // Lấy danh sách URL ảnh của xe
  Future<List<String>> getCarImages(int carId) async {
    final snapshot = await _firestore
        .collection('images')
        .where('carId', isEqualTo: carId)
        .get();
    return snapshot.docs.map((doc) => doc['url'] as String).toList();
  }

  Future<void> deleteCarImages(int carId) async {
    final snapshot = await _firestore
        .collection('images')
        .where('carId', isEqualTo: carId)
        .get();
    for (var doc in snapshot.docs) {
      await doc.reference.delete();
    }
  }

  Future<List<ImageModel>> getImagesByCarId(int carId) async {
    final snapshot = await _firestore
        .collection('images')
        .where('carId', isEqualTo: carId)
        .get();
    return snapshot.docs.map((doc) => ImageModel.fromMap(doc.data())).toList();
  }

  Future<void> deleteImagesByCarId(int carId) async {
    final snapshot = await _firestore
        .collection('images')
        .where('carId', isEqualTo: carId)
        .get();
    for (var doc in snapshot.docs) {
      await doc.reference.delete();
    }
  }

  Future<void> deleteImageByUrl(String imageUrl) async {
    final snapshot = await _firestore
        .collection('images')
        .where('url', isEqualTo: imageUrl)
        .limit(1) // Assuming URL is unique per image entry for simplicity
        .get();
    if (snapshot.docs.isNotEmpty) {
      await snapshot.docs.first.reference.delete();
    }
  }

  Future<void> updateImage(ImageModel image) async {
    await _firestore.collection('images').doc(image.id.toString()).update(image.toMap());
  }
}
