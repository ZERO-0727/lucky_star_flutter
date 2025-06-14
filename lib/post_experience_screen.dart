import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:typed_data';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'services/experience_service.dart';

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

class PostExperienceScreen extends StatefulWidget {
  final bool isAddWishActive;

  const PostExperienceScreen({super.key, this.isAddWishActive = false});

  @override
  _PostExperienceScreenState createState() => _PostExperienceScreenState();
}

class _PostExperienceScreenState extends State<PostExperienceScreen> {
  final _formKey = GlobalKey<FormState>();
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
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
  String? _currentExperienceId;

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _slotsController = TextEditingController();

  final ExperienceService _experienceService = ExperienceService();
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
    _createEmptyExperience();
  }

  // 🚨 EMERGENCY FIX: Create empty experience document immediately
  Future<void> _createEmptyExperience() async {
    if (_currentExperienceId != null) return;

    setState(() {
      _isCreatingDoc = true;
    });

    try {
      // Create minimal initial document with empty photoUrls array
      final newExperience = {
        'title': 'Draft Experience',
        'description': 'This experience is being created...',
        'location': 'TBD',
        'date': Timestamp.fromDate(DateTime.now().add(const Duration(days: 1))),
        'tags': ['Draft'],
        'photoUrls': [], // 🚨 CRITICAL: Initialize empty array
        'availableSlots': 1,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'userId': _experienceService.currentUser?.uid ?? 'anonymous',
      };

      // Create document and get its ID
      final docRef = await _firestore
          .collection('experiences')
          .add(newExperience);
      _currentExperienceId = docRef.id;

      print('✅ Empty experience document created: $_currentExperienceId');
    } catch (e) {
      print('❌ Failed to create experience document: $e');
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
    if (_currentExperienceId == null) {
      // Ensure we have a document before picking images
      await _createEmptyExperience();
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
    if (_currentExperienceId == null) {
      print('❌ No experience ID available for URL write');
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
      final currentUser = _experienceService.currentUser;
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
          'experience_images/${_experienceService.currentUser?.uid ?? "anonymous"}/$fileName';
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
          'experienceId': _currentExperienceId!,
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

  // Remove an image from the list and update Firestore
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

    try {
      // Remove from local state first
      setState(() {
        _images.remove(image);
        if (image.url != null) {
          _uploadedUrls.remove(image.url);
        }
      });

      // If successfully uploaded to Firestore, remove from Firestore array
      if (image.url != null &&
          image.savedToFirestore &&
          _currentExperienceId != null) {
        print('🗑️ REMOVING URL FROM FIRESTORE: ${image.url}');

        await _firestore
            .collection('experiences')
            .doc(_currentExperienceId!)
            .update({
              'photoUrls': FieldValue.arrayRemove([image.url]),
              'updatedAt': FieldValue.serverTimestamp(),
            });

        print('✅ URL REMOVED FROM FIRESTORE: ${image.url}');

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Image removed successfully'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      print('❌ ERROR REMOVING IMAGE: $e');

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to remove image: $e'),
          backgroundColor: Colors.red,
        ),
      );

      // Restore the image in the local state
      setState(() {
        _images.add(image);
        if (image.url != null) {
          _uploadedUrls.add(image.url!);
        }
      });
    }
  }

  // 🚨 EMERGENCY FIX: Write URL to Firestore using arrayUnion
  Future<void> _writeUrlToFirestore(String downloadUrl) async {
    if (_currentExperienceId == null) {
      print('❌ No experience ID available for URL write');
      throw Exception('No experience ID available');
    }

    try {
      print('💾 WRITING TO FIRESTORE: Adding URL to photoUrls array...');

      // Direct update for reliability - no transaction needed for array operations
      await _firestore
          .collection('experiences')
          .doc(_currentExperienceId!)
          .update({
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
          await _firestore
              .collection('experiences')
              .doc(_currentExperienceId!)
              .get();

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

  // Basic form functions
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(DateTime.now().year + 1),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null && picked != _selectedTime) {
      setState(() => _selectedTime = picked);
    }
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

    if (_selectedDate == null || _selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select date and time')),
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
      // Combine date and time
      final dateTime = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        _selectedTime!.hour,
        _selectedTime!.minute,
      );

      if (_currentExperienceId == null) {
        // Create document if it doesn't exist yet
        await _createEmptyExperience();
      }

      // Final form submit - just update the metadata
      await _firestore
          .collection('experiences')
          .doc(_currentExperienceId!)
          .update({
            'title': _titleController.text.trim(),
            'description': _descController.text.trim(),
            'location':
                _locationController.text.trim().isEmpty
                    ? 'Location TBD'
                    : _locationController.text.trim(),
            'date': Timestamp.fromDate(dateTime),
            'tags': selectedTags,
            'availableSlots': int.tryParse(_slotsController.text) ?? 1,
            'updatedAt': FieldValue.serverTimestamp(),
            'status': 'active', // Mark as active when user submits
          });

      print(
        '✅ EXPERIENCE FINALIZED: $_currentExperienceId with ${_uploadedUrls.length} photos',
      );

      // Display success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _uploadedUrls.isNotEmpty
                  ? 'Experience published with ${_uploadedUrls.length} photos!'
                  : 'Experience published successfully!',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );

        // Navigate back
        Navigator.of(context).pop();
      }
    } catch (e) {
      print('💥 Error in experience submission: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to publish experience: $e'),
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Experience'),
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
                        'Creating experience document...',
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
                  hintText: 'Give your experience a catchy title',
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
                  hintText: 'Describe what participants will experience...',
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
                  labelText: 'Location',
                  hintText: 'Where will this experience take place?',
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

              // Available Slots Field
              TextFormField(
                controller: _slotsController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Available Slots',
                  hintText: 'How many people can join?',
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
                    return 'Please enter number of slots';
                  }
                  if (int.tryParse(value) == null || int.parse(value) < 1) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Date & Time Fields
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => _selectDate(context),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Date',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _selectedDate != null
                                  ? DateFormat.yMd().format(_selectedDate!)
                                  : 'Select date',
                              style: TextStyle(
                                fontSize: 16,
                                color:
                                    _selectedDate != null
                                        ? Colors.black
                                        : Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: InkWell(
                      onTap: () => _selectTime(context),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Time',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _selectedTime != null
                                  ? _selectedTime!.format(context)
                                  : 'Select time',
                              style: TextStyle(
                                fontSize: 16,
                                color:
                                    _selectedTime != null
                                        ? Colors.black
                                        : Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
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

              // Photos Section (moved to bottom to match Post Wish layout)
              Text(
                'Photos (optional)',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade800,
                ),
              ),
              const SizedBox(height: 16),

              // Photo upload area matching Post Wish design
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
                                                        const EdgeInsets.all(6),
                                                    decoration: BoxDecoration(
                                                      color: Colors.red
                                                          .withOpacity(0.9),
                                                      shape: BoxShape.circle,
                                                      boxShadow: [
                                                        BoxShadow(
                                                          color: Colors.black
                                                              .withOpacity(0.2),
                                                          blurRadius: 2,
                                                          offset: const Offset(
                                                            0,
                                                            1,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    child: const Icon(
                                                      Icons.delete_outline,
                                                      size: 16,
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
                            'Publish Experience',
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
    );
  }
}
