import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'models/experience_model.dart';
import 'models/wish_model.dart';
import 'models/user_model.dart';
import 'models/chat_model.dart' as chat_models;
import 'services/chat_service.dart';
import 'services/user_service.dart';
import 'experience_detail_screen.dart';
import 'wish_detail_screen.dart';

class ChatDetailScreen extends StatefulWidget {
  final String chatId;
  final String userName;
  final String? userAvatar;
  final ExperienceModel? experience; // For experience-based chats
  final WishModel? wish; // For wish-based chats
  final String? initialMessage; // For pre-populated message

  const ChatDetailScreen({
    super.key,
    required this.chatId,
    required this.userName,
    this.userAvatar,
    this.experience,
    this.wish,
    this.initialMessage,
  });

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ChatService _chatService = ChatService();
  final UserService _userService = UserService();

  String? _currentUserId;
  UserModel? _otherUser;
  bool _isLoading = true;
  bool _isSending = false;
  String? _error;
  List<chat_models.ChatMessage> _messages = [];
  Stream<List<chat_models.ChatMessage>>? _messagesStream;
  chat_models.ChatConversation? _conversation;

  @override
  void initState() {
    super.initState();
    _currentUserId = FirebaseAuth.instance.currentUser?.uid;
    _initializeChat();
  }

  Future<void> _initializeChat() async {
    try {
      // Get conversation details
      final conversation = await _chatService.getConversationById(
        widget.chatId,
      );
      if (conversation == null) {
        setState(() {
          _error = 'Conversation not found';
          _isLoading = false;
        });
        return;
      }

      // Set up real-time messages stream
      final messagesStream = _chatService.listenToMessages(widget.chatId);

      // Mark messages as read
      await _chatService.markAsRead(widget.chatId);

      // Get other participant's user details
      final otherUser = await _chatService.getOtherParticipant(conversation);

      if (mounted) {
        setState(() {
          _conversation = conversation;
          _messagesStream = messagesStream;
          _otherUser = otherUser;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Error loading conversation: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() {
      _isSending = true;
    });

    try {
      // Clear the input field immediately for better UX
      _messageController.clear();

      // Send the message using the chat service
      await _chatService.sendMessage(conversationId: widget.chatId, text: text);

      // Auto-scroll to bottom
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send message: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  void _viewExperienceOrWish() {
    if (widget.experience != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) => ExperienceDetailScreen(
                experienceId: widget.experience!.experienceId,
                experience: widget.experience,
              ),
        ),
      );
    } else if (widget.wish != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) => WishDetailScreen(
                wishId: widget.wish!.wishId,
                wish: widget.wish,
              ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Loading...'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Error'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48, color: Colors.red.shade400),
                const SizedBox(height: 16),
                Text(
                  _error!,
                  style: const TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Go Back'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          // Experience/Wish preview card (if applicable)
          if (widget.experience != null || widget.wish != null)
            _buildPreviewCard(),

          // Messages
          Expanded(child: _buildMessagesList()),

          // Message input
          _buildMessageInput(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0.5,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.black),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: Colors.grey.shade300,
            backgroundImage:
                widget.userAvatar != null
                    ? NetworkImage(widget.userAvatar!)
                    : null,
            child:
                widget.userAvatar == null
                    ? Text(
                      widget.userName[0].toUpperCase(),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    )
                    : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.userName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                Text(
                  'Active now',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.green.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.phone, color: Colors.black),
          onPressed: () {
            // TODO: Implement call functionality
          },
        ),
        IconButton(
          icon: const Icon(Icons.more_vert, color: Colors.black),
          onPressed: () {
            // TODO: Implement more options
          },
        ),
      ],
    );
  }

