// lib/models/review.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Review {
  final String id;
  final String authorId;
  final String authorName; // Denormalize for easy display
  final String content;
  final double rating; // e.g., 1.0 to 5.0
  final Timestamp timestamp;

  Review({
    required this.id,
    required this.authorId,
    required this.authorName,
    required this.content,
    required this.rating,
    required this.timestamp,
  });

  factory Review.fromMap(Map<String, dynamic> data, String id) {
    return Review(
      id: id,
      authorId: data['authorId'],
      authorName: data['authorName'],
      content: data['content'],
      rating: (data['rating'] as num).toDouble(),
      timestamp: data['timestamp'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'authorId': authorId,
      'authorName': authorName,
      'content': content,
      'rating': rating,
      'timestamp': timestamp,
    };
  }
}