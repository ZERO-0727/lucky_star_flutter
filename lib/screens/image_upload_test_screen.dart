import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/firebase_image_upload_service.dart';

class ImageUploadTestScreen extends StatefulWidget {
  const ImageUploadTestScreen({super.key});

  @override
  State<ImageUploadTestScreen> createState() => _ImageUploadTestScreenState();
}

class _ImageUploadTestScreenState extends State<ImageUploadTestScreen> {
  String? _uploadedImageUrl;
  bool _isUploading = false;
  double _uploadProgress = 0.0;
  String _statusMessage = 'Ready to upload';
  XFile? _selectedImage;
  Uint8List? _imageBytes;
  bool _corsTestPassed = false;

  @override
  void initState() {
    super.initState();
    _checkAuthenticationStatus();
    _testCorsConfiguration();
  }

  void _checkAuthenticationStatus() {
    final userInfo = FirebaseImageUploadService.userInfo;
    setState(() {
      _statusMessage =
          userInfo['isAuthenticated']
              ? '✅ Authenticated as: ${userInfo['email']}'
              : '❌ Not authenticated - please sign in first';
    });
  }

  Future<void> _testCorsConfiguration() async {
    try {
      final bool corsWorking =
          await FirebaseImageUploadService.testCorsConfiguration();
      setState(() {
        _corsTestPassed = corsWorking;
      });
    } catch (e) {
      print('CORS test error: $e');
    }
  }

  Future<void> _pickImage() async {
    try {
      setState(() {
        _statusMessage = 'Selecting image...';
      });

      final XFile? image = await FirebaseImageUploadService.pickImage();

      if (image != null) {
        final Uint8List bytes = await image.readAsBytes();
        setState(() {
          _selectedImage = image;
          _imageBytes = bytes;
          _statusMessage = 'Image selected: ${image.name}';
          _uploadedImageUrl = null; // Clear previous upload
        });
      } else {
        setState(() {
          _statusMessage = 'No image selected';
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Error selecting image: $e';
      });
    }
  }

  Future<void> _uploadImage() async {
    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an image first')),
      );
      return;
    }

    if (!FirebaseImageUploadService.isUserAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please authenticate first'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
      _statusMessage = 'Starting upload...';
      _uploadedImageUrl = null;
    });

    try {
      final String downloadUrl = await FirebaseImageUploadService.uploadImage(
        imageFile: _selectedImage!,
        folder: 'test_uploads',
        onProgress: (double progress) {
          setState(() {
            _uploadProgress = progress;
            _statusMessage =
                'Uploading... ${(progress * 100).toStringAsFixed(1)}%';
          });
        },
      );

      setState(() {
        _uploadedImageUrl = downloadUrl;
        _statusMessage = '✅ Upload successful!';
        _isUploading = false;
      });

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🎉 Image uploaded successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _statusMessage = '❌ Upload failed: $e';
        _isUploading = false;
        _uploadProgress = 0.0;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteImage() async {
    if (_uploadedImageUrl == null) return;

    try {
      await FirebaseImageUploadService.deleteImage(_uploadedImageUrl!);

      setState(() {
        _uploadedImageUrl = null;
        _statusMessage = '🗑️ Image deleted successfully';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Image deleted successfully'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _statusMessage = '❌ Delete failed: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Firebase Image Upload Test'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Authentication Status Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '🔐 Authentication Status',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(_statusMessage),
                    const SizedBox(height: 8),
                    if (FirebaseImageUploadService.isUserAuthenticated) ...[
                      Text(
                        '👤 User ID: ${FirebaseImageUploadService.userInfo['uid']}',
                      ),
                      Text(
                        '📧 Email: ${FirebaseImageUploadService.userInfo['email']}',
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // CORS Test Status
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '🌐 CORS Configuration',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          _corsTestPassed ? Icons.check_circle : Icons.error,
                          color: _corsTestPassed ? Colors.green : Colors.red,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _corsTestPassed
                              ? 'CORS is properly configured'
                              : 'CORS test failed - check configuration',
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retest CORS'),
                      onPressed: _testCorsConfiguration,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Image Selection Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '📸 Image Selection',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    if (_imageBytes != null) ...[
                      // Show selected image preview
                      Container(
                        height: 200,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.memory(_imageBytes!, fit: BoxFit.cover),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text('Selected: ${_selectedImage?.name ?? 'Unknown'}'),
                      const SizedBox(height: 16),
                    ],

                    // Image picker buttons
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.photo_library),
                            label: const Text('Pick from Gallery'),
                            onPressed: _isUploading ? null : _pickImage,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.camera_alt),
                            label: const Text('Take Photo'),
                            onPressed:
                                _isUploading
                                    ? null
                                    : () async {
                                      final image =
                                          await FirebaseImageUploadService.pickImage(
                                            source: ImageSource.camera,
                                          );
                                      if (image != null) {
                                        final bytes = await image.readAsBytes();
                                        setState(() {
                                          _selectedImage = image;
                                          _imageBytes = bytes;
                                          _statusMessage =
                                              'Photo taken: ${image.name}';
                                        });
                                      }
                                    },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Upload Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '☁️ Upload to Firebase',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Upload progress
                    if (_isUploading) ...[
                      LinearProgressIndicator(value: _uploadProgress),
                      const SizedBox(height: 8),
                      Text(
                        'Progress: ${(_uploadProgress * 100).toStringAsFixed(1)}%',
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Upload button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon:
                            _isUploading
                                ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                                : const Icon(Icons.cloud_upload),
                        label: Text(
                          _isUploading ? 'Uploading...' : 'Upload Image',
                        ),
                        onPressed:
                            (_selectedImage != null && !_isUploading)
                                ? _uploadImage
                                : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Uploaded Image Display
            if (_uploadedImageUrl != null) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '✅ Uploaded Image',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Display uploaded image
                      Container(
                        height: 200,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green, width: 2),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            _uploadedImageUrl!,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return const Center(
                                child: Icon(Icons.error, color: Colors.red),
                              );
                            },
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Download URL
                      const Text(
                        'Download URL:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      SelectableText(
                        _uploadedImageUrl!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.blue,
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Delete button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.delete),
                          label: const Text('Delete Image'),
                          onPressed: _deleteImage,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
