import 'dart:async';
import 'package:cohouse_match/models/user.dart'; // Import UserData for the typing stream
import 'package:firebase_database/firebase_database.dart';

class PresenceService {
  // Now that `flutterfire configure` has been run, the default instance
  // will correctly point to your regional database. This is cleaner.
  final FirebaseDatabase _rtdb = FirebaseDatabase.instance;

  /// Sets the user's status to online in the Realtime Database.
  void setUserOnline(String uid) {
    final userStatusRef = _rtdb.ref('status/$uid');
    
    final status = {
      'isOnline': true,
      'lastSeen': ServerValue.timestamp,
    };
    
    userStatusRef.set(status);
    userStatusRef.onDisconnect().set({
      'isOnline': false,
      'lastSeen': ServerValue.timestamp,
    });
  }

  /// Manually sets the user's status to offline.
  void setUserOffline(String uid) {
    _rtdb.ref('status/$uid').update({
      'isOnline': false,
      'lastSeen': ServerValue.timestamp,
    });
  }

  /// Returns a stream of a user's online status.
  Stream<bool> getPresenceStream(String uid) {
    return _rtdb.ref('status/$uid/isOnline').onValue.map((event) {
      return event.snapshot.value as bool? ?? false;
    });
  }

  // --- METHODS FOR TYPING INDICATOR ---

  /// Sets the current user's typing status for a specific chat room.
  void setUserTyping(String chatRoomId, String uid, bool isTyping) {
    _rtdb.ref('typing_status/$chatRoomId/$uid').set(isTyping);
  }

  /// Returns a stream of typing statuses for all members of a chat,
  /// except for the current user.
  Stream<List<String>> getTypingStream(String chatRoomId, String currentUid, Map<String, UserData> memberData) {
    final chatTypingRef = _rtdb.ref('typing_status/$chatRoomId');

    return chatTypingRef.onValue.map((event) {
      final List<String> typingNames = [];
      if (event.snapshot.value != null) {
        final data = Map<String, dynamic>.from(event.snapshot.value as Map);
        
        data.forEach((uid, isTyping) {
          if (isTyping == true && uid != currentUid) {
            final name = memberData[uid]?.name ?? 'Someone';
            typingNames.add(name);
          }
        });
      }
      return typingNames;
    });
  }
}