// lib/screens/wrapper.dart
import 'package:cohouse_match/screens/authenticate.dart';
import 'package:cohouse_match/screens/home_wrapper.dart';
import 'package:cohouse_match/services/auth_service.dart';
import 'package:cohouse_match/screens/onboarding/onboarding_screen.dart'; 
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
    final authService = Provider.of<AuthService>(context);

    return StreamBuilder<User?>(
      stream: authService.user,
      builder: (context, userSnapshot) {
        if (userSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        final user = userSnapshot.data;

        if (user == null) {
          return const Authenticate();
        } else {
          final notificationService = NotificationService();
          notificationService.initNotifications();
          notificationService.saveTokenToDatabase(user.uid);

          return StreamBuilder<UserData?>(
            stream: DatabaseService(uid: user.uid).userData,
            builder: (context, userDataSnapshot) {
              if (userDataSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(body: Center(child: CircularProgressIndicator()));
              }

              if (userDataSnapshot.hasData && userDataSnapshot.data != null) {
                final userData = userDataSnapshot.data!;
                if (userData.isProfileComplete) {
                  return const HomeWrapper();
                } else {
                  return OnboardingScreen(firebaseUser: user);
                }
              } else {
                return OnboardingScreen(firebaseUser: user);
              }
            },
          );
        }
      },
    );
  }
}