import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cohouse_match/models/user.dart';
import 'package:cohouse_match/models/message.dart';
import 'package:cohouse_match/models/match.dart';
import 'package:cohouse_match/models/review.dart';
import 'package:cohouse_match/services/presence_service.dart';
class DatabaseService {
  final String? uid;
  DatabaseService({this.uid});

  final CollectionReference userCollection = FirebaseFirestore.instance.collection('users');
  final CollectionReference messagesCollection = FirebaseFirestore.instance.collection('messages');
  final CollectionReference matchesCollection = FirebaseFirestore.instance.collection('matches');

  // Add a review for a user
  Future<void> addReview(String targetUserId, Review review) async {
    await userCollection.doc(targetUserId).collection('reviews').add(review.toMap());
  }

  // Get all reviews for a user
  Stream<List<Review>> getReviews(String targetUserId) {
    return userCollection.doc(targetUserId).collection('reviews').orderBy('timestamp', descending: true)
        .snapshots().map((snapshot) => snapshot.docs.map((doc) => Review.fromMap(doc.data(), doc.id)).toList());
  }

  // UPDATED METHOD for location data
  Future<void> updateUserData({
    required String email,
    String? name,
    String? bio,
    String? photoUrl,
    List<String>? personalityTags,
    List<String>? lifestyleDetails,
    double? budget,
    String? location,
    GeoPoint? coordinates, // NEW: Accept GeoPoint coordinates
    String? gender,
    int? age,
  }) async {
    Map<String, dynamic> userData = {'email': email};

    if (name != null) userData['name'] = name;
    if (bio != null) userData['bio'] = bio;
    if (photoUrl != null) userData['photoUrl'] = photoUrl;
    if (personalityTags != null) userData['personalityTags'] = personalityTags;
    if (lifestyleDetails != null) userData['lifestyleDetails'] = lifestyleDetails;
    if (budget != null) userData['budget'] = budget;
    if (location != null) userData['location'] = location; // The display name
    if (gender != null) userData['gender'] = gender;
    if (age != null) userData['age'] = age;

    if (coordinates != null) {
      userData['coordinates'] = coordinates;
    }

    return await userCollection.doc(uid).set(userData, SetOptions(merge: true));
  }

  // user data from snapshots - CLEANED UP
  UserData? _userDataFromSnapshot(DocumentSnapshot snapshot) {
    if (!snapshot.exists || snapshot.data() == null) {
      return null;
    }
    return UserData.fromMap(snapshot.data() as Map<String, dynamic>, snapshot.id);
  }

  // get user doc stream for the current uid - CLEANED UP
  Stream<UserData?> get userData {
    return userCollection.doc(uid).snapshots().map(_userDataFromSnapshot);
  }

  // get user doc stream for a specific uid - CLEANED UP
  Stream<UserData?> userDataFromUid(String targetUid) {
    return userCollection.doc(targetUid).snapshots().map((snapshot) {
      if (!snapshot.exists) {
        return null;
      }
      return UserData.fromMap(snapshot.data() as Map<String, dynamic>, snapshot.id);
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
          print('Fetched ${snapshot.docs.length} matches for user $userId'); // Added print statement
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
    return userCollection.snapshots().asyncMap(
      (snapshot) async {
        List<UserData> users = [];
        for (var doc in snapshot.docs) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          UserData userData = UserData.fromMap(data, doc.id);
          bool isOnline = await PresenceService().getPresenceStream(doc.id).first;
          userData.isOnline = isOnline;
          users.add(userData);
        }
        return users;
      },
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
