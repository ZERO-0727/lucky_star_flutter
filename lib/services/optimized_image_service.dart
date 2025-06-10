import 'dart:typed_data';
import 'dart:async';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart' show ui;
import 'package:image/image.dart' as image;
import 'notification_service.dart';

class OptimizedImageService {
  static const int _maxWidth = 1080;
  static const int _maxHeight = 1080;
  static const int _quality = 85; // 85% quality for good balance
  static const int _maxFileSizeKB = 500; // Target max 500KB per image

  // Throttle progress updates to reduce UI overhead
  static const Duration _progressUpdateThrottle = Duration(milliseconds: 100);
  static Timer? _progressUpdateTimer;
  static int _lastReportedProgress = -1;

  /// Compresses a single image for optimal upload performance
  static Future<Uint8List?> _compressImage(
    XFile imageFile,
    int imageIndex,
    int totalImages,
  ) async {
    try {
      print('Compressing image ${imageIndex + 1}/$totalImages...');

      // Read original bytes
      final originalBytes = await imageFile.readAsBytes();
      final originalSizeKB = (originalBytes.length / 1024).round();

      print('Original size: ${originalSizeKB}KB');

      // If already small enough, return original
      if (originalSizeKB <= _maxFileSizeKB) {
        print('Image already optimized: ${originalSizeKB}KB');
        return originalBytes;
      }

      if (kIsWeb) {
        return _compressAndResizeImage(originalBytes, _maxWidth, _quality);
      }

      // Compress the image
      final compressedBytes = await FlutterImageCompress.compressWithList(
        originalBytes,
        minWidth: _maxWidth,
        minHeight: _maxHeight,
        quality: _quality,
        format: CompressFormat.jpeg,
      );

      final compressedSizeKB = (compressedBytes.length / 1024).round();
      final compressionRatio =
          ((1 - compressedBytes.length / originalBytes.length) * 100)
              .toStringAsFixed(1);

      print(
        'Compressed size: ${compressedSizeKB}KB (${compressionRatio}% reduction)',
      );

      return compressedBytes;
    } catch (e) {
      print('Compression failed for image ${imageIndex + 1}: $e');
      // Fallback to original if compression fails
      return await imageFile.readAsBytes();
    }
  }

  static Future<Uint8List> compressImage(Uint8List bytes, String fileExtension, int maxWidth, int quality) async {
    if (fileExtension.toLowerCase() == 'jpg' || fileExtension.toLowerCase() == 'jpeg') {
      return _compressAndResizeImage(bytes, maxWidth, quality);
    } else {
      return _resizeNonJpegImage(bytes, maxWidth);
    }
  }

  static Future<Uint8List> _compressAndResizeImage(Uint8List bytes, int maxWidth, int quality) async {
    try {
      final byteData = ByteData.sublistView(bytes);
      final codec = await ui.instantiateImageCodec(byteData.buffer.asUint8List());
      final frame = await codec.getNextFrame();
      
      // FIX: Use PNG format then convert to JPEG
      final pngByteData = await frame.image.toByteData(format: ui.ImageByteFormat.png);
      final pngBytes = pngByteData!.buffer.asUint8List();
      
      // Convert to JPEG using image package
      final decodedImage = image.decodeImage(pngBytes)!;
      final resizedImage = image.copyResize(decodedImage, width: maxWidth);
      final jpegBytes = image.encodeJpg(resizedImage, quality: quality);
      
      return jpegBytes;
    } catch (e) {
      print('Error during image compression: $e');
      rethrow;
    }
  }

  static Future<Uint8List> _resizeNonJpegImage(Uint8List bytes, int maxWidth) async {
    try {
      final decodedImage = image.decodeImage(bytes)!;
      final resizedImage = image.copyResize(decodedImage, width: maxWidth);
      final resizedBytes = image.encodePng(resizedImage);
      
      return resizedBytes;
    } catch (e) {
      print('Error during image resizing: $e');
      rethrow;
    }
  }

