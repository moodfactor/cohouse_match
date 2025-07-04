
// lib/services/presence_service.dart
import 'package:firebase_database/firebase_database.dart';

class PresenceService {
  final FirebaseDatabase _rtdb = FirebaseDatabase.instance;
  
  /// Sets the user's status to online in the Realtime Database.
  /// Also sets up the `onDisconnect` hook to mark the user as offline
  /// when the app is closed or connection is lost.
  void setUserOnline(String uid) {
    final status = {
      'isOnline': true,
      'lastSeen': ServerValue.timestamp,
    };
    // The path to this user's status in the database
    final userStatusRef = _rtdb.ref('status/$uid');
    
    // Set the user's status to online
    userStatusRef.set(status);
    
    // Set the onDisconnect hook
    userStatusRef.onDisconnect().set({
      'isOnline': false,
      'lastSeen': ServerValue.timestamp,
    });
  }

  /// Manually sets the user's status to offline.
  /// Useful for when the app is paused but not fully disconnected.
  void setUserOffline(String uid) {
    final status = {
      'isOnline': false,
      'lastSeen': ServerValue.timestamp,
    };
    _rtdb.ref('status/$uid').set(status);
  }

  /// Returns a stream of a user's online status.
  /// The stream will emit `true` if the user is online, and `false` otherwise.
  Stream<bool> getPresenceStream(String uid) {
    return _rtdb.ref('status/$uid/isOnline').onValue.map((event) {
      // The snapshot's value could be null if the user has never been online.
      // We default to false in that case.
      return event.snapshot.value as bool? ?? false;
    });
  }
}