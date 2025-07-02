import 'package:cohouse_match/screens/authenticate.dart';
import 'package:cohouse_match/screens/home_wrapper.dart';
import 'package:cohouse_match/screens/onboarding/onboarding_screen.dart'; // Keep this import
import 'package:cohouse_match/services/database_service.dart';
import 'package:cohouse_match/models/user.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:cohouse_match/services/notification_service.dart';

class Wrapper extends StatelessWidget {
  const Wrapper({super.key});

  @override
  Widget build(BuildContext context) {
    // Get the User object from the StreamProvider
    final user = context.watch<User?>();

    // If the user is not logged in, show the authentication screen
    if (user == null) {
      return const Authenticate();
    } 
    
    // If the user IS logged in, proceed
    else {
      // Initialize notifications and save the FCM token
      final notificationService = NotificationService();
      notificationService.initNotifications();
      notificationService.saveTokenToDatabase(user.uid);

      // Now, stream the user's data from Firestore to check profile status
      return StreamBuilder<UserData?>(
        stream: DatabaseService().userDataFromUid(user.uid),
        builder: (context, userSnapshot) {
          // While waiting for the Firestore data, show a loading indicator
          if (userSnapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }

          // If the stream has an error
          if (userSnapshot.hasError) {
            return const Scaffold(body: Center(child: Text("Something went wrong!")));
          }
          
          // If the stream has data and it's not null (document exists)
          if (userSnapshot.hasData && userSnapshot.data != null) {
            final userData = userSnapshot.data!;

            // Use the getter to check if the profile is complete
            if (userData.isProfileComplete) {
              // If complete, show the main app
              return const HomeWrapper();
            } else {
              // If not complete, show the onboarding screen and PASS THE USER OBJECT
              return OnboardingScreen(firebaseUser: user); 
            }
          } 
          
          // If the document does not exist yet (or is null), it's a new user.
          // This case is handled by your AuthService now, but as a fallback,
          // we direct them to onboarding.
          else {
            return OnboardingScreen(firebaseUser: user);
          }
        },
      );
    }
  }
}