  /// Uploads a single compressed image with progress tracking
  static Future<String?> _uploadSingleImage(
    Uint8List imageBytes,
    String fileName,
    int imageIndex,
    int totalImages,
  ) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('No authenticated user');
      }

      // Use default Firebase Storage instance
      final storage = FirebaseStorage.instance;

      // Add detailed logging for debugging
      print('Firebase Auth User: ${currentUser.uid}');
      print('Storage bucket: ${storage.bucket}');
      print('Upload path: experiences/${currentUser.uid}/$fileName');

      final ref = storage
          .ref()
          .child('experiences')
          .child(currentUser.uid)
          .child(fileName);

      print(
        'Starting upload for image ${imageIndex + 1}/$totalImages: $fileName (${(imageBytes.length / 1024).round()}KB)',
      );

      final uploadTask = ref.putData(
        imageBytes,
        SettableMetadata(
          contentType: 'image/jpeg',
          customMetadata: {
            'compressed': 'true',
            'originalIndex': imageIndex.toString(),
          },
        ),
      );

      print('UploadTask created successfully, starting progress monitoring...');

      // Track upload progress with throttling
      late StreamSubscription progressSubscription;
      progressSubscription = uploadTask.snapshotEvents.listen((snapshot) {
        final progress = snapshot.bytesTransferred / snapshot.totalBytes;
        print(
          'Upload progress for image ${imageIndex + 1}: ${(progress * 100).toStringAsFixed(1)}%',
        );
        _throttledProgressUpdate(imageIndex, totalImages, progress);
      });

      // Wait for upload to complete
      final snapshot = await uploadTask.timeout(
        const Duration(seconds: 30), // Temporary for debugging
        onTimeout: () {
          progressSubscription.cancel();
          throw Exception('Upload timeout for image ${imageIndex + 1}');
        },
      );

      progressSubscription.cancel();

      // Get download URL
      final downloadURL = await snapshot.ref.getDownloadURL().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Download URL timeout for image ${imageIndex + 1}');
        },
      );

      print('Upload successful for image ${imageIndex + 1}: $downloadURL');
      return downloadURL;
    } catch (e) {
      print('Upload failed for image ${imageIndex + 1}: $e');
      return null; // Return null for failed uploads
    }
  }

  /// Throttled progress updates to reduce UI overhead
  static void _throttledProgressUpdate(
    int imageIndex,
    int totalImages,
    double imageProgress,
  ) {
    final currentProgress =
        ((imageIndex + imageProgress) * 100 / totalImages).round();

    // Only update if progress changed significantly and not throttled
    if (currentProgress != _lastReportedProgress &&
        _progressUpdateTimer?.isActive != true) {
      _lastReportedProgress = currentProgress;

      // Update notification service
      NotificationService().updateCurrentImageProgress(
        imageIndex,
        totalImages,
        imageProgress,
      );

      // Set throttle timer
      _progressUpdateTimer = Timer(_progressUpdateThrottle, () {
        // Timer completed, allow next update
      });
    }
  }

  /// Main method: Parallel compression and upload with optimizations
  static Future<List<String>> uploadImagesOptimized(List<XFile> images) async {
    if (images.isEmpty) return [];

    final notificationService = NotificationService();
    final List<String> successfulUrls = [];

    try {
      print('Starting optimized upload for ${images.length} images...');
      notificationService.showUploadingNotification(images.length);

      // Phase 1: Parallel compression (CPU-bound, can be parallelized)
      print('Phase 1: Compressing ${images.length} images in parallel...');
      final compressionTasks = <Future<Uint8List?>>[];

      for (int i = 0; i < images.length; i++) {
        compressionTasks.add(_compressImage(images[i], i, images.length));
      }

      final compressedImages = await Future.wait(compressionTasks);
      final validImages = <MapEntry<int, Uint8List>>[];

      for (int i = 0; i < compressedImages.length; i++) {
        if (compressedImages[i] != null) {
          validImages.add(MapEntry(i, compressedImages[i]!));
        }
      }

      print(
        'Compression complete: ${validImages.length}/${images.length} images ready',
      );

      // Phase 2: Parallel upload (I/O-bound, benefit from parallelization)
      print('Phase 2: Uploading ${validImages.length} images in parallel...');

      final uploadTasks = <Future<String?>>[];

      for (final entry in validImages) {
        final index = entry.key;
        final bytes = entry.value;
        final fileName = '${DateTime.now().millisecondsSinceEpoch}_$index.jpg';

        uploadTasks.add(
          _uploadSingleImage(bytes, fileName, index, validImages.length),
        );
      }

      // Wait for all uploads to complete
      final uploadResults = await Future.wait(uploadTasks);

      // Collect successful uploads
      for (final url in uploadResults) {
        if (url != null) {
          successfulUrls.add(url);
        }
      }

      final successCount = successfulUrls.length;
      final failureCount = images.length - successCount;

      print('Upload complete: $successCount successful, $failureCount failed');

      if (successCount > 0) {
        notificationService.showUploadSuccess(successCount);
      } else {
        notificationService.showUploadError('All image uploads failed');
      }

      return successfulUrls;
    } catch (e) {
      print('Optimized upload failed: $e');
      notificationService.showUploadError('Upload failed: ${e.toString()}');
      return successfulUrls; // Return any partial successes
    }
  }

  /// Test compression on a single image to verify setup
  static Future<void> testCompression(XFile testImage) async {
    try {
      print('Testing image compression...');
      final compressed = await _compressImage(testImage, 0, 1);

      if (compressed != null) {
        final originalSize = (await testImage.readAsBytes()).length;
        final compressedSize = compressed.length;
        final ratio = ((1 - compressedSize / originalSize) * 100)
            .toStringAsFixed(1);

        print('Compression test successful:');
        print('- Original: ${(originalSize / 1024).round()}KB');
        print('- Compressed: ${(compressedSize / 1024).round()}KB');
        print('- Reduction: $ratio%');
      } else {
        print('Compression test failed');
      }
    } catch (e) {
      print('Compression test error: $e');
    }
  }

  /// Get estimated upload time based on image count and sizes
  static Future<Duration> estimateUploadTime(List<XFile> images) async {
    if (images.isEmpty) return Duration.zero;

    try {
      // Estimate based on compressed sizes and parallel upload
      int totalEstimatedBytes = 0;

      for (final image in images) {
        final bytes = await image.readAsBytes();
        final originalSize = bytes.length;

        // Estimate compression (usually 60-80% reduction)
        final estimatedCompressedSize =
            (originalSize * 0.3).round(); // Conservative estimate
        totalEstimatedBytes += estimatedCompressedSize;
      }

      // Estimate upload speed (conservative: 500KB/s)
      const estimatedSpeedBytesPerSecond = 500 * 1024; // 500KB/s
      final estimatedSeconds =
          totalEstimatedBytes / estimatedSpeedBytesPerSecond;

      // Factor in parallel uploads (assume 3x speed improvement)
      final parallelSpeedSeconds = estimatedSeconds / 3;

      return Duration(seconds: parallelSpeedSeconds.ceil());
    } catch (e) {
      print('Upload time estimation failed: $e');
      return const Duration(minutes: 1); // Fallback estimate
    }
  }
}
