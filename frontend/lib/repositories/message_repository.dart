import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:online_car_marketplace_app/models/message_model.dart';

class MessageRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> addMessage(Message message) async {
    await _firestore.doc('messages/${message.id}').set(message.toMap());
  }

  Future<void> addMessageAutoIncrement(Message message) async {
    final snapshot = await _firestore
        .collection('messages')
        .orderBy('id', descending: true)
        .limit(1)
        .get();

    int nextId = 1;
    if (snapshot.docs.isNotEmpty) {
      final lastMessage = Message.fromMap(snapshot.docs.first.data());
      nextId = lastMessage.id + 1;
    }

    final newMessage = Message(
      id: nextId,
      senderId: message.senderId,
      receiverId: message.receiverId,
      content: message.content,
      sentAt: message.sentAt,
    );

    await _firestore
        .collection('messages')
        .doc(newMessage.id.toString())
        .set(newMessage.toMap());
  }

  Future<List<Message>> getMessages() async {
    final snapshot = await _firestore.collection('messages').get();
    return snapshot.docs.map((doc) => Message.fromMap(doc.data())).toList();
  }
}