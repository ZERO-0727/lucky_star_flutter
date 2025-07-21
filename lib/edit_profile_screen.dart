import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:typed_data';
import 'models/user_model.dart';
import 'services/user_service.dart';

class EditProfileScreen extends StatefulWidget {
  final UserModel? user;

  const EditProfileScreen({super.key, this.user});

  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final UserService _userService = UserService();
  final ImagePicker _picker = ImagePicker();

  // Form controllers
  final TextEditingController _displayNameController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();

  // State variables
  UserModel? _currentUser;
  String? _selectedGender;
  Uint8List? _selectedImageBytes;
  String? _selectedImageName;
  String? _currentAvatarUrl;
  bool _isLoading = false;
  bool _isUploading = false;
  bool _isInitialLoading = true;
  String? _currentUserId;

  // Gender options
  final List<String> _genderOptions = ['Male', 'Female'];

  // Exchange status options
  final List<String> _exchangeStatusOptions = [
    'Open to Exchange',
    'By Request Only',
    'Unavailable',
  ];
  String? _selectedExchangeStatus;

  @override
  void initState() {
    super.initState();
    _initializeUser();
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _bioController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _initializeUser() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        _currentUserId = user.uid;

        // Load user data from Firestore
        final userData = await _userService.getUserById(user.uid);
        if (userData != null && mounted) {
          setState(() {
            _currentUser = userData;
            _displayNameController.text = userData.displayName;
            _bioController.text = userData.bio;
            _locationController.text = userData.location;
            _selectedGender =
                userData.gender.isNotEmpty ? userData.gender : null;
            _selectedExchangeStatus =
                userData.status.isNotEmpty
                    ? userData.status
                    : 'Open to Exchange';
            _currentAvatarUrl = userData.avatarUrl;
            _isInitialLoading = false;
          });
        } else {
          // Create initial user document if doesn't exist
          final newUser = UserModel(
            userId: user.uid,
            displayName: user.displayName ?? 'User',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
          await _userService.createUser(newUser);
          if (mounted) {
            setState(() {
              _currentUser = newUser;
              _displayNameController.text = newUser.displayName;
              _isInitialLoading = false;
            });
          }
        }
      }
    } catch (e) {
      print('Error initializing user: $e');
      if (mounted) {
        setState(() {
          _isInitialLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading profile: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );

      if (image != null) {
        final bytes = await image.readAsBytes();
        if (mounted) {
          setState(() {
            _selectedImageBytes = bytes;
            _selectedImageName = image.name;
          });
        }
      }
    } catch (e) {
      print('Error picking image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error selecting image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<String?> _uploadAvatar() async {
    if (_selectedImageBytes == null || _currentUserId == null) return null;

    try {
      if (mounted) {
        setState(() {
          _isUploading = true;
        });
      }

      final storageRef = FirebaseStorage.instance
          .ref()
          .child('user_avatars')
          .child('$_currentUserId.jpg');

      final uploadTask = storageRef.putData(
        _selectedImageBytes!,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      // Monitor upload progress
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        final progress = snapshot.bytesTransferred / snapshot.totalBytes;
        print('Upload progress: ${(progress * 100).toStringAsFixed(2)}%');
      });

      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      if (mounted) {
        setState(() {
          _isUploading = false;
          _currentAvatarUrl = downloadUrl;
        });
      }

      return downloadUrl;
    } catch (e) {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
      print('Error uploading avatar: $e');
      throw e;
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    if (_currentUserId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('User not authenticated'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      String? avatarUrl = _currentAvatarUrl;

      // Upload new avatar if selected
      if (_selectedImageBytes != null) {
        avatarUrl = await _uploadAvatar();
      }

      // Update user data
      final updatedUser = _currentUser!.copyWith(
        displayName: _displayNameController.text.trim(),
        bio: _bioController.text.trim(),
        location: _locationController.text.trim(),
        gender: _selectedGender ?? '',
        status: _selectedExchangeStatus ?? 'Open to Exchange',
        avatarUrl: avatarUrl ?? '',
        updatedAt: DateTime.now(),
      );

      await _userService.updateUser(updatedUser);

      if (mounted) {
        setState(() {
          _currentUser = updatedUser;
          _selectedImageBytes = null;
          _selectedImageName = null;
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(updatedUser); // Return updated user
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        print('Error saving profile: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving profile: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitialLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Edit Profile'), centerTitle: true),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile'), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Profile Photo Section
              _buildAvatarSection(),
              const SizedBox(height: 24),

              // Personal Information Section
              _buildSectionHeader('Personal Information'),
              const SizedBox(height: 16),

              TextFormField(
                controller: _displayNameController,
                decoration: _inputDecoration('Display Name'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your display name';
                  }
                  if (value.trim().length < 2) {
                    return 'Display name must be at least 2 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Gender Dropdown
              DropdownButtonFormField<String>(
                value: _selectedGender,
                decoration: _inputDecoration('Gender'),
                hint: const Text('Select Gender'),
                items:
                    _genderOptions.map((String gender) {
                      return DropdownMenuItem<String>(
                        value: gender,
                        child: Text(gender),
                      );
                    }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedGender = newValue;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select your gender';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // About You Section
              _buildSectionHeader('About You'),
              const SizedBox(height: 16),
              TextFormField(
                controller: _bioController,
                maxLines: 4,
                maxLength: 500,
                decoration: _inputDecoration(
                  'Tell us about yourself...',
                ).copyWith(
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 16,
                  ),
                ),
                validator: (value) {
                  if (value != null && value.length > 500) {
                    return 'Bio must be less than 500 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Contact Information Section
              _buildSectionHeader('Contact Information'),
              const SizedBox(height: 16),
              TextFormField(
                controller: _locationController,
                decoration: _inputDecoration('Location'),
                validator: (value) {
                  if (value != null && value.isNotEmpty && value.length < 2) {
                    return 'Location must be at least 2 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 40),

              // Save Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7153DF),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child:
                      _isLoading
                          ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                          : const Text(
                            'Save Changes',
                            style: TextStyle(fontSize: 18, color: Colors.white),
                          ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarSection() {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFF7153DF), width: 3),
      ),
      child: CircleAvatar(
        radius: 60,
        backgroundColor: Colors.grey[300],
        backgroundImage:
            _selectedImageBytes != null
                ? MemoryImage(_selectedImageBytes!)
                : (_currentAvatarUrl != null && _currentAvatarUrl!.isNotEmpty)
                ? NetworkImage(_currentAvatarUrl!)
                : null,
        child:
            (_selectedImageBytes == null &&
                    (_currentAvatarUrl == null || _currentAvatarUrl!.isEmpty))
                ? const Icon(Icons.person, size: 60, color: Colors.grey)
                : null,
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Row(
      children: [
        Expanded(child: Divider(color: Colors.grey[400], thickness: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF7153DF),
            ),
          ),
        ),
        Expanded(child: Divider(color: Colors.grey[400], thickness: 1)),
      ],
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.grey[100],
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF7153DF), width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red, width: 2),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );
  }
}
