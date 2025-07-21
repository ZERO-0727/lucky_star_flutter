import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:typed_data';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'services/wish_service.dart';

// 🚨 EMERGENCY FIX: Simple image status tracking
enum ImageStatus { pending, uploading, success, failed, retrying }

// 🚨 EMERGENCY FIX: Simplified image item with robust error handling
class ImageItem {
  final XFile file;
  final String name;
  ImageStatus status;
  String? url;
  String? error;
  int retryCount = 0;
  bool savedToFirestore = false;

  ImageItem({
    required this.file,
    required this.name,
    this.status = ImageStatus.pending,
    this.url,
    this.error,
  });
}

class PostWishScreen extends StatefulWidget {
  const PostWishScreen({super.key});

  @override
  _PostWishScreenState createState() => _PostWishScreenState();
}

class _PostWishScreenState extends State<PostWishScreen> {
  final _formKey = GlobalKey<FormState>();
  final List<String> _categories = [
    'Food',
    'Sport',
    'Travel',
    'Culture',
    'Adventure',
    'Learning',
  ];
  final Map<String, bool> _selectedCategories = {};

  // 🚨 EMERGENCY FIX: New state management for images
  final List<ImageItem> _images = [];
  final List<String> _uploadedUrls = [];
  String? _currentWishId;

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _budgetController = TextEditingController();

  final WishService _wishService = WishService();
  bool _isLoading = false;
  bool _isCreatingDoc = false;

