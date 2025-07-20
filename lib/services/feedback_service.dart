import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/feedback_model.dart';

class FeedbackService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final CollectionReference _feedbackCollection = _firestore.collection(
    'feedback',
  );

  /// Submit new feedback
  static Future<String?> submitFeedback({
    required String type,
    required String content,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User must be authenticated to submit feedback');
      }

      // Get user display name from Firestore user document if available
      String? userDisplayName = user.displayName;
      try {
        final userDoc =
            await _firestore.collection('users').doc(user.uid).get();
        if (userDoc.exists) {
          final userData = userDoc.data() as Map<String, dynamic>?;
          userDisplayName = userData?['displayName'] ?? user.displayName;
        }
      } catch (e) {
        print('Error fetching user display name: $e');
        // Continue with default display name
      }

      final feedback = FeedbackModel(
        feedbackId: '', // Will be set by Firestore
        userId: user.uid,
        userDisplayName: userDisplayName,
        userEmail: user.email,
        type: type,
        content: content.trim(),
        createdAt: DateTime.now(),
        status: 'pending',
      );

      final docRef = await _feedbackCollection.add(feedback.toFirestore());

      print('Feedback submitted successfully: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      print('Error submitting feedback: $e');
      throw Exception('Failed to submit feedback: $e');
    }
  }

  /// Get all feedback (for admin purposes)
  static Future<List<FeedbackModel>> getAllFeedback({
    String? status,
    int? limit,
  }) async {
    try {
      Query query = _feedbackCollection.orderBy('createdAt', descending: true);

      if (status != null) {
        query = query.where('status', isEqualTo: status);
      }

      if (limit != null) {
        query = query.limit(limit);
      }

      final querySnapshot = await query.get();

      return querySnapshot.docs
          .map((doc) => FeedbackModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error getting feedback: $e');
      throw Exception('Failed to get feedback: $e');
    }
  }

  /// Get feedback by user ID
  static Future<List<FeedbackModel>> getFeedbackByUser(String userId) async {
    try {
      final querySnapshot =
          await _feedbackCollection
              .where('userId', isEqualTo: userId)
              .orderBy('createdAt', descending: true)
              .get();

      return querySnapshot.docs
          .map((doc) => FeedbackModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error getting user feedback: $e');
      throw Exception('Failed to get user feedback: $e');
    }
  }

  /// Update feedback status (for admin purposes)
  static Future<void> updateFeedbackStatus({
    required String feedbackId,
    required String status,
  }) async {
    try {
      await _feedbackCollection.doc(feedbackId).update({
        'status': status,
        'updatedAt': Timestamp.now(),
      });

      print('Feedback status updated: $feedbackId -> $status');
    } catch (e) {
      print('Error updating feedback status: $e');
      throw Exception('Failed to update feedback status: $e');
    }
  }

  /// Get feedback by ID
  static Future<FeedbackModel?> getFeedbackById(String feedbackId) async {
    try {
      final doc = await _feedbackCollection.doc(feedbackId).get();

      if (doc.exists) {
        return FeedbackModel.fromFirestore(doc);
      }

      return null;
    } catch (e) {
      print('Error getting feedback by ID: $e');
      throw Exception('Failed to get feedback: $e');
    }
  }

  /// Delete feedback (for admin purposes)
  static Future<void> deleteFeedback(String feedbackId) async {
    try {
      await _feedbackCollection.doc(feedbackId).delete();
      print('Feedback deleted: $feedbackId');
    } catch (e) {
      print('Error deleting feedback: $e');
      throw Exception('Failed to delete feedback: $e');
    }
  }

  /// Get feedback statistics
  static Future<Map<String, int>> getFeedbackStats() async {
    try {
      final querySnapshot = await _feedbackCollection.get();
      final docs = querySnapshot.docs;

      int total = docs.length;
      int pending = 0;
      int reviewed = 0;
      int resolved = 0;

      Map<String, int> typeCount = {};

      for (final doc in docs) {
        final data = doc.data() as Map<String, dynamic>;
        final status = data['status'] ?? 'pending';
        final type = data['type'] ?? 'Other';

        switch (status) {
          case 'pending':
            pending++;
            break;
          case 'reviewed':
            reviewed++;
            break;
          case 'resolved':
            resolved++;
            break;
        }

        typeCount[type] = (typeCount[type] ?? 0) + 1;
      }

      return {
        'total': total,
        'pending': pending,
        'reviewed': reviewed,
        'resolved': resolved,
        ...typeCount,
      };
    } catch (e) {
      print('Error getting feedback stats: $e');
      throw Exception('Failed to get feedback statistics: $e');
    }
  }
}
