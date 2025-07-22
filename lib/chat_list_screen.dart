import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'chat_detail_screen.dart';
import 'models/chat_model.dart';
import 'models/user_model.dart';
import 'models/experience_model.dart';
import 'models/wish_model.dart';
import 'services/chat_service.dart';
import 'services/user_service.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final ChatService _chatService = ChatService();
  final UserService _userService = UserService();

  bool _isLoading = true;
  String? _error;
  String? _currentUserId;
  List<ChatConversationDisplay> _conversations = [];
  Stream<List<ChatConversation>>? _conversationsStream;

  @override
  void initState() {
    super.initState();
    _currentUserId = FirebaseAuth.instance.currentUser?.uid;
    _initializeChats();
  }

  Future<void> _initializeChats() async {
    if (_currentUserId == null) {
      setState(() {
        _isLoading = false;
        _error = 'Please log in to view your messages';
      });
      return;
    }

    try {
      // Set up the stream for real-time updates
      final conversationsStream = _chatService.listenToUserConversations();

      setState(() {
        _conversationsStream = conversationsStream;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error loading conversations: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Chat',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.notifications_none_outlined,
              color: Colors.black,
            ),
            onPressed: () {
              // TODO: Implement notification center
              // Show friend requests, new experience messages, system announcements
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Notification center coming soon!'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red.shade400),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                _error!,
                style: const TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _initializeChats,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_conversationsStream == null) {
      return _buildEmptyState();
    }

    return StreamBuilder<List<ChatConversation>>(
      stream: _conversationsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            _conversations.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: Color(0xFF7153DF)),
                SizedBox(height: 16),
                Text(
                  'Loading messages...',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        }

        if (snapshot.hasError) {
          // Print detailed error information to terminal
          _printDetailedError(
            'Chat List Stream',
            snapshot.error,
            snapshot.stackTrace,
          );

          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48, color: Colors.red.shade400),
                const SizedBox(height: 16),
                Text(
                  'Error loading conversations: ${snapshot.error}',
                  style: const TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _initializeChats,
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        final conversations = snapshot.data ?? [];

        if (conversations.isEmpty) {
          return _buildEmptyState();
        }

        // Process conversations to display format
        _processConversations(conversations);

        return _buildChatList();
      },
    );
  }

  Future<void> _processConversations(
    List<ChatConversation> conversations,
  ) async {
    if (_currentUserId == null) return;

    final List<ChatConversationDisplay> displayConversations = [];

    for (final conversation in conversations) {
      // Get other user details
      final otherUser = await _chatService.getOtherParticipant(conversation);

      // Get experience or wish details if applicable
      ExperienceModel? experience;
      WishModel? wish;

      if (conversation.experienceId != null) {
        experience = await _chatService.getConversationExperience(conversation);
      } else if (conversation.wishId != null) {
        wish = await _chatService.getConversationWish(conversation);
      }

      // Create display object
      final display = ChatConversationDisplay(
        conversation: conversation,
        otherUser: otherUser,
        experience: experience,
        wish: wish,
        unreadCount: conversation.unreadCounts[_currentUserId] ?? 0,
      );

      displayConversations.add(display);
    }

    // Sort by last message time (newest first)
    displayConversations.sort(
      (a, b) => b.conversation.lastMessageTime.compareTo(
        a.conversation.lastMessageTime,
      ),
    );

    setState(() {
      _conversations = displayConversations;
    });
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.chat_bubble_outline,
                size: 60,
                color: Colors.grey.shade400,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No conversations yet',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Start connecting through experiences and wishes.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade100),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.lightbulb_outline,
                    size: 20,
                    color: Colors.blue.shade600,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Browse experiences to start chatting',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.blue.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatList() {
    return RefreshIndicator(
      onRefresh: _initializeChats,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: _conversations.length,
        separatorBuilder:
            (context, index) =>
                Divider(height: 1, color: Colors.grey.shade200, indent: 80),
        itemBuilder: (context, index) {
          final chatDisplay = _conversations[index];
          return _buildChatTile(chatDisplay);
        },
      ),
    );
  }

  Widget _buildChatTile(ChatConversationDisplay chatDisplay) {
    final chat = chatDisplay.conversation;
    final otherUser = chatDisplay.otherUser;

    // Get user name and avatar
    String userName = 'User';
    String? userAvatar;

    if (otherUser != null) {
      userName =
          otherUser.displayName.isNotEmpty ? otherUser.displayName : 'User';
      userAvatar = otherUser.avatarUrl.isNotEmpty ? otherUser.avatarUrl : null;
    }

    // Online status (placeholder - implement actual status if available)
    final bool isOnline = false;

    // Unread count from the current user's perspective
    final unreadCount = chatDisplay.unreadCount;

    return InkWell(
      onTap: () async {
        try {
          setState(() => _isLoading = true);

          // Mark as read when opening the chat
          await _chatService.markAsRead(chat.id);

          if (!mounted) return;
          setState(() => _isLoading = false);

          // Navigate to chat detail screen
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) => ChatDetailScreen(
                    chatId: chat.id,
                    userName: userName,
                    userAvatar: userAvatar,
                    experience: chatDisplay.experience,
                    wish: chatDisplay.wish,
                  ),
            ),
          );

          // Refresh data when returning
          if (mounted) {
            _initializeChats();

            // Show snackbar if there was a result (e.g. message sent)
            if (result == true) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Message sent successfully'),
                  backgroundColor: Colors.green,
                  duration: Duration(seconds: 2),
                ),
              );
            }
          }
        } catch (e, stackTrace) {
          // Print detailed error information to terminal
          _printDetailedError('Chat Navigation', e, stackTrace);

          if (mounted) {
            setState(() => _isLoading = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error opening chat: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            // Avatar
            Stack(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.grey.shade300,
                  backgroundImage:
                      userAvatar != null ? NetworkImage(userAvatar) : null,
                  child:
                      userAvatar == null
                          ? Text(
                            userName.isNotEmpty
                                ? userName[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          )
                          : null,
                ),
                // Online indicator (if online)
                if (isOnline)
                  Positioned(
                    bottom: 2,
                    right: 2,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: Colors.green.shade400,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 16),

            // Message content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          userName,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight:
                                unreadCount > 0
                                    ? FontWeight.w600
                                    : FontWeight.w500,
                            color: Colors.black,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        _formatTimestamp(chat.lastMessageTime),
                        style: TextStyle(
                          fontSize: 14,
                          color:
                              unreadCount > 0
                                  ? Colors.blue.shade600
                                  : Colors.grey.shade600,
                          fontWeight:
                              unreadCount > 0
                                  ? FontWeight.w500
                                  : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      // Context badge for experience/wish (optional)
                      if (chatDisplay.experience != null ||
                          chatDisplay.wish != null) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          margin: const EdgeInsets.only(right: 6),
                          decoration: BoxDecoration(
                            color:
                                chatDisplay.experience != null
                                    ? Colors.blue.shade100
                                    : Colors.purple.shade100,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            chatDisplay.experience != null ? 'EXP' : 'WISH',
                            style: TextStyle(
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                              color:
                                  chatDisplay.experience != null
                                      ? Colors.blue.shade800
                                      : Colors.purple.shade800,
                            ),
                          ),
                        ),
                      ],

                      Expanded(
                        child: Text(
                          chat.lastMessageText,
                          style: TextStyle(
                            fontSize: 15,
                            color:
                                unreadCount > 0
                                    ? Colors.grey.shade800
                                    : Colors.grey.shade600,
                            fontWeight:
                                unreadCount > 0
                                    ? FontWeight.w500
                                    : FontWeight.normal,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (unreadCount > 0) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade600,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          constraints: const BoxConstraints(minWidth: 20),
                          child: Text(
                            unreadCount.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays == 0) {
      // Today - show time
      return DateFormat('HH:mm').format(timestamp);
    } else if (difference.inDays == 1) {
      // Yesterday
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      // This week - show day
      return DateFormat('EEE').format(timestamp);
    } else {
      // Older - show date
      return DateFormat('MM/dd').format(timestamp);
    }
  }

  /// Print detailed error information to terminal for debugging
  /// This is especially useful for Firestore database index errors
  void _printDetailedError(
    String actionType,
    dynamic error,
    StackTrace? stackTrace,
  ) {
    print('\n${'=' * 80}');
    print('🚨 CHAT LIST ERROR DETAILS');
    print('=' * 80);
    print('Action Type: $actionType');
    print('Screen: Chat List Screen');
    print('Timestamp: ${DateTime.now().toIso8601String()}');

    if (_currentUserId != null) {
      print('\nUser Context:');
      print('  - Current User ID: $_currentUserId');
      print('  - Conversations Count: ${_conversations.length}');
    }

    print('\nError Details:');
    print('  Error Type: ${error.runtimeType}');
    print('  Error Message: $error');

    // Check if this looks like a Firestore index error
    final errorString = error.toString().toLowerCase();
    if (errorString.contains('index') ||
        errorString.contains('composite') ||
        errorString.contains('requires an index')) {
      print('\n🔍 INDEX ERROR DETECTED!');
      print('This error indicates that a Firestore database index is missing.');
      print('Follow these steps to resolve:');
      print('');
      print('1. Go to Firebase Console: https://console.firebase.google.com/');
      print('2. Navigate to your project');
      print('3. Go to Firestore Database > Indexes');
      print(
        '4. Look for the suggested index configuration in the error message above',
      );
      print('5. Create the composite index as suggested');
      print('');
      print(
        'Alternative: Check the Firebase Console for automatic index creation suggestions.',
      );
    }

    // Check for permission errors
    if (errorString.contains('permission') || errorString.contains('denied')) {
      print('\n🔒 PERMISSION ERROR DETECTED!');
      print(
        'This error indicates insufficient Firestore security rules permissions.',
      );
      print(
        'Check your Firestore security rules for the chats/conversations collection.',
      );
    }

    // Print current action configuration for debugging
    print('\nAction Configuration:');

    if (actionType.contains('Chat List Stream')) {
      print('  Collection: chats/conversations');
      print('  Operation: Listen to user conversations stream');
      print('  Scenario: Loading conversation list from My Page chat overview');
      print(
        '  Required Fields: participants, lastMessageTime, lastMessageText, unreadCounts',
      );
      print(
        '  Typical query: where participants array-contains currentUserId, orderBy lastMessageTime desc',
      );
    } else if (actionType.contains('Chat Navigation')) {
      print('  Collection: chats/conversations');
      print(
        '  Operation: Mark conversation as read and navigate to chat detail',
      );
      print('  Scenario: User clicked on conversation from chat list');
      print('  Actions: markAsRead() then navigate to ChatDetailScreen');
    }

    print('\n💡 Common Chat Service Index Requirements:');
    print('  Collection: chats');
    print('  Typical indexes needed:');
    print('    - participants (Arrays), lastMessageTime (Descending)');
    print('    - participants (Arrays), updatedAt (Descending)');
    print(
      '    - participants (Arrays), experienceId (Ascending), lastMessageTime (Descending)',
    );
    print(
      '    - participants (Arrays), wishId (Ascending), lastMessageTime (Descending)',
    );

    // Print stack trace if available
    if (stackTrace != null) {
      print('\nStack Trace:');
      print(stackTrace.toString());
    }

    print('=' * 80);
    print('END ERROR DETAILS');
    print('=' * 80 + '\n');
  }
}

/// Helper class to hold processed conversation data for display
class ChatConversationDisplay {
  final ChatConversation conversation;
  final UserModel? otherUser;
  final ExperienceModel? experience;
  final WishModel? wish;
  final int unreadCount;

  ChatConversationDisplay({
    required this.conversation,
    required this.otherUser,
    this.experience,
    this.wish,
    required this.unreadCount,
  });
}
