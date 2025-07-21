import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/experience_model.dart';
import '../models/user_model.dart';
import '../experience_detail_screen.dart';
import '../services/user_service.dart';

class ExperienceCard extends StatefulWidget {
  final ExperienceModel experience;
  final VoidCallback? onFavoriteToggle;
  final bool isFavorited;

  const ExperienceCard({
    super.key,
    required this.experience,
    this.onFavoriteToggle,
    this.isFavorited = false,
  });

  @override
  State<ExperienceCard> createState() => _ExperienceCardState();
}

class _ExperienceCardState extends State<ExperienceCard>
    with SingleTickerProviderStateMixin {
  bool _isFavorited = false;
  UserModel? _publisher;
  bool _isLoading = true;
  final UserService _userService = UserService();

  // Animation controller for hover effects
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isHovered = false;

  // Design tokens
  static const Color _secondaryTextColor = Color(0xFF666666);
  static const Color _brandColor = Color(0xFF6B46C1); // Purple brand color
  static const Color _cardBackgroundColor = Colors.white;
  static const Color _infoAreaBackgroundColor = Color(0xFFFAFAFA);

  @override
  void initState() {
    super.initState();
    _isFavorited = widget.isFavorited;
    _fetchPublisherData();

    // Initialize animation controller
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.98).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
  }

  @override
  void didUpdateWidget(ExperienceCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update local state when parent state changes
    if (oldWidget.isFavorited != widget.isFavorited) {
      setState(() {
        _isFavorited = widget.isFavorited;
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // Fetch user data for the experience publisher
  Future<void> _fetchPublisherData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      if (widget.experience.userRef != null) {
        // Fetch from userRef if available
        final doc = await widget.experience.userRef!.get();
        if (doc.exists) {
          _publisher = UserModel.fromFirestore(
            doc as DocumentSnapshot<Map<String, dynamic>>,
          );
        }
      }

      if (_publisher == null) {
        // Fallback to userId if userRef not available or fails
        _publisher = await _userService.getUserById(widget.experience.userId);
      }
    } catch (e) {
      print('Error fetching publisher data: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Check if user has Pro membership
  bool get _isProMember {
    return _publisher?.verificationBadges.contains('pro') ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            onEnter: (_) => setState(() => _isHovered = true),
            onExit: (_) => setState(() => _isHovered = false),
            child: GestureDetector(
              onTapDown: (_) {
                _animationController.forward();
              },
              onTapUp: (_) {
                _animationController.reverse();
              },
              onTapCancel: () {
                _animationController.reverse();
              },
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => ExperienceDetailScreen(
                          experienceId: widget.experience.experienceId,
                          experience: widget.experience,
                        ),
                  ),
                );
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: _cardBackgroundColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.black.withOpacity(0.05),
                    width: 1,
                  ),
                  boxShadow:
                      _isHovered
                          ? [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                            BoxShadow(
                              color: Colors.black.withOpacity(0.06),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 16,
                              offset: const Offset(0, 8),
                            ),
                          ]
                          : [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                            BoxShadow(
                              color: Colors.black.withOpacity(0.03),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                            BoxShadow(
                              color: Colors.black.withOpacity(0.02),
                              blurRadius: 16,
                              offset: const Offset(0, 8),
                            ),
                          ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Featured image at the top
                    _buildImageHeader(),

                    // Content area with subtle background
                    Container(
                      decoration: const BoxDecoration(
                        color: _infoAreaBackgroundColor,
                        borderRadius: BorderRadius.vertical(
                          bottom: Radius.circular(16),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Content area with improved structure
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Row 1: User info + date
                                _buildUserInfoRow(),

                                const SizedBox(height: 8),

                                // Row 2: Category chip
                                _buildCategoryChip(),

                                const SizedBox(height: 8),

                                // Row 3: Title + Row 4: Description + Row 5: Location/Slots
                                _buildMainContent(),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // Image header with favorite button
  Widget _buildImageHeader() {
    return Stack(
      children: [
        // Full cover image without empty spaces
        ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          child: Container(
            height: 180,
            width: double.infinity,
            child:
                widget.experience.photoUrls.isNotEmpty
                    ? Image.network(
                      widget.experience.photoUrls.first,
                      height: 180,
                      width: double.infinity,
                      fit:
                          BoxFit
                              .cover, // This ensures full coverage with cropping
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 180,
                          width: double.infinity,
                          color: Colors.grey.shade300,
                          child: const Icon(
                            Icons.broken_image,
                            size: 60,
                            color: Colors.grey,
                          ),
                        );
                      },
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          height: 180,
                          width: double.infinity,
                          color: Colors.grey.shade100,
                          child: Center(
                            child: CircularProgressIndicator(
                              value:
                                  loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                      : null,
                              color: _brandColor,
                            ),
                          ),
                        );
                      },
                    )
                    : Container(
                      height: 180,
                      width: double.infinity,
                      color: Colors.grey.shade200,
                      child: const Icon(
                        Icons.explore,
                        size: 60,
                        color: Colors.grey,
                      ),
                    ),
          ),
        ),

        // Favorite button
        Positioned(
          top: 12,
          right: 12,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                // Don't update local state here - let parent handle it
                widget.onFavoriteToggle?.call();
              },
              customBorder: const CircleBorder(),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.95),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  widget.isFavorited ? Icons.star : Icons.star_border,
                  color:
                      widget.isFavorited ? Colors.amber : _secondaryTextColor,
                  size: 20,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Row 1: User info + date (similar to WishCard)
  Widget _buildUserInfoRow() {
    return Row(
      children: [
        // Small avatar
        _isLoading || _publisher == null || _publisher!.avatarUrl.isEmpty
            ? CircleAvatar(
              radius: 12,
              backgroundColor: Colors.grey.shade200,
              child: Icon(Icons.person, color: Colors.grey.shade500, size: 12),
            )
            : CircleAvatar(
              radius: 12,
              backgroundImage: NetworkImage(_publisher!.avatarUrl),
              backgroundColor: Colors.grey.shade200,
            ),

        const SizedBox(width: 8),

        // Username
        Text(
          _isLoading || _publisher == null || _publisher!.displayName.isEmpty
              ? 'Host'
              : _publisher!.displayName,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),

        const SizedBox(width: 4),

        // Verification badge
        if (_publisher != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.teal.shade50,
              borderRadius: BorderRadius.circular(3),
              border: Border.all(color: Colors.teal.shade100),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.verified, size: 10, color: Colors.teal.shade700),
                const SizedBox(width: 2),
                Text(
                  "Verified",
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w500,
                    color: Colors.teal.shade700,
                  ),
                ),
              ],
            ),
          ),

        const SizedBox(width: 6),

        // Separator
        Text("・", style: TextStyle(fontSize: 14, color: Colors.grey.shade500)),

        const SizedBox(width: 6),

        // Date/time
        Text(
          _formatTimeAgo(widget.experience.createdAt),
          style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
        ),

        // Pro badge if user has Pro membership
        if (_publisher != null && _isProMember) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFFB800), Color(0xFFFF8A00)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Text(
              'PRO',
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ],
    );
  }

  // Row 2: Category chip
  Widget _buildCategoryChip() {
    if (widget.experience.tags.isEmpty) {
      return const SizedBox.shrink();
    }

    final category = widget.experience.tags.first; // Show only first tag

    // Get a consistent color based on the category name
    final int colorSeed = category.hashCode.abs() % 5;
    final List<Color> categoryColors = [
      Colors.purple.shade100,
      Colors.blue.shade100,
      Colors.teal.shade100,
      Colors.amber.shade100,
      Colors.pink.shade100,
    ];
    final List<Color> textColors = [
      Colors.purple.shade700,
      Colors.blue.shade700,
      Colors.teal.shade700,
      Colors.amber.shade700,
      Colors.pink.shade700,
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: categoryColors[colorSeed],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        category,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: textColors[colorSeed],
        ),
      ),
    );
  }

  // Main content area with title, description, location/slots
  Widget _buildMainContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title
        Text(
          widget.experience.title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            height: 1.2,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),

        const SizedBox(height: 6),

        // Description (2 lines max)
        if (widget.experience.description.isNotEmpty)
          Text(
            widget.experience.description,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade700,
              height: 1.3,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),

        const SizedBox(height: 8),

        // Location and available slots row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Location (left side)
            if (widget.experience.location?.isNotEmpty == true)
              Expanded(
                child: Row(
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      size: 14,
                      color: Colors.grey.shade500,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        widget.experience.location!,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              )
            else
              const Expanded(child: SizedBox()), // Empty space when no location
            // Available slots (always right-aligned)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: _brandColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _brandColor.withOpacity(0.2)),
              ),
              child: Text(
                '${widget.experience.availableSlots - widget.experience.currentParticipants}/${widget.experience.availableSlots} available',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: _brandColor,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Helper method to format time ago
  String _formatTimeAgo(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) {
      return 'now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d';
    } else {
      return '${(difference.inDays / 7).floor()}w';
    }
  }
}
