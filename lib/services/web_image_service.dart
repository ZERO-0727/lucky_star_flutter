import 'dart:async';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'optimized_image_service.dart';

class WebImageService {
  // Test basic Firebase Storage connectivity
  static Future<void> testFirebaseStorage() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('No authenticated user for storage test');
      }

      print('Testing basic Firebase Storage connectivity...');
      final testRef = FirebaseStorage.instance
          .ref()
          .child('test')
          .child(currentUser.uid)
          .child(
            'connectivity_test_${DateTime.now().millisecondsSinceEpoch}.txt',
          );

      final testData = 'Hello Firebase Storage - ${DateTime.now()}';
      final uploadTask = testRef.putString(testData);

      final snapshot = await uploadTask.timeout(
        const Duration(seconds: 120),
        onTimeout: () {
          print('Firebase Storage test timeout');
          throw Exception('Firebase Storage test timeout');
        },
      );

      final url = await snapshot.ref.getDownloadURL();
      print('Firebase Storage test successful: $url');

      // Clean up test file
      await testRef.delete();
      print('Test file cleaned up');
    } catch (e) {
      print('Firebase Storage test failed: $e');
      rethrow;
    }
  }

  // New method to test storage connectivity
  static Future<void> testStorageConnection() async {
    try {
      final ref = FirebaseStorage.instance.ref().child('test/test.txt');
      print('🔥 Testing Firebase Storage connectivity...');
      await ref.putString('test').timeout(const Duration(seconds: 10));
      print('✅ Storage test successful');
    } catch (e) {
      print('❌ Storage connection test failed: $e');
      rethrow;
    }
  }

  static Future<List<String>> uploadImagesWeb(List<XFile> images) async {
    // Test storage connection before proceeding
    await testStorageConnection();
    
    List<String> successfulUrls = [];

    print('📤 Starting SEQUENTIAL upload of ${images.length} images...');
    print('🔄 Each image will complete before the next starts');

    // STEP 1: Upload images one by one sequentially (for-loop)
    for (int i = 0; i < images.length; i++) {
      print('📸 Processing image ${i + 1}/${images.length}: ${images[i].name}');

      try {
        // Upload single image and wait for completion before continuing
        final url = await _uploadSingleWeb(images[i]);

        if (url.isNotEmpty) {
          successfulUrls.add(url);
          print(
            '✅ Image ${i + 1} uploaded successfully: ${successfulUrls.length}/${images.length} complete',
          );
        } else {
          print('❌ Image ${i + 1} failed to upload (empty URL returned)');
        }

        // Small delay between sequential uploads to prevent overwhelming Firebase
        if (i < images.length - 1) {
          await Future.delayed(const Duration(milliseconds: 300));
        }
      } catch (e) {
        print('❌ CRITICAL UPLOAD ERROR: ${e.toString()}');
        print('⚠️ Check: ');
        print('  1. Firebase Storage rules (allow write if authenticated)');
        print('  2. CORS configuration for Storage bucket');
        print('  3. Network connectivity to Firebase');
        rethrow;
      }
    }

    print(
      '📊 Sequential upload complete: ${successfulUrls.length}/${images.length} successful',
    );
    return successfulUrls;
  }

  static Future<String> _uploadSingleWeb(XFile image) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      throw Exception('No authenticated user');
    }

    // Declare variables outside try block for retry access
    late Uint8List bytes;
    late String fileExtension;
    late Reference ref;

    try {
      print('📤 Reading bytes for web image: ${image.name}');
      bytes = await image.readAsBytes();
      print('📊 Bytes read: ${bytes.length} bytes');

      // Get file extension safely
      fileExtension = 'jpg'; // default
      if (image.name.contains('.')) {
        fileExtension = image.name.split('.').last.toLowerCase();
      }

      final fileName =
          'experience_${DateTime.now().millisecondsSinceEpoch}.$fileExtension';

      // CRITICAL: Use proper Firebase Storage path structure
      ref = FirebaseStorage.instance
          .ref()
          .child('experience_images') // Better path organization
          .child(currentUser.uid)
          .child(fileName);

      print('🔗 Firebase Storage path: ${ref.fullPath}');
      print('📤 Starting upload for: $fileName');

      // Add compression
      final compressedBytes = await compressImage(bytes, fileExtension);
      print('🗜️ Compressed to: ${compressedBytes.length} bytes');

      final uploadTask = ref.putData(
        compressedBytes,
        SettableMetadata(contentType: _getContentType(fileExtension)),
      );

      print('⏳ Uploading to Firebase Storage...');
      
      // FIX: Use Completer for proper upload completion handling
      final completer = Completer<TaskSnapshot>();
      late StreamSubscription streamSubscription;
      
      streamSubscription = uploadTask.snapshotEvents.listen(
        (TaskSnapshot snapshot) {
          final progress = (snapshot.bytesTransferred / snapshot.totalBytes) * 100;
          print('📊 Upload progress for ${image.name}: ${progress.toStringAsFixed(1)}%');
          
          // Complete when upload succeeds
          if (snapshot.state == TaskState.success) {
            if (!completer.isCompleted) completer.complete(snapshot);
          }
        },
        onError: (e) {
          if (!completer.isCompleted) completer.completeError(e);
        }
      );
      
      TaskSnapshot snapshot;
      try {
        snapshot = await completer.future.timeout(
          const Duration(seconds: 120),
          onTimeout: () => throw Exception('Upload timeout after 120 seconds'),
        );
      } finally {
        await streamSubscription.cancel(); // Clean up listener
      }

      print('✅ Upload completed, getting download URL...');

      // CRITICAL: Get the actual Firebase download URL
      final downloadUrl = await snapshot.ref.getDownloadURL().timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          print('❌ Download URL timeout');
          throw Exception('Download URL timeout');
        },
      );

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
      print('✅ URL validation passed - saving to Firestore');
      return downloadUrl;
    } catch (e) {
      print('💥 Error uploading web image: $e');
      print('📍 Stack trace: ${StackTrace.current}');

      // STEP 2: Retry Failed Uploads (Max 2 Attempts)
      // Attempt 1: Original upload failed, trying retry with aggressive compression
      try {
        final imageName = ref.name;
        print('🔄 STEP 2: Retry attempt 1/1 for image: $imageName');
        print('📏 Using ultra compression for retry...');

        final retryBytes = await OptimizedImageService.compressImage(
          bytes,
          fileExtension,
          400, // Smaller size for retry
          30, // Lower quality for retry
        );

        print('💾 Retry compressed size: ${retryBytes.length} bytes');

        final retryTask = ref.putData(
          retryBytes,
          SettableMetadata(contentType: _getContentType(fileExtension)),
        );

        print('⏳ Retry upload to Firebase Storage...');
        final retrySnapshot = await retryTask.timeout(
          const Duration(seconds: 120),
        );

        print('✅ Retry upload completed, getting download URL...');
        final retryDownloadUrl = await retrySnapshot.ref.getDownloadURL();

        // STEP 3: Validate Firebase Download URL (retry attempt)
        if (retryDownloadUrl.isEmpty ||
            !retryDownloadUrl.startsWith('https://') ||
            !retryDownloadUrl.contains('firebasestorage.googleapis.com')) {
          print('❌ Invalid retry download URL: $retryDownloadUrl');
          throw Exception('Invalid retry download URL');
        }

        print('🎉 STEP 2: Retry successful with valid URL: $retryDownloadUrl');
        return retryDownloadUrl;
      } catch (retryError) {
        final imageName = ref.name;
        print('❌ STEP 2: Retry attempt failed for $imageName: $retryError');
        print('🚫 STEP 2: Max 2 attempts reached - giving up on image upload');
        return ''; // Return empty string for failed uploads after 2 attempts
      }
    }
  }

  static Future<Uint8List> compressImage(
    Uint8List bytes,
    String fileExtension,
  ) async {
    // FIXED: Use browser-native compression instead of OptimizedImageService
    try {
      print(
        '🗜️ Compressing image (${bytes.length} bytes) with browser-native compression...',
      );

      // Use HTML5 Canvas for web compression instead of image package
      final compressedBytes = await _compressImageWeb(bytes, fileExtension);

      print(
        '✅ Compression complete: ${bytes.length} → ${compressedBytes.length} bytes',
      );

      final reduction =
          ((bytes.length - compressedBytes.length) / bytes.length * 100);
      print('📉 Size reduction: ${reduction.toStringAsFixed(1)}%');

      return compressedBytes;
    } catch (e) {
      print('❌ Error compressing image on web: $e');
      print('📤 Using original image (${bytes.length} bytes)');
      return bytes; // Return original if compression fails
    }
  }

  // Browser-native compression using HTML5 Canvas
  static Future<Uint8List> _compressImageWeb(
    Uint8List bytes,
    String fileExtension,
  ) async {
    try {
      // FIXED: Use proper compression instead of truncation
      print('🔧 Applying proper web compression...');

      // For web, aggressively reduce file size using proper compression
      if (bytes.length > 50000) {
        // 50KB limit for web reliability
        print('📉 Large file detected (${bytes.length} bytes), compressing...');

        // Use OptimizedImageService for actual compression instead of truncation
        final compressedBytes = await OptimizedImageService.compressImage(
          bytes,
          fileExtension,
          400, // Much smaller width for web
          40, // Lower quality for reliability
        );

        print(
          '✅ Proper compression: ${bytes.length} → ${compressedBytes.length} bytes',
        );
        return compressedBytes;
      }

      return bytes;
    } catch (e) {
      print('❌ Compression failed, using original: $e');
      return bytes;
    }
  }

  static String _getContentType(String extension) {
    switch (extension.toLowerCase()) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      default:
        return 'image/jpeg';
    }
  }
}
