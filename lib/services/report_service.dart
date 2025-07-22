import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/report_model.dart';

class ReportService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'reports';

  // Get a reference to the reports collection
  CollectionReference<Map<String, dynamic>> get _reportsCollection =>
      _firestore.collection(_collection);

  /// Report a user with comprehensive details
  Future<String> reportUser({
    required String reportedUserId,
    required ReportReason reason,
    required String category,
    required String description,
    String? chatId,
    String? messageId,
    List<String> evidence = const [],
  }) async {
    try {
      final String currentUserId = _getCurrentUserId();

      // Prevent self-reporting
      if (currentUserId == reportedUserId) {
        throw Exception('Cannot report yourself');
      }

      // Check for duplicate reports (same reporter, reported user, and reason within 24 hours)
      final oneDayAgo = DateTime.now().subtract(const Duration(days: 1));
      final duplicateQuery =
          await _reportsCollection
              .where('reporterId', isEqualTo: currentUserId)
              .where('reportedUserId', isEqualTo: reportedUserId)
              .where('reason', isEqualTo: reason.toString().split('.').last)
              .where('createdAt', isGreaterThan: Timestamp.fromDate(oneDayAgo))
              .get();

      if (duplicateQuery.docs.isNotEmpty) {
        throw Exception(
          'You have already reported this user for the same reason recently',
        );
      }

      // Auto-assign severity based on reason
      final severity = ReportModel.autoAssignSeverity(reason);

      // Create the report
      final reportData = {
        'reporterId': currentUserId,
        'reportedUserId': reportedUserId,
        'reason': reason.toString().split('.').last,
        'category': category,
        'description': description,
        'chatId': chatId,
        'messageId': messageId,
        'evidence': evidence,
        'status': ReportStatus.pending.toString().split('.').last,
        'createdAt': FieldValue.serverTimestamp(),
        'severity': severity.toString().split('.').last,
      };

      final docRef = await _reportsCollection.add(reportData);

      // Auto-escalate critical reports
      if (severity == ReportSeverity.critical) {
        await _escalateReport(
          docRef.id,
          'Auto-escalated due to critical severity',
        );
      }

      print('User $reportedUserId reported successfully with ID: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      print('Error reporting user: $e');
      rethrow;
    }
  }

  /// Get reports made by the current user
  Future<List<ReportModel>> getMyReports({int limit = 20}) async {
    try {
      final String currentUserId = _getCurrentUserId();

      final querySnapshot =
          await _reportsCollection
              .where('reporterId', isEqualTo: currentUserId)
              .orderBy('createdAt', descending: true)
              .limit(limit)
              .get();

      return querySnapshot.docs
          .map((doc) => ReportModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error getting my reports: $e');
      rethrow;
    }
  }

  /// Get reports against a specific user (admin function)
  Future<List<ReportModel>> getReportsAgainstUser(
    String userId, {
    int limit = 50,
  }) async {
    try {
      final querySnapshot =
          await _reportsCollection
              .where('reportedUserId', isEqualTo: userId)
              .orderBy('createdAt', descending: true)
              .limit(limit)
              .get();

      return querySnapshot.docs
          .map((doc) => ReportModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error getting reports against user: $e');
      rethrow;
    }
  }

  /// Get reports by status (admin function)
  Future<List<ReportModel>> getReportsByStatus(
    ReportStatus status, {
    int limit = 50,
  }) async {
    try {
      final querySnapshot =
          await _reportsCollection
              .where('status', isEqualTo: status.toString().split('.').last)
              .orderBy('createdAt', descending: true)
              .limit(limit)
              .get();

      return querySnapshot.docs
          .map((doc) => ReportModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error getting reports by status: $e');
      rethrow;
    }
  }

  /// Get reports by severity (admin function)
  Future<List<ReportModel>> getReportsBySeverity(
    ReportSeverity severity, {
    int limit = 50,
  }) async {
    try {
      final querySnapshot =
          await _reportsCollection
              .where('severity', isEqualTo: severity.toString().split('.').last)
              .orderBy('createdAt', descending: true)
              .limit(limit)
              .get();

      return querySnapshot.docs
          .map((doc) => ReportModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error getting reports by severity: $e');
      rethrow;
    }
  }

  /// Update report status (admin function)
  Future<void> updateReportStatus(
    String reportId,
    ReportStatus newStatus, {
    String? adminNotes,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'status': newStatus.toString().split('.').last,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (adminNotes != null) {
        updateData['adminNotes'] = adminNotes;
      }

      if (newStatus == ReportStatus.resolved ||
          newStatus == ReportStatus.dismissed) {
        updateData['resolvedAt'] = FieldValue.serverTimestamp();
      }

      await _reportsCollection.doc(reportId).update(updateData);

      print('Report $reportId status updated to $newStatus');
    } catch (e) {
      print('Error updating report status: $e');
      rethrow;
    }
  }

  /// Get report by ID
  Future<ReportModel?> getReportById(String reportId) async {
    try {
      final doc = await _reportsCollection.doc(reportId).get();

      if (!doc.exists) {
        return null;
      }

      return ReportModel.fromFirestore(doc);
    } catch (e) {
      print('Error getting report by ID: $e');
      rethrow;
    }
  }

  /// Get report count for a specific user (for auto-moderation)
  Future<int> getReportCountForUser(
    String userId, {
    Duration? timeframe,
  }) async {
    try {
      Query query = _reportsCollection
          .where('reportedUserId', isEqualTo: userId)
          .where('status', whereIn: ['pending', 'reviewing']);

      if (timeframe != null) {
        final cutoffDate = DateTime.now().subtract(timeframe);
        query = query.where(
          'createdAt',
          isGreaterThan: Timestamp.fromDate(cutoffDate),
        );
      }

      final querySnapshot = await query.get();
      return querySnapshot.docs.length;
    } catch (e) {
      print('Error getting report count: $e');
      return 0;
    }
  }

  /// Check if user should be auto-flagged based on reports
  Future<bool> shouldAutoFlag(String userId) async {
    try {
      // Get report counts for different time periods
      final reportsLast24h = await getReportCountForUser(
        userId,
        timeframe: const Duration(hours: 24),
      );
      final reportsLast7days = await getReportCountForUser(
        userId,
        timeframe: const Duration(days: 7),
      );

      // Define thresholds
      const int threshold24h = 3;
      const int threshold7days = 10;

      return reportsLast24h >= threshold24h ||
          reportsLast7days >= threshold7days;
    } catch (e) {
      print('Error checking auto-flag status: $e');
      return false;
    }
  }

  /// Escalate a report to higher priority (internal method)
  Future<void> _escalateReport(String reportId, String reason) async {
    try {
      await _reportsCollection.doc(reportId).update({
        'status': ReportStatus.reviewing.toString().split('.').last,
        'escalated': true,
        'escalationReason': reason,
        'escalatedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print('Report $reportId escalated: $reason');
    } catch (e) {
      print('Error escalating report: $e');
      rethrow;
    }
  }

  /// Get trending report reasons (analytics)
  Future<Map<String, int>> getTrendingReportReasons({
    Duration timeframe = const Duration(days: 7),
  }) async {
    try {
      final cutoffDate = DateTime.now().subtract(timeframe);
      final querySnapshot =
          await _reportsCollection
              .where('createdAt', isGreaterThan: Timestamp.fromDate(cutoffDate))
              .get();

      final reasonCounts = <String, int>{};

      for (final doc in querySnapshot.docs) {
        final data = doc.data();
        final reason = data['reason'] as String? ?? 'unknown';
        reasonCounts[reason] = (reasonCounts[reason] ?? 0) + 1;
      }

      return reasonCounts;
    } catch (e) {
      print('Error getting trending report reasons: $e');
      return {};
    }
  }

  /// Add evidence to an existing report
  Future<void> addEvidenceToReport(
    String reportId,
    List<String> evidenceUrls,
  ) async {
    try {
      await _reportsCollection.doc(reportId).update({
        'evidence': FieldValue.arrayUnion(evidenceUrls),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print('Evidence added to report $reportId');
    } catch (e) {
      print('Error adding evidence to report: $e');
      rethrow;
    }
  }

  /// Delete a report (admin only, rarely used)
  Future<void> deleteReport(String reportId) async {
    try {
      await _reportsCollection.doc(reportId).delete();
      print('Report $reportId deleted');
    } catch (e) {
      print('Error deleting report: $e');
      rethrow;
    }
  }

  /// Stream reports for real-time admin dashboard
  Stream<List<ReportModel>> streamReportsByStatus(ReportStatus status) {
    return _reportsCollection
        .where('status', isEqualTo: status.toString().split('.').last)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map(
          (querySnapshot) =>
              querySnapshot.docs
                  .map((doc) => ReportModel.fromFirestore(doc))
                  .toList(),
        );
  }

  /// Helper method to get current user ID
  String _getCurrentUserId() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('No authenticated user found');
    }
    return user.uid;
  }

  /// Validate if current user is admin (placeholder - implement based on your admin system)
  Future<bool> _isCurrentUserAdmin() async {
    // TODO: Implement admin validation based on your user roles system
    // This could check a user's role in Firestore, or verify against a list of admin UIDs
    return false;
  }
}
