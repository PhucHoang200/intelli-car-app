import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:online_car_marketplace_app/models/role_model.dart';

class RoleRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> addRole(Role role) async {
    await _firestore.doc('roles/${role.id}').set(role.toMap());
  }

  // Thêm role với ID tự động tăng
  Future<void> addBrandAutoIncrement(Role role) async {
    final snapshot = await _firestore
        .collection('roles')
        .orderBy('id', descending: true)
        .limit(1)
        .get();

    int nextId = 1;
    if (snapshot.docs.isNotEmpty) {
      final lastBrand = Role.fromMap(snapshot.docs.first.data());
      nextId = lastBrand.id + 1;
    }

    final newBrand = Role(
      id: nextId,
      name: role.name,
    );

    await _firestore
        .collection('roles')
        .doc(newBrand.id.toString())
        .set(newBrand.toMap());
  }

  Future<List<Role>> getRoles() async {
    final snapshot = await _firestore.collection('roles').get();
    return snapshot.docs.map((doc) => Role.fromMap(doc.data())).toList();
  }
}