import 'package:online_car_marketplace_app/models/post_model.dart';
import 'package:online_car_marketplace_app/models/car_model.dart';

import 'brand_model.dart';
import 'model_model.dart';

class PostWithCarAndImages {
  final Post post;
  final Car? car;
  final List<String> imageUrls;
  final String? sellerName;
  final String? sellerPhone;
  final String? sellerAddress;
  final String? carLocation;
  final String? carModelName;
  final Brand? brand;

  PostWithCarAndImages({
    required this.post,
    required this.car,
    required this.imageUrls,
    this.sellerName,
    this.sellerPhone,
    this.sellerAddress,
    this.carLocation,
    this.carModelName,
    this.brand,
  });

  factory PostWithCarAndImages.fromJson(Map<String, dynamic> map) {
    // Để đọc carModelName, bạn cần parse carModel object trước
    final carModelData = map['carModel'] as Map<String, dynamic>?;
    final carModel = carModelData != null ? CarModel.fromMap(carModelData) : null;

    return PostWithCarAndImages(
      post: Post.fromMap(map['post'] as Map<String, dynamic>),
      car: map['car'] != null ? Car.fromMap(map['car'] as Map<String, dynamic>) : null,
      imageUrls: (map['imageUrls'] as List<dynamic>?)?.cast<String>() ?? [],
      sellerName: map['sellerName'] as String?,
      sellerPhone: map['sellerPhone'] as String?,
      sellerAddress: map['sellerAddress'] as String?,
      carLocation: map['carLocation'] as String?,
      carModelName: carModel?.name,
      brand: map['brand'] != null ? Brand.fromMap(map['brand'] as Map<String, dynamic>) : null,
    );
  }
}