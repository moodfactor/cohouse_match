import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cohouse_match/models/user.dart';
import 'package:cohouse_match/models/message.dart';
import 'package:cohouse_match/models/match.dart';
import 'package:cohouse_match/models/review.dart';

class DatabaseService {
  final String? uid;
  DatabaseService({this.uid});

  // collection reference
  final CollectionReference userCollection = FirebaseFirestore.instance
      .collection('users');
  final CollectionReference messagesCollection = FirebaseFirestore.instance
      .collection('messages');
  final CollectionReference matchesCollection = FirebaseFirestore.instance
      .collection('matches');

  // Add a review for a user
  Future<void> addReview(String targetUserId, Review review) async {
    // A review document is created inside the 'reviews' subcollection of the target user
    await userCollection
        .doc(targetUserId)
        .collection('reviews')
        .add(review.toMap());
  }

  // Get all reviews for a user
  Stream<List<Review>> getReviews(String targetUserId) {
    return userCollection
        .doc(targetUserId)
        .collection('reviews')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Review.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

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
    int? age,
  ) async {
    // Create a base map with email which is required
    Map<String, dynamic> userData = {'email': email};

    // Add other fields only if they're not null
    if (name != null) userData['name'] = name;
    if (bio != null) userData['bio'] = bio;
    if (photoUrl != null) userData['photoUrl'] = photoUrl;
    if (personalityTags != null) userData['personalityTags'] = personalityTags;
    if (lifestyleDetails != null) {
      userData['lifestyleDetails'] = lifestyleDetails;
    }
    if (budget != null) userData['budget'] = budget;
    if (location != null) userData['location'] = location;
    if (gender != null) userData['gender'] = gender;
    if (age != null) userData['age'] = age;

    return await userCollection.doc(uid).set(userData, SetOptions(merge: true));
  }

  // user data from snapshots
  UserData? _userDataFromSnapshot(DocumentSnapshot snapshot) {
    if (!snapshot.exists || snapshot.data() == null) {
      return null;
    }
    Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
    // FIX: Pass the entire map and the uid to the factory constructor.
    return UserData.fromMap(data, uid!);
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
      return UserData.fromMap(data, targetUid); // Pass the full map and uid
    });
  }

  // NEW: Send message in any chat room (individual or group)
  Future<void> sendMessageInChat(
    String chatRoomId,
    String senderId,
    String content,
  ) async {
    await messagesCollection.doc(chatRoomId).collection('chats').add({
      'senderId': senderId,
      'content': content,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  // Get messages
  Stream<List<Message>> getMessages(String chatRoomId) {
    return messagesCollection
        .doc(chatRoomId)
        .collection('chats')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => Message.fromMap(doc.data()))
              .toList();
        });
  }

  // Create a match
  Future<void> createMatch(
    String user1Id,
    String user2Id, {
    List<String>? groupMembers,
  }) async {
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
    }, SetOptions(merge: true)); // Use merge to be safe
  }

  // Get matches for a user
  Stream<List<Match>> getMatches(String userId) {
    // This query is more robust for finding all matches a user is a part of.
    return matchesCollection
        .where('members', arrayContains: userId)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map(
                (doc) =>
                    Match.fromMap(doc.data() as Map<String, dynamic>, doc.id),
              )
              .toList();
        });
  }

  // Get all users
  Stream<List<UserData>> get users {
    return userCollection.snapshots().map(
      (snapshot) => snapshot.docs
          .map(
            (doc) =>
                UserData.fromMap(doc.data() as Map<String, dynamic>, doc.id),
          )
          .toList(),
    );
  }

  // Get user data as a Future
  Future<Map<String, dynamic>?> getUserData() async {
    try {
      DocumentSnapshot snapshot = await userCollection.doc(uid).get();
      if (snapshot.exists) {
        return snapshot.data() as Map<String, dynamic>?;
      }
      return null;
    } catch (e) {
      print('Error getting user data: $e');
      return null;
    }
  }
}
