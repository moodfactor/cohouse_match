// lib/services/notification_service.dart
import 'package:cohouse_match/screens/matches_screen.dart';
import 'package:cohouse_match/screens/messages_screen.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cohouse_match/services/database_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cohouse_match/main.dart';
import 'package:flutter/material.dart' show MaterialPageRoute, BuildContext;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cohouse_match/screens/chat_screen.dart';

class NotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> initNotifications() async {
    // Request permission from the user (will prompt on iOS)
    await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Initialize flutter_local_notifications
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    final DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
      onDidReceiveLocalNotification: (id, title, body, payload) async {},
    );
    final InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );
    await _flutterLocalNotificationsPlugin.initialize(initializationSettings,
        onDidReceiveNotificationResponse: (details) async {
      if (details.payload != null) {
        _handleNotificationNavigation(details.payload!);
      }
    });

    // Get the device token
    final token = await _fcm.getToken();
    print("FCM Token: $token"); // For testing
    // Save the initial token to the database
    if (token != null) {
      saveTokenToDatabase(FirebaseAuth.instance.currentUser?.uid ?? '');
    }

    // Listen for token refreshes
    _fcm.onTokenRefresh.listen((newToken) {
      print("FCM Token refreshed: $newToken");
      saveTokenToDatabase(FirebaseAuth.instance.currentUser?.uid ?? '');
    });
    
    // Handle notifications when the app is in the foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Got a message whilst in the foreground!');
      print('Message data: ${message.data}');

      if (message.notification != null) {
        print('Message also contained a notification: ${message.notification}');
        _showLocalNotification(message);
      }
    });

    // Handle notifications when the app is in the background or terminated
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('A new onMessageOpenedApp event was published!');
      _handleNotificationNavigation(message.data['chatRoomId']);
    });
  }

  void _showLocalNotification(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;

    _flutterLocalNotificationsPlugin.show(
      notification.hashCode,
      notification.title,
      notification.body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'high_importance_channel', // id
          'High Importance Notifications', // title
          channelDescription: 'This channel is used for important notifications.',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
      payload: message.data['chatRoomId'], // Pass chatRoomId as payload
    );
  }

  void _handleNotificationNavigation(String? chatRoomId) {
    final currentState = navigatorKey.currentState;

    if (currentState == null) return;

    if (chatRoomId != null && chatRoomId.isNotEmpty) {
      // Navigate to the specific chat screen
      currentState.push(MaterialPageRoute(builder: (_) => ChatScreen(chatRoomId: chatRoomId, chatTitle: '', memberIds: [])));
    } else {
      // This is a match notification. Navigate to the MatchesScreen.
      currentState.push(MaterialPageRoute(builder: (_) => MatchesScreen()));
    }
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

  /// Removes the FCM device token from the current user's document.
  Future<void> removeTokenFromDatabase(String userId) async {
    if (userId.isEmpty) return;

    String? token = await _fcm.getToken();

    if (token != null) {
      await DatabaseService(uid: userId).userCollection.doc(userId).update({
        'fcmTokens': FieldValue.arrayRemove([token])
      });
    }
  }
}