  // Firestore and Storage references
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instanceFor(
    bucket: 'gs://luckystar-flutter-12d06.firebasestorage.app',
  );
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    for (var category in _categories) {
      _selectedCategories[category] = false;
    }
    _createEmptyWish();
  }

  // 🚨 EMERGENCY FIX: Create empty wish document immediately
  Future<void> _createEmptyWish() async {
    if (_currentWishId != null) return;

    setState(() {
      _isCreatingDoc = true;
    });

    try {
      // Create minimal initial document with empty photoUrls array
      final newWish = {
        'title': 'Draft Wish',
        'description': 'This wish is being created...',
        'location': 'TBD',
        'preferredDate': Timestamp.fromDate(
          DateTime.now().add(const Duration(days: 14)),
        ),
        'categories': ['Draft'],
        'photoUrls': [], // 🚨 CRITICAL: Initialize empty array
        'interestedCount': 0,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'userId': _wishService.currentUser?.uid ?? 'anonymous',
        'status': 'Open',
      };

      // Create document and get its ID
      final docRef = await _firestore.collection('wishes').add(newWish);
      _currentWishId = docRef.id;

      print('✅ Empty wish document created: $_currentWishId');
    } catch (e) {
      print('❌ Failed to create wish document: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating document: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCreatingDoc = false;
        });
      }
    }
  }

  // 🚨 EMERGENCY FIX: Select and immediately upload images
  Future<void> _pickAndUploadImages() async {
    if (_currentWishId == null) {
      // Ensure we have a document before picking images
      await _createEmptyWish();
    }

    try {
      // Limit to 3 images max as requested
      if (_images.length >= 3) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Maximum 3 images allowed'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      // Select images - limit to JPEG/PNG as requested
      final pickedImages = await _picker.pickMultiImage();
      if (pickedImages.isEmpty) return;

      // Validate file types (JPEG/PNG only)
      final validImages =
          pickedImages.where((img) {
            final ext = img.name.toLowerCase();
            return ext.endsWith('.jpg') ||
                ext.endsWith('.jpeg') ||
                ext.endsWith('.png');
          }).toList();

      // Check if we can add all images or need to limit
      final remaining = 3 - _images.length;
      final imagesToAdd =
          validImages
              .take(remaining)
              .map((file) => ImageItem(file: file, name: file.name))
              .toList();

      if (imagesToAdd.isEmpty) return;

      setState(() {
        _images.addAll(imagesToAdd);
      });

      // 🚨 CRITICAL: Start upload IMMEDIATELY for each image
      for (final image in imagesToAdd) {
        _uploadImageToFirebase(image);
      }
    } catch (e) {
      print('❌ Error picking images: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error selecting images: $e')));
      }
    }
  }

  // 🚨 EMERGENCY FIX: Upload single image with immediate Firestore update
  Future<void> _uploadImageToFirebase(ImageItem image) async {
    if (_currentWishId == null) {
      print('❌ No wish ID available for URL write');
      return;
    }

    // Set status to uploading
    setState(() {
      image.status = ImageStatus.uploading;
    });

    try {
      print('📤 UPLOADING: ${image.name}');

      // Task 7: Add debug logging for web
      print('🌐 Platform: ${kIsWeb ? "Web" : "Mobile"}');

      // Debug authentication status
      final currentUser = _wishService.currentUser;
      print(
        '🔐 Auth Status: ${currentUser != null ? "Authenticated" : "Not Authenticated"}',
      );
      if (currentUser != null) {
        print('👤 User ID: ${currentUser.uid}');
        print('📧 User Email: ${currentUser.email ?? "No email"}');
      } else {
        throw Exception(
          'User not authenticated - Firebase Storage requires authentication',
        );
      }

      // Get file bytes
      final bytes = await image.file.readAsBytes();
      if (bytes.isEmpty) {
        throw Exception('Empty image file');
      }

      print('📏 File size: ${bytes.length} bytes');

      // 1. Setup upload location
      final fileName = 'img_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final path =
          'wish_images/${_wishService.currentUser?.uid ?? "anonymous"}/$fileName';
      final ref = _storage.ref().child(path);

      print('📂 Upload path: $path');

      // Task 8: Simplify compression logic
      // Check file size (skip compression for now to isolate issue)
      if (bytes.length > 5 * 1024 * 1024) {
        // 5MB limit
        throw Exception('Image too large. Please select images under 5MB');
      }
      Uint8List uploadBytes = bytes;

      // 3. Upload file with metadata
      final metadata = SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {
          'wishId': _currentWishId!,
          'uploadedAt': DateTime.now().toIso8601String(),
        },
      );

      // 4. Start upload with increased timeout
      final uploadTask = ref.putData(uploadBytes, metadata);

      // Task 6: Fix upload progress monitoring
      uploadTask.snapshotEvents.listen(
        (snapshot) {
          final progress = snapshot.bytesTransferred / snapshot.totalBytes;
          print('📊 Upload progress: ${(progress * 100).toStringAsFixed(1)}%');
          print(
            '📊 Bytes transferred: ${snapshot.bytesTransferred} / ${snapshot.totalBytes}',
          );
        },
        onError: (error) {
          print('❌ Upload stream error: $error');
        },
      );

      // Task 5: Increase timeout from 45 to 120 seconds
      final snapshot = await uploadTask.timeout(
        const Duration(seconds: 120), // Increased from 45
        onTimeout:
            () => throw TimeoutException('Upload timed out after 120 seconds'),
      );

      // 7. Get download URL
      final downloadUrl = await snapshot.ref.getDownloadURL();

      // 8. Validate URL
      if (!downloadUrl.startsWith('https://') ||
          !downloadUrl.contains('firebasestorage.googleapis.com')) {
        throw Exception('Invalid Firebase Storage URL');
      }

      // 9. Update local state
      if (mounted) {
        setState(() {
          image.status = ImageStatus.success;
          image.url = downloadUrl;
          _uploadedUrls.add(downloadUrl);
        });
      }

      print('✅ UPLOAD SUCCESS: ${image.name} → $downloadUrl');

      // 🚨 CRITICAL: IMMEDIATELY write URL to Firestore
      await _writeUrlToFirestore(downloadUrl);

      // Mark as saved to Firestore
      if (mounted) {
        setState(() {
          image.savedToFirestore = true;
        });
      }
    } catch (e) {
      print('❌ UPLOAD ERROR for ${image.name}: $e');

      // Update state to show failure
      if (mounted) {
        setState(() {
          image.status = ImageStatus.failed;
          image.error = e.toString();
        });
      }

      // Show error notification
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to upload ${image.name}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
            action: SnackBarAction(
              label: 'Retry',
              onPressed: () => _retryUpload(image),
            ),
          ),
        );
      }
    }
  }

  // 🚨 EMERGENCY FIX: Retry failed upload
  Future<void> _retryUpload(ImageItem image) async {
    if (mounted) {
      setState(() {
        image.status = ImageStatus.retrying;
        image.retryCount++;
        image.error = null;
      });
    }

    await _uploadImageToFirebase(image);
  }

  // Remove an image from the list and update Firestore with animation
  Future<void> _removeImage(ImageItem image) async {
    // First check if the image is currently uploading
    if (image.status == ImageStatus.uploading ||
        image.status == ImageStatus.retrying) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please wait for upload to complete before removing'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Store URL for Firestore update
    final String? imageUrl = image.url;
    final bool wasSavedToFirestore = image.savedToFirestore;

    // Set the image to be animating out (for UI purposes only)
    setState(() {
      image.status = ImageStatus.pending; // Change status to reflect deletion
    });

    // Start the Firestore update if needed
    bool firestoreUpdateSuccessful = true;
    if (imageUrl != null && wasSavedToFirestore && _currentWishId != null) {
      try {
        print('🗑️ REMOVING URL FROM FIRESTORE: $imageUrl');

        await _firestore.collection('wishes').doc(_currentWishId!).update({
          'photoUrls': FieldValue.arrayRemove([imageUrl]),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        print('✅ URL REMOVED FROM FIRESTORE: $imageUrl');
      } catch (e) {
        print('❌ ERROR REMOVING IMAGE FROM FIRESTORE: $e');
        firestoreUpdateSuccessful = false;

        // Show error message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to remove image: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }

    // Only proceed with removing from UI if Firestore update was successful or not needed
    if (firestoreUpdateSuccessful) {
      // Remove from local state after a short delay for animation
      await Future.delayed(const Duration(milliseconds: 300));

      if (mounted) {
        setState(() {
          _images.remove(image);
          if (imageUrl != null) {
            _uploadedUrls.remove(imageUrl);
          }
        });

        // Show success message with smooth animation
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Image removed successfully'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 1),
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.all(10),
            animation: null, // Uses default smooth animation
          ),
        );
      }
    } else {
      // Restore the image status if Firestore update failed
      if (mounted) {
        setState(() {
          // Reset the status to what it was before
          image.status =
              imageUrl != null ? ImageStatus.success : ImageStatus.failed;
        });
      }
    }
  }

  // 🚨 EMERGENCY FIX: Write URL to Firestore using arrayUnion
  Future<void> _writeUrlToFirestore(String downloadUrl) async {
    if (_currentWishId == null) {
      print('❌ No wish ID available for URL write');
      throw Exception('No wish ID available');
    }

    try {
      print('💾 WRITING TO FIRESTORE: Adding URL to photoUrls array...');

      // Direct update for reliability - no transaction needed for array operations
      await _firestore.collection('wishes').doc(_currentWishId!).update({
        'photoUrls': FieldValue.arrayUnion([downloadUrl]),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print('✅ FIRESTORE SUCCESS: URL added to photoUrls array');
      print('🔗 URL saved to Firestore: $downloadUrl');

      // Verify the update
      await _verifyFirestoreUpdate();
    } catch (e) {
      print('❌ FIRESTORE ERROR: Failed to write URL - $e');
      throw Exception('Failed to write URL to Firestore: $e');
    }
  }

  // Verify Firestore update was successful
  Future<void> _verifyFirestoreUpdate() async {
    try {
      final doc =
          await _firestore.collection('wishes').doc(_currentWishId!).get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        final photoUrls = data['photoUrls'] as List<dynamic>? ?? [];

        print(
          '🔍 VERIFICATION: Firestore document contains ${photoUrls.length} URLs',
        );

        // Log the actual URLs in Firestore for debugging
        for (int i = 0; i < photoUrls.length; i++) {
          print('🔗 Firestore URL ${i + 1}: ${photoUrls[i]}');
        }
      } else {
        print('❌ VERIFICATION FAILED: Document not found');
      }
    } catch (e) {
      print('⚠️ VERIFICATION ERROR: $e');
    }
  }

  // 🚨 EMERGENCY FIX: Delete temporary wish document
  Future<void> _deleteTemporaryWish() async {
    if (_currentWishId == null) return;

    try {
      print('🗑️ DELETING TEMPORARY WISH: $_currentWishId');
      
      await _firestore.collection('wishes').doc(_currentWishId!).delete();
      
      print('✅ TEMPORARY WISH DELETED: $_currentWishId');
      _currentWishId = null;
    } catch (e) {
      print('❌ FAILED TO DELETE TEMPORARY WISH: $e');
      // Don't throw error here, just log it as it's cleanup
    }
  }

  // Show confirmation dialog when user tries to go back
  Future<bool> _showCancelConfirmationDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Creating Wish?'),
        content: const Text(
          'Are you sure you want to cancel creating this wish? Any progress will be lost.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );
    
    return result ?? false;
  }

  // Handle back button press
  Future<bool> _onWillPop() async {
    // If user hasn't entered any meaningful content, allow back without confirmation
    if (_titleController.text.trim().isEmpty && 
        _descController.text.trim().isEmpty &&
        _images.isEmpty) {
      // Still delete the empty document
      await _deleteTemporaryWish();
      return true;
    }

    // Show confirmation dialog
    final shouldCancel = await _showCancelConfirmationDialog();
    
    if (shouldCancel) {
      // Delete the temporary wish document
      await _deleteTemporaryWish();
      return true; // Allow navigation
    }
    
    return false; // Prevent navigation
  }

  // Submit form - just updates metadata, images already uploaded
  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Task 2: Prevent form submission during upload
    final uploadingImages =
        _images
            .where(
              (img) =>
                  img.status == ImageStatus.uploading ||
                  img.status == ImageStatus.retrying,
            )
            .toList();

    if (uploadingImages.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please wait for ${uploadingImages.length} image(s) to finish uploading',
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Task 9: Add upload completion check
    final failedImages =
        _images.where((img) => img.status == ImageStatus.failed).toList();

    if (failedImages.isNotEmpty) {
      final proceed = await showDialog<bool>(
        context: context,
        builder:
            (context) => AlertDialog(
              title: const Text('Some images failed to upload'),
              content: Text(
                '${failedImages.length} image(s) failed. Continue without them?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Continue'),
                ),
              ],
            ),
      );
      if (proceed != true) return;
    }

    // Check if at least one image is uploaded successfully
    final successfulImages =
        _images.where((img) => img.status == ImageStatus.success).toList();
    if (successfulImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please upload at least one image'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Get selected categories
    final selectedTags =
        _selectedCategories.entries
            .where((entry) => entry.value)
            .map((entry) => entry.key)
            .toList();

    if (selectedTags.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one category')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      if (_currentWishId == null) {
        // Create document if it doesn't exist yet
        await _createEmptyWish();
      }

      // Parse budget if provided
      double? budget;
      if (_budgetController.text.trim().isNotEmpty) {
        budget = double.tryParse(_budgetController.text.trim());
      }

      // Final form submit - just update the metadata (no date/time needed)
      Map<String, dynamic> updateData = {
        'title': _titleController.text.trim(),
        'description': _descController.text.trim(),
        'location':
            _locationController.text.trim().isEmpty
                ? 'Location TBD'
                : _locationController.text.trim(),
        'categories': selectedTags,
        'updatedAt': FieldValue.serverTimestamp(),
        'status': 'Open', // Mark as active when user submits
      };

      // Add budget if provided
      if (budget != null) {
        updateData['budget'] = budget;
      }

      await _firestore
          .collection('wishes')
          .doc(_currentWishId!)
          .update(updateData);

      print(
        '✅ WISH FINALIZED: $_currentWishId with ${_uploadedUrls.length} photos',
      );

      // Display success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _uploadedUrls.isNotEmpty
                  ? 'Wish published with ${_uploadedUrls.length} photos!'
                  : 'Wish published successfully!',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );

        // Navigate back
        Navigator.of(context).pop();
      }
    } catch (e) {
      print('💥 Error in wish submission: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to publish wish: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Helper methods for UI
  Color _getStatusColor(ImageStatus status) {
    switch (status) {
      case ImageStatus.pending:
        return Colors.grey;
      case ImageStatus.uploading:
        return Colors.blue;
      case ImageStatus.success:
        return Colors.green;
      case ImageStatus.failed:
        return Colors.red;
      case ImageStatus.retrying:
        return Colors.orange;
    }
  }

  IconData _getStatusIcon(ImageStatus status) {
    switch (status) {
      case ImageStatus.pending:
        return Icons.hourglass_empty;
      case ImageStatus.uploading:
        return Icons.upload_file;
      case ImageStatus.success:
        return Icons.check_circle;
      case ImageStatus.failed:
        return Icons.error;
      case ImageStatus.retrying:
        return Icons.refresh;
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        
        final shouldPop = await _onWillPop();
        if (shouldPop && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Create Wish'),
          centerTitle: true,
          elevation: 0,
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
        ),
        backgroundColor: Colors.grey.shade50,
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Document creation status
                if (_isCreatingDoc)
                  Container(
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(bottom: 24),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.blue.shade600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          'Creating wish document...',
                          style: TextStyle(
                            color: Colors.blue.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),

                // Title Field
                TextFormField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    labelText: 'Title',
                    hintText: 'What experience are you looking for?',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16.0),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16.0),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16.0),
                      borderSide: BorderSide(
                        color: Colors.blue.shade400,
                        width: 2,
                      ),
                    ),
                    contentPadding: const EdgeInsets.all(20),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a title';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Description Field
                TextFormField(
                  controller: _descController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    labelText: 'Description',
                    hintText: 'Describe the experience you want in detail...',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16.0),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16.0),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16.0),
                      borderSide: BorderSide(
                        color: Colors.blue.shade400,
                        width: 2,
                      ),
                    ),
                    contentPadding: const EdgeInsets.all(20),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a description';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Location Field
                TextFormField(
                  controller: _locationController,
                  decoration: InputDecoration(
                    labelText: 'Preferred Location',
                    hintText: 'Where would you like this experience?',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16.0),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16.0),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16.0),
                      borderSide: BorderSide(
                        color: Colors.blue.shade400,
                        width: 2,
                      ),
                    ),
                    contentPadding: const EdgeInsets.all(20),
                  ),
                ),
                const SizedBox(height: 20),

                // Budget Field
                TextFormField(
                  controller: _budgetController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Budget (optional)',
                    hintText: 'What\'s your budget for this experience?',
                    prefixText: '\$',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16.0),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16.0),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16.0),
                      borderSide: BorderSide(
                        color: Colors.blue.shade400,
                        width: 2,
                      ),
                    ),
                    contentPadding: const EdgeInsets.all(20),
                  ),
                ),
                const SizedBox(height: 32),

                // Category Selection
                Text(
                  'Category',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12.0,
                  runSpacing: 8.0,
                  children:
                      _categories.map((category) {
                        final isSelected = _selectedCategories[category]!;
                        return InkWell(
                          onTap: () {
                            setState(() {
                              _selectedCategories[category] = !isSelected;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  isSelected
                                      ? Colors.blue.shade500
                                      : Colors.white,
                              borderRadius: BorderRadius.circular(25),
                              border: Border.all(
                                color:
                                    isSelected
                                        ? Colors.blue.shade500
                                        : Colors.grey.shade300,
                              ),
                            ),
                            child: Text(
                              category,
                              style: TextStyle(
                                color:
                                    isSelected
                                        ? Colors.white
                                        : Colors.grey.shade700,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                ),
                const SizedBox(height: 32),

                // Photos Section (moved to bottom to match Post Experience layout)
                Text(
                  'Photos (optional)',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                  ),
                ),
                const SizedBox(height: 16),

                // Photo upload area matching Post Experience design
                InkWell(
                  onTap: _pickAndUploadImages,
                  child: Container(
                    height: 150,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.grey.shade300,
                        style: BorderStyle.solid,
                      ),
                    ),
                    child:
                        _images.isEmpty
                            ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.add,
                                  size: 48,
                                  color: Colors.grey.shade400,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Add Photo',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey.shade600,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${_images.length}/3 photos',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                              ],
                            )
                            : Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Photos (${_images.length}/3)',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.grey.shade700,
                                        ),
                                      ),
                                      if (_images.length < 3)
                                        InkWell(
                                          onTap: _pickAndUploadImages,
                                          child: Icon(
                                            Icons.add_circle,
                                            color: Colors.blue.shade500,
                                            size: 24,
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Expanded(
                                    child: ListView.builder(
                                      scrollDirection: Axis.horizontal,
                                      itemCount: _images.length,
                                      itemBuilder: (context, index) {
                                        final image = _images[index];
                                        return Container(
                                          width: 80,
                                          height: 80,
                                          margin: const EdgeInsets.only(right: 8),
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            border: Border.all(
                                              color: _getStatusColor(
                                                image.status,
                                              ),
                                              width: 2,
                                            ),
                                          ),
                                          child: Stack(
                                            children: [
                                              ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                                child:
                                                    kIsWeb
                                                        ? FutureBuilder<
                                                          Uint8List
                                                        >(
                                                          future:
                                                              image.file
                                                                  .readAsBytes(),
                                                          builder: (
                                                            context,
                                                            snapshot,
                                                          ) {
                                                            if (snapshot
                                                                .hasData) {
                                                              return Image.memory(
                                                                snapshot.data!,
                                                                width: 80,
                                                                height: 80,
                                                                fit: BoxFit.cover,
                                                              );
                                                            }
                                                            return const Center(
                                                              child:
                                                                  CircularProgressIndicator(
                                                                    strokeWidth:
                                                                        2,
                                                                  ),
                                                            );
                                                          },
                                                        )
                                                        : Image.file(
                                                          File(image.file.path),
                                                          width: 80,
                                                          height: 80,
                                                          fit: BoxFit.cover,
                                                        ),
                                              ),
                                              // Enhanced delete button for all images (except those currently uploading)
                                              if (image.status !=
                                                      ImageStatus.uploading &&
                                                  image.status !=
                                                      ImageStatus.retrying)
                                                Positioned(
                                                  top: 2,
                                                  right: 2,
                                                  child: GestureDetector(
                                                    onTap: () {
                                                      // Show a confirmation snackbar after removal
                                                      _removeImage(image).then((
                                                        _,
                                                      ) {
                                                        ScaffoldMessenger.of(
                                                          context,
                                                        ).showSnackBar(
                                                          const SnackBar(
                                                            content: Text(
                                                              'Image removed successfully',
                                                            ),
                                                            backgroundColor:
                                                                Colors.green,
                                                            duration: Duration(
                                                              seconds: 1,
                                                            ),
                                                          ),
                                                        );
                                                      });
                                                    },
                                                    child: Container(
                                                      padding:
                                                          const EdgeInsets.all(8),
                                                      decoration: BoxDecoration(
                                                        color: Colors.red.shade700
                                                            .withOpacity(0.9),
                                                        shape: BoxShape.circle,
                                                        boxShadow: [
                                                          BoxShadow(
                                                            color: Colors.black
                                                                .withOpacity(0.3),
                                                            blurRadius: 3,
                                                            offset: const Offset(
                                                              0,
                                                              1,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                      child: const Icon(
                                                        Icons.close,
                                                        size: 18,
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              // Status indicator (moved to bottom left)
                                              Positioned(
                                                bottom: 2,
                                                left: 2,
                                                child: Container(
                                                  padding: const EdgeInsets.all(
                                                    2,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: _getStatusColor(
                                                      image.status,
                                                    ),
                                                    shape: BoxShape.circle,
                                                  ),
                                                  child: Icon(
                                                    _getStatusIcon(image.status),
                                                    size: 12,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ),
                                              // Retry button for failed uploads
                                              if (image.status ==
                                                  ImageStatus.failed)
                                                Positioned(
                                                  bottom: 2,
                                                  right: 2,
                                                  child: InkWell(
                                                    onTap:
                                                        () => _retryUpload(image),
                                                    child: Container(
                                                      padding:
                                                          const EdgeInsets.all(2),
                                                      decoration:
                                                          const BoxDecoration(
                                                            color: Colors.red,
                                                            shape:
                                                                BoxShape.circle,
                                                          ),
                                                      child: const Icon(
                                                        Icons.refresh,
                                                        size: 12,
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                  ),
                ),
                const SizedBox(height: 40),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submitForm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade600,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      disabledBackgroundColor: Colors.grey.shade300,
                    ),
                    child:
                        _isLoading
                            ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                            : const Text(
                              'Publish Wish',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
