// File: lib/screens/messages_screen.dart
import 'package:cohouse_match/models/match.dart';
import 'package:cohouse_match/models/user.dart';
import 'package:cohouse_match/screens/chat_screen.dart';
import 'package:cohouse_match/services/database_service.dart';
import 'package:cohouse_match/services/presence_service.dart';
import 'package:cohouse_match/widgets/empty_state_widget.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
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
    final presenceService = Provider.of<PresenceService>(context);

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
            return const EmptyStateWidget(
              icon: Icons.chat_bubble_outline_rounded,
              title: "No Conversations",
              subtitle: "When you match with someone, you can start chatting here.",
            );
          }

          return ListView.builder(
            itemCount: matches.length,
            itemBuilder: (context, index) {
              final match = matches[index];
              final String chatRoomId = match.id;

              if (match.type == 'group') {
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
                            memberIds: match.members,
                          ),
                        ),
                      );
                    },
                  ),
                );
              } else {
                final chatPartnerId = match.user1Id == currentUser.uid ? match.user2Id : match.user1Id;
                
                return FutureBuilder<UserData?>(
                  future: _databaseService.userDataFromUid(chatPartnerId).first,
                  builder: (context, userSnapshot) {
                    if (userSnapshot.connectionState == ConnectionState.waiting) {
                      return const Card(
                        margin: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                        child: ListTile(title: Text('Loading chat partner...')),
                      );
                    }

                    if (!userSnapshot.hasData || userSnapshot.data == null) {
                      return const Card(
                        margin: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                        child: ListTile(title: Text('Chat partner not found or data unavailable')),
                      );
                    }

                    final chatPartner = userSnapshot.data!;
                    
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                      child: ListTile(
                        leading: StreamBuilder<bool>(
                          stream: presenceService.getPresenceStream(chatPartnerId),
                          builder: (context, presenceSnapshot) {
                            final isOnline = presenceSnapshot.data ?? false;
                            return Stack(
                              children: [
                                CircleAvatar(
                                  radius: 25,
                                  backgroundImage: (chatPartner.photoUrl != null && chatPartner.photoUrl!.isNotEmpty)
                                      ? NetworkImage(chatPartner.photoUrl!)
                                      : null,
                                  child: (chatPartner.photoUrl == null || chatPartner.photoUrl!.isEmpty)
                                      ? const Icon(Icons.person)
                                      : null,
                                ),
                                if (isOnline)
                                  Positioned(
                                    bottom: 0,
                                    right: 0,
                                    child: Container(
                                      width: 15,
                                      height: 15,
                                      decoration: BoxDecoration(
                                        color: Colors.green,
                                        shape: BoxShape.circle,
                                        border: Border.all(color: Colors.white, width: 2),
                                      ),
                                    ),
                                  ),
                              ],
                            );
                          },
                        ),
                        title: Text(chatPartner.name ?? 'No Name'),
                        subtitle: Text(chatPartner.email ?? 'No email'),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ChatScreen(
                                chatRoomId: chatRoomId,
                                chatTitle: chatPartner.name ?? 'Chat',
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