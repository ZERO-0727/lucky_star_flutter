import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';

import '../models/chat_model.dart';
import '../models/experience_model.dart';
import '../models/wish_model.dart';
import '../models/user_model.dart';
import 'user_service.dart';

/// Service for handling chat functionality with Firestore
class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final UserService _userService = UserService();

  // Collection references
  CollectionReference get _conversations =>
      _firestore.collection('conversations');

  // Get messages subcollection for a specific conversation
  CollectionReference _getMessagesRef(String conversationId) {
    return _conversations.doc(conversationId).collection('messages');
  }

  // Get current user ID or throw error if not authenticated
  String get _currentUserId {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }
    return user.uid;
  }

  /// Create a new conversation between the current user and another user
  /// Returns the conversation ID
  Future<String> createConversation({
    required String otherUserId,
    String? experienceId,
    String? wishId,
    String? initialMessage,
  }) async {
    final currentUserId = _currentUserId;

    // Check if a conversation between these users already exists for this experience/wish
    final existingConversation = await findExistingConversation(
      otherUserId: otherUserId,
      experienceId: experienceId,
      wishId: wishId,
    );

    if (existingConversation != null) {
      // If there's already a conversation, return its ID
      return existingConversation.id;
    }

    // Create a new conversation document
    final participantIds = [currentUserId, otherUserId];

    // Initialize with empty unread counts and typing status
    final unreadCounts = <String, int>{};
    final typing = <String, bool>{};

    for (final userId in participantIds) {
      unreadCounts[userId] = 0;
      typing[userId] = false;
    }

    // Set unread count for the other user to 1 if there's an initial message
    if (initialMessage != null && initialMessage.isNotEmpty) {
      unreadCounts[otherUserId] = 1;
    }

    // Create the conversation
    final conversationRef = _conversations.doc();
    final conversationId = conversationRef.id;

    final conversation = ChatConversation(
      id: conversationId,
      participantIds: participantIds,
      experienceId: experienceId,
      wishId: wishId,
      lastMessageText: initialMessage ?? '',
      lastMessageTime: DateTime.now(),
      unreadCounts: unreadCounts,
      typing: typing,
    );

    // Save the conversation to Firestore
    await conversationRef.set(conversation.toFirestore());

    // If there's an initial message, add it to the conversation
    if (initialMessage != null && initialMessage.isNotEmpty) {
      await sendMessage(conversationId: conversationId, text: initialMessage);
    }

    return conversationId;
  }

  /// Find an existing conversation between the current user and another user
  /// with the same experience or wish ID
  Future<ChatConversation?> findExistingConversation({
    required String otherUserId,
    String? experienceId,
    String? wishId,
  }) async {
    try {
      final currentUserId = _currentUserId;

      // Build query to find conversations with both users
      Query query = _conversations
          .where('participantIds', arrayContains: currentUserId)
          .where('active', isEqualTo: true);

      // Execute the query
      final querySnapshot = await query.get();

      // Filter the results to find conversations with the other user and matching experience/wish
      for (final doc in querySnapshot.docs) {
        final conversation = ChatConversation.fromFirestore(doc);

        // Check if the other user is in the conversation
        if (!conversation.participantIds.contains(otherUserId)) {
          continue;
        }

        // Check if experienceId matches (if provided)
        if (experienceId != null && conversation.experienceId != experienceId) {
          continue;
        }

        // Check if wishId matches (if provided)
        if (wishId != null && conversation.wishId != wishId) {
          continue;
        }

        // Found a matching conversation
        return conversation;
      }

      // No matching conversation found
      return null;
    } catch (e) {
      print('Error finding existing conversation: $e');
      return null;
    }
  }

  /// Get a conversation by ID
  Future<ChatConversation?> getConversationById(String conversationId) async {
    final doc = await _conversations.doc(conversationId).get();
    if (!doc.exists) return null;
    return ChatConversation.fromFirestore(doc);
  }

  /// Get all conversations for the current user
  Future<List<ChatConversation>> getUserConversations() async {
    try {
      final currentUserId = _currentUserId;

      final querySnapshot =
          await _conversations
              .where('participantIds', arrayContains: currentUserId)
              .where('active', isEqualTo: true)
              .orderBy('lastMessageTime', descending: true)
              .get();

      return querySnapshot.docs
          .map((doc) => ChatConversation.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error getting user conversations: $e');
      return [];
    }
  }

  /// Send a message to a conversation
  Future<String> sendMessage({
    required String conversationId,
    required String text,
    String? imageUrl,
  }) async {
    final currentUserId = _currentUserId;
    final now = DateTime.now();

    // Get the conversation
    final conversationDoc = await _conversations.doc(conversationId).get();
    if (!conversationDoc.exists) {
      throw Exception('Conversation not found');
    }

    final conversation = ChatConversation.fromFirestore(conversationDoc);

    // Ensure the current user is a participant
    if (!conversation.participantIds.contains(currentUserId)) {
      throw Exception('User is not a participant in this conversation');
    }

    // Create the message document
    final messageRef = _getMessagesRef(conversationId).doc();
    final messageId = messageRef.id;

    final message = ChatMessage(
      id: messageId,
      conversationId: conversationId,
      senderId: currentUserId,
      text: text,
      timestamp: now,
      isRead: false,
      status: MessageStatus.sent,
      imageUrl: imageUrl,
    );

    // Update the conversation with the new message info
    final updatedUnreadCounts = Map<String, int>.from(
      conversation.unreadCounts,
    );

    // Increment unread count for all participants except sender
    for (final participantId in conversation.participantIds) {
      if (participantId != currentUserId) {
        updatedUnreadCounts[participantId] =
            (updatedUnreadCounts[participantId] ?? 0) + 1;
      }
    }

    // Update the conversation
    await _conversations.doc(conversationId).update({
      'lastMessageText': text,
      'lastMessageTime': Timestamp.fromDate(now),
      'unreadCounts': updatedUnreadCounts,
    });

    // Save the message
    await messageRef.set(message.toFirestore());

    return messageId;
  }

  /// Mark messages in a conversation as read for the current user
  Future<void> markAsRead(String conversationId) async {
    final currentUserId = _currentUserId;

    // Get the conversation
    final conversationDoc = await _conversations.doc(conversationId).get();
    if (!conversationDoc.exists) return;

    final conversation = ChatConversation.fromFirestore(conversationDoc);

    // Reset unread count for current user
    final updatedUnreadCounts = Map<String, int>.from(
      conversation.unreadCounts,
    );
    updatedUnreadCounts[currentUserId] = 0;

    // Update the conversation
    await _conversations.doc(conversationId).update({
      'unreadCounts': updatedUnreadCounts,
    });

    // Mark all messages from other users as read
    final batch = _firestore.batch();
    final querySnapshot =
        await _getMessagesRef(conversationId)
            .where('senderId', isNotEqualTo: currentUserId)
            .where('isRead', isEqualTo: false)
            .get();

    for (final doc in querySnapshot.docs) {
      batch.update(doc.reference, {'isRead': true, 'status': 'read'});
    }

    await batch.commit();
  }

  /// Update typing status for the current user in a conversation
  Future<void> updateTypingStatus(String conversationId, bool isTyping) async {
    final currentUserId = _currentUserId;

    // Get the conversation
    final conversationDoc = await _conversations.doc(conversationId).get();
    if (!conversationDoc.exists) return;

    // Update typing status for the current user
    await _conversations.doc(conversationId).update({
      'typing.$currentUserId': isTyping,
    });
  }

  /// Get a stream of messages for a conversation
  Stream<List<ChatMessage>> listenToMessages(String conversationId) {
    return _getMessagesRef(conversationId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => ChatMessage.fromFirestore(doc))
                  .toList(),
        );
  }

  /// Get a stream of conversations for the current user
  Stream<List<ChatConversation>> listenToUserConversations() {
    final currentUserId = _currentUserId;

    return _conversations
        .where('participantIds', arrayContains: currentUserId)
        .where('active', isEqualTo: true)
        .orderBy('lastMessageTime', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => ChatConversation.fromFirestore(doc))
                  .toList(),
        );
  }

  /// Get the total number of unread messages across all conversations
  Future<int> getTotalUnreadCount() async {
    final currentUserId = _currentUserId;

    final querySnapshot =
        await _conversations
            .where('participantIds', arrayContains: currentUserId)
            .where('active', isEqualTo: true)
            .get();

    int totalUnread = 0;

    for (final doc in querySnapshot.docs) {
      final conversation = ChatConversation.fromFirestore(doc);
      totalUnread += conversation.unreadCounts[currentUserId] ?? 0;
    }

    return totalUnread;
  }

  /// Load user details for a conversation (to display name, avatar, etc.)
  Future<UserModel?> getOtherParticipant(ChatConversation conversation) async {
    final currentUserId = _currentUserId;

    // Find the other participant's ID
    final otherUserId = conversation.participantIds.firstWhere(
      (id) => id != currentUserId,
      orElse: () => '', // Fallback if no other participant found
    );

    if (otherUserId.isEmpty) return null;

    // Fetch user details
    return _userService.getUserById(otherUserId);
  }

  /// Load experience details for a conversation
  Future<ExperienceModel?> getConversationExperience(
    ChatConversation conversation,
  ) async {
    if (conversation.experienceId == null) return null;

    final doc =
        await _firestore
            .collection('experiences')
            .doc(conversation.experienceId)
            .get();

    if (!doc.exists) return null;

    return ExperienceModel.fromFirestore(doc);
  }

  /// Load wish details for a conversation
  Future<WishModel?> getConversationWish(ChatConversation conversation) async {
    if (conversation.wishId == null) return null;

    final doc =
        await _firestore.collection('wishes').doc(conversation.wishId).get();

    if (!doc.exists) return null;

    return WishModel.fromFirestore(doc);
  }

  /// Archive a conversation (hide it without deleting)
  Future<void> archiveConversation(String conversationId) async {
    await _conversations.doc(conversationId).update({'active': false});
  }

  /// Delete a conversation and all its messages
  Future<void> deleteConversation(String conversationId) async {
    // Delete all messages in the conversation
    final messagesSnapshot = await _getMessagesRef(conversationId).get();
    final batch = _firestore.batch();

    for (final doc in messagesSnapshot.docs) {
      batch.delete(doc.reference);
    }

    // Delete the conversation
    batch.delete(_conversations.doc(conversationId));

    // Commit the batch delete
    await batch.commit();
  }
}
