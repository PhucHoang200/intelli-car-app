import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:online_car_marketplace_app/models/car_model.dart';
import 'package:online_car_marketplace_app/models/post_model.dart';

void main() {
  final date = DateTime.utc(2026, 1, 2, 3, 4, 5);
  Map<String, dynamic> postData(Object creationDate) => {
        'id': 1,
        'userId': 'seller-1',
        'carId': 7,
        'title': 'Test car',
        'description': 'Test description',
        'creationDate': creationDate,
      };
  Map<String, dynamic> carData(num price) => {
        'id': 7,
        'userId': 'seller-1',
        'modelId': 2,
        'fuelType': 'Xăng',
        'transmission': 'Tự động',
        'year': 2020,
        'mileage': 10000,
        'location': 'Hà Nội',
        'price': price,
        'condition': 'Xe cũ',
        'origin': 'Trong nước',
      };
  test('car preserves all fields through map conversion', () {
    final data = carData(250000000.5);
    expect(Car.fromMap(data).toMap(), data);
  });
  test('car accepts integer API price as double', () {
    expect(Car.fromMap(carData(250000000)).price, 250000000.0);
  });
  test('car preserves nullable seller', () {
    final data = carData(1)..['userId'] = null;
    expect(Car.fromMap(data).toMap()['userId'], isNull);
  });
  test('car rejects nonnumeric price instead of silently coercing', () {
    final data = carData(1)..['price'] = 'invalid';
    expect(() => Car.fromMap(data), throwsA(isA<TypeError>()));
  });
  test('post reads Firestore timestamp and preserves complete record', () {
    final data = postData(Timestamp.fromDate(date));
    final post = Post.fromMap(data);
    expect(post.creationDate.isAtSameMomentAs(date), isTrue);
    expect(post.toMap(), data);
  });
  test('post reads API timestamp with timezone offset', () {
    final post = Post.fromMap(postData('2026-01-02T10:04:05+07:00'));
    expect(post.creationDate.isAtSameMomentAs(date), isTrue);
  });
  test('post rejects malformed date string', () {
    expect(() => Post.fromMap(postData('invalid')), throwsFormatException);
  });
  test('post preserves nullable seller', () {
    final data = postData(Timestamp.fromDate(date))..['userId'] = null;
    expect(Post.fromMap(data).toMap()['userId'], isNull);
  });
}
