import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'models/user_model.dart';
import 'services/favorites_service.dart';
import 'services/user_service.dart';
import 'user_detail_page.dart';

class FavoritesListScreen extends StatefulWidget {
  const FavoritesListScreen({super.key});

  @override
  State<FavoritesListScreen> createState() => _FavoritesListScreenState();
}

class _FavoritesListScreenState extends State<FavoritesListScreen> {
  List<UserModel> _favoriteUsers = [];
  bool _isLoading = true;
  final UserService _userService = UserService();

  @override
  void initState() {
    super.initState();
    _loadFavoriteUsers();
  }

  Future<void> _loadFavoriteUsers() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Get all favorite user IDs
      final favoriteUserIds = await FavoritesService.getFavoriteUsers();
      final List<UserModel> loadedUsers = [];

      // Load user data for each favorite
      for (final userId in favoriteUserIds) {
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
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading favorite users: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _onFavoriteChanged() async {
    // Reload favorites when a user is removed
    await _loadFavoriteUsers();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'My LuckyStar',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF7153DF),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      backgroundColor: Colors.grey[50],
      body:
          _isLoading
              ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF7153DF)),
              )
              : _favoriteUsers.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                onRefresh: _loadFavoriteUsers,
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _favoriteUsers.length,
                  itemBuilder: (context, index) {
                    final user = _favoriteUsers[index];
                    return _buildUserCard(user, index);
                  },
                ),
              ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.star_border, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 24),
          Text(
            'No Favorites Yet',
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Discover amazing people and tap ⭐ on their profiles to add them to your LuckyStar list!',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: Colors.grey[600],
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pushNamed(context, '/user-plaza');
            },
            icon: const Icon(Icons.explore),
            label: const Text('Explore Users'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7153DF),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserCard(UserModel user, int index) {
    // Get user's primary interest or location for subtitle
    String subtitle = '';
    if (user.location.isNotEmpty) {
      subtitle = user.location;
    } else if (user.interests.isNotEmpty) {
      subtitle = user.interests.take(2).join(', ');
    } else {
      subtitle = 'LuckyStar User';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            spreadRadius: 0,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (context) => UserDetailPage(
                      userId: user.userId,
                      displayName: user.displayName,
                    ),
              ),
            ).then((_) {
              _loadFavoriteUsers();
            });
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                // Enhanced User Avatar
                _buildModernUserAvatar(user),
                const SizedBox(width: 16),

                // User Information - Expanded to take available space
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name and Verification Row
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              user.displayName,
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF1A1A1A),
                                letterSpacing: -0.2,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          // Verification badges
                          if (user.isVerified) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.verified,
                                size: 16,
                                color: Colors.blue[600],
                              ),
                            ),
                          ],
                          if (user.verificationBadges.contains('pro')) ...[
                            const SizedBox(width: 4),
                            Container(
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFD700).withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.workspace_premium,
                                size: 16,
                                color: Color(0xFFFFD700),
                              ),
                            ),
                          ],
                        ],
                      ),

                      const SizedBox(height: 6),

                      // Subtitle with better styling
                      Text(
                        subtitle,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: const Color(0xFF6B7280),
                          fontWeight: FontWeight.w400,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),

                      const SizedBox(height: 12),

                      // Status and Trust Score Row
                      Row(
                        children: [
                          // Status indicator
                          _buildModernStatusIndicator(user.status),
                          const SizedBox(width: 16),
                          // Trust score with better design
                          _buildTrustScoreChip(user.trustScore),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 12),

                // Modern Favorite Button
                _buildModernFavoriteButton(user),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModernUserAvatar(UserModel user) {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF7153DF).withOpacity(0.1),
            const Color(0xFF9C7EFF).withOpacity(0.05),
          ],
        ),
        border: Border.all(
          color: const Color(0xFF7153DF).withOpacity(0.15),
          width: 2,
        ),
      ),
      child: ClipOval(
        child:
            user.avatarUrl.isNotEmpty
                ? Image.network(
                  user.avatarUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return _buildModernAvatarFallback(user);
                  },
                )
                : _buildModernAvatarFallback(user),
      ),
    );
  }

  Widget _buildModernAvatarFallback(UserModel user) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [const Color(0xFF7153DF), const Color(0xFF9C7EFF)],
        ),
      ),
      child: Center(
        child: Text(
          user.displayName.isNotEmpty ? user.displayName[0].toUpperCase() : '?',
          style: GoogleFonts.poppins(
            fontSize: 28,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildModernStatusIndicator(String status) {
    Color statusColor;
    String statusText;
    IconData statusIcon;

    switch (status.toLowerCase()) {
      case 'open to exchange':
      case 'available':
        statusColor = const Color(0xFF10B981);
        statusText = 'Available';
        statusIcon = Icons.circle;
        break;
      case 'by request only':
      case 'busy':
      case 'limited':
        statusColor = const Color(0xFFF59E0B);
        statusText = 'By Request';
        statusIcon = Icons.schedule;
        break;
      case 'unavailable':
      case 'not available':
        statusColor = const Color(0xFF6B7280);
        statusText = 'Unavailable';
        statusIcon = Icons.do_not_disturb;
        break;
      default:
        statusColor = const Color(0xFF10B981);
        statusText = 'Available';
        statusIcon = Icons.circle;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(statusIcon, size: 12, color: statusColor),
          const SizedBox(width: 4),
          Text(
            statusText,
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: statusColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrustScoreChip(int trustScore) {
    Color chipColor;
    if (trustScore >= 80) {
      chipColor = const Color(0xFF10B981);
    } else if (trustScore >= 60) {
      chipColor = const Color(0xFFF59E0B);
    } else {
      chipColor = const Color(0xFFEF4444);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: chipColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.shield_outlined, size: 12, color: chipColor),
          const SizedBox(width: 4),
          Text(
            '$trustScore',
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: chipColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernFavoriteButton(UserModel user) {
    return GestureDetector(
      onTap: () => _toggleFavorite(user),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [const Color(0xFF7153DF), const Color(0xFF9C7EFF)],
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF7153DF).withOpacity(0.3),
              spreadRadius: 0,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Icon(Icons.star_rounded, color: Colors.white, size: 22),
      ),
    );
  }

  // Keep the old avatar fallback method for compatibility but unused
  Widget _buildUserAvatar(UserModel user) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: const Color(0xFF7153DF).withOpacity(0.3),
          width: 2,
        ),
      ),
      child: ClipOval(
        child:
            user.avatarUrl.isNotEmpty
                ? Image.network(
                  user.avatarUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return _buildAvatarFallback(user);
                  },
                )
                : _buildAvatarFallback(user),
      ),
    );
  }

  Widget _buildAvatarFallback(UserModel user) {
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
        child: Text(
          user.displayName.isNotEmpty ? user.displayName[0].toUpperCase() : '?',
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildStatusIndicator(String status) {
    Color statusColor;
    String statusText;

    switch (status.toLowerCase()) {
      case 'open to exchange':
      case 'available':
        statusColor = Colors.green;
        statusText = 'Available';
        break;
      case 'by request only':
      case 'busy':
      case 'limited':
        statusColor = Colors.orange;
        statusText = 'By Request';
        break;
      case 'unavailable':
      case 'not available':
        statusColor = Colors.grey;
        statusText = 'Unavailable';
        break;
      default:
        statusColor = Colors.green;
        statusText = 'Available';
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          statusText,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: statusColor,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Future<void> _toggleFavorite(UserModel user) async {
    try {
      final success = await FavoritesService.toggleUserFavorite(user.userId);

      if (success) {
        // Remove from current list since we're unfavoriting
        setState(() {
          _favoriteUsers.removeWhere((u) => u.userId == user.userId);
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${user.displayName} removed from My LuckyStar'),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 2),
            ),
          );
        }
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
    }
  }
}
