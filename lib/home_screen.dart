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
import 'services/wish_service.dart';
import 'services/experience_service.dart';
import 'services/chat_service.dart';
import 'models/user_model.dart';
import 'models/wish_model.dart';
import 'models/experience_model.dart';
import 'chat_detail_screen.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Helper class to convert Map data to DocumentSnapshot-like object
class _FakeDocumentSnapshot implements DocumentSnapshot {
  @override
  final String id;
  final Map<String, dynamic> _data;

  _FakeDocumentSnapshot(this.id, this._data);

  @override
  Map<String, dynamic>? data() => _data;

  @override
  bool get exists => _data.isNotEmpty;

  @override
  DocumentReference get reference => throw UnimplementedError();

  @override
  SnapshotMetadata get metadata => throw UnimplementedError();

  @override
  dynamic operator [](Object field) => _data[field];

  @override
  dynamic get(Object field) => _data[field];
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<UserModel> _favoriteUsers = [];
  List<WishModel> _favoriteWishes = [];
  List<ExperienceModel> _favoriteExperiences = [];
  bool _isLoadingFavorites = true;
  bool _isLoadingWishes = true;
  bool _isLoadingExperiences = true;
  final UserService _userService = UserService();
  final WishService _wishService = WishService();
  final ExperienceService _experienceService = ExperienceService();
  final ChatService _chatService = ChatService();

  // Featured content
  List<WishModel> _featuredWishes = [];
  List<ExperienceModel> _featuredExperiences = [];
  bool _isLoadingFeatured = true;

