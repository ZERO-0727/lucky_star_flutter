import 'package:flutter/material.dart';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/wish_model.dart';
import '../models/user_model.dart';
import '../wish_detail_screen.dart';
import '../services/user_service.dart';
import 'shared/card_image.dart';

class WishCard extends StatefulWidget {
  final WishModel wish;
  final VoidCallback? onFavoriteToggle;
  final bool isFavorited;

  const WishCard({
    super.key,
    required this.wish,
    this.onFavoriteToggle,
    this.isFavorited = false,
  });

  @override
  State<WishCard> createState() => _WishCardState();
}

class _WishCardState extends State<WishCard> {
  bool _isFavorited = false;
  UserModel? _publisher;
  bool _isLoading = true;
  final UserService _userService = UserService();

  @override
  void initState() {
    super.initState();
    _isFavorited = widget.isFavorited;
    _fetchPublisherData();
  }

  // Fetch user data for the wish publisher
  Future<void> _fetchPublisherData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Fetch user data directly by userId
      _publisher = await _userService.getUserById(widget.wish.userId);
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
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      shadowColor: Colors.black.withOpacity(0.4),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) => WishDetailScreen(
                    wishId: widget.wish.wishId,
                    wish: widget.wish,
                  ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Featured image at the top
            _buildImageHeader(),

            // User info at the top of content section
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: _buildUserInfo(),
            ),

            const Divider(height: 24, indent: 16, endIndent: 16),

            // Main content section below user info
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: _buildContentSection(),
            ),
          ],
        ),
      ),
    );
  }

  // Image header with favorite button
  Widget _buildImageHeader() {
    return Stack(
      children: [
        // Use the unified CardImage component
        ClipRRect(
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(12), // Consistent border radius with card
          ),
          child: CardImage(
            photoUrls: widget.wish.photoUrls,
            height: 220, // Fixed height as per requirements (200-240px)
            emptyStateIcon: 'star',
            progressIndicatorColor: Colors.blue.shade300,
          ),
        ),

        // Favorite button - star icon with improved style
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
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 1,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Icon(
                  _isFavorited ? Icons.star : Icons.star_border,
                  color: _isFavorited ? Colors.amber : Colors.grey.shade700,
                  size: 20,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // User info row (larger avatar, more prominent style)
  Widget _buildUserInfo() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // User Avatar (circular, larger size)
        _isLoading || _publisher == null || _publisher!.avatarUrl.isEmpty
            ? CircleAvatar(
              radius: 24,
              backgroundColor: Colors.grey.shade200,
              child: Icon(Icons.person, color: Colors.grey.shade500, size: 24),
            )
            : CircleAvatar(
              radius: 24,
              backgroundImage: NetworkImage(_publisher!.avatarUrl),
              backgroundColor: Colors.grey.shade200,
            ),
        const SizedBox(width: 12),

        // Username + verification
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      _isLoading ||
                              _publisher == null ||
                              _publisher!.displayName.isEmpty
                          ? 'Wisher: ${widget.wish.userId.substring(0, min(8, widget.wish.userId.length))}...'
                          : _publisher!.displayName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),

                  const SizedBox(width: 6),

                  // Verification badge (more prominent)
                  if (_publisher != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.teal.shade50,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.teal.shade100),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.verified,
                            size: 14,
                            color: Colors.teal.shade700,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            "Verified",
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: Colors.teal.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 4),

              Row(
                children: [
                  // Pro badge if user has Pro membership (more prominent)
                  if (_publisher != null && _isProMember)
                    Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.amber.shade700,
                            Colors.orange.shade700,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(4),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.amber.shade200.withOpacity(0.5),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: const Text(
                        'PRO MEMBER',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),

                  // Posted date with icon for better visibility
                  Icon(
                    Icons.access_time,
                    size: 12,
                    color: Colors.grey.shade500,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _formatPostDate(widget.wish.createdAt),
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildContentSection() {
    final Color iconColor = Colors.grey.shade700;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title (larger, more prominent)
        Text(
          widget.wish.title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            height: 1.3,
            letterSpacing: -0.2,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 16),

        // Info rows with consistent styling
        // Location (moved up in hierarchy)
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.location_on, size: 18, color: iconColor),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                widget.wish.location.isNotEmpty
                    ? widget.wish.location
                    : 'Location not specified',
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey.shade800,
                  height: 1.3,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Date (with consistent styling)
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.calendar_today, size: 18, color: iconColor),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _formatWishDate(widget.wish.preferredDate),
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey.shade800,
                  height: 1.3,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Budget with improved styling
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.payments_outlined, size: 18, color: iconColor),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.green.shade100),
              ),
              child: Text(
                widget.wish.formattedBudget,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.green.shade700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Categories section (improved styling with pills)
        if (widget.wish.categories.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                widget.wish.categories.map((category) {
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
                    Colors.purple.shade800,
                    Colors.blue.shade800,
                    Colors.teal.shade800,
                    Colors.amber.shade800,
                    Colors.pink.shade800,
                  ];

                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: categoryColors[colorSeed],
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      category,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: textColors[colorSeed],
                      ),
                    ),
                  );
                }).toList(),
          ),
      ],
    );
  }

  // Add hover effects when built as a stateful widget
  // This is for web support, but will be ignored on mobile
  Widget _buildHoverEffects(Widget child) {
    return MouseRegion(cursor: SystemMouseCursors.click, child: child);
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Unknown';

    final now = DateTime.now();
    final difference = date.difference(now);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Tomorrow';
    } else if (difference.inDays > 0 && difference.inDays <= 7) {
      return 'In ${difference.inDays}d';
    } else if (difference.inDays > 7 && difference.inDays <= 30) {
      return 'In ${(difference.inDays / 7).floor()}w';
    } else if (difference.inDays > 0) {
      return '${date.month}/${date.day}';
    } else {
      // Past dates
      final pastDifference = now.difference(date);
      if (pastDifference.inDays == 1) {
        return 'Yesterday';
      } else if (pastDifference.inDays < 7) {
        return '${pastDifference.inDays}d ago';
      } else {
        return '${date.month}/${date.day}';
      }
    }
  }

  // Format preferred date for display (simple format)
  String _formatPreferredDate(DateTime date) {
    final now = DateTime.now();
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    // Format: "Jun 15, 2025" or "Today" or "Tomorrow"
    if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day) {
      return 'Today';
    } else if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day + 1) {
      return 'Tomorrow';
    } else {
      return '${months[date.month - 1]} ${date.day}, ${date.year}';
    }
  }

  // Format the wish date in a readable format (matching experience card format)
  String _formatWishDate(DateTime date) {
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
    if (date.difference(now).inDays < 7) {
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

  // Format post date (when the wish was created)
  String _formatPostDate(DateTime date) {
    final now = DateTime.now();
    final months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    // Check if it's today
    if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day) {
      return 'Today';
    }

    // Check if it's yesterday
    final yesterday = now.subtract(const Duration(days: 1));
    if (date.year == yesterday.year &&
        date.month == yesterday.month &&
        date.day == yesterday.day) {
      return 'Yesterday';
    }

    // Otherwise, return in Month Day, Year format
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}
