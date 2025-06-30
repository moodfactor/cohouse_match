import 'package:flutter/material.dart';
import 'package:cohouse_match/screens/chat_screen.dart';
import 'package:cohouse_match/services/database_service.dart';
import 'package:cohouse_match/models/user.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  final DatabaseService _databaseService = DatabaseService();

  @override
  Widget build(BuildContext context) {
    final currentUser = Provider.of<User?>(context);

    if (currentUser == null) {
      return const Center(child: Text('Please log in to view messages.'));
    }

    // This is a simplified approach. In a real app, you'd fetch actual matches
    // or conversations to display here.
    // For now, let's just show a list of all other users as potential chat partners.
    return StreamBuilder<List<UserData>>(
      stream: _databaseService.userCollection.snapshots().map((snapshot) {
        return snapshot.docs.map((doc) {
          return UserData.fromMap(doc.data() as Map<String, dynamic>, doc.id);
        }).where((user) => user.uid != currentUser.uid).toList();
      }),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final users = snapshot.data ?? [];

        if (users.isEmpty) {
          return const Center(child: Text('No users to chat with yet.'));
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Messages'),
          ),
          body: ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundImage: user.photoUrl != null
                        ? NetworkImage(user.photoUrl!) as ImageProvider<Object>?
                        : null,
                    child: user.photoUrl == null
                        ? const Icon(Icons.person) : null,
                  ),
                  title: Text(user.name ?? 'No Name'),
                  subtitle: Text(user.email),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatScreen(
                          receiverId: user.uid,
                          receiverName: user.name ?? user.email,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        );
      },
    );
  }
}