import 'package:cloud_firestore/cloud_firestore.dart';

class Message {
  final int id;
  final int senderId;
  final int receiverId;
  final String content;
  final Timestamp sentAt;

  Message({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.content,
    required this.sentAt,
  });

  factory Message.fromMap(Map<String, dynamic> map) {
    return Message(
      id: map['id'] as int,
      senderId: map['senderId'] as int,
      receiverId: map['receiverId'] as int,
      content: map['content'] as String,
      sentAt: map['sentAt'] as Timestamp,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'senderId': senderId,
    'receiverId': receiverId,
    'content': content,
    'sentAt': sentAt,
  };
}