  @override
  void initState() {
    super.initState();
    _loadFavoriteUsers();
    _loadFavoriteWishes();
    _loadFavoriteExperiences();
    _loadFeaturedContent();
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

  Future<void> _loadFavoriteWishes() async {
    try {
      setState(() {
        _isLoadingWishes = true;
      });

      // Get favorite wish IDs (up to 5 most recent)
      final favoriteWishIds = await FavoritesService.getFavoriteWishes();
      final List<WishModel> loadedWishes = [];

      // Load wish data for each favorite (limit to 5)
      for (final wishId in favoriteWishIds.take(5)) {
        try {
          final wish = await _wishService.getWish(wishId);
          if (wish != null) {
            loadedWishes.add(wish);
          }
        } catch (e) {
          print('Error loading favorite wish $wishId: $e');
          // Continue loading other wishes even if one fails
        }
      }

      if (mounted) {
        setState(() {
          _favoriteWishes = loadedWishes;
          _isLoadingWishes = false;
        });
      }
    } catch (e) {
      print('Error loading favorite wishes: $e');
      if (mounted) {
        setState(() {
          _isLoadingWishes = false;
        });
      }
    }
  }

  Future<void> _loadFavoriteExperiences() async {
    try {
      setState(() {
        _isLoadingExperiences = true;
      });

      // Get favorite experience IDs (up to 5 most recent)
      final favoriteExperienceIds =
          await FavoritesService.getFavoriteExperiences();
      final List<ExperienceModel> loadedExperiences = [];

      // Load experience data for each favorite (limit to 5)
      for (final experienceId in favoriteExperienceIds.take(5)) {
        try {
          final experience = await _experienceService.getExperience(
            experienceId,
          );
          if (experience != null) {
            loadedExperiences.add(experience);
          }
        } catch (e) {
          print('Error loading favorite experience $experienceId: $e');
          // Continue loading other experiences even if one fails
        }
      }

      if (mounted) {
        setState(() {
          _favoriteExperiences = loadedExperiences;
          _isLoadingExperiences = false;
        });
      }
    } catch (e) {
      print('Error loading favorite experiences: $e');
      if (mounted) {
        setState(() {
          _isLoadingExperiences = false;
        });
      }
    }
  }

  Future<void> _loadFeaturedContent() async {
    try {
      setState(() {
        _isLoadingFeatured = true;
      });

      // Load top 3 popular wishes by favorites count
      final popularWishesData = await FavoritesService.getPopularWishes(
        limit: 3,
        minFavorites: 3,
        maxDaysOld: 30,
      );

      // Load top 3 popular experiences by favorites count
      final popularExperiencesData =
          await FavoritesService.getPopularExperiences(
            limit: 3,
            minFavorites: 3,
            maxDaysOld: 30,
          );

      // Convert to model objects
      final List<WishModel> featuredWishes = [];
      for (final wishData in popularWishesData) {
        try {
          // Create a document snapshot-like object
          final fakeDoc = _FakeDocumentSnapshot(wishData['id'], wishData);
          final wish = WishModel.fromFirestore(fakeDoc);
          featuredWishes.add(wish);
        } catch (e) {
          print('Error converting wish data: $e');
        }
      }

      final List<ExperienceModel> featuredExperiences = [];
      for (final expData in popularExperiencesData) {
        try {
          // Create a document snapshot-like object
          final fakeDoc = _FakeDocumentSnapshot(expData['id'], expData);
          final experience = ExperienceModel.fromFirestore(fakeDoc);
          featuredExperiences.add(experience);
        } catch (e) {
          print('Error converting experience data: $e');
        }
      }

      if (mounted) {
        setState(() {
          _featuredWishes = featuredWishes;
          _featuredExperiences = featuredExperiences;
          _isLoadingFeatured = false;
        });
      }
    } catch (e) {
      print('Error loading featured content: $e');
      if (mounted) {
        setState(() {
          _isLoadingFeatured = false;
        });
      }
    }
  }

  void _onFavoriteChanged() {
    // Reload favorites when a user is added/removed from favorites
    _loadFavoriteUsers();
    _loadFavoriteWishes();
    _loadFavoriteExperiences();
    _loadFeaturedContent(); // Also reload featured content
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
      onTap: () async {
        // Open chat directly with this user
        await _openChatWithUser(user);
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

  Future<void> _openChatWithUser(UserModel user) async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder:
            (context) => const Center(
              child: CircularProgressIndicator(color: Color(0xFF7153DF)),
            ),
      );

      // Create or find existing conversation
      final conversationId = await _chatService.createConversation(
        otherUserId: user.userId,
        initialMessage:
            "Hi! I'd like to connect with you through LuckyStar! 😊",
      );

      // Close loading dialog
      if (mounted) Navigator.of(context).pop();

      // Navigate to chat screen
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) => ChatDetailScreen(
                  chatId: conversationId,
                  userName: user.displayName,
                  userAvatar: user.avatarUrl.isNotEmpty ? user.avatarUrl : null,
                ),
          ),
        );
      }
    } catch (e) {
      // Close loading dialog if still open
      if (mounted && Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }

      print('Error opening chat with user: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to open chat: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
          child:
              _isLoadingFeatured
                  ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF7153DF)),
                  )
                  : _featuredExperiences.isEmpty
                  ? Center(
                    child: Text(
                      'No popular experiences found.\nMaybe try reducing the minimum favorites requirement?',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  )
                  : ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _featuredExperiences.length,
                    itemBuilder: (context, index) {
                      final experience = _featuredExperiences[index];
                      return _buildPopularExperienceCard(experience);
                    },
                  ),
        ),
      ],
    );
  }

  Widget _buildPopularExperienceCard(ExperienceModel experience) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(
          context,
          '/experience-detail',
          arguments: {
            'experienceId': experience.experienceId,
            'experience': experience,
          },
        );
      },
      child: Container(
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
            // Image section with Popular badge
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                  child:
                      experience.photoUrls.isNotEmpty
                          ? Image.network(
                            experience.photoUrls.first,
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
                                      Icons.explore,
                                      color: Colors.grey.shade400,
                                      size: 40,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      "Image not available",
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          )
                          : Container(
                            height: 150,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Colors.blue.shade300,
                                  Colors.purple.shade300,
                                ],
                              ),
                            ),
                            child: Center(
                              child: Icon(
                                Icons.explore,
                                color: Colors.white,
                                size: 60,
                              ),
                            ),
                          ),
                ),
                // Popular badge
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.shade600,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Popular',
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
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
                  Text(
                    experience.title,
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    experience.description,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          experience.location.isNotEmpty
                              ? experience.location
                              : 'Location TBD',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.people, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        '${experience.currentParticipants} participants',
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
      ),
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
            Text(
              'Favorite Wishes',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pushNamed(context, '/all-favorite-wishes');
              },
              child: Text(
                'View All',
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
          height: 120,
          child:
              _isLoadingWishes
                  ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF7153DF)),
                  )
                  : _favoriteWishes.isEmpty
                  ? Center(
                    child: Text(
                      'No favorite wishes yet.\nTap ⭐ on wishes to add them here!',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  )
                  : ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _favoriteWishes.length,
                    itemBuilder: (context, index) {
                      final wish = _favoriteWishes[index];
                      return _buildFavoriteWishCard(wish);
                    },
                  ),
        ),
      ],
    );
  }

  Widget _buildFavoriteWishCard(WishModel wish) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(
          context,
          '/wish-detail',
          arguments: {'wishId': wish.wishId, 'wish': wish},
        ).then((_) {
          // Refresh favorites when returning
          _loadFavoriteWishes();
        });
      },
      child: Container(
        width: 200,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.star, color: Colors.amber.shade600, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    wish.title,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              wish.description,
              style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),
            Row(
              children: [
                Icon(Icons.location_on, size: 12, color: Colors.grey[500]),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    wish.location.isNotEmpty ? wish.location : 'Location TBD',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: Colors.grey[500],
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.favorite, size: 12, color: Colors.red.shade400),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMyExchanges() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Favorite Experiences',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pushNamed(context, '/all-favorite-experiences');
              },
              child: Text(
                'View All',
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
          height: 120,
          child:
              _isLoadingExperiences
                  ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF7153DF)),
                  )
                  : _favoriteExperiences.isEmpty
                  ? Center(
                    child: Text(
                      'No favorite experiences yet.\nTap ⭐ on experiences to add them here!',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  )
                  : ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _favoriteExperiences.length,
                    itemBuilder: (context, index) {
                      final experience = _favoriteExperiences[index];
                      return _buildFavoriteExperienceCard(experience);
                    },
                  ),
        ),
      ],
    );
  }

  Widget _buildFavoriteExperienceCard(ExperienceModel experience) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(
          context,
          '/experience-detail',
          arguments: {
            'experienceId': experience.experienceId,
            'experience': experience,
          },
        ).then((_) {
          // Refresh favorites when returning
          _loadFavoriteExperiences();
        });
      },
      child: Container(
        width: 200,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.explore, color: Colors.blue.shade600, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    experience.title,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              experience.description,
              style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),
            Row(
              children: [
                Icon(Icons.location_on, size: 12, color: Colors.grey[500]),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    experience.location.isNotEmpty
                        ? experience.location
                        : 'Location TBD',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: Colors.grey[500],
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.favorite, size: 12, color: Colors.red.shade400),
              ],
            ),
          ],
        ),
      ),
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
          child:
              _isLoadingFeatured
                  ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF7153DF)),
                  )
                  : _featuredWishes.isEmpty
                  ? Center(
                    child: Text(
                      'No popular wishes found.\nMaybe try reducing the minimum favorites requirement?',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  )
                  : ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _featuredWishes.length,
                    itemBuilder: (context, index) {
                      final wish = _featuredWishes[index];
                      return _buildPopularWishCard(wish);
                    },
                  ),
        ),
      ],
    );
  }

  Widget _buildPopularWishCard(WishModel wish) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(
          context,
          '/wish-detail',
          arguments: {'wishId': wish.wishId, 'wish': wish},
        );
      },
      child: Container(
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
            // Wish header with star icon and popularity badge
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
                      wish.title,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF7153DF),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Popular',
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Colors.red.shade600,
                      ),
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
                    wish.description,
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
                      Icon(
                        Icons.location_on,
                        size: 14,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          wish.location.isNotEmpty
                              ? wish.location
                              : 'Location TBD',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                          overflow: TextOverflow.ellipsis,
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
                        '${wish.preferredDate.day}/${wish.preferredDate.month}/${wish.preferredDate.year}',
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
                        Icons.favorite,
                        size: 14,
                        color: Colors.red.shade600,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${wish.interestedCount} interested',
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
      ),
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
