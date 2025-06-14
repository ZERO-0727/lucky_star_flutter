import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'models/user_model.dart';
import 'services/user_service.dart';
import 'widgets/avatar_placeholder.dart';
import 'account_settings_page.dart';
import 'language_selection_page.dart';
import 'interest_editing_page.dart';
import 'edit_profile_screen.dart';
import 'services/favorites_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'models/experience_model.dart';
import 'models/wish_model.dart';

class MyPage extends StatefulWidget {
  const MyPage({super.key});

  @override
  State<MyPage> createState() => _MyPageState();
}

class _MyPageState extends State<MyPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final UserService _userService = UserService();

  UserModel? _currentUser;
  bool _isLoading = true;
  String? _currentUserId;
  String _selectedExchangeStatus = 'Open to Exchange';

  final List<String> _exchangeStatusOptions = [
    'Open to Exchange',
    'By Request Only',
    'Unavailable',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadUserData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        _currentUserId = user.uid;
        final userData = await _userService.getUserById(user.uid);

        if (userData != null && mounted) {
          setState(() {
            _currentUser = userData;
            _selectedExchangeStatus =
                userData.status.isNotEmpty
                    ? userData.status
                    : 'Open to Exchange';
            _isLoading = false;
          });
        } else {
          // Create user if doesn't exist
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
              _isLoading = false;
            });
          }
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print('Error loading user data: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _refreshUserData() async {
    if (_currentUserId != null) {
      try {
        final userData = await _userService.getUserById(_currentUserId!);
        if (userData != null && mounted) {
          setState(() {
            _currentUser = userData;
            _selectedExchangeStatus =
                userData.status.isNotEmpty
                    ? userData.status
                    : 'Open to Exchange';
          });
        }
      } catch (e) {
        print('Error refreshing user data: $e');
      }
    }
  }

  Future<void> _updateExchangeStatus(String newStatus) async {
    if (_currentUser == null) return;

    try {
      await _userService.updateUserFields(_currentUser!.userId, {
        'status': newStatus,
      });

      if (mounted) {
        setState(() {
          _selectedExchangeStatus = newStatus;
          _currentUser = _currentUser!.copyWith(status: newStatus);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Exchange status updated'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error updating exchange status: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating exchange status: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Open to Exchange':
        return const Color(0xFF4CAF50); // Green
      case 'By Request Only':
        return const Color(0xFFFFEB3B); // Yellow
      case 'Unavailable':
        return const Color(0xFF9E9E9E); // Gray
      default:
        return const Color(0xFF4CAF50); // Default to green
    }
  }

  void _showStatusSelectionBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Select Exchange Status',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              ..._exchangeStatusOptions.map((status) {
                Color badgeColor;
                Color textColor;
                String statusIcon;

                switch (status) {
                  case 'Open to Exchange':
                    badgeColor = const Color(0xFF4CAF50); // Green
                    textColor = Colors.white;
                    statusIcon = '✅';
                    break;
                  case 'By Request Only':
                    badgeColor = const Color(0xFFFFEB3B); // Yellow
                    textColor = Colors.black;
                    statusIcon = '🟡';
                    break;
                  case 'Unavailable':
                    badgeColor = const Color(0xFF9E9E9E); // Gray
                    textColor = const Color(0xFF424242);
                    statusIcon = '⬜';
                    break;
                  default:
                    badgeColor = const Color(0xFF4CAF50);
                    textColor = Colors.white;
                    statusIcon = '✅';
                }

                return ListTile(
                  onTap: () {
                    Navigator.pop(context);
                    _updateExchangeStatus(status);
                  },
                  leading: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: badgeColor,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      '$statusIcon $status',
                      style: GoogleFonts.poppins(
                        color: textColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  trailing:
                      _selectedExchangeStatus == status
                          ? const Icon(Icons.check, color: Color(0xFF7153DF))
                          : null,
                );
              }).toList(),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('My Profile'),
          backgroundColor: Colors.white,
          elevation: 0,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_currentUser == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('My Profile'),
          backgroundColor: Colors.white,
          elevation: 0,
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.person_off, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'Please log in to view your profile',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AccountSettingsPage(),
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refreshUserData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildProfileHeader(),
                _buildStatisticsPanel(),
                _buildTabsSection(),
                _buildTagSection('Languages', _currentUser!.languages),
                _buildTagSection('Interests', _currentUser!.interests),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
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
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFF7153DF),
                        width: 2,
                      ),
                    ),
                    child: ClipOval(
                      child:
                          _currentUser!.avatarUrl.isNotEmpty
                              ? Image.network(
                                _currentUser!.avatarUrl,
                                width: 100,
                                height: 100,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return const AvatarPlaceholder(size: 100);
                                },
                              )
                              : const AvatarPlaceholder(size: 100),
                    ),
                  ),
                  if (_currentUser!.isVerified)
                    Positioned(
                      bottom: 0,
                      right: 25,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00C853),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(
                          Icons.verified_user,
                          color: Colors.white,
                          size: 14,
                        ),
                      ),
                    ),
                  if (_currentUser!.verificationBadges.isNotEmpty)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2196F3),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(
                          Icons.badge,
                          color: Colors.white,
                          size: 14,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _currentUser!.displayName,
                            style: GoogleFonts.poppins(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: _showStatusSelectionBottomSheet,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                _selectedExchangeStatus,
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: _getStatusColor(
                                    _selectedExchangeStatus,
                                  ),
                                ),
                              ),
                              Icon(
                                Icons.arrow_drop_down,
                                color: _getStatusColor(_selectedExchangeStatus),
                                size: 18,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    if (_currentUser!.location.isNotEmpty) ...[
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
                              _currentUser!.location,
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                    ],
                    if (_currentUser!.gender.isNotEmpty) ...[
                      Row(
                        children: [
                          Icon(Icons.person, size: 16, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(
                            _currentUser!.gender,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            'About You',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _currentUser!.bio.isNotEmpty
                ? _currentUser!.bio
                : 'No bio added yet. Tap "Edit Profile" to add one!',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color:
                  _currentUser!.bio.isNotEmpty
                      ? Colors.grey[800]
                      : Colors.grey[500],
              fontStyle:
                  _currentUser!.bio.isNotEmpty
                      ? FontStyle.normal
                      : FontStyle.italic,
            ),
          ),
          const SizedBox(height: 20),
          // Edit Profile Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () async {
                final result = await Navigator.push<UserModel>(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditProfileScreen(user: _currentUser),
                  ),
                );
                if (result != null) {
                  setState(() {
                    _currentUser = result;
                    _selectedExchangeStatus =
                        result.status.isNotEmpty
                            ? result.status
                            : 'Open to Exchange';
                  });
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7153DF),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Edit Profile'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsPanel() {
    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.only(top: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            'Experiences',
            _currentUser!.experiencesCount.toString(),
            Icons.explore,
          ),
          _buildStatItem(
            'Wishes',
            _currentUser!.wishesCount.toString(),
            Icons.star,
          ),
          _buildStatItem(
            'Trust Score',
            _currentUser!.trustScore.toString(),
            Icons.verified,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFF7153DF), size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF7153DF),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildTabsSection() {
    return Container(
      height: 320,
      margin: const EdgeInsets.only(top: 16),
      decoration: BoxDecoration(
        color: Colors.white,
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
        children: [
          TabBar(
            controller: _tabController,
            labelColor: const Color(0xFF7153DF),
            unselectedLabelColor: Colors.grey,
            indicatorColor: const Color(0xFF7153DF),
            tabs: const [
              Tab(icon: Icon(Icons.star), text: 'Favorites'),
              Tab(icon: Icon(Icons.upload), text: 'Published'),
              Tab(icon: Icon(Icons.history), text: 'Records'),
              Tab(icon: Icon(Icons.star_rate), text: 'Ratings'),
            ],
          ),
          SizedBox(
            height: 250,
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildFavoritesTab(),
                _buildPublishedTab(),
                _buildRecordsTab(),
                _buildRatingsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFavoritesTab() {
    return FutureBuilder<Map<String, List<dynamic>>>(
      future: _loadFavorites(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('Error loading favorites: ${snapshot.error}'),
          );
        }

        final favorites = snapshot.data ?? {'experiences': [], 'wishes': []};
        final favoriteExperiences = favorites['experiences'] ?? [];
        final favoriteWishes = favorites['wishes'] ?? [];

        if (favoriteExperiences.isEmpty && favoriteWishes.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.star_border, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No favorites yet',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
                Text(
                  'Tap the star icon on posts to add them here',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (favoriteExperiences.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Text(
                    'Favorite Experiences',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF7153DF),
                    ),
                  ),
                ),
                ...favoriteExperiences
                    .map(
                      (experience) => _buildFavoriteExperienceCard(experience),
                    )
                    .toList(),
              ],
              if (favoriteWishes.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Text(
                    'Favorite Wishes',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange.shade700,
                    ),
                  ),
                ),
                ...favoriteWishes
                    .map((wish) => _buildFavoriteWishCard(wish))
                    .toList(),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildPublishedTab() {
    return const Center(child: Text('Published content coming soon'));
  }

  Widget _buildRecordsTab() {
    return const Center(child: Text('Records coming soon'));
  }

  Widget _buildRatingsTab() {
    return const Center(child: Text('Ratings coming soon'));
  }

  Widget _buildTagSection(String title, List<String> tags) {
    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.only(top: 16),
      decoration: BoxDecoration(
        color: Colors.white,
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit, size: 20),
                onPressed: () {
                  _showTagEditor(context, title, tags);
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          tags.isNotEmpty
              ? Wrap(
                spacing: 8,
                runSpacing: 8,
                children:
                    tags.map((tag) {
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
                          tag,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: const Color(0xFF7153DF),
                          ),
                        ),
                      );
                    }).toList(),
              )
              : Text(
                'No ${title.toLowerCase()} added yet. Tap the edit icon to add some!',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey[500],
                  fontStyle: FontStyle.italic,
                ),
              ),
        ],
      ),
    );
  }

  Future<Map<String, List<dynamic>>> _loadFavorites() async {
    try {
      final favoriteExperienceIds =
          await FavoritesService.getFavoriteExperiences();
      final favoriteWishIds = await FavoritesService.getFavoriteWishes();

      final favoriteExperiences = <ExperienceModel>[];
      final favoriteWishes = <WishModel>[];

      final currentUserId = FirebaseAuth.instance.currentUser?.uid;

      for (final id in favoriteExperienceIds) {
        try {
          final doc =
              await FirebaseFirestore.instance
                  .collection('experiences')
                  .doc(id)
                  .get();
          if (doc.exists) {
            final experience = ExperienceModel.fromFirestore(doc);
            if (experience.userId != currentUserId) {
              favoriteExperiences.add(experience);
            }
          }
        } catch (e) {
          print('Error loading experience $id: $e');
        }
      }

      for (final id in favoriteWishIds) {
        try {
          final doc =
              await FirebaseFirestore.instance
                  .collection('wishes')
                  .doc(id)
                  .get();
          if (doc.exists) {
            final wish = WishModel.fromFirestore(doc);
            if (wish.userId != currentUserId) {
              favoriteWishes.add(wish);
            }
          }
        } catch (e) {
          print('Error loading wish $id: $e');
        }
      }

      return {'experiences': favoriteExperiences, 'wishes': favoriteWishes};
    } catch (e) {
      print('Error loading favorites: $e');
      return {'experiences': [], 'wishes': []};
    }
  }

  Widget _buildFavoriteExperienceCard(ExperienceModel experience) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
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
        borderRadius: BorderRadius.circular(12),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                bottomLeft: Radius.circular(12),
              ),
              child: Container(
                width: 80,
                height: 80,
                color: Colors.grey.shade300,
                child:
                    experience.photoUrls.isNotEmpty
                        ? Image.network(
                          experience.photoUrls.first,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(Icons.image, color: Colors.grey);
                          },
                        )
                        : const Icon(Icons.explore, color: Colors.grey),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      experience.title,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      experience.location,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.people, size: 12, color: Colors.blue),
                        const SizedBox(width: 4),
                        Text(
                          '${experience.availableSlots} slots',
                          style: GoogleFonts.poppins(fontSize: 10),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFavoriteWishCard(WishModel wish) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(
            context,
            '/wish-detail',
            arguments: {'wishId': wish.wishId, 'wish': wish},
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Row(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.orange.shade100,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                ),
              ),
              child: Icon(Icons.star, color: Colors.orange.shade700, size: 40),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      wish.title,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      wish.location,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.schedule,
                          size: 12,
                          color: Colors.orange,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          wish.preferredDate != null
                              ? 'Has date preference'
                              : 'Flexible',
                          style: GoogleFonts.poppins(fontSize: 10),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showTagEditor(
    BuildContext context,
    String title,
    List<String> tags,
  ) async {
    if (title == 'Languages') {
      final result = await Navigator.push<List<String>>(
        context,
        MaterialPageRoute(
          builder:
              (context) => LanguageSelectionPage(
                selectedLanguages: _currentUser!.languages,
                currentUser: _currentUser,
              ),
        ),
      );

      if (result != null && mounted) {
        // Update local state and refresh user data
        setState(() {
          _currentUser = _currentUser!.copyWith(languages: result);
        });
        await _refreshUserData();
      }
    } else if (title == 'Interests') {
      final result = await Navigator.push<List<String>>(
        context,
        MaterialPageRoute(
          builder:
              (context) => InterestEditingPage(
                selectedInterests: _currentUser!.interests,
                currentUser: _currentUser,
              ),
        ),
      );

      if (result != null && mounted) {
        // Update local state and refresh user data
        setState(() {
          _currentUser = _currentUser!.copyWith(interests: result);
        });
        await _refreshUserData();
      }
    }
  }
}
