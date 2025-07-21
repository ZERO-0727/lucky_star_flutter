import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'models/user_model.dart';
import 'models/experience_model.dart';
import 'models/wish_model.dart';
import 'services/user_service.dart';
import 'services/chat_service.dart';
import 'services/favorites_service.dart';
import 'services/experience_service.dart';
import 'services/wish_service.dart';
import 'chat_detail_screen.dart';
import 'experience_detail_screen.dart';
import 'wish_detail_screen.dart';

class UserDetailPage extends StatefulWidget {
  final String userId;
  final String displayName;

  const UserDetailPage({
    super.key,
    required this.userId,
    required this.displayName,
  });

  @override
  State<UserDetailPage> createState() => _UserDetailPageState();
}

class _UserDetailPageState extends State<UserDetailPage>
    with SingleTickerProviderStateMixin {
  final UserService _userService = UserService();
  final ChatService _chatService = ChatService();
  final ExperienceService _experienceService = ExperienceService();
  final WishService _wishService = WishService();

  bool _isLoading = true;
  bool _isSendingMessage = false;
  bool _isFavorited = false;
  bool _isToggling = false;
  UserModel? _user;
  String? _errorMessage;

  // Content data
  List<ExperienceModel> _userExperiences = [];
  List<WishModel> _userWishes = [];
  bool _isLoadingExperiences = true;
  bool _isLoadingWishes = true;

  // Tab controller
  late TabController _tabController;
  int _selectedTabIndex = 0;

  // Helper method to check if current user is viewing their own profile
  bool get _isViewingOwnProfile {
    final currentUser = FirebaseAuth.instance.currentUser;
    return currentUser != null && currentUser.uid == widget.userId;
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadUserData();
    _checkFavoriteStatus();
    _loadUserContent();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadUserContent() async {
    await Future.wait([_loadUserExperiences(), _loadUserWishes()]);
  }

  Future<void> _loadUserExperiences() async {
    try {
      setState(() {
        _isLoadingExperiences = true;
      });

      final experiences = await _experienceService.getUserExperiences(
        widget.userId,
      );

      if (mounted) {
        setState(() {
          _userExperiences = experiences;
          _isLoadingExperiences = false;
        });
      }
    } catch (e) {
      print('Error loading user experiences: $e');
      if (mounted) {
        setState(() {
          _isLoadingExperiences = false;
        });
      }
    }
  }

  Future<void> _loadUserWishes() async {
    try {
      setState(() {
        _isLoadingWishes = true;
      });

      final wishes = await _wishService.getUserWishes(widget.userId);

      if (mounted) {
        setState(() {
          _userWishes = wishes;
          _isLoadingWishes = false;
        });
      }
    } catch (e) {
      print('Error loading user wishes: $e');
      if (mounted) {
        setState(() {
          _isLoadingWishes = false;
        });
      }
    }
  }

  Future<void> _checkFavoriteStatus() async {
    if (!_isViewingOwnProfile) {
      final isFavorited = await FavoritesService.isUserFavorited(widget.userId);
      if (mounted) {
        setState(() {
          _isFavorited = isFavorited;
        });
      }
    }
  }

  Future<void> _toggleFavorite() async {
    if (_isToggling || _isViewingOwnProfile) return;

    setState(() {
      _isToggling = true;
    });

    try {
      final success = await FavoritesService.toggleUserFavorite(widget.userId);

      if (success && mounted) {
        setState(() {
          _isFavorited = !_isFavorited;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isFavorited
                  ? 'Added to My LuckyStar'
                  : 'Removed from My LuckyStar',
            ),
            backgroundColor: _isFavorited ? Colors.green : Colors.orange,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('Error toggling favorite: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating favorites: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isToggling = false;
        });
      }
    }
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = await _userService.getUserById(widget.userId);

      setState(() {
        _user = user;
        _isLoading = false;
      });

      // If user doesn't exist, create a placeholder user for demo purposes
      if (_user == null) {
        final now = DateTime.now();
        _user = UserModel(
          userId: widget.userId,
          displayName: widget.displayName,
          bio:
              'Hello from ${widget.displayName}. I love traveling and meeting new people!',
          interests: ['Hiking', 'Photography', 'Food', 'Art', 'Music'],
          visitedCountries: [
            'Japan',
            'United States',
            'France',
            'Italy',
            'Australia',
          ],
          referenceCount: 3,
          status: 'Open to Exchange',
          trustScore: 87,
          statistics: {
            'experiencesCount': 5,
            'wishesCount': 3,
            'wishesFullfilledCount': 2,
            'responseRate': 90,
          },
          verificationBadges: ['Worldcoin', 'Government ID'],
          createdAt: now,
          updatedAt: now,
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load user data: $e';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_errorMessage!), backgroundColor: Colors.red),
      );
    }
  }

  void _showActionSheet() {
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
            children: [
              ListTile(
                leading: const Icon(Icons.share, color: Color(0xFF7153DF)),
                title: Text(
                  'Share User',
                  style: GoogleFonts.poppins(fontSize: 16),
                ),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Share feature coming soon'),
                      backgroundColor: Colors.blue,
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.report, color: Colors.orange),
                title: Text(
                  'Report User',
                  style: GoogleFonts.poppins(fontSize: 16),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _showReportConfirmation();
                },
              ),
              ListTile(
                leading: const Icon(Icons.block, color: Colors.red),
                title: Text(
                  'Block User',
                  style: GoogleFonts.poppins(fontSize: 16),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _showBlockConfirmation();
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  void _showReportConfirmation() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Report User',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
          ),
          content: Text(
            'Are you sure you want to report this user? Your feedback will be recorded.',
            style: GoogleFonts.poppins(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: GoogleFonts.poppins(color: Colors.grey),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('User reported'),
                    backgroundColor: Colors.orange,
                  ),
                );
              },
              child: Text(
                'Report',
                style: GoogleFonts.poppins(color: Colors.orange),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showBlockConfirmation() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Block User',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
          ),
          content: Text(
            'Are you sure you want to block ${_user?.displayName}? You won\'t see their content anymore.',
            style: GoogleFonts.poppins(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: GoogleFonts.poppins(color: Colors.grey),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('User blocked'),
                    backgroundColor: Colors.red,
                  ),
                );
              },
              child: Text(
                'Block',
                style: GoogleFonts.poppins(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: _buildAppBar(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_user == null) {
      return Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: _buildAppBar(),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              const Text(
                'User not found',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(_errorMessage ?? 'Could not load user data'),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Stack(
        children: [
          // Main Content
          SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 140),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Bar
                _buildAppBar(),

                // User Profile Section (inline, no card style)
                _buildInlineUserProfile(),

                // Statistics Section
                _buildStatisticsSection(),

                // Interests Section
                _buildInterestsSection(),

                // Content Tabs Section
                _buildContentTabsSection(),

                // Visited Countries Section
                _buildVisitedCountriesSection(),

                const SizedBox(height: 30),
              ],
            ),
          ),

          // Fixed Bottom Buttons
          _buildBottomButtons(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.black),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        // Hide three-dot menu when viewing own profile
        if (!_isViewingOwnProfile)
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.black),
            onPressed: _showActionSheet,
          ),
      ],
    );
  }

  Widget _buildInlineUserProfile() {
    return SizedBox(
      height: 360, // Increased from 280px to 360px for visual impact
      width: double.infinity,
      child: Stack(
        children: [
          // Optimized Avatar Display
          _buildOptimizedAvatar(),

          // Dark overlay for better text readability
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
                stops: const [0.4, 1.0],
              ),
            ),
          ),

          // Status Label - Top Right
          Positioned(top: 16, right: 16, child: _buildStatusBadge()),

          // Bookmark Star - Below Status (hidden when viewing own profile)
          if (!_isViewingOwnProfile)
            Positioned(top: 60, right: 16, child: _buildBookmarkButton()),

          // User Info Overlay - Bottom Left
          Positioned(
            bottom: 16,
            left: 16,
            right: 80,
            child: _buildUserInfoOverlay(),
          ),
        ],
      ),
    );
  }

  Widget _buildOptimizedAvatar() {
    if (_user!.avatarUrl.isEmpty) {
      // Fallback gradient background
      return Container(
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
      );
    }

    return ClipRect(
      child: Image.network(
        _user!.avatarUrl,
        width: double.infinity,
        height: 360,
        fit: BoxFit.cover,
        alignment: const Alignment(0.0, -0.3),
        errorBuilder: (context, error, stackTrace) {
          return Container(
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
          );
        },
      ),
    );
  }

  Widget _buildStatusBadge() {
    Color badgeColor;
    Color textColor;
    String statusText;
    String statusIcon;

    switch (_user!.status.toLowerCase()) {
      case 'open to exchange':
      case 'available':
        badgeColor = const Color(0xFF4CAF50);
        textColor = Colors.white;
        statusText = 'Open to Exchange';
        statusIcon = '✅';
        break;
      case 'by request only':
      case 'busy':
      case 'limited':
        badgeColor = const Color(0xFFFFEB3B);
        textColor = Colors.black;
        statusText = 'By Request Only';
        statusIcon = '🟡';
        break;
      case 'unavailable':
      case 'not available':
        badgeColor = const Color(0xFF9E9E9E);
        textColor = const Color(0xFF424242);
        statusText = 'Unavailable';
        statusIcon = '⬜';
        break;
      default:
        badgeColor = const Color(0xFF4CAF50);
        textColor = Colors.white;
        statusText = 'Open to Exchange';
        statusIcon = '✅';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: badgeColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        '$statusIcon $statusText',
        style: GoogleFonts.poppins(
          color: textColor,
          fontWeight: FontWeight.w600,
          fontSize: 11,
        ),
      ),
    );
  }

  Widget _buildBookmarkButton() {
    return GestureDetector(
      onTap: _isToggling ? null : _toggleFavorite,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child:
            _isToggling
                ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      const Color(0xFF7153DF),
                    ),
                  ),
                )
                : Icon(
                  _isFavorited ? Icons.star : Icons.star_border,
                  color:
                      _isFavorited ? const Color(0xFF7153DF) : Colors.grey[600],
                  size: 20,
                ),
      ),
    );
  }

  Widget _buildUserInfoOverlay() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Name and Verification Badges Row
        Row(
          children: [
            Expanded(
              child: Text(
                _user!.displayName,
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  shadows: [
                    Shadow(
                      color: Colors.black.withOpacity(0.5),
                      blurRadius: 2,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Verification Badges
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_user!.isVerified)
                  _buildVerificationBadge(Icons.verified, Colors.blue),
                if (_user!.verificationBadges.contains('pro'))
                  _buildVerificationBadge(
                    Icons.workspace_premium,
                    const Color(0xFFFFD700),
                  ),
                if (_user!.verificationBadges.contains('web3'))
                  _buildVerificationBadge(
                    Icons.security,
                    const Color(0xFF00E676),
                  ),
              ],
            ),
          ],
        ),

        const SizedBox(height: 8),

        // Location
        if (_user!.location.isNotEmpty) ...[
          Row(
            children: [
              Icon(
                Icons.location_on,
                size: 16,
                color: Colors.white.withOpacity(0.9),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  _user!.location,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.9),
                    shadows: [
                      Shadow(
                        color: Colors.black.withOpacity(0.5),
                        blurRadius: 2,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],

        // Languages
        if (_user!.languages.isNotEmpty) ...[
          Row(
            children: [
              Icon(
                Icons.language,
                size: 16,
                color: Colors.white.withOpacity(0.9),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  _user!.languages.take(3).join(', '),
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.9),
                    shadows: [
                      Shadow(
                        color: Colors.black.withOpacity(0.5),
                        blurRadius: 2,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildVerificationBadge(IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(left: 4),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Icon(icon, size: 16, color: color),
    );
  }

  Widget _buildStatisticsSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.only(top: 16, left: 16, right: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
          // Line 1: Wishes Fulfilled | Experiences Joined
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatItem(
                '${_user!.wishesFullfilledCount}',
                'Wishes Fulfilled',
                const Color(0xFF7153DF),
              ),
              _buildStatItem(
                '${_user!.experiencesCount}',
                'Experiences Joined',
                const Color(0xFF7153DF),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Line 2: Last Active | Trust Score
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [_buildLastActiveWidget(), _buildTrustScoreWidget()],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String value, String label, Color valueColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: valueColor,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildLastActiveWidget() {
    // Calculate days since last active (mock data for now)
    final daysSinceActive = DateTime.now().difference(_user!.updatedAt).inDays;
    String activeText;

    if (daysSinceActive == 0) {
      activeText = 'Active today';
    } else if (daysSinceActive == 1) {
      activeText = 'Active yesterday';
    } else if (daysSinceActive < 7) {
      activeText = 'Active $daysSinceActive days ago';
    } else {
      activeText = 'Active ${(daysSinceActive / 7).floor()} weeks ago';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          activeText,
          style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[700]),
        ),
        Text(
          'Last Active',
          style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[500]),
        ),
      ],
    );
  }

  Widget _buildTrustScoreWidget() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          '${_user!.trustScore} / 100',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF7153DF),
          ),
        ),
        Text(
          'Trust Score',
          style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildInterestsSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.only(top: 16, left: 16, right: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
          Text(
            'Interests',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _user!.interests.isNotEmpty
              ? Wrap(
                spacing: 8,
                runSpacing: 8,
                children:
                    _user!.interests.map((interest) {
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
                          interest,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: const Color(0xFF7153DF),
                          ),
                        ),
                      );
                    }).toList(),
              )
              : Text(
                'No interests added yet',
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

  Widget _buildContentTabsSection() {
    return Container(
      margin: const EdgeInsets.only(top: 16, left: 16, right: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
          // Tab Bar
          TabBar(
            controller: _tabController,
            labelColor: const Color(0xFF7153DF),
            unselectedLabelColor: Colors.grey[600],
            indicatorColor: const Color(0xFF7153DF),
            indicatorWeight: 2,
            labelStyle: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
            unselectedLabelStyle: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
            tabs: [
              Tab(text: 'Experiences (${_userExperiences.length})'),
              Tab(text: 'Wishes (${_userWishes.length})'),
            ],
          ),

          // Tab Content
          SizedBox(
            height: 300,
            child: TabBarView(
              controller: _tabController,
              children: [_buildExperiencesTab(), _buildWishesTab()],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExperiencesTab() {
    if (_isLoadingExperiences) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF7153DF)),
      );
    }

    if (_userExperiences.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.explore_outlined, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 12),
            Text(
              'No experiences yet',
              style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 4),
            Text(
              _isViewingOwnProfile
                  ? 'Share your first experience!'
                  : 'This user hasn\'t shared any experiences yet',
              style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[400]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _userExperiences.length,
      itemBuilder: (context, index) {
        final experience = _userExperiences[index];
        return _buildExperienceCard(experience);
      },
    );
  }

  Widget _buildWishesTab() {
    if (_isLoadingWishes) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF7153DF)),
      );
    }

    if (_userWishes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.star_outline, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 12),
            Text(
              'No wishes yet',
              style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 4),
            Text(
              _isViewingOwnProfile
                  ? 'Make your first wish!'
                  : 'This user hasn\'t made any wishes yet',
              style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[400]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _userWishes.length,
      itemBuilder: (context, index) {
        final wish = _userWishes[index];
        return _buildWishCard(wish);
      },
    );
  }

  Widget _buildExperienceCard(ExperienceModel experience) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            spreadRadius: 0,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF7153DF).withOpacity(0.8),
                const Color(0xFF9C7EFF).withOpacity(0.6),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(Icons.explore, color: Colors.white, size: 24),
        ),
        title: Text(
          experience.title.isNotEmpty ? experience.title : 'Draft Experience',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1A1A1A),
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 6),
            Text(
              experience.description.isNotEmpty
                  ? experience.description
                  : 'This experience is being created...',
              style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[700]),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.location_on, size: 14, color: Colors.grey[500]),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    experience.location.isNotEmpty
                        ? experience.location
                        : 'TBD',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: Icon(Icons.chevron_right, color: Colors.grey[400]),
        onTap: () {
          // Only navigate if experience has a valid ID
          if (experience.experienceId.isNotEmpty) {
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
          } else {
            // Show message for draft experiences
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('This experience is still being created'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        },
      ),
    );
  }

  Widget _buildWishCard(WishModel wish) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: CircleAvatar(
          backgroundColor: Colors.orange.withOpacity(0.1),
          child: Icon(Icons.star, color: Colors.orange[700]),
        ),
        title: Text(
          wish.title,
          style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              wish.description,
              style: GoogleFonts.poppins(fontSize: 12),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.location_on, size: 12, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  wish.location,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ],
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) =>
                      WishDetailScreen(wishId: wish.wishId, wish: wish),
            ),
          );
        },
      ),
    );
  }

  Widget _buildVisitedCountriesSection() {
    final visitedCount = _user!.visitedCountries.length;

    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.only(top: 16, left: 16, right: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
            children: [
              const Icon(Icons.public, color: Color(0xFF7153DF), size: 20),
              const SizedBox(width: 8),
              Text(
                'Countries Visited',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Show countries as chips if any exist
          if (visitedCount > 0) ...[
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children:
                  _user!.visitedCountries.map((country) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F8FF),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFF7153DF).withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.flag,
                            size: 14,
                            color: Color(0xFF7153DF),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            country,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: const Color(0xFF7153DF),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
            ),
            const SizedBox(height: 8),
            Text(
              '$visitedCount countries visited',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          ] else ...[
            // Show empty state
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.flag, color: Colors.grey[400], size: 24),
                  const SizedBox(width: 8),
                  Text(
                    '0 countries visited',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _sendMessage() async {
    // Prevent multiple taps
    if (_isSendingMessage || _user == null) return;

    setState(() {
      _isSendingMessage = true;
    });

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('You must be logged in to send messages');
      }

      // Check if we're trying to message ourselves
      if (currentUser.uid == widget.userId) {
        throw Exception('You cannot send messages to yourself');
      }

      // Create or get existing conversation (without sending any automatic message)
      final conversationId = await _chatService.createConversation(
        otherUserId: widget.userId,
      );

      if (mounted) {
        // Navigate to chat detail screen (user will manually type and send messages)
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) => ChatDetailScreen(
                  chatId: conversationId,
                  userName: _user!.displayName,
                  userAvatar: _user!.avatarUrl,
                ),
          ),
        );
      }
    } catch (e, stackTrace) {
      // Print detailed error information to terminal
      _printDetailedError('Send Message', e, stackTrace);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening chat: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSendingMessage = false;
        });
      }
    }
  }

  Widget _buildBottomButtons() {
    // Hide bottom buttons when viewing own profile
    if (_isViewingOwnProfile) {
      return const SizedBox.shrink();
    }

    // Check if user has exactly one experience for the "Join This Experience" button
    final hasExactlyOneExperience = _userExperiences.length == 1;
    final singleExperience =
        hasExactlyOneExperience ? _userExperiences.first : null;
    final canJoinExperience =
        hasExactlyOneExperience &&
        singleExperience != null &&
        singleExperience.experienceId.isNotEmpty;

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Row(
          children: [
            // Only show "Join This Experience" button if user has exactly one experience
            if (canJoinExperience) ...[
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _joinUserExperience(singleExperience!),
                  icon: const Icon(Icons.group_add),
                  label: Text('Join "${singleExperience!.title}"'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7153DF),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
            ],
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _isSendingMessage ? null : _sendMessage,
                icon:
                    _isSendingMessage
                        ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              const Color(0xFF7153DF),
                            ),
                          ),
                        )
                        : const Icon(Icons.message),
                label: Text(
                  _isSendingMessage ? 'Connecting...' : 'Send Message',
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF7153DF),
                  side: const BorderSide(color: Color(0xFF7153DF)),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _joinUserExperience(ExperienceModel experience) async {
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

      // Simulate joining the experience (replace with actual API call)
      await Future.delayed(const Duration(seconds: 1));

      // Close loading dialog
      if (mounted) Navigator.of(context).pop();

      // Show success message and navigate to experience detail
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully joined "${experience.title}"!'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );

        // Navigate to experience detail page
        Navigator.pushNamed(
          context,
          '/experience-detail',
          arguments: {
            'experienceId': experience.experienceId,
            'experience': experience,
          },
        );
      }
    } catch (e) {
      // Close loading dialog if still open
      if (mounted && Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }

      print('Error joining experience: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to join experience: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Print detailed error information to terminal for debugging
  /// This is especially useful for Firestore database index errors
  void _printDetailedError(
    String actionType,
    dynamic error,
    StackTrace? stackTrace,
  ) {
    print('\n' + '=' * 80);
    print('🚨 CHAT/MESSAGING ERROR DETAILS');
    print('=' * 80);
    print('Action Type: $actionType');
    print('Screen: User Detail Page');
    print('Timestamp: ${DateTime.now().toIso8601String()}');

    if (_user != null) {
      print('\nUser Context:');
      print('  - Target User ID: ${_user!.userId}');
      print('  - Target User Name: ${_user!.displayName}');
      print('  - Target User Status: ${_user!.status}');
      if (_user!.location.isNotEmpty) {
        print('  - Target User Location: ${_user!.location}');
      }
    }

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      print('\nCurrent User Context:');
      print('  - Current User ID: ${currentUser.uid}');
    }

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

    // Check for permission errors
    if (errorString.contains('permission') || errorString.contains('denied')) {
      print('\n🔒 PERMISSION ERROR DETECTED!');
      print(
        'This error indicates insufficient Firestore security rules permissions.',
      );
      print(
        'Check your Firestore security rules for the chats/conversations collection.',
      );
    }

    // Print current action configuration for debugging
    print('\nAction Configuration:');
    print('  Collection: chats/conversations');
    print('  Operation: Create conversation and send message');

    if (actionType.contains('Send Message')) {
      print('  Scenario: Direct message to user from profile page');
      print(
        '  Required Fields: participants, lastMessage, createdAt, updatedAt',
      );
    }

    print('\n💡 Common Chat Service Index Requirements:');
    print('  Collection: chats');
    print('  Typical indexes needed:');
    print('    - participants (Arrays), updatedAt (Descending)');
    print('    - participants (Arrays), createdAt (Descending)');

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
