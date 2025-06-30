import 'package:flutter/material.dart';
import 'package:cohouse_match/screens/chat_screen.dart';
import 'package:cohouse_match/services/database_service.dart';
import 'package:cohouse_match/models/user.dart';
import 'package:cohouse_match/models/match.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

class MatchesScreen extends StatefulWidget {
  const MatchesScreen({super.key});

  @override
  State<MatchesScreen> createState() => _MatchesScreenState();
}

class _MatchesScreenState extends State<MatchesScreen> {
  final DatabaseService _databaseService = DatabaseService();

  @override
  Widget build(BuildContext context) {
    final currentUser = Provider.of<User?>(context);

    if (currentUser == null) {
      return const Center(child: Text('Please log in to view matches.'));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Matches'),
      ),
      body: StreamBuilder<List<Match>>(
        stream: _databaseService.getMatches(currentUser.uid),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Text('Error: ${snapshot.error}');
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final matches = snapshot.data ?? [];

          if (matches.isEmpty) {
            return const Center(child: Text('No matches yet.'));
          }

          return ListView.builder(
            itemCount: matches.length,
            itemBuilder: (context, index) {
              final match = matches[index];
              final matchedUserId = match.user1Id == currentUser.uid
                  ? match.user2Id
                  : match.user1Id;

              return FutureBuilder<UserData>(
                future: _databaseService.userCollection.doc(matchedUserId).get().then(
                    (doc) => UserData.fromMap(doc.data() as Map<String, dynamic>, doc.id)),
                builder: (context, userSnapshot) {
                  if (userSnapshot.connectionState == ConnectionState.waiting) {
                    return const ListTile(
                      title: Text('Loading...'),
                    );
                  }
                  if (userSnapshot.hasError) {
                    return ListTile(
                      title: Text('Error loading user: ${userSnapshot.error}'),
                    );
                  }
                  final matchedUser = userSnapshot.data;
                  if (matchedUser == null) {
                    return const SizedBox.shrink();
                  }

                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundImage: matchedUser.photoUrl != null
                            ? NetworkImage(matchedUser.photoUrl!) as ImageProvider<Object>?
                            : null,
                        child: matchedUser.photoUrl == null
                            ? const Icon(Icons.person) : null,
                      ),
                      title: Text(matchedUser.name ?? 'No Name'),
                      subtitle: Text(matchedUser.bio ?? 'No bio available.'),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChatScreen(
                              receiverId: matchedUser.uid,
                              receiverName: matchedUser.name ?? matchedUser.email,
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}