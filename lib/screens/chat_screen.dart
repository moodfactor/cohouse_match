// lib/screens/chat_screen.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cohouse_match/models/message.dart';
import 'package:cohouse_match/models/user.dart';
import 'package:cohouse_match/services/database_service.dart';

class ChatScreen extends StatefulWidget {
  final String chatRoomId;
  final String chatTitle;
  final List<String> memberIds;

  const ChatScreen({
    super.key,
    required this.chatRoomId,
    required this.chatTitle,
    required this.memberIds,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final DatabaseService _db = DatabaseService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String _chatTitle = '';
  List<String> _memberIds = [];

  // Cache for member data to prevent fetching on every message
  final Map<String, UserData> _memberData = {};
  bool _isLoadingMembers = true;

  @override
  void initState() {
    super.initState();
    _fetchChatDetails();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// Fetches chat details (title and member IDs) from Firestore.
  Future<void> _fetchChatDetails() async {
    try {
      final matchDoc = await _db.matchesCollection.doc(widget.chatRoomId).get();
      if (matchDoc.exists) {
        final data = matchDoc.data() as Map<String, dynamic>;
        setState(() {
          _chatTitle = data['chatTitle'] ?? 'Chat'; // Assuming a chatTitle field
          _memberIds = List<String>.from(data['members'] ?? []);
        });
        _fetchMemberData();
      } else {
        print('Chat room not found: ${widget.chatRoomId}');
        // Handle case where chat room doesn't exist, e.g., navigate back
      }
    } catch (e) {
      print('Error fetching chat details: $e');
    }
  }

  /// Fetches UserData for all members in the chat and stores it in a map for quick access.
  Future<void> _fetchMemberData() async {
    if (_memberIds.isEmpty) {
      setState(() => _isLoadingMembers = false);
      return;
    }
    for (String uid in _memberIds) {
      final userData = await _db.userDataFromUid(uid).first;
      if (userData != null) {
        _memberData[uid] = userData;
      }
    }
    if (mounted) {
      setState(() => _isLoadingMembers = false);
    }
  }

  /// Sends the message content to Firestore.
  void _sendMessage() {
    final messageText = _messageController.text.trim();
    if (messageText.isNotEmpty) {
      final currentUser = _auth.currentUser;
      if (currentUser != null) {
        _db.sendMessageInChat(
          widget.chatRoomId,
          currentUser.uid,
          messageText,
        );
        _messageController.clear();
        // The StreamBuilder will handle the new message appearing,
        // and the auto-scroll logic within it will trigger.
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      // This should ideally not be reached due to the app's wrapper logic.
      return const Scaffold(
        body: Center(child: Text('Error: Not logged in.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_chatTitle),
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoadingMembers || _chatTitle.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : StreamBuilder<List<Message>>(
                    stream: _db.getMessages(widget.chatRoomId),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return Center(child: Text('Error: ${snapshot.error}'));
                      }
                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return const Center(
                          child: Text('No messages yet. Say hello!'),
                        );
                      }

                      final messages = snapshot.data!;

                      // This ensures that the view scrolls to the bottom after the UI has been built.
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (_scrollController.hasClients) {
                          _scrollController.jumpTo(_scrollController.position.minScrollExtent);
                        }
                      });

                      return ListView.builder(
                        controller: _scrollController,
                        reverse: true, // This is key for chat UIs
                        padding: const EdgeInsets.symmetric(vertical: 10.0),
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final message = messages[index];
                          final isMe = message.senderId == currentUser.uid;
                          final sender = _memberData[message.senderId];
                          final bool isGroupChat = _memberIds.length > 2;

                          return _MessageBubble(
                            message: message,
                            sender: sender,
                            isMe: isMe,
                            showSenderInfo: !isMe && isGroupChat,
                          );
                        },
                      );
                    },
                  ),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  /// Builds the text input field and send button.
  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            offset: const Offset(0, -1),
            blurRadius: 2,
            color: Colors.black.withOpacity(0.05),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                textCapitalization: TextCapitalization.sentences,
                autocorrect: true,
                enableSuggestions: true,
                decoration: const InputDecoration(
                  hintText: 'Send a message...',
                  border: InputBorder.none,
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.send),
              onPressed: _sendMessage,
              color: Theme.of(context).primaryColor,
            ),
          ],
        ),
      ),
    );
  }
}

/// A dedicated widget for rendering a single chat message bubble.
class _MessageBubble extends StatelessWidget {
  final Message message;
  final UserData? sender;
  final bool isMe;
  final bool showSenderInfo;

  const _MessageBubble({
    required this.message,
    required this.sender,
    required this.isMe,
    required this.showSenderInfo,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (showSenderInfo)
            CircleAvatar(
              radius: 15,
              backgroundImage: (sender?.photoUrl != null && sender!.photoUrl!.isNotEmpty)
                  ? NetworkImage(sender!.photoUrl!)
                  : null,
              child: (sender?.photoUrl == null || sender!.photoUrl!.isEmpty)
                  ? Text(sender?.name?.substring(0, 1) ?? 'U')
                  : null,
            ),
          if (showSenderInfo) const SizedBox(width: 8),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
              decoration: BoxDecoration(
                color: isMe ? Theme.of(context).primaryColor : Colors.grey[200],
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: isMe ? const Radius.circular(18) : const Radius.circular(0),
                  bottomRight: isMe ? const Radius.circular(0) : const Radius.circular(18),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (showSenderInfo)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4.0),
                      child: Text(
                        sender?.name ?? 'Unknown User',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  Text(
                    message.content,
                    style: TextStyle(
                      color: isMe ? Colors.white : Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}