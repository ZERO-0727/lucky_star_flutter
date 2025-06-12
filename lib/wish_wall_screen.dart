import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'plaza_post_detail_screen.dart';
import 'search_page.dart';
import 'experience_detail_screen.dart';
import 'wish_detail_screen.dart';
import 'models/experience_model.dart';
import 'models/wish_model.dart';
import 'package:intl/intl.dart';

class WishWallScreen extends StatefulWidget {
  final int initialTabIndex;

  const WishWallScreen({super.key, this.initialTabIndex = 0});

  @override
  State<WishWallScreen> createState() => _WishWallScreenState();
}

class _WishWallScreenState extends State<WishWallScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _selectedDateFilter;
  String? _selectedTag;
  final List<String> _availableTags = [
    'All',
    'Food',
    'Sport',
    'Travel',
    'Culture',
    'Adventure',
    'Learning',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTabIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Wish Wall'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SearchPage()),
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [Tab(text: 'Wish Wall'), Tab(text: 'Share Experience')],
        ),
      ),
      body: Column(
        children: [
          // Filters Section
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Date filter
                DropdownButtonFormField<String>(
                  value: _selectedDateFilter,
                  decoration: const InputDecoration(
                    labelText: 'Filter by Date',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'today', child: Text('Today')),
                    DropdownMenuItem(
                      value: 'this_week',
                      child: Text('This Week'),
                    ),
                    DropdownMenuItem(
                      value: 'this_month',
                      child: Text('This Month'),
                    ),
                    DropdownMenuItem(value: 'all', child: Text('All Time')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedDateFilter = value;
                    });
                  },
                ),

                const SizedBox(height: 12),

                // Tag filter (only show on Share Experience tab)
                if (_tabController.index == 1)
                  DropdownButtonFormField<String>(
                    value: _selectedTag,
                    decoration: const InputDecoration(
                      labelText: 'Filter by Category',
                      border: OutlineInputBorder(),
                    ),
                    items:
                        _availableTags.map((tag) {
                          return DropdownMenuItem(
                            value: tag == 'All' ? null : tag,
                            child: Text(tag),
                          );
                        }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedTag = value;
                      });
                    },
                  ),
              ],
            ),
          ),

          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [_buildWishList(), _buildShareExperience()],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showOptions,
        backgroundColor: const Color(0xFF7153DF),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildWishList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 8, // Dummy data for wishes
      itemBuilder: (context, index) => _buildWishCard(context, index),
    );
  }

  Widget _buildShareExperience() {
    return StreamBuilder<QuerySnapshot>(
      stream: _getFilteredExperiencesStream(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red.shade400),
                const SizedBox(height: 16),
                Text('Error loading experiences: ${snapshot.error}'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => setState(() {}),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final experiences = snapshot.data?.docs ?? [];

        if (experiences.isEmpty) {
          return _buildEmptyState();
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: experiences.length,
          itemBuilder: (context, index) {
            final doc = experiences[index];
            final experience = ExperienceModel.fromFirestore(doc);
            return _buildRealExperienceCard(context, experience);
          },
        );
      },
    );
  }

  Stream<QuerySnapshot> _getFilteredExperiencesStream() {
    try {
      // Debug logging to see exact query being made
      print('🔍 Building Firestore query with filters:');
      print('  - Date filter: $_selectedDateFilter');
      print('  - Tag filter: $_selectedTag');

      Query query = FirebaseFirestore.instance
          .collection('experiences')
          .where('status', isEqualTo: 'active');

      // Handle different query combinations to avoid complex composite indexes
      if (_selectedTag != null && _selectedDateFilter != null) {
        // Complex case: both tag and date filter
        print('  - Using complex query: status + tags + createdAt + orderBy');

        DateTime filterDate = _getFilterDate(_selectedDateFilter!);

        query = query
            .where('tags', arrayContains: _selectedTag)
            .where('createdAt', isGreaterThan: Timestamp.fromDate(filterDate))
            .orderBy('createdAt', descending: true);

        print(
          '  - Required index: experiences (status ASC, tags ASC, createdAt DESC)',
        );
      } else if (_selectedTag != null) {
        // Tag filter only
        print('  - Using tag query: status + tags + orderBy');

        query = query
            .where('tags', arrayContains: _selectedTag)
            .orderBy('createdAt', descending: true);

        print(
          '  - Required index: experiences (status ASC, tags ASC, createdAt DESC)',
        );
      } else if (_selectedDateFilter != null) {
        // Date filter only
        print('  - Using date query: status + createdAt + orderBy');

        DateTime filterDate = _getFilterDate(_selectedDateFilter!);

        query = query
            .where('createdAt', isGreaterThan: Timestamp.fromDate(filterDate))
            .orderBy('createdAt', descending: true);

        print('  - Required index: experiences (status ASC, createdAt DESC)');
      } else {
        // No filters, just basic query
        print('  - Using basic query: status + orderBy');

        query = query.orderBy('createdAt', descending: true);

        print('  - Required index: experiences (status ASC, createdAt DESC)');
      }

      print('  - Final query limit: 50');
      return query.limit(50).snapshots();
    } catch (e) {
      print('❌ Error building Firestore query: $e');

      // Fallback to basic query if complex query fails
      print('🔄 Falling back to basic query without filters');
      return FirebaseFirestore.instance
          .collection('experiences')
          .where('status', isEqualTo: 'active')
          .orderBy('createdAt', descending: true)
          .limit(50)
          .snapshots();
    }
  }

  DateTime _getFilterDate(String filter) {
    switch (filter) {
      case 'today':
        // Get start of today (midnight)
        final now = DateTime.now();
        return DateTime(now.year, now.month, now.day);
      case 'this_week':
        return DateTime.now().subtract(const Duration(days: 7));
      case 'this_month':
        return DateTime.now().subtract(const Duration(days: 30));
      case 'all':
      default:
        return DateTime.now().subtract(const Duration(days: 365));
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.explore_off,
                size: 60,
                color: Colors.grey.shade400,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No experiences found',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _getEmptyStateMessage(),
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // Action buttons
            Column(
              children: [
                if (_selectedDateFilter != null || _selectedTag != null) ...[
                  OutlinedButton.icon(
                    onPressed: () {
                      setState(() {
                        _selectedDateFilter = null;
                        _selectedTag = null;
                      });
                    },
                    icon: const Icon(Icons.clear),
                    label: const Text('Clear Filters'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.blue.shade600,
                      side: BorderSide(color: Colors.blue.shade600),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pushNamed(context, '/post-experience');
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Share an Experience'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getEmptyStateMessage() {
    if (_selectedDateFilter != null && _selectedTag != null) {
      return 'No experiences found for $_selectedTag in $_selectedDateFilter timeframe.\nTry adjusting your filters or be the first to share!';
    } else if (_selectedDateFilter != null) {
      return 'No experiences found for $_selectedDateFilter.\nTry a different date range or share your own!';
    } else if (_selectedTag != null) {
      return 'No $_selectedTag experiences found.\nTry a different category or share yours!';
    } else {
      return 'Be the first to share an amazing experience\nwith the community!';
    }
  }

  Widget _buildRealExperienceCard(
    BuildContext context,
    ExperienceModel experience,
  ) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image section
          Container(
            height: 200,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              color: Colors.grey.shade300,
            ),
            child:
                experience.photoUrls.isNotEmpty
                    ? ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(16),
                      ),
                      child: Container(
                        width: double.infinity,
                        height: 200,
                        color: Colors.black, // Background for letterbox effect
                        child: Image.network(
                          experience.photoUrls.first,
                          width: double.infinity,
                          height: 200,
                          fit:
                              BoxFit
                                  .contain, // Show full image with letterboxing
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              height: 200,
                              color: Colors.grey.shade300,
                              child: const Center(
                                child: Icon(
                                  Icons.image,
                                  size: 60,
                                  color: Colors.grey,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    )
                    : const Center(
                      child: Icon(Icons.image, size: 60, color: Colors.grey),
                    ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title and bookmark
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        experience.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.star_border, color: Colors.grey),
                      onPressed: () {
                        // TODO: Implement favorite functionality
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Description
                Text(
                  experience.description,
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 12),

                // Host info
                Row(
                  children: [
                    const CircleAvatar(
                      radius: 16,
                      backgroundColor: Colors.blue,
                      child: Icon(Icons.person, color: Colors.white, size: 16),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Host: ${experience.userId.substring(0, 8)}...',
                      style: const TextStyle(fontSize: 14),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${experience.availableSlots} slots',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Tags
                if (experience.tags.isNotEmpty)
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children:
                        experience.tags.take(3).map((tag) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade100,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              tag,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.blue.shade700,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          );
                        }).toList(),
                  ),

                const SizedBox(height: 12),

                // Location and date
                Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      size: 16,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        experience.location,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Icon(Icons.schedule, size: 16, color: Colors.grey.shade600),
                    const SizedBox(width: 4),
                    Text(
                      DateFormat('MMM dd').format(experience.date),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // View Details button (removed like icon)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => ExperienceDetailScreen(
                                experienceId: experience.experienceId,
                                experience: experience,
                              ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade600,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('View Details'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWishCard(BuildContext context, int index) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image and title
          Stack(
            children: [
              Container(
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.blueGrey[100],
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                ),
                child: const Center(
                  child: Icon(Icons.image, size: 60, color: Colors.grey),
                ),
              ),
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.verified, size: 16, color: Colors.white),
                      SizedBox(width: 4),
                      Text(
                        'Secure',
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title and star favorite
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Wish $index',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.star_border, color: Colors.grey),
                      onPressed: () {
                        // TODO: Implement favorite functionality
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // User info
                Row(
                  children: [
                    const CircleAvatar(
                      radius: 16,
                      backgroundColor: Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    Text('User $index', style: const TextStyle(fontSize: 14)),
                  ],
                ),
                const SizedBox(height: 8),

                // Tags
                const Wrap(
                  spacing: 8,
                  children: [
                    Chip(label: Text('Tag1', style: TextStyle(fontSize: 12))),
                    Chip(label: Text('Tag2', style: TextStyle(fontSize: 12))),
                  ],
                ),
                const SizedBox(height: 8),

                // Location and time
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    const Text('Location', style: TextStyle(fontSize: 12)),
                    const Spacer(),
                    const Icon(Icons.access_time, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      '${index + 1}h ago',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // View Details button (removed like icon)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      // Create a dummy wish model for navigation
                      final now = DateTime.now();
                      final dummyWish = WishModel(
                        wishId: 'wish_$index',
                        userId: 'user_$index',
                        title: 'Wish $index',
                        description: 'Details for Wish $index',
                        location: 'Location',
                        categories: ['Tag1', 'Tag2'],
                        preferredDate: now.add(Duration(days: index)),
                        createdAt: now.subtract(Duration(hours: index + 1)),
                        updatedAt: now.subtract(Duration(hours: index + 1)),
                        status: 'Open',
                      );

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => WishDetailScreen(
                                wishId: 'wish_$index',
                                wish: dummyWish,
                              ),
                        ),
                      );
                    },
                    child: const Text('View Details'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showOptions() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.explore),
                title: const Text('Share Experience'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/post-experience');
                },
              ),
              ListTile(
                leading: const Icon(Icons.star),
                title: const Text('Make a Wish'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/request-experience');
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
