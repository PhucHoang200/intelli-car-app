import 'package:flutter/material.dart';
import 'package:online_car_marketplace_app/models/message_model.dart';
import 'package:online_car_marketplace_app/repositories/message_repository.dart';

class MessageProvider with ChangeNotifier {
  final MessageRepository _messageRepository = MessageRepository();
  List<Message> _messages = [];

  List<Message> get messages => _messages;

  Future<void> fetchMessages() async {
    _messages = await _messageRepository.getMessages();
    notifyListeners();
  }

  Future<void> sendMessageAutoIncrement(Message message) async {
    await _messageRepository.addMessageAutoIncrement(message);
    await fetchMessages(); // Refresh list after sending
  }

  void clearMessages() {
    _messages = [];
    notifyListeners();
  }
}
