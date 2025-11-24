import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:online_car_marketplace_app/models/brand_model.dart';

class BrandRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> addBrand(Brand brand) async {
    await _firestore.doc('brands/${brand.id}').set(brand.toMap());
  }

  //Thêm brand với ID tự động tăng
  Future<void> addBrandAutoIncrement(Brand brand) async {
    final snapshot = await _firestore
        .collection('brands')
        .orderBy('id', descending: true)
        .limit(1)
        .get();

    int nextId = 1;
    if (snapshot.docs.isNotEmpty) {
      final lastBrand = Brand.fromMap(snapshot.docs.first.data());
      nextId = lastBrand.id + 1;
    }

    final newBrand = Brand(
      id: nextId,
      name: brand.name,
    );

    await _firestore
        .collection('brands')
        .doc(newBrand.id.toString())
        .set(newBrand.toMap());
  }

  Future<List<Brand>> getBrands() async {
    final snapshot = await _firestore.collection('brands').get();
    return snapshot.docs.map((doc) => Brand.fromMap(doc.data())).toList();
  }
}
