import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:online_car_marketplace_app/models/car_type_model.dart';

class CarTypeRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> addCarType(CarType carType) async {
    await _firestore.doc('car_types/${carType.id}').set(carType.toMap());
  }

  // Thêm carType với ID tự động tăng
  Future<void> addCarTypeAutoIncrement(CarType carType) async {
    final snapshot = await _firestore
        .collection('car_types')
        .orderBy('id', descending: true)
        .limit(1)
        .get();

    int nextId = 1;
    if (snapshot.docs.isNotEmpty) {
      final lastBrand = CarType.fromMap(snapshot.docs.first.data());
      nextId = lastBrand.id + 1;
    }

    final newCarType = CarType(
      id: nextId,
      name: carType.name,
    );

    await _firestore
        .collection('car_types')
        .doc(newCarType.id.toString())
        .set(newCarType.toMap());
  }


  Future<List<CarType>> getCarTypes() async {
    final snapshot = await _firestore.collection('car_types').get();
    return snapshot.docs.map((doc) => CarType.fromMap(doc.data())).toList();
  }
}
