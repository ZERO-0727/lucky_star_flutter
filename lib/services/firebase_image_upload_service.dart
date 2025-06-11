import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';

class FirebaseImageUploadService {
  // Your correct Firebase Storage bucket
  static final FirebaseStorage _storage = FirebaseStorage.instanceFor(
    bucket: 'gs://luckystar-flutter-12d06.firebasestorage.app',
  );

  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final ImagePicker _picker = ImagePicker();

  /// Check if user is authenticated
  static bool get isUserAuthenticated => _auth.currentUser != null;

  /// Get current user info for debugging
  static Map<String, dynamic> get userInfo {
    final user = _auth.currentUser;
    return {
      'isAuthenticated': user != null,
      'uid': user?.uid ?? 'No user',
      'email': user?.email ?? 'No email',
      'displayName': user?.displayName ?? 'No name',
    };
  }

  /// Pick an image from gallery/camera
  static Future<XFile?> pickImage({
    ImageSource source = ImageSource.gallery,
  }) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      return image;
    } catch (e) {
      print('❌ Error picking image: $e');
      rethrow;
    }
  }

  /// Upload image to Firebase Storage with authentication check
  static Future<String> uploadImage({
    required XFile imageFile,
    String folder = 'uploads',
    Function(double)? onProgress,
  }) async {
    // 1. Check authentication
    if (!isUserAuthenticated) {
      throw Exception('❌ User must be authenticated to upload images');
    }

    final user = _auth.currentUser!;

    // 2. Debug logging
    print('🚀 Starting image upload...');
    print('🌐 Platform: ${kIsWeb ? "Web" : "Mobile"}');
    print('🔐 User authenticated: ${user.email} (${user.uid})');

    try {
      // 3. Read file bytes
      final Uint8List bytes = await imageFile.readAsBytes();
      if (bytes.isEmpty) {
        throw Exception('❌ Selected image file is empty');
      }

      print(
        '📏 File size: ${bytes.length} bytes (${(bytes.length / 1024 / 1024).toStringAsFixed(2)} MB)',
      );

      // 4. Check file size limit (5MB)
      if (bytes.length > 5 * 1024 * 1024) {
        throw Exception('❌ Image too large. Please select images under 5MB');
      }

      // 5. Generate unique filename
      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final String extension =
          imageFile.name.toLowerCase().endsWith('.png') ? 'png' : 'jpg';
      final String fileName =
          'image_${timestamp}_${user.uid.substring(0, 8)}.$extension';

      // 6. Create storage reference
      final String uploadPath = '$folder/${user.uid}/$fileName';
      final Reference ref = _storage.ref().child(uploadPath);

      print('📂 Upload path: $uploadPath');
      print('🎯 Storage bucket: ${_storage.bucket}');

      // 7. Set metadata
      final SettableMetadata metadata = SettableMetadata(
        contentType: extension == 'png' ? 'image/png' : 'image/jpeg',
        customMetadata: {
          'uploadedBy': user.uid,
          'uploadedAt': DateTime.now().toIso8601String(),
          'userEmail': user.email ?? 'unknown',
          'originalName': imageFile.name,
          'platform': kIsWeb ? 'web' : 'mobile',
        },
      );

      // 8. Start upload
      final UploadTask uploadTask = ref.putData(bytes, metadata);

      // 9. Monitor progress
      uploadTask.snapshotEvents.listen(
        (TaskSnapshot snapshot) {
          final double progress =
              snapshot.bytesTransferred / snapshot.totalBytes;
          print('📊 Upload progress: ${(progress * 100).toStringAsFixed(1)}%');
          onProgress?.call(progress);
        },
        onError: (error) {
          print('❌ Upload stream error: $error');
        },
      );

      // 10. Wait for completion with timeout
      final TaskSnapshot snapshot = await uploadTask.timeout(
        const Duration(seconds: 120),
        onTimeout:
            () => throw Exception('❌ Upload timed out after 120 seconds'),
      );

      // 11. Get download URL
      final String downloadUrl = await snapshot.ref.getDownloadURL();

      // 12. Validate URL
      if (!downloadUrl.startsWith('https://') ||
          !downloadUrl.contains('firebasestorage.googleapis.com')) {
        throw Exception('❌ Invalid download URL received');
      }

      print('✅ Upload successful!');
      print('🔗 Download URL: $downloadUrl');

      // 13. Verify CORS is working (this call succeeds means CORS is properly configured)
      print(
        '🌐 CORS verification: Upload completed successfully - CORS is working!',
      );

      return downloadUrl;
    } catch (e) {
      print('💥 Upload failed: $e');

      // Provide specific error messages for common issues
      if (e.toString().contains('storage/unauthorized')) {
        throw Exception(
          '❌ Upload unauthorized. Check Firebase Storage security rules.',
        );
      } else if (e.toString().contains('storage/retry-limit-exceeded')) {
        throw Exception(
          '❌ Upload failed due to poor network. Please try again.',
        );
      } else if (e.toString().contains('storage/unknown')) {
        throw Exception(
          '❌ Upload failed. Check authentication and storage rules.',
        );
      } else {
        rethrow;
      }
    }
  }

  /// Test CORS configuration by attempting a simple operation
  static Future<bool> testCorsConfiguration() async {
    try {
      print('🧪 Testing CORS configuration...');

      if (!isUserAuthenticated) {
        print('⚠️ User not authenticated - cannot test upload');
        return false;
      }

      // Try to list files in user's folder (lightweight operation)
      final user = _auth.currentUser!;
      final Reference testRef = _storage.ref().child('test/${user.uid}/');

      // This operation will fail if CORS is not properly configured
      await testRef.listAll();

      print('✅ CORS test passed - Firebase Storage is accessible from web');
      return true;
    } catch (e) {
      print('❌ CORS test failed: $e');
      print('💡 This might indicate CORS configuration issues');
      return false;
    }
  }

  /// Delete an image from Firebase Storage
  static Future<void> deleteImage(String downloadUrl) async {
    try {
      if (!isUserAuthenticated) {
        throw Exception('❌ User must be authenticated to delete images');
      }

      final Reference ref = _storage.refFromURL(downloadUrl);
      await ref.delete();
      print('🗑️ Image deleted successfully');
    } catch (e) {
      print('❌ Error deleting image: $e');
      rethrow;
    }
  }
}
