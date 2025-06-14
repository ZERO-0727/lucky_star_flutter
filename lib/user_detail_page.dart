import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'models/user_model.dart';
import 'services/user_service.dart';

class UserDetailPage extends StatefulWidget {
  final String userId;
  final String displayName;

  const UserDetailPage({
    Key? key,
    required this.userId,
    required this.displayName,
  }) : super(key: key);

  @override
  State<UserDetailPage> createState() => _UserDetailPageState();
}

class _UserDetailPageState extends State<UserDetailPage> {
  final UserService _userService = UserService();
  bool _isLoading = true;
  UserModel? _user;
  String? _errorMessage;

  // Helper method to check if current user is viewing their own profile
  bool get _isViewingOwnProfile {
    final currentUser = FirebaseAuth.instance.currentUser;
    return currentUser != null && currentUser.uid == widget.userId;
  }

  @override
  void initState() {
    super.initState();
    _loadUserData();
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
    return Container(
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
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bookmark feature coming soon'),
            backgroundColor: Colors.blue,
          ),
        );
      },
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
        child: Icon(Icons.star_border, color: Colors.grey[600], size: 20),
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
          // Tab Headers
          Container(
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Color(0xFF7153DF), width: 2),
                      ),
                    ),
                    child: Text(
                      'Experiences',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF7153DF),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Text(
                      'Wishes',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Tab Content (Placeholder)
          Container(
            height: 200,
            padding: const EdgeInsets.all(20),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.explore_outlined,
                    size: 48,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Content coming soon',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'User experiences and wishes will appear here',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey[400],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ],
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
                Icon(
                  Icons.flag,
                  color:
                      visitedCount > 0
                          ? const Color(0xFF7153DF)
                          : Colors.grey[400],
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  '$visitedCount countries visited',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color:
                        visitedCount > 0
                            ? const Color(0xFF7153DF)
                            : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          if (visitedCount > 0) ...[
            const SizedBox(height: 12),
            Text(
              'Map and detailed view coming soon',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.grey[500],
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBottomButtons() {
    // Hide bottom buttons when viewing own profile
    if (_isViewingOwnProfile) {
      return const SizedBox.shrink();
    }

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
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Request sent to join experience'),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
                icon: const Icon(Icons.group_add),
                label: const Text('Join This Experience'),
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
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Message feature coming soon'),
                      backgroundColor: Colors.blue,
                    ),
                  );
                },
                icon: const Icon(Icons.message),
                label: const Text('Send Message'),
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
}
