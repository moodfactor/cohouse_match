import 'package:cohouse_match/screens/authenticate.dart';
import 'package:cohouse_match/screens/home_wrapper.dart';
import 'package:flutter/material.dart';
import 'package:cohouse_match/screens/login_screen.dart';
import 'package:cohouse_match/services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Wrapper extends StatelessWidget {
  const Wrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthService auth = AuthService();

    return StreamBuilder<User?>(
      stream: auth.user,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator(); // Or a splash screen
        } else {
          if (snapshot.hasData) {
            return const HomeWrapper();
          } else {
            return const Authenticate();
          }
        }
      },
    );
  }
}