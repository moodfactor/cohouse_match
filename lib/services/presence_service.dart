
// lib/services/presence_service.dart
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_core/firebase_core.dart'; // Import firebase_core

class PresenceService {
  final FirebaseDatabase _rtdb = FirebaseDatabase.instanceFor(
    app: Firebase.app(), // Use the default Firebase app
    databaseURL: 'https://cohousematch-default-rtdb.europe-west1.firebasedatabase.app', // Specify your regional database URL
  );

  /// Sets the user's status to online in the Realtime Database.
  /// Also sets up the `onDisconnect` hook to mark the user as offline
  /// when the app is closed or connection is lost.
  void setUserOnline(String uid) {
    print('Setting user $uid online');
    final userStatusRef = _rtdb.ref('status/$uid');

    userStatusRef.set({
      'isOnline': true,
      'lastSeen': ServerValue.timestamp,
    }).then((_) {
      print('User $uid set online successfully in RTDB');
    }).catchError((error) {
      print('Error setting user $uid online in RTDB: $error');
    });

    // Set the onDisconnect hook to set isOnline to false when the user disconnects
    userStatusRef.onDisconnect().update({
      'isOnline': false,
      'lastSeen': ServerValue.timestamp,
    }).then((_) {
      print('onDisconnect for user $uid set successfully in RTDB');
    }).catchError((error) {
      print('Error setting onDisconnect for user $uid in RTDB: $error');
    });
  }

  /// Manually sets the user's status to offline.
  /// Useful for when the app is paused but not fully disconnected.
  void setUserOffline(String uid) {
    print('Setting user $uid offline');
    _rtdb.ref('status/$uid').update({
      'isOnline': false,
      'lastSeen': ServerValue.timestamp,
    }).then((_) {
      print('User $uid set offline successfully in RTDB');
    }).catchError((error) {
      print('Error setting user $uid offline in RTDB: $error');
    });
  }

  /// Returns a stream of a user's online status.
  /// The stream will emit `true` if the user is online, and `false` otherwise.
  Stream<bool> getPresenceStream(String uid) {
    print('Listening to presence stream for user $uid');
    return _rtdb.ref('status/$uid/isOnline').onValue.map((event) {
      final isOnline = event.snapshot.value as bool? ?? false;
      print('Presence stream for user $uid emitted: $isOnline');
      return isOnline;
    });
  }
}