import 'package:cloud_firestore/cloud_firestore.dart';

// lib/models/message.dart
class Message {
  final String senderId;
  // receiverId is no longer necessary, as the chat room itself defines the participants
  final String content;
  final Timestamp timestamp;

  Message({
    required this.senderId,
    required this.content,
    required this.timestamp,
  });

  factory Message.fromMap(Map<String, dynamic> data) {
    return Message(
      senderId: data['senderId'] ?? '',
      content:
          data['content'] ?? data['message'] ?? '', // Handle old 'message' key
      timestamp: data['timestamp'] ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {'senderId': senderId, 'content': content, 'timestamp': timestamp};
  }
}
