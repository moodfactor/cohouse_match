import 'package:cloud_firestore/cloud_firestore.dart';

class Match {
  final String id;
  final String user1Id;
  final String user2Id;
  final DateTime timestamp;

  Match({
    required this.id,
    required this.user1Id,
    required this.user2Id,
    required this.timestamp,
  });

  factory Match.fromMap(Map<String, dynamic> data, String id) {
    return Match(
      id: id,
      user1Id: data['user1Id'],
      user2Id: data['user2Id'],
      timestamp: (data['timestamp'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'user1Id': user1Id,
      'user2Id': user2Id,
      'timestamp': timestamp,
    };
  }
}