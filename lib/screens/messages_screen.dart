// lib/screens/messages_screen.dart
import 'package:flutter/material.dart';
import 'package:cohouse_match/screens/chat_screen.dart';
import 'package:cohouse_match/services/database_service.dart';
import 'package:cohouse_match/models/user.dart';
import 'package:cohouse_match/models/match.dart';
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
      ),
      body: StreamBuilder<List<Match>>(
        stream: _databaseService.getMatches(currentUser.uid),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final matches = snapshot.data ?? [];

          if (matches.isEmpty) {
            return const Center(child: Text('No matches yet. Swipe right to find a match!'));
          }

          return ListView.builder(
            itemCount: matches.length,
            itemBuilder: (context, index) {
              final match = matches[index];
              final String chatRoomId = match.id;

              if (match.type == 'group') {
                // Build a list tile for a group chat
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                  child: ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.group)),
                    title: const Text('Group Match'),
                    subtitle: Text('Created on ${match.timestamp.toLocal().toString().split(' ')[0]}'),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChatScreen(
                            chatRoomId: chatRoomId,
                            chatTitle: 'Group Chat',
                            // Pass all members for displaying names in the chat
                            memberIds: match.members,
                          ),
                        ),
                      );
                    },
                  ),
                );
              } else {
                // For individual chats
                final chatPartnerId = match.user1Id == currentUser.uid ? match.user2Id : match.user1Id;
                
                return FutureBuilder<UserData?>(
                  future: _databaseService.userDataFromUid(chatPartnerId).first,
                  builder: (context, userSnapshot) {
                    if (userSnapshot.connectionState == ConnectionState.waiting) {
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                        child: const ListTile(
                          leading: CircleAvatar(child: Icon(Icons.person)),
                          title: Text('Loading...'),
                          subtitle: Text('Fetching user data'),
                        ),
                      );
                    }

                    final chatPartner = userSnapshot.data;
                    
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundImage: chatPartner?.photoUrl != null
                              ? NetworkImage(chatPartner!.photoUrl!)
                              : null,
                          child: chatPartner?.photoUrl == null
                              ? const Icon(Icons.person)
                              : null,
                        ),
                        title: Text(chatPartner?.name ?? 'No Name'),
                        subtitle: Text(chatPartner?.email ?? 'No email'),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ChatScreen(
                                chatRoomId: chatRoomId,
                                chatTitle: chatPartner?.name ?? 'Chat',
                                memberIds: [currentUser.uid, chatPartnerId],
                              ),
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