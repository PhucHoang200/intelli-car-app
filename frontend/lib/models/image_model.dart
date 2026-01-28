import 'package:cloud_firestore/cloud_firestore.dart';

class ImageModel {
  final int id;
  final int carId;
  final String url;
  final Timestamp creationDate;

  ImageModel({
    required this.id,
    required this.carId,
    required this.url,
    required this.creationDate,
  });

  factory ImageModel.fromMap(Map<String, dynamic> map) {
    return ImageModel(
      id: map['id'] as int,
      carId: map['carId'] as int,
      url: map['url'] as String,
      creationDate: map['creationDate'] as Timestamp,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'carId': carId,
    'url': url,
    'creationDate': creationDate,
  };
}