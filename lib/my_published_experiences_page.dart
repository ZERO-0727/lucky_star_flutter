import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'models/experience_model.dart';
import 'experience_detail_screen.dart';

class MyPublishedExperiencesPage extends StatefulWidget {
  const MyPublishedExperiencesPage({super.key});

  @override
  State<MyPublishedExperiencesPage> createState() =>
      _MyPublishedExperiencesPageState();
}

class _MyPublishedExperiencesPageState
    extends State<MyPublishedExperiencesPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<QuerySnapshot>? _experiencesStream;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initExperiencesStream();
  }

  void _initExperiencesStream() {
    final currentUser = _auth.currentUser;

    if (currentUser == null) {
      setState(() {
        _error = 'You must be logged in to view your experiences';
        _isLoading = false;
      });
      return;
    }

    try {
      _experiencesStream =
          _firestore
              .collection('experiences')
              .where('userId', isEqualTo: currentUser.uid)
              .orderBy('createdAt', descending: true)
              .snapshots();

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error loading experiences: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Published Experiences'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
              ? _buildErrorState()
              : StreamBuilder<QuerySnapshot>(
                stream: _experiencesStream,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return _buildErrorState(
                      error: 'Error loading experiences: ${snapshot.error}',
                    );
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return _buildEmptyState();
                  }

                  final experiences = snapshot.data!.docs;
                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: experiences.length,
                    itemBuilder: (context, index) {
                      final experienceDoc = experiences[index];
                      final experienceData =
                          experienceDoc.data() as Map<String, dynamic>;
                      experienceData['id'] =
                          experienceDoc.id; // Add document ID to the data
                      return _buildExperienceCard(experienceData);
                    },
                  );
                },
              ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Navigate to add experience page
          Navigator.pushNamed(context, '/post-experience');
        },
        backgroundColor: const Color(0xFF7153DF),
        icon: const Icon(Icons.add),
        label: const Text('Add New Experience'),
      ),
    );
  }

  Widget _buildErrorState({String? error}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 80, color: Colors.red[300]),
          const SizedBox(height: 16),
          Text(
            error ?? _error ?? 'Something went wrong',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[800],
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              setState(() {
                _isLoading = true;
                _error = null;
              });
              _initExperiencesStream();
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7153DF),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.explore_off, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No experiences published yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your published experiences will appear here',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              // Navigate to add experience page
              Navigator.pushNamed(context, '/post-experience');
            },
            icon: const Icon(Icons.add),
            label: const Text('Add New Experience'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7153DF),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExperienceCard(Map<String, dynamic> experience) {
    // Get image URL (first one if there are multiple)
    final List<dynamic> photoUrls = experience['photoUrls'] ?? [];
    final String imageUrl = photoUrls.isNotEmpty ? photoUrls[0] : '';

    // Format timestamp
    String formattedDate = 'Unknown date';
    if (experience['createdAt'] != null) {
      try {
        final timestamp = experience['createdAt'] as Timestamp;
        final dateTime = timestamp.toDate();
        formattedDate = DateFormat('MMM d, yyyy').format(dateTime);
      } catch (e) {
        print('Error formatting date: $e');
      }
    }

    // Get categories for display as tags
    final List<dynamic> categories = experience['categories'] ?? [];

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child:
                imageUrl.isEmpty
                    ? Container(
                      height: 200,
                      color: Colors.grey[300],
                      child: const Center(
                        child: Icon(Icons.image, size: 50, color: Colors.grey),
                      ),
                    )
                    : Image.network(
                      imageUrl,
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 200,
                          color: Colors.grey[300],
                          child: const Center(
                            child: Icon(
                              Icons.image,
                              size: 50,
                              color: Colors.grey,
                            ),
                          ),
                        );
                      },
                    ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Text(
                  experience['title'] ?? 'Untitled Experience',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),

                // Description
                Text(
                  experience['description'] ?? 'No description provided',
                  style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 16),

                // Categories/Tags
                if (categories.isNotEmpty) ...[
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children:
                        categories.map<Widget>((category) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF5F0FF),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: const Color(0xFF7153DF).withOpacity(0.3),
                              ),
                            ),
                            child: Text(
                              category.toString(),
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF7153DF),
                              ),
                            ),
                          );
                        }).toList(),
                  ),
                  const SizedBox(height: 16),
                ],

                // Location
                if (experience['location'] != null) ...[
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 14,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          experience['location'],
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],

                // Posted date
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 14,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Posted: $formattedDate',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Action buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // Edit button
                    OutlinedButton.icon(
                      onPressed: () {
                        // Edit experience logic
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Edit experience ${experience['id']} coming soon',
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.edit, size: 16),
                      label: const Text('Edit'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF7153DF),
                        side: const BorderSide(color: Color(0xFF7153DF)),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Delete button
                    OutlinedButton.icon(
                      onPressed: () {
                        _showDeleteConfirmation(experience);
                      },
                      icon: const Icon(Icons.delete_outline, size: 16),
                      label: const Text('Delete'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(Map<String, dynamic> experience) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Experience'),
            content: Text(
              'Are you sure you want to delete "${experience['title']}"?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  await _deleteExperience(experience['id']);
                },
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Delete'),
              ),
            ],
          ),
    );
  }

  Future<void> _deleteExperience(String experienceId) async {
    try {
      await _firestore.collection('experiences').doc(experienceId).delete();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Experience deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete experience: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
