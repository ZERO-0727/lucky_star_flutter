import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'search_page.dart';
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
  String? _selectedLocation;

  // Available filter options
  final List<String> _availableTags = [
    'All',
    'Food',
    'Sport',
    'Travel',
    'Culture',
    'Adventure',
    'Learning',
  ];

  final List<String> _availableLocations = [
    'All',
    'Canada',
    'United States',
    'Australia',
    'Japan',
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
                // Location filter (new) - show on both tabs
                DropdownButtonFormField<String>(
                  value: _selectedLocation,
                  decoration: const InputDecoration(
                    labelText: 'Filter by Location',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.location_on),
                  ),
                  items:
                      _availableLocations.map((location) {
                        return DropdownMenuItem(
                          value: location == 'All' ? null : location,
                          child: Text(location),
                        );
                      }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedLocation = value;
                    });
                  },
                ),

                const SizedBox(height: 12),

                // Date filter
                DropdownButtonFormField<String>(
                  value: _selectedDateFilter,
                  decoration: const InputDecoration(
                    labelText: 'Filter by Date',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.calendar_today),
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
                      prefixIcon: Icon(Icons.category),
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
          // Print detailed error information to terminal
          _printDetailedError(
            'Wish List Query',
            snapshot.error,
            snapshot.stackTrace,
          );

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
          // Print detailed error information to terminal
          _printDetailedError(
            'Share Experience Query',
            snapshot.error,
            snapshot.stackTrace,
          );

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
      print('  - Location filter: $_selectedLocation');

      Query query = FirebaseFirestore.instance
          .collection('experiences')
          .where('status', isEqualTo: 'active');

      // Location filter - apply first if present
      if (_selectedLocation != null) {
        print('  - Using location filter: $_selectedLocation');
        query = query.where('location', isEqualTo: _selectedLocation);
      }

      // Apply date and tag filters after location (if present)
      if (_selectedTag != null && _selectedDateFilter != null) {
        // Complex case: both tag and date filter with possible location
        print('  - Using complex query with multiple filters');

        DateTime filterDate = _getFilterDate(_selectedDateFilter!);

        query = query
            .where('tags', arrayContains: _selectedTag)
            .where('createdAt', isGreaterThan: Timestamp.fromDate(filterDate))
            .orderBy('createdAt', descending: true);

        if (_selectedLocation != null) {
          print(
            '  - Required index: experiences (status, location, tags, createdAt)',
          );
        } else {
          print('  - Required index: experiences (status, tags, createdAt)');
        }
      } else if (_selectedTag != null) {
        // Tag filter only (with possible location)
        print('  - Using tag filter');

        query = query
            .where('tags', arrayContains: _selectedTag)
            .orderBy('createdAt', descending: true);

        if (_selectedLocation != null) {
          print(
            '  - Required index: experiences (status, location, tags, createdAt)',
          );
        } else {
          print('  - Required index: experiences (status, tags, createdAt)');
        }
      } else if (_selectedDateFilter != null) {
        // Date filter only (with possible location)
        print('  - Using date filter');

        DateTime filterDate = _getFilterDate(_selectedDateFilter!);

        query = query
            .where('createdAt', isGreaterThan: Timestamp.fromDate(filterDate))
            .orderBy('createdAt', descending: true);

        if (_selectedLocation != null) {
          print(
            '  - Required index: experiences (status, location, createdAt)',
          );
        } else {
          print('  - Required index: experiences (status, createdAt)');
        }
      } else {
        // Only location filter or no filters at all
        print('  - Using basic query with ordering');
        query = query.orderBy('createdAt', descending: true);

        if (_selectedLocation != null) {
          print(
            '  - Required index: experiences (status, location, createdAt)',
          );
        } else {
          print('  - Required index: experiences (status, createdAt)');
        }
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
      print('  - Location filter: $_selectedLocation');

      Query query = FirebaseFirestore.instance
          .collection('wishes')
          .where('status', isEqualTo: 'Open');

      // Apply location filter first if present
      if (_selectedLocation != null) {
        print('  - Using location filter: $_selectedLocation');
        query = query.where('location', isEqualTo: _selectedLocation);
      }

      if (_selectedDateFilter != null) {
        // Date filter (with possible location)
        print('  - Using date filter');

        DateTime filterDate = _getFilterDate(_selectedDateFilter!);

        query = query
            .where('createdAt', isGreaterThan: Timestamp.fromDate(filterDate))
            .orderBy('createdAt', descending: true);

        if (_selectedLocation != null) {
          print('  - Required index: wishes (status, location, createdAt)');
        } else {
          print('  - Required index: wishes (status, createdAt)');
        }
      } else {
        // Only location filter or no filters
        print('  - Using basic query with ordering');

        query = query.orderBy('createdAt', descending: true);

        if (_selectedLocation != null) {
          print('  - Required index: wishes (status, location, createdAt)');
        } else {
          print('  - Required index: wishes (status, createdAt)');
        }
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
                if (_selectedDateFilter != null ||
                    _selectedLocation != null) ...[
                  OutlinedButton.icon(
                    onPressed: () {
                      setState(() {
                        _selectedDateFilter = null;
                        _selectedLocation = null;
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
    if (_selectedLocation != null && _selectedDateFilter != null) {
      return 'No wishes found in $_selectedLocation for $_selectedDateFilter.\nTry adjusting your filters or make your own wish!';
    } else if (_selectedLocation != null) {
      return 'No wishes found in $_selectedLocation.\nTry a different location or make your own wish!';
    } else if (_selectedDateFilter != null) {
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
                if (_selectedDateFilter != null ||
                    _selectedTag != null ||
                    _selectedLocation != null) ...[
                  OutlinedButton.icon(
                    onPressed: () {
                      setState(() {
                        _selectedDateFilter = null;
                        _selectedTag = null;
                        _selectedLocation = null;
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
    // All three filters applied
    if (_selectedLocation != null &&
        _selectedDateFilter != null &&
        _selectedTag != null) {
      return 'No $_selectedTag experiences found in $_selectedLocation for $_selectedDateFilter timeframe.\nTry adjusting your filters or be the first to share!';
    }
    // Location + Date filter
    else if (_selectedLocation != null && _selectedDateFilter != null) {
      return 'No experiences found in $_selectedLocation for $_selectedDateFilter.\nTry adjusting your filters or share your own!';
    }
    // Location + Tag filter
    else if (_selectedLocation != null && _selectedTag != null) {
      return 'No $_selectedTag experiences found in $_selectedLocation.\nTry a different location or category, or share your own!';
    }
    // Date + Tag filter
    else if (_selectedDateFilter != null && _selectedTag != null) {
      return 'No $_selectedTag experiences found for $_selectedDateFilter timeframe.\nTry adjusting your filters or be the first to share!';
    }
    // Only Location filter
    else if (_selectedLocation != null) {
      return 'No experiences found in $_selectedLocation.\nTry a different location or share your own!';
    }
    // Only Date filter
    else if (_selectedDateFilter != null) {
      return 'No experiences found for $_selectedDateFilter.\nTry a different date range or share your own!';
    }
    // Only Tag filter
    else if (_selectedTag != null) {
      return 'No $_selectedTag experiences found.\nTry a different category or share your own!';
    }
    // No filters
    else {
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

  /// Print detailed error information to terminal for debugging
  /// This is especially useful for Firestore database index errors
  void _printDetailedError(
    String queryType,
    dynamic error,
    StackTrace? stackTrace,
  ) {
    print('\n' + '=' * 80);
    print('🚨 FIRESTORE QUERY ERROR DETAILS');
    print('=' * 80);
    print('Query Type: $queryType');
    print('Timestamp: ${DateTime.now().toIso8601String()}');
    print('\nApplied Filters:');
    print('  - Date Filter: $_selectedDateFilter');
    print('  - Tag Filter: $_selectedTag');
    print('  - Location Filter: $_selectedLocation');

    print('\nError Details:');
    print('  Error Type: ${error.runtimeType}');
    print('  Error Message: $error');

    // Check if this looks like a Firestore index error
    final errorString = error.toString().toLowerCase();
    if (errorString.contains('index') ||
        errorString.contains('composite') ||
        errorString.contains('requires an index')) {
      print('\n🔍 INDEX ERROR DETECTED!');
      print('This error indicates that a Firestore database index is missing.');
      print('Follow these steps to resolve:');
      print('');
      print('1. Go to Firebase Console: https://console.firebase.google.com/');
      print('2. Navigate to your project');
      print('3. Go to Firestore Database > Indexes');
      print(
        '4. Look for the suggested index configuration in the error message above',
      );
      print('5. Create the composite index as suggested');
      print('');
      print(
        'Alternative: Check the Firebase Console for automatic index creation suggestions.',
      );
    }

    // Print current query configuration for debugging
    print('\nCurrent Query Configuration:');
    final collection = queryType.contains('Wish') ? 'wishes' : 'experiences';
    print('  Collection: $collection');

    if (queryType.contains('Wish')) {
      print('  Base Filter: status == "Open"');
      if (_selectedLocation != null) {
        print('  Location Filter: location == "$_selectedLocation"');
      }
      if (_selectedDateFilter != null) {
        print(
          '  Date Filter: createdAt > ${_getFilterDate(_selectedDateFilter!)}',
        );
      }
      print('  Order By: createdAt DESC');
      print('  Limit: 50');

      // Suggest required index
      if (_selectedLocation != null && _selectedDateFilter != null) {
        print('\n📋 Required Index:');
        print('  Collection: wishes');
        print(
          '  Fields: status (Ascending), location (Ascending), createdAt (Descending)',
        );
      } else if (_selectedLocation != null) {
        print('\n📋 Required Index:');
        print('  Collection: wishes');
        print(
          '  Fields: status (Ascending), location (Ascending), createdAt (Descending)',
        );
      } else if (_selectedDateFilter != null) {
        print('\n📋 Required Index:');
        print('  Collection: wishes');
        print('  Fields: status (Ascending), createdAt (Descending)');
      }
    } else {
      print('  Base Filter: status == "active"');
      if (_selectedLocation != null) {
        print('  Location Filter: location == "$_selectedLocation"');
      }
      if (_selectedTag != null) {
        print('  Tag Filter: tags array-contains "$_selectedTag"');
      }
      if (_selectedDateFilter != null) {
        print(
          '  Date Filter: createdAt > ${_getFilterDate(_selectedDateFilter!)}',
        );
      }
      print('  Order By: createdAt DESC');
      print('  Limit: 50');

      // Suggest required index
      List<String> indexFields = ['status (Ascending)'];
      if (_selectedLocation != null) {
        indexFields.add('location (Ascending)');
      }
      if (_selectedTag != null) {
        indexFields.add('tags (Arrays)');
      }
      if (_selectedDateFilter != null ||
          _selectedTag != null ||
          _selectedLocation != null) {
        indexFields.add('createdAt (Descending)');
      }

      if (indexFields.length > 2) {
        print('\n📋 Required Index:');
        print('  Collection: experiences');
        print('  Fields: ${indexFields.join(', ')}');
      }
    }

    // Print stack trace if available
    if (stackTrace != null) {
      print('\nStack Trace:');
      print(stackTrace.toString());
    }

    print('=' * 80);
    print('END ERROR DETAILS');
    print('=' * 80 + '\n');
  }
}
