import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'my_wishes_page.dart';
import 'my_published_experiences_page.dart';
import 'trust_reputation_page.dart';
import 'widgets/upload_progress_bar.dart';
import 'services/web_image_service.dart';
import 'services/optimized_image_service.dart';
import 'services/favorites_service.dart';
import 'services/user_service.dart';
import 'models/user_model.dart';
import 'package:image_picker/image_picker.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late TabController _wishesTabController;
  late TabController _exchangesTabController;
  List<UserModel> _favoriteUsers = [];
  bool _isLoadingFavorites = true;
  final UserService _userService = UserService();

  @override
  void initState() {
    super.initState();
    _wishesTabController = TabController(length: 2, vsync: this);
    _exchangesTabController = TabController(length: 3, vsync: this);
    _loadFavoriteUsers();
  }

  Future<void> _loadFavoriteUsers() async {
    try {
      setState(() {
        _isLoadingFavorites = true;
      });

      // Get favorite user IDs (up to 4 most recent)
      final favoriteUserIds = await FavoritesService.getFavoriteUsers();
      final List<UserModel> loadedUsers = [];

      // Load user data for each favorite (limit to 4)
      for (final userId in favoriteUserIds.take(4)) {
        try {
          final user = await _userService.getUserById(userId);
          if (user != null) {
            loadedUsers.add(user);
          }
        } catch (e) {
          print('Error loading favorite user $userId: $e');
          // Continue loading other users even if one fails
        }
      }

      if (mounted) {
        setState(() {
          _favoriteUsers = loadedUsers;
          _isLoadingFavorites = false;
        });
      }
    } catch (e) {
      print('Error loading favorite users: $e');
      if (mounted) {
        setState(() {
          _isLoadingFavorites = false;
        });
      }
    }
  }

  void _onFavoriteChanged() {
    // Reload favorites when a user is added/removed from favorites
    _loadFavoriteUsers();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'CosmoSoul',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        backgroundColor: const Color(0xFF7153DF),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications, color: Colors.white),
            onPressed: () {
              // TODO: Implement notifications functionality
            },
          ),
          IconButton(
            icon: const CircleAvatar(
              radius: 16,
              backgroundColor: Colors.white,
              child: Icon(Icons.person, color: Color(0xFF7153DF), size: 20),
            ),
            onPressed: () {
              Navigator.pushNamed(context, '/my-page');
            },
          ),
          const SizedBox(width: 8), // Add some padding from the edge
        ],
      ),
      body: Column(
        children: [
          // Upload progress bar at top with global state
          ValueListenableBuilder<UploadProgressState>(
            valueListenable: UploadProgressManager().progressNotifier,
            builder: (context, progressState, child) {
              return UploadProgressBar(
                totalImages: progressState.totalImages,
                uploadedImages: progressState.uploadedImages,
                isVisible: progressState.isActive,
                onDismiss: () {
                  UploadProgressManager().dismissUpload();
                },
              );
            },
          ),

          // Main content
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Header with greeting
                _buildHeader(),
                const SizedBox(height: 20),

                // My LuckyStar horizontal list
                _buildLuckyStarAvatars(),
                const SizedBox(height: 20),

                // Wishes Wall Preview
                _buildWishesWallPreview(),
                const SizedBox(height: 20),

                // Discover Experiences
                _buildDiscoverExperiences(),
                const SizedBox(height: 20),

                // My Wishes tabbed view
                _buildMyWishes(),
                const SizedBox(height: 20),

                // My Exchanges tabbed view
                _buildMyExchanges(),
                const SizedBox(height: 20),

                // Trust & Reputation
                _buildTrustReputation(),
                const SizedBox(height: 20),

                // Calendar preview
                _buildCalendarPreview(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Welcome to CosmoSoul',
          style: GoogleFonts.poppins(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF7153DF),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Discover new experiences and connect with like-minded individuals',
          style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildLuckyStarAvatars() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'My LuckyStar',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pushNamed(context, '/favorites-list');
              },
              child: Text(
                'See All',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: const Color(0xFF7153DF),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 125,
          child:
              _isLoadingFavorites
                  ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF7153DF)),
                  )
                  : _favoriteUsers.isEmpty
                  ? Center(
                    child: Text(
                      'No favorites yet.\nTap ⭐ on user profiles to add them here!',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  )
                  : ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _favoriteUsers.length,
                    itemBuilder: (context, index) {
                      final user = _favoriteUsers[index];
                      return _buildDynamicConnectionCard(user);
                    },
                  ),
        ),
      ],
    );
  }

  Widget _buildDynamicConnectionCard(UserModel user) {
    // Get the user's primary interest or use their bio
    String role = 'LuckyStar User';
    if (user.interests.isNotEmpty) {
      role = user.interests.first;
    } else if (user.bio.isNotEmpty && user.bio.length > 20) {
      role = '${user.bio.substring(0, 20)}...';
    }

    return GestureDetector(
      onTap: () {
        // Navigate to user detail page
        Navigator.pushNamed(
          context,
          '/user-detail',
          arguments: {'userId': user.userId, 'displayName': user.displayName},
        ).then((_) {
          // Refresh favorites when returning from user detail page
          _loadFavoriteUsers();
        });
      },
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        width: 105,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF7153DF), width: 2),
              ),
              child: ClipOval(
                child:
                    user.avatarUrl.isNotEmpty
                        ? Image.network(
                          user.avatarUrl,
                          fit: BoxFit.cover,
                          width: 80,
                          height: 80,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: const Color(0xFF7153DF).withOpacity(0.1),
                              child: Icon(
                                Icons.person,
                                color: const Color(0xFF7153DF),
                                size: 40,
                              ),
                            );
                          },
                        )
                        : Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                const Color(0xFF7153DF).withOpacity(0.8),
                                const Color(0xFF9C7EFF).withOpacity(0.6),
                              ],
                            ),
                          ),
                          child: Center(
                            child: Text(
                              user.displayName.isNotEmpty
                                  ? user.displayName[0].toUpperCase()
                                  : '?',
                              style: GoogleFonts.poppins(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              user.displayName,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              role,
              style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectionCard(String imageUrl, String name, String role) {
    return Container(
      margin: const EdgeInsets.only(right: 12),
      width: 105, // Fixed width to constrain the card
      child: Column(
        mainAxisSize:
            MainAxisSize.min, // Prevents overflow by minimizing height
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF7153DF), width: 2),
            ),
            child: ClipOval(
              child: Image.network(
                imageUrl,
                fit: BoxFit.cover,
                width: 80,
                height: 80,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey.shade200,
                    child: const Icon(
                      Icons.person,
                      color: Colors.grey,
                      size: 40,
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 6), // Reduced spacing
          Text(
            name,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis, // Handle text overflow
          ),
          Text(
            role,
            style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis, // Handle text overflow
            maxLines: 1,
          ),
        ],
      ),
    );
  }

  Widget _buildDiscoverExperiences() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Featured Experiences',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pushNamed(context, '/share-experiences');
              },
              child: Text(
                'See All',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: const Color(0xFF7153DF),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 250,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _buildExperienceCard(
                'https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=300',
                'Cooking Class',
                'Learn authentic Italian cooking',
                'Tokyo',
                45,
              ),
              _buildExperienceCard(
                'https://images.unsplash.com/photo-1542038784456-1ea8e935640e?w=300',
                'Photography Tour',
                'Explore city through lens',
                'Osaka',
                28,
              ),
              _buildExperienceCard(
                'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?w=300',
                'Art Workshop',
                'Painting & creativity',
                'Kyoto',
                32,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildExperienceCard(
    String imageUrl,
    String title,
    String description,
    String location,
    int rsvps,
  ) {
    return Container(
      width: 280,
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Image.network(
              imageUrl,
              height: 150,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  height: 150,
                  width: double.infinity,
                  color: Colors.grey.shade200,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.image_not_supported,
                        color: Colors.grey.shade400,
                        size: 40,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Image not available",
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                );
              },
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  height: 150,
                  width: double.infinity,
                  color: Colors.grey.shade100,
                  child: Center(
                    child: CircularProgressIndicator(
                      value:
                          loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                              : null,
                      color: const Color(0xFF7153DF),
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
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      location,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.people, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      '$rsvps RSVPs',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey[600],
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

  Widget _buildMyWishes() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'My Wishes',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const MyWishesPage()),
                );
              },
              child: const Text(
                'View All',
                style: TextStyle(color: Color(0xFF7153DF)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TabBar(
          controller: _wishesTabController,
          labelColor: const Color(0xFF7153DF),
          unselectedLabelColor: Colors.grey,
          tabs: const [Tab(text: 'Pending'), Tab(text: 'Fulfilled')],
        ),
        SizedBox(
          height: 150,
          child: TabBarView(
            controller: _wishesTabController,
            children: [_buildWishList(), _buildWishList()],
          ),
        ),
      ],
    );
  }

  Widget _buildWishList() {
    return ListView.builder(
      itemCount: 3, // Dummy data
      itemBuilder: (context, index) {
        return ListTile(
          leading: const Icon(Icons.star, color: Colors.amber),
          title: Text('Wish $index'),
          subtitle: const Text('Status: Pending'),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        );
      },
    );
  }

  Widget _buildMyExchanges() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'My Exchanges',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MyPublishedExperiencesPage(),
                  ),
                );
              },
              child: const Text(
                'View All',
                style: TextStyle(color: Color(0xFF7153DF)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TabBar(
          controller: _exchangesTabController,
          labelColor: const Color(0xFF7153DF),
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: 'Participating'),
            Tab(text: 'Saved'),
            Tab(text: 'Recommended'),
          ],
        ),
        SizedBox(
          height: 150,
          child: TabBarView(
            controller: _exchangesTabController,
            children: [
              _buildExchangeList(),
              _buildExchangeList(),
              _buildExchangeList(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildExchangeList() {
    return ListView.builder(
      itemCount: 3, // Dummy data
      itemBuilder: (context, index) {
        return ListTile(
          leading: const Icon(Icons.swap_horiz, color: Color(0xFF7153DF)),
          title: Text('Exchange $index'),
          subtitle: const Text('Status: Active'),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        );
      },
    );
  }

  Widget _buildTrustReputation() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Trust & Reputation',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('Your reputation score: 100/100'),
            ],
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const TrustReputationPage(),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7153DF),
            ),
            child: const Text('Edit', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarPreview() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Upcoming Event',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const ListTile(
            leading: Icon(Icons.event, color: Color(0xFF7153DF)),
            title: Text('Music Festival'),
            subtitle: Text('Central Park • June 15, 2025'),
            trailing: Chip(
              label: Text('Confirmed', style: TextStyle(color: Colors.white)),
              backgroundColor: Colors.green,
            ),
          ),
          const SizedBox(height: 16),
          // Firebase Test Button
          Center(
            child: Column(
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pushNamed(context, '/firebase-test');
                  },
                  icon: const Icon(Icons.storage),
                  label: const Text('Test Firebase Connection'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7153DF),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pushNamed(context, '/firebase-auth-debug');
                  },
                  icon: const Icon(Icons.bug_report),
                  label: const Text('Firebase Auth Debug'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pushNamed(
                      context,
                      '/firebase-email-verification-debug',
                    );
                  },
                  icon: const Icon(Icons.mail_outline),
                  label: const Text('Email Verification Debug'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                ElevatedButton.icon(
                  onPressed: () async {
                    try {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Testing Firebase Storage...'),
                        ),
                      );
                      await WebImageService.testFirebaseStorage();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Firebase Storage test successful!'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Firebase Storage test failed: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.cloud_upload),
                  label: const Text('Test Firebase Storage'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                ElevatedButton.icon(
                  onPressed: () async {
                    try {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Testing image compression...'),
                        ),
                      );

                      final ImagePicker picker = ImagePicker();
                      final XFile? image = await picker.pickImage(
                        source: ImageSource.gallery,
                      );

                      if (image != null) {
                        await OptimizedImageService.testCompression(image);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Compression test complete! Check console for details.',
                              ),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      } else {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('No image selected'),
                              backgroundColor: Colors.orange,
                            ),
                          );
                        }
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Compression test failed: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.compress),
                  label: const Text('Test Image Compression'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepOrange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWishesWallPreview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Wishes Wall',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pushNamed(context, '/wish-wall');
              },
              child: Text(
                'See All',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: const Color(0xFF7153DF),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 180,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _buildWishCard(
                'Language Exchange',
                'Looking for a native English speaker for language practice',
                'Tokyo',
                'Jun 20, 2025',
                12,
              ),
              _buildWishCard(
                'Photography Partner',
                'Need someone to explore night photography in the city',
                'Shibuya',
                'Jun 25, 2025',
                8,
              ),
              _buildWishCard(
                'Hiking Buddy',
                'Planning a weekend hike, looking for experienced hikers',
                'Mt. Fuji',
                'Jul 5, 2025',
                15,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWishCard(
    String title,
    String description,
    String location,
    String date,
    int rsvpCount,
  ) {
    return Container(
      width: 250,
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Wish header with star icon
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: Color(0xFFF5F0FF),
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                const Icon(Icons.star, color: Color(0xFFFFD700), size: 24),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF7153DF),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          // Wish content
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  description,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.grey[800],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.location_on, size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      location,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 14,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      date,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.people, size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      '$rsvpCount people interested',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey[600],
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
}
