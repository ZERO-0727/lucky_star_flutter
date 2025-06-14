import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a chat conversation between two users
class ChatConversation {
  final String id;
  final List<String> participantIds; // User IDs of participants
  final String? experienceId; // Reference to experience (if applicable)
  final String? wishId; // Reference to wish (if applicable)
  final String lastMessageText;
  final DateTime lastMessageTime;
  final Map<String, int> unreadCounts; // Map of userId -> unread count
  final Map<String, bool> typing; // Map of userId -> typing status
  final bool active; // Whether the conversation is active or archived

  ChatConversation({
    required this.id,
    required this.participantIds,
    this.experienceId,
    this.wishId,
    required this.lastMessageText,
    required this.lastMessageTime,
    required this.unreadCounts,
    required this.typing,
    this.active = true,
  });

  /// Create a new conversation instance from a Firestore document
  factory ChatConversation.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ChatConversation(
      id: doc.id,
      participantIds: List<String>.from(data['participantIds'] ?? []),
      experienceId: data['experienceId'],
      wishId: data['wishId'],
      lastMessageText: data['lastMessageText'] ?? '',
      lastMessageTime:
          (data['lastMessageTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
      unreadCounts: Map<String, int>.from(data['unreadCounts'] ?? {}),
      typing: Map<String, bool>.from(data['typing'] ?? {}),
      active: data['active'] ?? true,
    );
  }

  /// Convert this conversation to a map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'participantIds': participantIds,
      'experienceId': experienceId,
      'wishId': wishId,
      'lastMessageText': lastMessageText,
      'lastMessageTime': Timestamp.fromDate(lastMessageTime),
      'unreadCounts': unreadCounts,
      'typing': typing,
      'active': active,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  /// Create a new instance with updated properties
  ChatConversation copyWith({
    String? id,
    List<String>? participantIds,
    String? experienceId,
    String? wishId,
    String? lastMessageText,
    DateTime? lastMessageTime,
    Map<String, int>? unreadCounts,
    Map<String, bool>? typing,
    bool? active,
  }) {
    return ChatConversation(
      id: id ?? this.id,
      participantIds: participantIds ?? this.participantIds,
      experienceId: experienceId ?? this.experienceId,
      wishId: wishId ?? this.wishId,
      lastMessageText: lastMessageText ?? this.lastMessageText,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      unreadCounts: unreadCounts ?? this.unreadCounts,
      typing: typing ?? this.typing,
      active: active ?? this.active,
    );
  }
}

/// Represents a single message in a chat conversation
class ChatMessage {
  final String id;
  final String conversationId;
  final String senderId;
  final String text;
  final DateTime timestamp;
  final bool isRead;
  final MessageStatus status;
  final String? imageUrl;

  ChatMessage({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.text,
    required this.timestamp,
    this.isRead = false,
    this.status = MessageStatus.sent,
    this.imageUrl,
  });

  /// Create a new message instance from a Firestore document
  factory ChatMessage.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ChatMessage(
      id: doc.id,
      conversationId: data['conversationId'] ?? '',
      senderId: data['senderId'] ?? '',
      text: data['text'] ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isRead: data['isRead'] ?? false,
      status: _messageStatusFromString(data['status'] ?? 'sent'),
      imageUrl: data['imageUrl'],
    );
  }

  /// Convert this message to a map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'conversationId': conversationId,
      'senderId': senderId,
      'text': text,
      'timestamp': Timestamp.fromDate(timestamp),
      'isRead': isRead,
      'status': status.toString().split('.').last,
      'imageUrl': imageUrl,
    };
  }

  /// Helper method to convert string to MessageStatus enum
  static MessageStatus _messageStatusFromString(String status) {
    switch (status) {
      case 'sending':
        return MessageStatus.sending;
      case 'sent':
        return MessageStatus.sent;
      case 'delivered':
        return MessageStatus.delivered;
      case 'read':
        return MessageStatus.read;
      case 'failed':
        return MessageStatus.failed;
      default:
        return MessageStatus.sent;
    }
  }

  /// Create a new instance with updated properties
  ChatMessage copyWith({
    String? id,
    String? conversationId,
    String? senderId,
    String? text,
    DateTime? timestamp,
    bool? isRead,
    MessageStatus? status,
    String? imageUrl,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      senderId: senderId ?? this.senderId,
      text: text ?? this.text,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      status: status ?? this.status,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }
}

/// Enum representing the status of a message
enum MessageStatus { sending, sent, delivered, read, failed }
