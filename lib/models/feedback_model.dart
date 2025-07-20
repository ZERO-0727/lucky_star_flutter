import 'package:cloud_firestore/cloud_firestore.dart';

class FeedbackModel {
  final String feedbackId;
  final String userId;
  final String? userDisplayName;
  final String? userEmail;
  final String type;
  final String content;
  final DateTime createdAt;
  final String status; // 'pending', 'reviewed', 'resolved'

  FeedbackModel({
    required this.feedbackId,
    required this.userId,
    this.userDisplayName,
    this.userEmail,
    required this.type,
    required this.content,
    required this.createdAt,
    this.status = 'pending',
  });

  // Create a FeedbackModel from Firestore document
  factory FeedbackModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    return FeedbackModel(
      feedbackId: doc.id,
      userId: data['userId'] ?? '',
      userDisplayName: data['userDisplayName'],
      userEmail: data['userEmail'],
      type: data['type'] ?? '',
      content: data['content'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: data['status'] ?? 'pending',
    );
  }

  // Convert FeedbackModel to Map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'userDisplayName': userDisplayName,
      'userEmail': userEmail,
      'type': type,
      'content': content,
      'createdAt': Timestamp.fromDate(createdAt),
      'status': status,
    };
  }

  // Create a copy with updated fields
  FeedbackModel copyWith({
    String? feedbackId,
    String? userId,
    String? userDisplayName,
    String? userEmail,
    String? type,
    String? content,
    DateTime? createdAt,
    String? status,
  }) {
    return FeedbackModel(
      feedbackId: feedbackId ?? this.feedbackId,
      userId: userId ?? this.userId,
      userDisplayName: userDisplayName ?? this.userDisplayName,
      userEmail: userEmail ?? this.userEmail,
      type: type ?? this.type,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
    );
  }

  @override
  String toString() {
    return 'FeedbackModel(id: $feedbackId, userId: $userId, type: $type, status: $status)';
  }
}
