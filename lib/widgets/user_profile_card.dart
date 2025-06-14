import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/user_model.dart';

class UserProfileCard extends StatelessWidget {
  final UserModel user;
  final VoidCallback? onTap;
  final VoidCallback? onBookmark;
  final bool isBookmarked;
  final bool showDetailedStats;

  const UserProfileCard({
    Key? key,
    required this.user,
    this.onTap,
    this.onBookmark,
    this.isBookmarked = false,
    this.showDetailedStats = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Section - Full-Width Image Background
            _buildImageSection(context),

            // Bottom White Area
            _buildStatsSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSection(BuildContext context) {
    return Container(
      height: 280,
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

          // Bookmark Star - Below Status
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
    if (user.avatarUrl.isEmpty) {
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
        user.avatarUrl,
        width: double.infinity,
        height: 280,
        fit: BoxFit.cover,
        alignment: _getOptimalAlignment(),
        errorBuilder: (context, error, stackTrace) {
          // Fallback to gradient background on image load error
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
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
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
            child: Center(
              child: CircularProgressIndicator(
                value:
                    loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded /
                            loadingProgress.expectedTotalBytes!
                        : null,
                color: Colors.white.withOpacity(0.7),
              ),
            ),
          );
        },
      ),
    );
  }

  /// Returns optimal alignment for cropping based on Couchsurfing-style best practices
  /// Prioritizes upper body and face visibility
  Alignment _getOptimalAlignment() {
    // For portrait and square images, focus on upper portion to show face/upper body
    // This works well for typical profile photos
    return const Alignment(
      0.0,
      -0.3,
    ); // Slightly above center, ideal for face/upper body
  }

  Widget _buildStatusBadge() {
    Color badgeColor;
    Color textColor;
    String statusText;
    String statusIcon;

    switch (user.status.toLowerCase()) {
      case 'open to exchange':
      case 'available':
        badgeColor = const Color(0xFF4CAF50); // Green
        textColor = Colors.white;
        statusText = 'Open to Exchange';
        statusIcon = '✅';
        break;
      case 'by request only':
      case 'busy':
      case 'limited':
        badgeColor = const Color(0xFFFFEB3B); // Yellow
        textColor = Colors.black;
        statusText = 'By Request Only';
        statusIcon = '🟡';
        break;
      case 'unavailable':
      case 'not available':
        badgeColor = const Color(0xFF9E9E9E); // Gray
        textColor = const Color(0xFF424242); // Dark gray
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
      onTap: onBookmark,
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
        child: Icon(
          isBookmarked ? Icons.star : Icons.star_border,
          color: isBookmarked ? const Color(0xFF7153DF) : Colors.grey[600],
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
                user.displayName,
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
                if (user.isVerified)
                  _buildVerificationBadge(Icons.verified, Colors.blue),
                if (user.verificationBadges.contains('pro'))
                  _buildVerificationBadge(
                    Icons.workspace_premium,
                    const Color(0xFFFFD700),
                  ),
                if (user.verificationBadges.contains('web3'))
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
        if (user.location.isNotEmpty) ...[
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
                  user.location,
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
        if (user.languages.isNotEmpty) ...[
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
                  user.languages.take(3).join(', '),
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

  Widget _buildStatsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Line 1: Wishes Fulfilled | Experiences Joined
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatItem(
                '${user.wishesFullfilledCount}',
                'Wishes Fulfilled',
                const Color(0xFF7153DF),
              ),
              _buildStatItem(
                '${user.experiencesCount}',
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
    final daysSinceActive = DateTime.now().difference(user.updatedAt).inDays;
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
          '${user.trustScore} / 100',
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
}
