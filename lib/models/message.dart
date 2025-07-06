import 'package:cloud_firestore/cloud_firestore.dart';

// lib/models/message.dart

enum MessageType {
  text,
  image,
  // Add other types as needed, e.g., video, audio
}

class Message {
  final String senderId;
  final String content; // For text messages
  final String? imageUrl; // For image messages
  final Timestamp timestamp;
  final MessageType messageType;

  Message({
    required this.senderId,
    this.content = '', // Default to empty string for non-text messages
    this.imageUrl,
    required this.timestamp,
    this.messageType = MessageType.text, // Default to text
  });

  factory Message.fromMap(Map<String, dynamic> data) {
    return Message(
      senderId: data['senderId'] ?? '',
      content: data['content'] ?? '',
      imageUrl: data['imageUrl'],
      timestamp: data['timestamp'] ?? Timestamp.now(),
      messageType: MessageType.values.firstWhere(
        (e) => e.toString() == 'MessageType.${data['messageType']}',
        orElse: () => MessageType.text, // Default to text if type is unknown
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'content': content,
      'imageUrl': imageUrl,
      'timestamp': timestamp,
      'messageType': messageType.toString().split('.').last, // Store as string
    };
  }
}
