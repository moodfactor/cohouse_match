import 'package:cohouse_match/screens/authenticate.dart';
import 'package:cohouse_match/screens/home_wrapper.dart';
import 'package:cohouse_match/screens/profile_screen.dart';
import 'package:cohouse_match/services/database_service.dart';
import 'package:cohouse_match/models/user.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:provider/provider.dart';

class Wrapper extends StatelessWidget {
  const Wrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<User?>();

    if (user == null) {
      return const Authenticate();
    } else {
      return StreamBuilder<UserData?>(
        stream: DatabaseService().userDataFromUid(user.uid),
        builder: (context, userSnapshot) {
          if (userSnapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }
          if (userSnapshot.hasData && userSnapshot.data != null) {
            final userData = userSnapshot.data!;
            if (userData.isProfileComplete) {
              return const HomeWrapper();
            } else {
              return const ProfileScreen(); // Redirect to profile completion
            }
          } else {
            return const ProfileScreen(); // No user data found, prompt for profile completion
          }
        },
      );
    }
  }
}