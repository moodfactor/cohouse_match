import 'package:flutter/material.dart';

import 'package:cohouse_match/models/user.dart';

class HomeScreen extends StatelessWidget {
  final UserData? userData;
  const HomeScreen({super.key, this.userData});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home Screen'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text('Welcome to your regular app experience!'),
            const SizedBox(height: 20),
            if (userData != null) ...[
              Text('Hello, ${userData!.name ?? 'User'}!',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              if (userData!.bio != null && userData!.bio!.isNotEmpty)
                Text(userData!.bio!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16)),
            ],
        ]),
      ),
    );
  }
}