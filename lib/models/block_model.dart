import 'package:cloud_firestore/cloud_firestore.dart';

class BlockModel {
  final String id;
  final String blockerId;
  final String blockedUserId;
  final DateTime createdAt;
  final String reason;
  final String status;
  final Map<String, dynamic> metadata;

  BlockModel({
    required this.id,
    required this.blockerId,
    required this.blockedUserId,
    required this.createdAt,
    this.reason = 'user_initiated',
    this.status = 'active',
    this.metadata = const {},
  });

  /// Create a BlockModel from a Firestore document
  factory BlockModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return BlockModel(
      id: doc.id,
      blockerId: data['blockerId'] ?? '',
      blockedUserId: data['blockedUserId'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      reason: data['reason'] ?? 'user_initiated',
      status: data['status'] ?? 'active',
      metadata: data['metadata'] as Map<String, dynamic>? ?? {},
    );
  }

  /// Convert BlockModel to a Map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'blockerId': blockerId,
      'blockedUserId': blockedUserId,
      'createdAt': Timestamp.fromDate(createdAt),
      'reason': reason,
      'status': status,
      'metadata': metadata,
    };
  }

  /// Create a new instance with updated fields
  BlockModel copyWith({
    String? id,
    String? blockerId,
    String? blockedUserId,
    DateTime? createdAt,
    String? reason,
    String? status,
    Map<String, dynamic>? metadata,
  }) {
    return BlockModel(
      id: id ?? this.id,
      blockerId: blockerId ?? this.blockerId,
      blockedUserId: blockedUserId ?? this.blockedUserId,
      createdAt: createdAt ?? this.createdAt,
      reason: reason ?? this.reason,
      status: status ?? this.status,
      metadata: metadata ?? this.metadata,
    );
  }
}
