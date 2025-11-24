import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:online_car_marketplace_app/models/favorite_model.dart';

class FavoriteRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> addFavorite(Favorite favorite) async {
    await _firestore.doc('favorites/${favorite.id}').set(favorite.toMap());
  }

  // Thêm favorite với ID tự động tăng
  Future<void> addFavoriteAutoIncrement(Favorite favorite) async {
    final snapshot = await _firestore
        .collection('favorites')
        .orderBy('id', descending: true)
        .limit(1)
        .get();

    int nextId = 1;
    if (snapshot.docs.isNotEmpty) {
      final lastBrand = Favorite.fromMap(snapshot.docs.first.data());
      nextId = lastBrand.id + 1;
    }

    final newFavorite = Favorite(
      id: nextId,
      userId: favorite.userId,
      postId: favorite.postId,
    );

    await _firestore
        .collection('favorites')
        .doc(newFavorite.id.toString())
        .set(newFavorite.toMap());
  }

  Future<List<Favorite>> getFavorites() async {
    final snapshot = await _firestore.collection('favorites').get();
    return snapshot.docs.map((doc) => Favorite.fromMap(doc.data())).toList();
  }

  // Lấy danh sách các mục yêu thích của một người dùng cụ thể
  Future<List<Favorite>> getFavoritesByUserId(String userId) async {
    final snapshot = await _firestore
        .collection('favorites')
        .where('userId', isEqualTo: userId)
        .get();
    return snapshot.docs.map((doc) => Favorite.fromMap(doc.data())).toList();
  }

  Future<void> removeFavorite(String userId, int postId) async {
    final snapshot = await _firestore
        .collection('favorites')
        .where('userId', isEqualTo: userId)
        .where('postId', isEqualTo: postId)
        .get();

    for (var doc in snapshot.docs) {
      await _firestore.collection('favorites').doc(doc.id).delete();
      return;
    }
  }

  Future<List<Favorite>> getFavoritesByUserIdAndPostId(String userId, int postId) async {
    final snapshot = await _firestore
        .collection('favorites')
        .where('userId', isEqualTo: userId)
        .where('postId', isEqualTo: postId)
        .get();
    return snapshot.docs.map((doc) => Favorite.fromMap(doc.data())).toList();
  }
}
