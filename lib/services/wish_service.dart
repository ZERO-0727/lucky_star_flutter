import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:flutter/foundation.dart';
import '../models/wish_model.dart';
import 'web_image_service.dart';

class WishService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instanceFor(
    bucket: 'gs://luckystar-flutter-12d06.firebasestorage.app',
  );
  final ImagePicker _imagePicker = ImagePicker();

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Collection reference
  CollectionReference get _wishesCollection => _firestore.collection('wishes');

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
          'wish_${DateTime.now().millisecondsSinceEpoch}${path.extension(imageFile.path)}';

      // CRITICAL: Use same path structure as web but for wishes
      final storageRef = _storage
          .ref()
          .child('wish_images') // Changed from experience_images
          .child(currentUser!.uid)
          .child(fileName);

      print('📤 Uploading single wish image: $fileName');
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
      print('✅ Single wish image uploaded successfully with validation');
      return downloadUrl;
    } catch (e) {
      print('❌ Error uploading single wish image: $e');
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
            .child('wish_images') // Changed from experiences
            .child(currentUser!.uid)
            .child(fileName);

        print('Uploading wish image ${i + 1}/${imageFiles.length}: $fileName');

        final uploadTask = storageRef.putFile(file);
        final snapshot = await uploadTask;
        final downloadUrl = await snapshot.ref.getDownloadURL();

        downloadUrls.add(downloadUrl);
        print('Wish image uploaded successfully: $downloadUrl');
      } catch (e) {
        print('Error uploading wish image ${i + 1}: $e');
        // Continue with other images even if one fails
      }
    }

    debugPrint('✅ Successfully uploaded ${downloadUrls.length} wish images');
    debugPrint('📸 Wish Image URLs: $downloadUrls');

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

  /// Create a new wish
  Future<String> createWish(WishModel wish) async {
    if (currentUser == null) {
      throw Exception('No authenticated user');
    }

    try {
      print('Creating wish: ${wish.title}');

      // Create user reference
      final userRef = _firestore.collection('users').doc(currentUser!.uid);

      // Create wish with user reference
      final wishData = wish.toFirestore();
      wishData['userRef'] = userRef;
      wishData['userId'] = currentUser!.uid;

      final docRef = await _wishesCollection.add(wishData);
      final wishId = docRef.id;

      // NOTE: Images are now uploaded separately in background
      // This method only creates the Firestore document for immediate feedback

      print('Wish created successfully with ID: $wishId');
      return wishId;
    } catch (e) {
      print('Error creating wish: $e');
      throw Exception('Failed to create wish: $e');
    }
  }

  /// Get all wishes with optional filters
  Future<List<WishModel>> getWishes({
    String? category,
    String? location,
    double? minBudget,
    double? maxBudget,
    int limit = 20,
  }) async {
    try {
      Query query = _wishesCollection
          .where('status', isEqualTo: 'Open')
          .orderBy('createdAt', descending: true)
          .limit(limit);

      if (category != null && category.isNotEmpty) {
        query = query.where('categories', arrayContains: category);
      }

      if (location != null && location.isNotEmpty) {
        query = query.where('location', isEqualTo: location);
      }

      final querySnapshot = await query.get();

      List<WishModel> wishes =
          querySnapshot.docs
              .map((doc) => WishModel.fromFirestore(doc))
              .toList();

      // Filter by budget range if specified
      if (minBudget != null || maxBudget != null) {
        wishes =
            wishes.where((wish) {
              if (wish.budget == null)
                return true; // Include flexible budget wishes
              if (minBudget != null && wish.budget! < minBudget) return false;
              if (maxBudget != null && wish.budget! > maxBudget) return false;
              return true;
            }).toList();
      }

      return wishes;
    } catch (e) {
      print('Error getting wishes: $e');
      throw Exception('Failed to get wishes: $e');
    }
  }

  /// Get wishes stream for real-time updates
  Stream<List<WishModel>> getWishesStream({
    String? category,
    String? location,
    int limit = 20,
  }) {
    try {
      Query query = _wishesCollection
          .where('status', isEqualTo: 'Open')
          .orderBy('createdAt', descending: true)
          .limit(limit);

      if (category != null && category.isNotEmpty) {
        query = query.where('categories', arrayContains: category);
      }

      if (location != null && location.isNotEmpty) {
        query = query.where('location', isEqualTo: location);
      }

      return query.snapshots().map((snapshot) {
        return snapshot.docs
            .map((doc) => WishModel.fromFirestore(doc))
            .toList();
      });
    } catch (e) {
      print('Error getting wishes stream: $e');
      throw Exception('Failed to get wishes stream: $e');
    }
  }

  /// Get wish by ID
  Future<WishModel?> getWish(String wishId) async {
    try {
      final doc = await _wishesCollection.doc(wishId).get();

      if (doc.exists) {
        return WishModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Error getting wish: $e');
      throw Exception('Failed to get wish: $e');
    }
  }

  /// Get user's own wishes
  Future<List<WishModel>> getUserWishes([String? userId]) async {
    final targetUserId = userId ?? currentUser?.uid;

    if (targetUserId == null) {
      throw Exception('No user ID provided');
    }

    try {
      final querySnapshot =
          await _wishesCollection
              .where('userId', isEqualTo: targetUserId)
              .orderBy('createdAt', descending: true)
              .get();

      return querySnapshot.docs
          .map((doc) => WishModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error getting user wishes: $e');
      throw Exception('Failed to get user wishes: $e');
    }
  }

  /// Update wish
  Future<void> updateWish(String wishId, Map<String, dynamic> updates) async {
    try {
      debugPrint('🔄 Updating wish $wishId with: $updates');
      await _firestore.collection('wishes').doc(wishId).update(updates);
      debugPrint('✅ Successfully updated wish $wishId');
    } catch (e) {
      debugPrint('❌ Error updating wish: $e');
      rethrow;
    }
  }

  /// Update wish status
  Future<void> updateWishStatus(String wishId, String status) async {
    try {
      await _wishesCollection.doc(wishId).update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      print('Wish status updated successfully: $wishId -> $status');
    } catch (e) {
      print('Error updating wish status: $e');
      throw Exception('Failed to update wish status: $e');
    }
  }

  /// Delete wish
  Future<void> deleteWish(String wishId) async {
    if (currentUser == null) {
      throw Exception('No authenticated user');
    }

    try {
      // Soft delete by updating status
      await _wishesCollection.doc(wishId).update({
        'status': 'deleted',
        'updatedAt': FieldValue.serverTimestamp(),
      });
      print('Wish deleted successfully: $wishId');
    } catch (e) {
      print('Error deleting wish: $e');
      throw Exception('Failed to delete wish: $e');
    }
  }

  /// Express interest in a wish (increment interested count)
  Future<void> expressInterest(String wishId) async {
    if (currentUser == null) {
      throw Exception('No authenticated user');
    }

    try {
      await _firestore.runTransaction((transaction) async {
        final wishDoc = await transaction.get(_wishesCollection.doc(wishId));

        if (!wishDoc.exists) {
          throw Exception('Wish not found');
        }

        final wish = WishModel.fromFirestore(wishDoc);

        if (!wish.isOpen) {
          throw Exception('Wish is no longer open');
        }

        transaction.update(_wishesCollection.doc(wishId), {
          'interestedCount': FieldValue.increment(1),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });

      print('Successfully expressed interest in wish: $wishId');
    } catch (e) {
      print('Error expressing interest in wish: $e');
      throw Exception('Failed to express interest in wish: $e');
    }
  }

  /// Withdraw interest from a wish (decrement interested count)
  Future<void> withdrawInterest(String wishId) async {
    if (currentUser == null) {
      throw Exception('No authenticated user');
    }

    try {
      await _firestore.runTransaction((transaction) async {
        final wishDoc = await transaction.get(_wishesCollection.doc(wishId));

        if (!wishDoc.exists) {
          throw Exception('Wish not found');
        }

        final wish = WishModel.fromFirestore(wishDoc);

        if (wish.interestedCount <= 0) {
          throw Exception('No interest to withdraw');
        }

        transaction.update(_wishesCollection.doc(wishId), {
          'interestedCount': FieldValue.increment(-1),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });

      print('Successfully withdrew interest from wish: $wishId');
    } catch (e) {
      print('Error withdrawing interest from wish: $e');
      throw Exception('Failed to withdraw interest from wish: $e');
    }
  }

  /// Search wishes by title or description
  Future<List<WishModel>> searchWishes(String searchTerm) async {
    if (searchTerm.isEmpty) {
      return getWishes();
    }

    try {
      // Note: Firestore doesn't support full-text search natively
      // This is a basic implementation. For production, consider using Algolia or similar
      final querySnapshot =
          await _wishesCollection.where('status', isEqualTo: 'Open').get();

      final wishes =
          querySnapshot.docs
              .map((doc) => WishModel.fromFirestore(doc))
              .where(
                (wish) =>
                    wish.title.toLowerCase().contains(
                      searchTerm.toLowerCase(),
                    ) ||
                    wish.description.toLowerCase().contains(
                      searchTerm.toLowerCase(),
                    ) ||
                    wish.categories.any(
                      (category) => category.toLowerCase().contains(
                        searchTerm.toLowerCase(),
                      ),
                    ),
              )
              .toList();

      return wishes;
    } catch (e) {
      print('Error searching wishes: $e');
      throw Exception('Failed to search wishes: $e');
    }
  }
}
