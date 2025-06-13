import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'search_page.dart';
import 'experience_detail_screen.dart';
import 'models/experience_model.dart';
import 'models/wish_model.dart';
import 'widgets/experience_card.dart';
import 'widgets/wish_card.dart';

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
    return StreamBuilder<QuerySnapshot>(
      stream: _getFilteredWishesStream(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red.shade400),
                const SizedBox(height: 16),
                Text('Error loading wishes: ${snapshot.error}'),
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

        final wishes = snapshot.data?.docs ?? [];

        if (wishes.isEmpty) {
          return _buildEmptyWishState();
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: wishes.length,
          itemBuilder: (context, index) {
            final doc = wishes[index];
            final wish = WishModel.fromFirestore(doc);
            return WishCard(
              wish: wish,
              onFavoriteToggle: () {
                // TODO: Implement favorite functionality
                print('Favorite toggled for ${wish.wishId}');
              },
            );
          },
        );
      },
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
            return ExperienceCard(
              experience: experience,
              onFavoriteToggle: () {
                // TODO: Implement favorite functionality
                print('Favorite toggled for ${experience.experienceId}');
              },
            );
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

  Stream<QuerySnapshot> _getFilteredWishesStream() {
    try {
      // Debug logging to see exact query being made
      print('🔍 Building Firestore query for wishes with filters:');
      print('  - Date filter: $_selectedDateFilter');

      Query query = FirebaseFirestore.instance
          .collection('wishes')
          .where('status', isEqualTo: 'Open');

      if (_selectedDateFilter != null) {
        // Date filter only for wishes
        print('  - Using date query: status + createdAt + orderBy');

        DateTime filterDate = _getFilterDate(_selectedDateFilter!);

        query = query
            .where('createdAt', isGreaterThan: Timestamp.fromDate(filterDate))
            .orderBy('createdAt', descending: true);

        print('  - Required index: wishes (status ASC, createdAt DESC)');
      } else {
        // No filters, just basic query
        print('  - Using basic query: status + orderBy');

        query = query.orderBy('createdAt', descending: true);

        print('  - Required index: wishes (status ASC, createdAt DESC)');
      }

      print('  - Final query limit: 50');
      return query.limit(50).snapshots();
    } catch (e) {
      print('❌ Error building Firestore query for wishes: $e');

      // Fallback to basic query if complex query fails
      print('🔄 Falling back to basic query without filters');
      return FirebaseFirestore.instance
          .collection('wishes')
          .where('status', isEqualTo: 'Open')
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

  Widget _buildEmptyWishState() {
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
                Icons.star_border,
                size: 60,
                color: Colors.grey.shade400,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No wishes found',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _getEmptyWishStateMessage(),
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
                if (_selectedDateFilter != null) ...[
                  OutlinedButton.icon(
                    onPressed: () {
                      setState(() {
                        _selectedDateFilter = null;
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
                    Navigator.pushNamed(context, '/post-wish');
                  },
                  icon: const Icon(Icons.star),
                  label: const Text('Make a Wish'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple.shade600,
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

  String _getEmptyWishStateMessage() {
    if (_selectedDateFilter != null) {
      return 'No wishes found for $_selectedDateFilter.\nTry a different date range or make your own wish!';
    } else {
      return 'Be the first to make a wish and let the\ncommunity help make it come true!';
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
                  Navigator.pushNamed(context, '/post-wish');
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
