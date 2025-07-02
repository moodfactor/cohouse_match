import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cohouse_match/services/notification_service.dart';
import 'package:cohouse_match/services/database_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final NotificationService _notificationService = NotificationService();

  // Get current user
  User? getCurrentUser() {
    return _auth.currentUser;
  }

  // Sign in with email and password
  Future<User?> signInWithEmail(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
          email: email, password: password);
      
      // Ensure user data is initialized
      if (result.user != null) {
        await _ensureUserDataInitialized(result.user!.uid);
      }
      
      return result.user;
    } on FirebaseAuthException catch (e) {
      // Add more specific error handling if needed
      rethrow;
    }
  }

  // Register with email and password
  Future<User?> registerWithEmail(String email, String password) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
          email: email, password: password);
      
      // Initialize user data for new users
      if (result.user != null) {
        await DatabaseService(uid: result.user!.uid).updateUserData(
          email,
          null, // name
          null, // bio
          null, // photoUrl
          null, // personalityTags
          null, // lifestyleDetails
          null, // budget
          null, // location
          null, // gender
          null, // age
        );
      }
      
      // Ensure user data is initialized
      await _ensureUserDataInitialized(result.user!.uid);
      
      return result.user;
    } on FirebaseAuthException catch (e) {
      // Add more specific error handling if needed
      rethrow;
    }
  }

  // Sign in with Google
  Future<User?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        return null; // User cancelled sign in
      }
      
      final GoogleSignInAuthentication? googleAuth = await googleUser.authentication;
      if (googleAuth == null) {
        return null; // Failed to get authentication
      }
      
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      
      UserCredential result = await _auth.signInWithCredential(credential);
      
      // Ensure user data is initialized for both new and existing users
      await _ensureUserDataInitialized(result.user!.uid);
      
      return result.user;
    } catch (e) {
      print(e.toString());
      return null;
    }
  }

  // Helper method to ensure user data is initialized
  Future<void> _ensureUserDataInitialized(String uid) async {
    try {
      // Check if user data exists
      final userData = await DatabaseService(uid: uid).getUserData();
      
      // If no user data exists, initialize with basic info
      if (userData == null) {
        final user = _auth.currentUser;
        await DatabaseService(uid: uid).updateUserData(
          user?.email ?? '',
          user?.displayName, // Use Google display name if available
          null, // bio
          user?.photoURL, // Use Google photo URL if available
          null, // personalityTags
          null, // lifestyleDetails
          null, // budget
          null, // location
          null, // gender
          null, // age
        );
      }
    } catch (e) {
      print('Error ensuring user data initialized: $e');
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      // Remove FCM token before signing out
      final currentUser = _auth.currentUser;
      if (currentUser != null) {
        await _notificationService.removeTokenFromDatabase(currentUser.uid);
      }
      await _googleSignIn.signOut();
      await _auth.signOut();
    } catch (e) {
      print(e.toString());
    }
  }

  // Auth change stream
  Stream<User?> get user {
    return _auth.authStateChanges();
  }
}