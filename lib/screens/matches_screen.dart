import 'package:cohouse_match/screens/view_profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cohouse_match/models/match.dart';
import 'package:cohouse_match/models/user.dart';
import 'package:cohouse_match/services/database_service.dart';

class MatchesScreen extends StatefulWidget {
  const MatchesScreen({super.key});

  @override
  State<MatchesScreen> createState() => _MatchesScreenState();
}

class _MatchesScreenState extends State<MatchesScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    final currentUser = _auth.currentUser;

    if (currentUser == null) {
      return const Center(child: Text('Please log in to view your matches.'));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Matches'),
      ),
      body: StreamBuilder<List<Match>>(
        stream: DatabaseService().getMatches(currentUser.uid),
        builder: (context, AsyncSnapshot<List<Match>> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No matches yet.'));
          }

          final matches = snapshot.data!;

          return ListView.builder(
            itemCount: matches.length,
            itemBuilder: (context, index) {
              final match = matches[index];

              if (match.type == 'group') {
                final groupMembersIds = match.members.where((uid) => uid != currentUser.uid).toList();
                return Card(
                  margin: const EdgeInsets.all(8.0),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Group Match',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text('Match Date: ${match.timestamp.toLocal().toString().split(' ')[0]}'),
                        const SizedBox(height: 8),
                        const Text('Members:', style: TextStyle(fontWeight: FontWeight.bold)),
                        ...groupMembersIds.map((memberId) {
                          return FutureBuilder<UserData?>(
                            future: DatabaseService().userDataFromUid(memberId).first,
                            builder: (context, userSnapshot) {
                              if (userSnapshot.connectionState == ConnectionState.waiting) {
                                return const Text('Loading member...');
                              }
                              if (userSnapshot.hasError) {
                                return Text('Error loading member: ${userSnapshot.error}');
                              }
                              if (!userSnapshot.hasData) {
                                return const Text('Member not found');
                              }
                              final member = userSnapshot.data!;
                              return Padding(
                                padding: const EdgeInsets.only(left: 8.0, top: 4.0),
                                child: Text('- ${member.name ?? 'Unknown'} (${member.email})'),
                              );
                            },
                          );
                        }),
                      ],
                    ),
                  ),
                );
  } else {
    // --- THIS IS THE PART TO MODIFY FOR INDIVIDUAL MATCHES ---
    final matchedUserId = match.user1Id == currentUser.uid ? match.user2Id : match.user1Id;

    return FutureBuilder<UserData?>(
      future: DatabaseService().userDataFromUid(matchedUserId).first,
      builder: (context, userSnapshot) {
        if (userSnapshot.connectionState == ConnectionState.waiting) {
          return const ListTile(title: Text('Loading...'));
        }
        if (!userSnapshot.hasData) {
          return const ListTile(title: Text('User not found'));
        }

        final matchedUser = userSnapshot.data!;

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          child: ListTile(
            leading: CircleAvatar(
              backgroundImage: matchedUser.photoUrl != null
                  ? NetworkImage(matchedUser.photoUrl!)
                  : null,
              child: matchedUser.photoUrl == null ? const Icon(Icons.person) : null,
            ),
            title: Text(matchedUser.name ?? 'Unknown User', style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(matchedUser.bio ?? 'No bio available.', maxLines: 1, overflow: TextOverflow.ellipsis,),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ViewProfileScreen(userId: matchedUserId),
                ),
              );
            },
          ),
        );
      },
    );
  }
},
          );
        },
      ),
    );
  }
}
