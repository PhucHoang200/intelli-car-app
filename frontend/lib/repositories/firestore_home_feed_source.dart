import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:online_car_marketplace_app/models/post_model.dart';
import 'home_feed_loader.dart';

class FirestoreHomeFeedSource implements HomeFeedSource {
  FirestoreHomeFeedSource(this.firestore);
  final FirebaseFirestore firestore;

  @override
  Future<HomePostSlice> readPosts({int? limit, String? after}) async {
    // Same document-ID ordering as the old unfiltered collection query. This
    // does not require every legacy document to have a sortable creationDate.
    Query<Map<String, dynamic>> query =
        firestore.collection('posts').orderBy(FieldPath.documentId);
    if (after != null) query = query.startAfter([after]);
    if (limit != null) query = query.limit(limit + 1);
    final snapshot = await query.get();
    final docs =
        limit == null ? snapshot.docs : snapshot.docs.take(limit).toList();
    return HomePostSlice(docs.map((doc) => Post.fromMap(doc.data())).toList(),
        cursor: docs.isEmpty ? after : docs.last.id,
        hasMore: limit != null && snapshot.docs.length > limit);
  }

  @override
  Future<Map<String, dynamic>?> readCar(int id) async =>
      (await firestore.collection('cars').doc('$id').get()).data();
  @override
  Future<Map<String, dynamic>?> readModel(int id) async =>
      (await firestore.collection('models').doc('$id').get()).data();
  @override
  Future<Map<String, dynamic>?> readUser(String id) async =>
      (await firestore.collection('users').doc(id).get()).data();
  @override
  Future<List<String>> readImages(int carId) async => (await firestore
          .collection('images')
          .where('carId', isEqualTo: carId)
          .get())
      .docs
      .map((doc) => doc['url'] as String)
      .toList();
}