  Widget _buildPreviewCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child:
          widget.experience != null
              ? _buildExperiencePreview(widget.experience!)
              : _buildWishPreview(widget.wish!),
    );
  }

  Widget _buildExperiencePreview(ExperienceModel experience) {
    return Row(
      children: [
        // Thumbnail
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: Colors.grey.shade300,
          ),
          child:
              experience.photoUrls.isNotEmpty
                  ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      experience.photoUrls.first,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(Icons.image, color: Colors.grey);
                      },
                    ),
                  )
                  : const Icon(Icons.explore, color: Colors.grey),
        ),
        const SizedBox(width: 12),

        // Content
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                experience.title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                '${DateFormat('MMM dd').format(experience.date)} • ${experience.location}',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),

        // View button
        TextButton(
          onPressed: () {
            // TODO: Navigate to experience detail
          },
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          ),
          child: Text(
            'View',
            style: TextStyle(
              fontSize: 12,
              color: Colors.blue.shade600,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWishPreview(WishModel wish) {
    return Row(
      children: [
        // Icon
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: Colors.purple.shade100,
          ),
          child: Icon(Icons.star, color: Colors.purple.shade600, size: 30),
        ),
        const SizedBox(width: 12),

        // Content
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                wish.title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                '${DateFormat('MMM dd').format(wish.preferredDate)} • ${wish.location}',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),

        // View button
        TextButton(
          onPressed: () {
            // TODO: Navigate to wish detail
          },
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          ),
          child: Text(
            'View',
            style: TextStyle(
              fontSize: 12,
              color: Colors.purple.shade600,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMessagesList() {
    if (_messagesStream == null) {
      return const Center(child: Text('No messages'));
    }

    return StreamBuilder<List<chat_models.ChatMessage>>(
      stream: _messagesStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            _messages.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error loading messages: ${snapshot.error}',
              style: TextStyle(color: Colors.red.shade700),
            ),
          );
        }

        final messages = snapshot.data ?? [];

        // Store the messages for reference
        _messages = messages;

        if (messages.isEmpty) {
          return const Center(
            child: Text(
              'No messages yet. Start the conversation!',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
                fontStyle: FontStyle.italic,
              ),
            ),
          );
        }

        // Reverse the list for correct display order (StreamBuilder gives newest first)
        final displayMessages = messages.toList();

        return ListView.builder(
          controller: _scrollController,
          reverse: true, // Display newest at bottom
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: displayMessages.length,
          itemBuilder: (context, index) {
            final message = displayMessages[index];
            final showTimestamp =
                index == 0 ||
                displayMessages[index - 1].timestamp
                        .difference(message.timestamp)
                        .inMinutes
                        .abs() >
                    15;

            return Column(
              children: [
                if (showTimestamp)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Text(
                      _formatMessageTimestamp(message.timestamp),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                _buildMessageBubble(message),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildMessageBubble(chat_models.ChatMessage message) {
    final isFromCurrentUser = message.senderId == _currentUserId;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment:
            isFromCurrentUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isFromCurrentUser) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.grey.shade300,
              backgroundImage:
                  widget.userAvatar != null
                      ? NetworkImage(widget.userAvatar!)
                      : _otherUser?.avatarUrl != null &&
                          _otherUser!.avatarUrl.isNotEmpty
                      ? NetworkImage(_otherUser!.avatarUrl)
                      : null,
              child:
                  widget.userAvatar == null &&
                          (_otherUser?.avatarUrl == null ||
                              _otherUser!.avatarUrl.isEmpty)
                      ? Text(
                        widget.userName.isNotEmpty
                            ? widget.userName[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      )
                      : null,
            ),
            const SizedBox(width: 8),
          ],

          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color:
                    isFromCurrentUser
                        ? Colors.blue.shade600
                        : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.text,
                    style: TextStyle(
                      fontSize: 15,
                      color: isFromCurrentUser ? Colors.white : Colors.black,
                      height: 1.3,
                    ),
                  ),

                  // Message status indicator (only for current user's messages)
                  if (isFromCurrentUser)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            _getMessageStatusText(message.status),
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.white.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),

          if (isFromCurrentUser) const SizedBox(width: 40),
          if (!isFromCurrentUser) const SizedBox(width: 40),
        ],
      ),
    );
  }

  String _getMessageStatusText(chat_models.MessageStatus status) {
    switch (status) {
      case chat_models.MessageStatus.sending:
        return 'Sending...';
      case chat_models.MessageStatus.sent:
        return 'Sent';
      case chat_models.MessageStatus.delivered:
        return 'Delivered';
      case chat_models.MessageStatus.read:
        return 'Read';
      case chat_models.MessageStatus.failed:
        return 'Failed';
      default:
        return '';
    }
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200, width: 1)),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  controller: _messageController,
                  maxLines: 1,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _sendMessage(),
                  decoration: const InputDecoration(
                    hintText: 'Type a message...',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                  onChanged: (_) {
                    // Update typing status and rebuild to update send button
                    setState(() {});
                    // TODO: Implement debounced typing indicator with _chatService.updateTypingStatus
                  },
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap:
                  (_messageController.text.trim().isNotEmpty && !_isSending)
                      ? _sendMessage
                      : null,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color:
                      _messageController.text.trim().isNotEmpty
                          ? (_isSending
                              ? Colors.blue.shade300
                              : Colors.blue.shade600)
                          : Colors.grey.shade300,
                  shape: BoxShape.circle,
                ),
                child:
                    _isSending
                        ? Padding(
                          padding: const EdgeInsets.all(10.0),
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                        : Icon(
                          Icons.send,
                          color:
                              _messageController.text.trim().isNotEmpty
                                  ? Colors.white
                                  : Colors.grey.shade500,
                          size: 20,
                        ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatMessageTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays == 0) {
      return 'Today ${DateFormat('HH:mm').format(timestamp)}';
    } else if (difference.inDays == 1) {
      return 'Yesterday ${DateFormat('HH:mm').format(timestamp)}';
    } else {
      return DateFormat('MMM dd, HH:mm').format(timestamp);
    }
  }
}
