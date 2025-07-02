import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cohouse_match/models/user.dart';
import 'package:cohouse_match/models/message.dart';
import 'package:cohouse_match/models/match.dart';
import 'package:rxdart/rxdart.dart';
import 'package:cohouse_match/models/review.dart';

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

  final String chatRoomMId = 'chatRoomId'; // Placeholder for chat room ID


  // Add a review for a user
  Future<void> addReview(String targetUserId, Review review) async {
    // A review document is created inside the 'reviews' subcollection of the target user
    await userCollection.doc(targetUserId).collection('reviews').add(review.toMap());
  }


  // Get all reviews for a user
  Stream<List<Review>> getReviews(String targetUserId) {
    return userCollection
        .doc(targetUserId)
        .collection('reviews')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Review.fromMap(doc.data(), doc.id))
            .toList());
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
      int? age) async {
    // Create a base map with email which is required
    Map<String, dynamic> userData = {
      'email': email,
      'isProfileComplete': true, // Mark profile as complete after onboarding
    };

    // Add other fields only if they're not null
    if (name != null) userData['name'] = name;
    if (bio != null) userData['bio'] = bio;
    if (photoUrl != null) userData['photoUrl'] = photoUrl;
    if (personalityTags != null) userData['personalityTags'] = personalityTags;
    if (lifestyleDetails != null) userData['lifestyleDetails'] = lifestyleDetails;
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
      gender: data['gender'],
      age: data['age'],
      isProfileComplete: data['isProfileComplete'] ?? false,
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
        isProfileComplete: data['isProfileComplete'] ?? false,
      );
    });
  }

  // Send message
  Future<void> sendMessage(String senderId, String receiverId, String content) async {
    String message = content;
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

   // NEW: Send message in any chat room (individual or group)
  Future<void> sendMessageInChat(String chatRoomId, String senderId, String content) async {
    await messagesCollection.doc(chatRoomId).collection('chats').add({
      'senderId': senderId,
      'content': content, // Changed from 'message' to 'content' for consistency
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
      return snapshot.docs.map((doc) => Message.fromMap(doc.data())).toList();
    });
  }

  // Create a match
  Future<void> createMatch(String user1Id, String user2Id, {List<String>? groupMembers}) async {
    // Fetch user names for chat title
    final user1Doc = await userCollection.doc(user1Id).get();
    final user2Doc = await userCollection.doc(user2Id).get();
    final user1Name = (user1Doc.data() as Map<String, dynamic>)['name'] ?? 'User 1';
    final user2Name = (user2Doc.data() as Map<String, dynamic>)['name'] ?? 'User 2';
    // Ensure unique match document ID by sorting user IDs
    List<String> ids = [user1Id, user2Id];
    String matchType = 'individual';
    List<String> members = [];
    String chatTitle = '';

    if (groupMembers != null && groupMembers.length > 2) {
      ids = groupMembers..sort();
      matchType = 'group';
      members = groupMembers;
      chatTitle = 'Group Chat'; // Generic title for group chats
    } else {
      ids.sort();
      members = [user1Id, user2Id];
      chatTitle = '$user1Name & $user2Name'; // Title for individual chats
    }

    String matchId = ids.join('_');

    await matchesCollection.doc(matchId).set({
      'user1Id': user1Id,
      'user2Id': user2Id,
      'timestamp': FieldValue.serverTimestamp(),
      'type': matchType,
      'members': members,
      'chatTitle': chatTitle, // Add chatTitle here
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