import 'package:flutter/material.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  static const String _uploadingKey = 'experience_uploading';
  static const String _successKey = 'experience_success';
  static const String _errorKey = 'experience_error';

  final ValueNotifier<Map<String, dynamic>?> _currentNotification =
      ValueNotifier<Map<String, dynamic>?>(null);

  ValueNotifier<Map<String, dynamic>?> get currentNotification =>
      _currentNotification;

  void showUploadingNotification(int totalImages) {
    _currentNotification.value = {
      'type': _uploadingKey,
      'message': 'Uploading $totalImages images...',
      'progress': 0,
      'total': totalImages,
      'isVisible': true,
    };
  }

  void updateUploadProgress(
    int uploaded,
    int total, {
    String? currentImageName,
  }) {
    if (_currentNotification.value?['type'] == _uploadingKey) {
      String message = 'Uploading images... $uploaded/$total';
      if (currentImageName != null) {
        message = 'Uploading $currentImageName... $uploaded/$total';
      }

      _currentNotification.value = {
        ..._currentNotification.value!,
        'message': message,
        'progress': uploaded,
        'isVisible': true,
      };
    }
  }

  void updateCurrentImageProgress(
    int imageIndex,
    int totalImages,
    double imageProgress,
  ) {
    if (_currentNotification.value?['type'] == _uploadingKey) {
      final overallProgress = (imageIndex + imageProgress) / totalImages;
      _currentNotification.value = {
        ..._currentNotification.value!,
        'message':
            'Uploading image ${imageIndex + 1}/$totalImages (${(imageProgress * 100).toInt()}%)',
        'progress': imageIndex,
        'imageProgress': imageProgress,
        'overallProgress': overallProgress,
        'isVisible': true,
      };
    }
  }

  void showUploadSuccess(int uploadedCount) {
    _currentNotification.value = {
      'type': _successKey,
      'message':
          uploadedCount > 0
              ? 'Experience published with $uploadedCount images!'
              : 'Experience published successfully!',
      'isVisible': true,
    };

    // Auto-hide success message after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      hideNotification();
    });
  }

  void showUploadError(String error) {
    _currentNotification.value = {
      'type': _errorKey,
      'message': 'Image upload failed, but experience is published',
      'error': error,
      'isVisible': true,
    };

    // Auto-hide error message after 5 seconds
    Future.delayed(const Duration(seconds: 5), () {
      hideNotification();
    });
  }

  void hideNotification() {
    _currentNotification.value = null;
  }

  void dispose() {
    _currentNotification.dispose();
  }
}
