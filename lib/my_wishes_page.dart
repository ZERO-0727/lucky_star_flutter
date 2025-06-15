import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'models/wish_model.dart';
import 'wish_detail_screen.dart';

class MyWishesPage extends StatefulWidget {
  const MyWishesPage({super.key});

  @override
  State<MyWishesPage> createState() => _MyWishesPageState();
}

class _MyWishesPageState extends State<MyWishesPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<QuerySnapshot>? _wishesStream;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initWishesStream();
  }

  void _initWishesStream() {
    final currentUser = _auth.currentUser;

    if (currentUser == null) {
      setState(() {
        _error = 'You must be logged in to view your wishes';
        _isLoading = false;
      });
      return;
    }

    try {
      _wishesStream =
          _firestore
              .collection('wishes')
              .where('userId', isEqualTo: currentUser.uid)
              .orderBy('createdAt', descending: true)
              .snapshots();

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error loading wishes: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Wishes'),
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
                stream: _wishesStream,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return _buildErrorState(
                      error: 'Error loading wishes: ${snapshot.error}',
                    );
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return _buildEmptyState();
                  }

                  final wishes = snapshot.data!.docs;
                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: wishes.length,
                    itemBuilder: (context, index) {
                      final wishDoc = wishes[index];
                      final wishData = wishDoc.data() as Map<String, dynamic>;
                      wishData['id'] =
                          wishDoc.id; // Add document ID to the data
                      return _buildWishCard(wishData);
                    },
                  );
                },
              ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.pushNamed(context, '/post-wish');
        },
        backgroundColor: const Color(0xFF7153DF),
        icon: const Icon(Icons.add),
        label: const Text('Create a Wish'),
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
              _initWishesStream();
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
          Icon(Icons.star_border, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No wishes yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your posted wishes will appear here',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              // Navigate to create wish page
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Create wish feature coming soon'),
                ),
              );
            },
            icon: const Icon(Icons.add),
            label: const Text('Create a Wish'),
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

  Widget _buildWishCard(Map<String, dynamic> wish) {
    // Get image URL (first one if there are multiple)
    final List<dynamic> photoUrls = wish['photoUrls'] ?? [];
    final String imageUrl = photoUrls.isNotEmpty ? photoUrls[0] : '';

    // Format timestamp
    String formattedDate = 'Unknown date';
    if (wish['createdAt'] != null) {
      try {
        final timestamp = wish['createdAt'] as Timestamp;
        final dateTime = timestamp.toDate();
        formattedDate = DateFormat('MMM d, yyyy').format(dateTime);
      } catch (e) {
        print('Error formatting date: $e');
      }
    }

    // Get categories for display as tags
    final List<dynamic> categories = wish['categories'] ?? [];

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
                      height: 180,
                      color: Colors.grey[300],
                      child: const Center(
                        child: Icon(Icons.image, size: 50, color: Colors.grey),
                      ),
                    )
                    : Image.network(
                      imageUrl,
                      height: 180,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 180,
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
                  wish['title'] ?? 'Untitled Wish',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),

                // Description
                Text(
                  wish['description'] ?? 'No description provided',
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
                if (wish['location'] != null) ...[
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
                          wish['location'],
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

                // Created date
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 14,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Created: $formattedDate',
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
                        // Edit wish logic
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Edit wish ${wish['id']} coming soon',
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
                        _showDeleteConfirmation(wish);
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

  void _showDeleteConfirmation(Map<String, dynamic> wish) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Wish'),
            content: Text(
              'Are you sure you want to delete "${wish['title']}"?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  await _deleteWish(wish['id']);
                },
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Delete'),
              ),
            ],
          ),
    );
  }

  Future<void> _deleteWish(String wishId) async {
    try {
      await _firestore.collection('wishes').doc(wishId).delete();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Wish deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete wish: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
