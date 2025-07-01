// lib/services/notification_service.dart
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cohouse_match/services/database_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  Future<void> initNotifications() async {
    // Request permission from the user (will prompt on iOS)
    await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Get the device token
    final token = await _fcm.getToken();
    print("FCM Token: $token"); // For testing
    
    // TODO: Save the token to the current user's document in Firestore
  }

  /// Saves the FCM device token to the current user's document.
  Future<void> saveTokenToDatabase(String userId) async {
    if (userId.isEmpty) return;

    // Get the token for this device
    String? token = await _fcm.getToken();

    if (token != null) {
      // Add the token to a 'tokens' array field in the user's document.
      // Using an array supports multiple devices per user.
      await DatabaseService(uid: userId).userCollection.doc(userId).update({
        'fcmTokens': FieldValue.arrayUnion([token])
      });
    }
  }
}