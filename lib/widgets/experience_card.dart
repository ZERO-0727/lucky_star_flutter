import 'package:flutter/material.dart';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/experience_model.dart';
import '../models/user_model.dart';
import '../experience_detail_screen.dart';
import '../services/user_service.dart';
import 'shared/card_image.dart';

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
  bool _isPressed = false;

  // Design tokens
  static const Color _primaryTextColor = Color(0xFF1A1A1A);
  static const Color _secondaryTextColor = Color(0xFF666666);
  static const Color _auxiliaryTextColor = Color(0xFF999999);
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
                setState(() => _isPressed = true);
                _animationController.forward();
              },
              onTapUp: (_) {
                setState(() => _isPressed = false);
                _animationController.reverse();
              },
              onTapCancel: () {
                setState(() => _isPressed = false);
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
                          // User info section
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: _buildUserInfo(),
                          ),

                          // Subtle separator
                          Container(
                            height: 1,
                            margin: const EdgeInsets.symmetric(horizontal: 16),
                            color: Colors.grey.withOpacity(0.1),
                          ),

                          // Main content section
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: _buildContentSection(),
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
        // Use the unified CardImage component
        CardImage(
          photoUrls: widget.experience.photoUrls,
          height: 180,
          progressIndicatorColor: _brandColor,
        ),

        // Favorite button
        Positioned(
          top: 12,
          right: 12,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                setState(() {
                  _isFavorited = !_isFavorited;
                });
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
                  _isFavorited ? Icons.star : Icons.star_border,
                  color: _isFavorited ? Colors.amber : _secondaryTextColor,
                  size: 20,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Host info row with improved layout
  Widget _buildUserInfo() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // User Avatar (32px as per requirements)
        _isLoading || _publisher == null || _publisher!.avatarUrl.isEmpty
            ? CircleAvatar(
              radius: 16, // 32px diameter
              backgroundColor: Colors.grey.shade200,
              child: Icon(Icons.person, color: Colors.grey.shade500, size: 16),
            )
            : CircleAvatar(
              radius: 16, // 32px diameter
              backgroundImage: NetworkImage(_publisher!.avatarUrl),
              backgroundColor: Colors.grey.shade200,
            ),
        const SizedBox(width: 8),

        // Username + badges
        Expanded(
          child: Row(
            children: [
              // Username
              Flexible(
                child: Text(
                  _isLoading ||
                          _publisher == null ||
                          _publisher!.displayName.isEmpty
                      ? 'Host'
                      : _publisher!.displayName,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: _secondaryTextColor,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              // Verification badge
              if (_publisher != null)
                Container(
                  margin: const EdgeInsets.only(left: 6),
                  child: Icon(Icons.verified, size: 16, color: _brandColor),
                ),

              // Pro badge
              if (_publisher != null && _isProMember)
                Container(
                  margin: const EdgeInsets.only(left: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
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
          ),
        ),

        // Posted date (right-aligned)
        Text(
          _formatDate(widget.experience.createdAt),
          style: TextStyle(fontSize: 12, color: _auxiliaryTextColor),
        ),
      ],
    );
  }

  Widget _buildContentSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title (increased size and weight)
        const SizedBox(height: 4),
        Text(
          widget.experience.title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            height: 1.3,
            color: _primaryTextColor,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 8),

        // Location with icon
        Row(
          children: [
            Icon(
              Icons.location_on_outlined,
              size: 16,
              color: _auxiliaryTextColor,
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                widget.experience.location ?? 'Location not specified',
                style: TextStyle(fontSize: 12, color: _auxiliaryTextColor),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Date with icon
        Row(
          children: [
            Icon(
              Icons.calendar_today_outlined,
              size: 16,
              color: _auxiliaryTextColor,
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                _formatExperienceDate(widget.experience.date),
                style: TextStyle(fontSize: 12, color: _auxiliaryTextColor),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Available slots as prominent pill button
        Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: InkWell(
            onTap: () {
              // Handle slots tap
            },
            borderRadius: BorderRadius.circular(20),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: _brandColor.withOpacity(_isHovered ? 0.15 : 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _brandColor.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.people_outline, size: 16, color: _brandColor),
                  const SizedBox(width: 6),
                  Text(
                    '${widget.experience.availableSlots - widget.experience.currentParticipants} available slots',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _brandColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Tags section with unified design
        if (widget.experience.tags.isNotEmpty) ...[
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children:
                widget.experience.tags.take(4).map((tag) {
                  // Primary tag (first tag)
                  final bool isPrimary =
                      widget.experience.tags.indexOf(tag) == 0;

                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    height: 28,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color:
                          isPrimary
                              ? _brandColor
                              : _brandColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(14),
                      border:
                          !isPrimary
                              ? Border.all(
                                color: _brandColor.withOpacity(0.2),
                                width: 1,
                              )
                              : null,
                    ),
                    child: Text(
                      tag,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: isPrimary ? Colors.white : _brandColor,
                      ),
                    ),
                  );
                }).toList(),
          ),
        ],
      ],
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Unknown';

    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else if (difference.inDays < 30) {
      return '${(difference.inDays / 7).floor()}w ago';
    } else {
      return '${date.month}/${date.day}';
    }
  }

  // Format the experience date in a readable format
  String _formatExperienceDate(DateTime date) {
    final now = DateTime.now();

    // For events today
    if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day) {
      return 'Today at ${_formatTime(date)}';
    }

    // For events tomorrow
    final tomorrow = now.add(const Duration(days: 1));
    if (date.year == tomorrow.year &&
        date.month == tomorrow.month &&
        date.day == tomorrow.day) {
      return 'Tomorrow at ${_formatTime(date)}';
    }

    // For events within the next 7 days
    if (date.difference(now).inDays < 7 && date.isAfter(now)) {
      return '${_getDayOfWeek(date)} at ${_formatTime(date)}';
    }

    // For all other events
    return '${date.month}/${date.day}/${date.year} at ${_formatTime(date)}';
  }

  String _formatTime(DateTime date) {
    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour < 12 ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  String _getDayOfWeek(DateTime date) {
    switch (date.weekday) {
      case 1:
        return 'Monday';
      case 2:
        return 'Tuesday';
      case 3:
        return 'Wednesday';
      case 4:
        return 'Thursday';
      case 5:
        return 'Friday';
      case 6:
        return 'Saturday';
      case 7:
        return 'Sunday';
      default:
        return '';
    }
  }
}
