import 'package:cloud_firestore/cloud_firestore.dart';

enum ReportReason {
  harassment,
  spam,
  inappropriateContent,
  fakeAccount,
  impersonation,
  selfHarm,
  violence,
  other,
}

enum ReportStatus { pending, reviewing, resolved, dismissed }

enum ReportSeverity { low, medium, high, critical }

class ReportModel {
  final String id;
  final String reporterId;
  final String reportedUserId;
  final ReportReason reason;
  final String category;
  final String description;
  final String? chatId;
  final String? messageId;
  final List<String> evidence;
  final ReportStatus status;
  final DateTime createdAt;
  final DateTime? resolvedAt;
  final String? adminNotes;
  final ReportSeverity severity;

  ReportModel({
    required this.id,
    required this.reporterId,
    required this.reportedUserId,
    required this.reason,
    required this.category,
    required this.description,
    this.chatId,
    this.messageId,
    this.evidence = const [],
    this.status = ReportStatus.pending,
    required this.createdAt,
    this.resolvedAt,
    this.adminNotes,
    this.severity = ReportSeverity.medium,
  });

  /// Create a ReportModel from a Firestore document
  factory ReportModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return ReportModel(
      id: doc.id,
      reporterId: data['reporterId'] ?? '',
      reportedUserId: data['reportedUserId'] ?? '',
      reason: _reportReasonFromString(data['reason'] ?? 'other'),
      category: data['category'] ?? 'other',
      description: data['description'] ?? '',
      chatId: data['chatId'],
      messageId: data['messageId'],
      evidence: List<String>.from(data['evidence'] ?? []),
      status: _reportStatusFromString(data['status'] ?? 'pending'),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      resolvedAt: (data['resolvedAt'] as Timestamp?)?.toDate(),
      adminNotes: data['adminNotes'],
      severity: _reportSeverityFromString(data['severity'] ?? 'medium'),
    );
  }

  /// Convert ReportModel to a Map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'reporterId': reporterId,
      'reportedUserId': reportedUserId,
      'reason': reason.toString().split('.').last,
      'category': category,
      'description': description,
      'chatId': chatId,
      'messageId': messageId,
      'evidence': evidence,
      'status': status.toString().split('.').last,
      'createdAt': Timestamp.fromDate(createdAt),
      'resolvedAt': resolvedAt != null ? Timestamp.fromDate(resolvedAt!) : null,
      'adminNotes': adminNotes,
      'severity': severity.toString().split('.').last,
    };
  }

  /// Helper method to convert string to ReportReason enum
  static ReportReason _reportReasonFromString(String reason) {
    switch (reason.toLowerCase()) {
      case 'harassment':
        return ReportReason.harassment;
      case 'spam':
        return ReportReason.spam;
      case 'inappropriatecontent':
      case 'inappropriate_content':
        return ReportReason.inappropriateContent;
      case 'fakeaccount':
      case 'fake_account':
        return ReportReason.fakeAccount;
      case 'impersonation':
        return ReportReason.impersonation;
      case 'selfharm':
      case 'self_harm':
        return ReportReason.selfHarm;
      case 'violence':
        return ReportReason.violence;
      case 'other':
      default:
        return ReportReason.other;
    }
  }

  /// Helper method to convert string to ReportStatus enum
  static ReportStatus _reportStatusFromString(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return ReportStatus.pending;
      case 'reviewing':
        return ReportStatus.reviewing;
      case 'resolved':
        return ReportStatus.resolved;
      case 'dismissed':
        return ReportStatus.dismissed;
      default:
        return ReportStatus.pending;
    }
  }

  /// Helper method to convert string to ReportSeverity enum
  static ReportSeverity _reportSeverityFromString(String severity) {
    switch (severity.toLowerCase()) {
      case 'low':
        return ReportSeverity.low;
      case 'medium':
        return ReportSeverity.medium;
      case 'high':
        return ReportSeverity.high;
      case 'critical':
        return ReportSeverity.critical;
      default:
        return ReportSeverity.medium;
    }
  }

  /// Create a new instance with updated fields
  ReportModel copyWith({
    String? id,
    String? reporterId,
    String? reportedUserId,
    ReportReason? reason,
    String? category,
    String? description,
    String? chatId,
    String? messageId,
    List<String>? evidence,
    ReportStatus? status,
    DateTime? createdAt,
    DateTime? resolvedAt,
    String? adminNotes,
    ReportSeverity? severity,
  }) {
    return ReportModel(
      id: id ?? this.id,
      reporterId: reporterId ?? this.reporterId,
      reportedUserId: reportedUserId ?? this.reportedUserId,
      reason: reason ?? this.reason,
      category: category ?? this.category,
      description: description ?? this.description,
      chatId: chatId ?? this.chatId,
      messageId: messageId ?? this.messageId,
      evidence: evidence ?? this.evidence,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      adminNotes: adminNotes ?? this.adminNotes,
      severity: severity ?? this.severity,
    );
  }

  /// Get display-friendly reason text
  String get reasonDisplayText {
    switch (reason) {
      case ReportReason.harassment:
        return 'Harassment';
      case ReportReason.spam:
        return 'Spam';
      case ReportReason.inappropriateContent:
        return 'Inappropriate Content';
      case ReportReason.fakeAccount:
        return 'Fake Account';
      case ReportReason.impersonation:
        return 'Impersonation';
      case ReportReason.selfHarm:
        return 'Self Harm';
      case ReportReason.violence:
        return 'Violence';
      case ReportReason.other:
        return 'Other';
    }
  }

  /// Get display-friendly status text
  String get statusDisplayText {
    switch (status) {
      case ReportStatus.pending:
        return 'Pending Review';
      case ReportStatus.reviewing:
        return 'Under Review';
      case ReportStatus.resolved:
        return 'Resolved';
      case ReportStatus.dismissed:
        return 'Dismissed';
    }
  }

  /// Get display-friendly severity text
  String get severityDisplayText {
    switch (severity) {
      case ReportSeverity.low:
        return 'Low';
      case ReportSeverity.medium:
        return 'Medium';
      case ReportSeverity.high:
        return 'High';
      case ReportSeverity.critical:
        return 'Critical';
    }
  }

  /// Auto-assign severity based on reason
  static ReportSeverity autoAssignSeverity(ReportReason reason) {
    switch (reason) {
      case ReportReason.violence:
      case ReportReason.selfHarm:
        return ReportSeverity.critical;
      case ReportReason.harassment:
      case ReportReason.inappropriateContent:
        return ReportSeverity.high;
      case ReportReason.impersonation:
      case ReportReason.fakeAccount:
        return ReportSeverity.medium;
      case ReportReason.spam:
      case ReportReason.other:
        return ReportSeverity.low;
    }
  }
}
