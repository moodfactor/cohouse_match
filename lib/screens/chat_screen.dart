// lib/screens/chat_screen.dart

import 'dart:async'; // Import async for Timer
import 'package:cohouse_match/models/message.dart';
import 'package:cohouse_match/models/user.dart';
import 'package:cohouse_match/services/database_service.dart';
import 'package:cohouse_match/services/presence_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; // Import image_picker

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
  final PresenceService _presenceService = PresenceService();

  final Map<String, UserData> _memberData = {};
  bool _isLoadingMembers = true;
  String? _chatPartnerId;

  // --- NEW STATE FOR TYPING INDICATOR ---
  Timer? _typingTimer;

  @override
  void initState() {
    super.initState();
    _fetchMemberData();
    if (widget.memberIds.length == 2) {
      _chatPartnerId = widget.memberIds.firstWhere((id) => id != _auth.currentUser?.uid, orElse: () => '');
    }

    // Add a listener to the text controller to detect typing
    _messageController.addListener(_handleTyping);
  }

  @override
  void dispose() {
    // Clean up the typing status and timer when the screen is disposed
    _setTypingStatus(false);
    _typingTimer?.cancel();
    _messageController.removeListener(_handleTyping);
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// Handles the logic for setting typing status.
  void _handleTyping() {
    // If the user is typing, set their status immediately.
    if (_messageController.text.isNotEmpty) {
      _setTypingStatus(true);
    }

    // Cancel any existing timer.
    _typingTimer?.cancel();

    // Start a new timer. If it completes, the user has stopped typing.
    _typingTimer = Timer(const Duration(seconds: 2), () {
      _setTypingStatus(false);
    });
  }
  
  /// Helper to call the presence service to update typing status.
  void _setTypingStatus(bool isTyping) {
    final user = _auth.currentUser;
    if (user != null) {
      _presenceService.setUserTyping(widget.chatRoomId, user.uid, isTyping);
    }
  }

  Future<void> _fetchMemberData() async {
    for (String uid in widget.memberIds) {
      final userData = await _db.userDataFromUid(uid).first;
      if (userData != null) {
        _memberData[uid] = userData;
      }
    }
    if (mounted) {
      setState(() => _isLoadingMembers = false);
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      // Show a loading indicator
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Uploading image...'), duration: Duration(seconds: 5)),
      );
      try {
        final String? imageUrl = await _db.uploadImageToChat(image, widget.chatRoomId);
        if (imageUrl != null) {
          _sendMessage(imageUrl: imageUrl);
          ScaffoldMessenger.of(context).hideCurrentSnackBar(); // Hide loading indicator
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to upload image.')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error uploading image: $e')),
        );
      }
    }
  }

  void _sendMessage({String? imageUrl}) {
    // When a message is sent, immediately mark user as not typing.
    _typingTimer?.cancel();
    _setTypingStatus(false);
    
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    if (imageUrl != null && imageUrl.isNotEmpty) {
      _db.sendMessageInChat(
        widget.chatRoomId,
        currentUser.uid,
        '', // No content for image messages
        imageUrl: imageUrl,
        messageType: MessageType.image,
      );
    } else {
      final messageText = _messageController.text.trim();
      if (messageText.isNotEmpty) {
        _db.sendMessageInChat(
          widget.chatRoomId,
          currentUser.uid,
          messageText,
          messageType: MessageType.text,
        );
        _messageController.clear();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return const Scaffold(body: Center(child: Text('Error: Not logged in.')));
    }

    return Scaffold(
      appBar: AppBar(
        title: _isLoadingMembers
            ? Text(widget.chatTitle) // Show default title while loading
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.chatTitle),
                  StreamBuilder<List<String>>(
                    // Listen to the typing stream
                    stream: _presenceService.getTypingStream(
                      widget.chatRoomId,
                      currentUser.uid,
                      _memberData,
                    ),
                    builder: (context, snapshot) {
                      final typingNames = snapshot.data ?? [];
                      if (typingNames.isNotEmpty) {
                        // Display "is typing..." message
                        return Text(
                          '${typingNames.join(', ')} is typing...',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.normal,
                            fontStyle: FontStyle.italic,
                          ),
                        );
                      } else {
                        // Otherwise, show the online status for individual chats
                        if (_chatPartnerId != null &&
                            _chatPartnerId!.isNotEmpty) {
                          return StreamBuilder<bool>(
                            stream: _presenceService.getPresenceStream(
                              _chatPartnerId!,
                            ),
                            builder: (context, presenceSnapshot) {
                              final isOnline = presenceSnapshot.data ?? false;
                              return Text(
                                isOnline ? 'Online' : 'Offline',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.normal,
                                ),
                              );
                            },
                          );
                        }
                      }
                      // Return an empty widget if no status to show
                      return const SizedBox.shrink();
                    },
                  ),
                ],
              ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoadingMembers
                ? const Center(child: CircularProgressIndicator())
                : StreamBuilder<List<Message>>(
                    stream: _db.getMessages(widget.chatRoomId),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting &&
                          !snapshot.hasData) {
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

                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (_scrollController.hasClients) {
                          _scrollController.jumpTo(
                            _scrollController.position.minScrollExtent,
                          );
                        }
                      });

                      return ListView.builder(
                        controller: _scrollController,
                        reverse: true,
                        padding: const EdgeInsets.symmetric(vertical: 10.0),
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final message = messages[index];
                          final isMe = message.senderId == currentUser.uid;
                          final sender = _memberData[message.senderId];
                          final bool isGroupChat = widget.memberIds.length > 2;

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
            IconButton(
              icon: const Icon(Icons.image),
              onPressed: _pickImage,
              color: Theme.of(context).primaryColor,
            ),
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
        mainAxisAlignment: isMe
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (showSenderInfo)
            CircleAvatar(
              radius: 15,
              backgroundImage:
                  (sender?.photoUrl != null && sender!.photoUrl!.isNotEmpty)
                  ? NetworkImage(sender!.photoUrl!)
                  : null,
              child: (sender?.photoUrl == null || sender!.photoUrl!.isEmpty)
                  ? Text(sender?.name?.substring(0, 1) ?? 'U')
                  : null,
            ),
          if (showSenderInfo) const SizedBox(width: 8),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 14.0,
                vertical: 10.0,
              ),
              decoration: BoxDecoration(
                color: isMe ? Theme.of(context).primaryColor : Colors.grey[200],
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: isMe
                      ? const Radius.circular(18)
                      : const Radius.circular(0),
                  bottomRight: isMe
                      ? const Radius.circular(0)
                      : const Radius.circular(18),
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
                  if (message.messageType == MessageType.image && message.imageUrl != null)
                    GestureDetector(
                      onTap: () {
                        // Optional: Implement full-screen image viewer
                        showDialog(
                          context: context,
                          builder: (context) => Dialog(
                            child: Image.network(message.imageUrl!),
                          ),
                        );
                      },
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8.0),
                        child: Image.network(
                          message.imageUrl!,
                          width: 200, // Adjust as needed
                          height: 200, // Adjust as needed
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Center(
                              child: CircularProgressIndicator(
                                value: loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                    : null,
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return const Text('Could not load image');
                          },
                        ),
                      ),
                    )
                  else if (message.messageType == MessageType.text)
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
