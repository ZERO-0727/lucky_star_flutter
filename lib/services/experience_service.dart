import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:flutter/foundation.dart';
import '../models/experience_model.dart';
import 'web_image_service.dart';
import 'user_service.dart';

class ExperienceService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _imagePicker = ImagePicker();
  final UserService _userService = UserService();

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Collection reference
  CollectionReference get _experiencesCollection =>
      _firestore.collection('experiences');

  /// Upload single image to Firebase Storage (for progress tracking)
  Future<String> uploadSingleImage(XFile imageFile) async {
    if (currentUser == null) {
      throw Exception('No authenticated user');
    }

    // Check if running on web
    if (kIsWeb) {
      return WebImageService.uploadImagesWeb([
        imageFile,
      ]).then((urls) => urls.isNotEmpty ? urls.first : '');
    }

    // Enhanced mobile code for non-web platforms
    try {
      final file = File(imageFile.path);
      final fileName =
          'experience_${DateTime.now().millisecondsSinceEpoch}${path.extension(imageFile.path)}';

      // CRITICAL: Use same path structure as web
      final storageRef = _storage
          .ref()
          .child('experience_images') // Same as web
          .child(currentUser!.uid)
          .child(fileName);

      print('📤 Uploading single image: $fileName');
      print('🔗 Firebase Storage path: ${storageRef.fullPath}');

      final uploadTask = storageRef.putFile(file);
      final snapshot = await uploadTask;

      // CRITICAL: Get the actual Firebase download URL
      final downloadUrl = await snapshot.ref.getDownloadURL();

      // CRITICAL: Validate the URL before returning
      if (downloadUrl.isEmpty || !downloadUrl.startsWith('https://')) {
        print('❌ Invalid download URL received: $downloadUrl');
        throw Exception('Invalid download URL: $downloadUrl');
      }

      // CRITICAL: Ensure it's a proper Firebase Storage URL
      if (!downloadUrl.contains('firebasestorage.googleapis.com')) {
        print('❌ Not a Firebase Storage URL: $downloadUrl');
        throw Exception('Not a Firebase Storage URL: $downloadUrl');
      }

      print('🎉 Valid Firebase download URL: $downloadUrl');
      print('✅ Single image uploaded successfully with validation');
      return downloadUrl;
    } catch (e) {
      print('❌ Error uploading single image: $e');
      return ''; // Return empty string for failed uploads
    }
  }

  /// Upload multiple images to Firebase Storage
  Future<List<String>> uploadImages(List<XFile> imageFiles) async {
    if (currentUser == null) {
      throw Exception('No authenticated user');
    }

    // Check if running on web - temporarily use original method for debugging
    if (kIsWeb) {
      // TODO: Switch back to OptimizedImageService after fixing Firebase Storage
      return WebImageService.uploadImagesWeb(imageFiles);
      // return OptimizedImageService.uploadImagesOptimized(imageFiles);
    }

    // Original mobile code for non-web platforms
    List<String> downloadUrls = [];

    for (int i = 0; i < imageFiles.length; i++) {
      try {
        final file = File(imageFiles[i].path);
        final fileName =
            '${DateTime.now().millisecondsSinceEpoch}_$i${path.extension(imageFiles[i].path)}';
        final storageRef = _storage
            .ref()
            .child('experiences')
            .child(currentUser!.uid)
            .child(fileName);

        print('Uploading image ${i + 1}/${imageFiles.length}: $fileName');

        final uploadTask = storageRef.putFile(file);
        final snapshot = await uploadTask;
        final downloadUrl = await snapshot.ref.getDownloadURL();

        downloadUrls.add(downloadUrl);
        print('Image uploaded successfully: $downloadUrl');
      } catch (e) {
        print('Error uploading image ${i + 1}: $e');
        // Continue with other images even if one fails
      }
    }

    debugPrint('✅ Successfully uploaded ${downloadUrls.length} images');
    debugPrint('📸 Image URLs: $downloadUrls');

    return downloadUrls;
  }

  /// Pick images from gallery
  Future<List<XFile>> pickImages() async {
    try {
      final List<XFile> images = await _imagePicker.pickMultiImage(
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      // Limit to 10 images maximum
      if (images.length > 10) {
        print('Warning: User selected ${images.length} images, limiting to 10');
        return images.take(10).toList();
      }

      return images;
    } catch (e) {
      print('Error picking images: $e');
      return [];
    }
  }

  /// Create a new experience
  Future<String> createExperience(ExperienceModel experience) async {
    if (currentUser == null) {
      throw Exception('No authenticated user');
    }

    try {
      print('Creating experience: ${experience.title}');

      // Create user reference
      final userRef = _firestore.collection('users').doc(currentUser!.uid);

      // Create experience with user reference
      final experienceData = experience.toFirestore();
      experienceData['userRef'] = userRef;
      experienceData['userId'] = currentUser!.uid;

      final docRef = await _experiencesCollection.add(experienceData);
      final expId = docRef.id;

      // NOTE: Images are now uploaded separately in background
      // This method only creates the Firestore document for immediate feedback

      print('Experience created successfully with ID: $expId');
      return expId;
    } catch (e) {
      print('Error creating experience: $e');
      throw Exception('Failed to create experience: $e');
    }
  }

  /// Get all experiences with optional filters (excludes blocked users)
  Future<List<ExperienceModel>> getExperiences({
    String? category,
    String? location,
    int limit = 20,
  }) async {
    try {
      // Get blocked users list first
      final blockedUsers = await _userService.getBlockedUsers();

      Query query = _experiencesCollection
          .where('status', isEqualTo: 'active')
          .where('isPublic', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .limit(limit * 2); // Get more to account for filtering

      if (category != null && category.isNotEmpty) {
        query = query.where('tags', arrayContains: category);
      }

      if (location != null && location.isNotEmpty) {
        query = query.where('location', isEqualTo: location);
      }

      final querySnapshot = await query.get();

      final allExperiences =
          querySnapshot.docs
              .map((doc) => ExperienceModel.fromFirestore(doc))
              .toList();

      // Filter out experiences from blocked users
      final filteredExperiences =
          allExperiences
              .where((experience) => !blockedUsers.contains(experience.userId))
              .take(limit)
              .toList();

      return filteredExperiences;
    } catch (e) {
      print('Error getting experiences: $e');
      throw Exception('Failed to get experiences: $e');
    }
  }

  /// Get experiences stream for real-time updates
  Stream<List<ExperienceModel>> getExperiencesStream({
    String? category,
    String? location,
    int limit = 20,
  }) {
    try {
      Query query = _experiencesCollection
          .where('status', isEqualTo: 'active')
          .where('isPublic', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .limit(limit);

      if (category != null && category.isNotEmpty) {
        query = query.where('tags', arrayContains: category);
      }

      if (location != null && location.isNotEmpty) {
        query = query.where('location', isEqualTo: location);
      }

      return query.snapshots().map((snapshot) {
        return snapshot.docs
            .map((doc) => ExperienceModel.fromFirestore(doc))
            .toList();
      });
    } catch (e) {
      print('Error getting experiences stream: $e');
      throw Exception('Failed to get experiences stream: $e');
    }
  }

  /// Get experience by ID
  Future<ExperienceModel?> getExperience(String experienceId) async {
    try {
      final doc = await _experiencesCollection.doc(experienceId).get();

      if (doc.exists) {
        return ExperienceModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Error getting experience: $e');
      throw Exception('Failed to get experience: $e');
    }
  }

  /// Get user's own experiences
  Future<List<ExperienceModel>> getUserExperiences([String? userId]) async {
    final targetUserId = userId ?? currentUser?.uid;

    if (targetUserId == null) {
      throw Exception('No user ID provided');
    }

    try {
      final querySnapshot =
          await _experiencesCollection
              .where('userId', isEqualTo: targetUserId)
              .orderBy('createdAt', descending: true)
              .get();

      return querySnapshot.docs
          .map((doc) => ExperienceModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error getting user experiences: $e');
      throw Exception('Failed to get user experiences: $e');
    }
  }

  /// Update experience
  Future<void> updateExperience(
    String expId,
    Map<String, dynamic> updates,
  ) async {
    try {
      debugPrint('🔄 Updating experience $expId with: $updates');
      await _firestore.collection('experiences').doc(expId).update(updates);
      debugPrint('✅ Successfully updated experience $expId');
    } catch (e) {
      debugPrint('❌ Error updating experience: $e');
      rethrow;
    }
  }

  /// Delete experience
  Future<void> deleteExperience(String experienceId) async {
    if (currentUser == null) {
      throw Exception('No authenticated user');
    }

    try {
      // Soft delete by updating status
      await _experiencesCollection.doc(experienceId).update({
        'status': 'deleted',
        'updatedAt': FieldValue.serverTimestamp(),
      });
      print('Experience deleted successfully: $experienceId');
    } catch (e) {
      print('Error deleting experience: $e');
      throw Exception('Failed to delete experience: $e');
    }
  }

  /// Join experience (increment participants)
  Future<void> joinExperience(String experienceId) async {
    if (currentUser == null) {
      throw Exception('No authenticated user');
    }

    try {
      await _firestore.runTransaction((transaction) async {
        final experienceDoc = await transaction.get(
          _experiencesCollection.doc(experienceId),
        );

        if (!experienceDoc.exists) {
          throw Exception('Experience not found');
        }

        final experience = ExperienceModel.fromFirestore(experienceDoc);

        if (!experience.hasAvailableSlots) {
          throw Exception('No available slots');
        }

        transaction.update(_experiencesCollection.doc(experienceId), {
          'currentParticipants': FieldValue.increment(1),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });

      print('Successfully joined experience: $experienceId');
    } catch (e) {
      print('Error joining experience: $e');
      throw Exception('Failed to join experience: $e');
    }
  }

  /// Leave experience (decrement participants)
  Future<void> leaveExperience(String experienceId) async {
    if (currentUser == null) {
      throw Exception('No authenticated user');
    }

    try {
      await _firestore.runTransaction((transaction) async {
        final experienceDoc = await transaction.get(
          _experiencesCollection.doc(experienceId),
        );

        if (!experienceDoc.exists) {
          throw Exception('Experience not found');
        }

        final experience = ExperienceModel.fromFirestore(experienceDoc);

        if (experience.currentParticipants <= 0) {
          throw Exception('No participants to remove');
        }

        transaction.update(_experiencesCollection.doc(experienceId), {
          'currentParticipants': FieldValue.increment(-1),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });

      print('Successfully left experience: $experienceId');
    } catch (e) {
      print('Error leaving experience: $e');
      throw Exception('Failed to leave experience: $e');
    }
  }

  /// Search experiences by title or description (excludes blocked users)
  Future<List<ExperienceModel>> searchExperiences(String searchTerm) async {
    if (searchTerm.isEmpty) {
      return getExperiences();
    }

    try {
      // Get blocked users list first
      final blockedUsers = await _userService.getBlockedUsers();

      // Note: Firestore doesn't support full-text search natively
      // This is a basic implementation. For production, consider using Algolia or similar
      final querySnapshot =
          await _experiencesCollection
              .where('status', isEqualTo: 'active')
              .where('isPublic', isEqualTo: true)
              .get();

      final experiences =
          querySnapshot.docs
              .map((doc) => ExperienceModel.fromFirestore(doc))
              .where(
                (experience) =>
                    // Filter out blocked users first
                    !blockedUsers.contains(experience.userId) &&
                    // Then apply search criteria
                    (experience.title.toLowerCase().contains(
                          searchTerm.toLowerCase(),
                        ) ||
                        experience.description.toLowerCase().contains(
                          searchTerm.toLowerCase(),
                        ) ||
                        experience.tags.any(
                          (tag) => tag.toLowerCase().contains(
                            searchTerm.toLowerCase(),
                          ),
                        )),
              )
              .toList();

      return experiences;
    } catch (e) {
      print('Error searching experiences: $e');
      throw Exception('Failed to search experiences: $e');
    }
  }
}
