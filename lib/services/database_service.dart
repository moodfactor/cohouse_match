import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cohouse_match/models/user.dart';
import 'package:cohouse_match/models/message.dart';
import 'package:cohouse_match/models/match.dart';
import 'package:rxdart/rxdart.dart';

class DatabaseService {
  final String? uid;
  DatabaseService({this.uid});

  // collection reference
  final CollectionReference userCollection =
      FirebaseFirestore.instance.collection('users');
  final CollectionReference messagesCollection =
      FirebaseFirestore.instance.collection('messages');
  final CollectionReference matchesCollection =
      FirebaseFirestore.instance.collection('matches');

  Future<void> updateUserData(
      String email,
      String? name,
      String? bio,
      String? photoUrl,
      List<String>? personalityTags,
      List<String>? lifestyleDetails,
      double? budget,
      String? location,
      String? gender,
      int? age) async {
    return await userCollection.doc(uid).set({
      'email': email,
      'name': name,
      'bio': bio,
      'photoUrl': photoUrl,
      'personalityTags': personalityTags,
      'lifestyleDetails': lifestyleDetails,
      'budget': budget,
      'location': location,
      'gender': gender,
      'age': age,
    }, SetOptions(merge: true));
  }

  // user data from snapshots
  UserData? _userDataFromSnapshot(DocumentSnapshot snapshot) {
    if (!snapshot.exists || snapshot.data() == null) {
      return null;
    }
    Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
    return UserData(
      uid: uid!,
      email: data['email'] ?? '',
      name: data['name'],
      bio: data['bio'],
      photoUrl: data['photoUrl'],
      personalityTags: data['personalityTags'] != null
          ? List<String>.from(data['personalityTags'])
          : null,
      lifestyleDetails: data['lifestyleDetails'] != null
          ? List<String>.from(data['lifestyleDetails'])
          : null,
      budget: data['budget']?.toDouble(),
      location: data['location'],
    );
  }

  // get user doc stream for the current uid
  Stream<UserData?> get userData {
    return userCollection.doc(uid).snapshots().map(_userDataFromSnapshot);
  }

  // get user doc stream for a specific uid
  Stream<UserData?> userDataFromUid(String targetUid) {
    return userCollection.doc(targetUid).snapshots().map((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) {
        return null;
      }
      Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
      return UserData(
        uid: targetUid,
        email: data['email'] ?? '',
        name: data['name'],
        bio: data['bio'],
        photoUrl: data['photoUrl'],
        personalityTags: data['personalityTags'] != null
            ? List<String>.from(data['personalityTags'])
            : null,
        lifestyleDetails: data['lifestyleDetails'] != null
            ? List<String>.from(data['lifestyleDetails'])
            : null,
        budget: data['budget']?.toDouble(),
        location: data['location'],
        gender: data['gender'],
        age: data['age'],
      );
    });
  }

  // Send message
  Future<void> sendMessage(String senderId, String receiverId, String message) async {
    // Create a chat room ID from the two user IDs (sorted to ensure consistency)
    List<String> ids = [senderId, receiverId];
    ids.sort();
    String chatRoomId = ids.join('_');

    await messagesCollection.doc(chatRoomId).collection('chats').add({
      'senderId': senderId,
      'receiverId': receiverId,
      'message': message,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  // Get messages
  Stream<List<Message>> getMessages(String userId1, String userId2) {
    List<String> ids = [userId1, userId2];
    ids.sort();
    String chatRoomId = ids.join('_');

    return messagesCollection
        .doc(chatRoomId)
        .collection('chats')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Message.fromMap(doc.data())).toList();
    });
  }

  // Create a match
  Future<void> createMatch(String user1Id, String user2Id, {List<String>? groupMembers}) async {
    // Ensure unique match document ID by sorting user IDs
    List<String> ids = [user1Id, user2Id];
    String matchType = 'individual';
    List<String> members = [];

    if (groupMembers != null && groupMembers.length > 2) {
      ids = groupMembers..sort();
      matchType = 'group';
      members = groupMembers;
    } else {
      ids.sort();
      members = [user1Id, user2Id];
    }

    String matchId = ids.join('_');

    await matchesCollection.doc(matchId).set({
      'user1Id': user1Id,
      'user2Id': user2Id,
      'timestamp': FieldValue.serverTimestamp(),
      'type': matchType,
      'members': members,
    });
  }

  // Get matches for a user
  Stream<List<Match>> getMatches(String userId) {
    Stream<List<Match>> matchesAsUser1 = matchesCollection
        .where('user1Id', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Match.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    });
    Stream<List<Match>> matchesAsUser2 = matchesCollection
        .where('user2Id', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Match.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    });
    Stream<List<Match>> matchesAsMember = matchesCollection
        .where('members', arrayContains: userId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Match.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    });
    return Rx.merge<List<Match>>([matchesAsUser1, matchesAsUser2, matchesAsMember]);
  }

  // Get all users
  Stream<List<UserData>> get users {
    return userCollection.snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => UserData.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList());
  }
}