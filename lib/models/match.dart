import 'package:cloud_firestore/cloud_firestore.dart';

class Match {
  final String id;
  final String user1Id;
  final String user2Id;
  final DateTime timestamp;
  final String type; // 'individual' or 'group'
  final List<String> members; // UIDs of all members in the match

  Match({
    required this.id,
    required this.user1Id,
    required this.user2Id,
    required this.timestamp,
    this.type = 'individual',
    this.members = const [],
  });

  factory Match.fromMap(Map<String, dynamic> data, String id) {
    return Match(
      id: id,
      user1Id: data['user1Id'],
      user2Id: data['user2Id'],
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      type: data['type'] ?? 'individual',
      members: List<String>.from(data['members'] ?? []), // Ensure members is a list
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'user1Id': user1Id,
      'user2Id': user2Id,
      'timestamp': timestamp,
      'type': type,
      'members': members,
    };
  }
}