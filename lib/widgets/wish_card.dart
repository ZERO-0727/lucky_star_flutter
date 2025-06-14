import 'package:flutter/material.dart';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/wish_model.dart';
import '../models/user_model.dart';
import '../wish_detail_screen.dart';
import '../services/user_service.dart';

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
      elevation: 1,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Featured image at the top
            _buildImageHeader(),

            // Content section - Airbnb-style layout
            Padding(
              padding: const EdgeInsets.all(16),
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
        // Image container - optimized for consistent aspect ratio and display
        AspectRatio(
          aspectRatio: 16 / 9, // 16:9 ratio for consistent appearance
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
            ),
            child:
                widget.wish.photoUrls.isNotEmpty
                    ? ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(12),
                      ),
                      child: Image.network(
                        widget.wish.photoUrls.first,
                        fit:
                            BoxFit
                                .cover, // Cover ensures full container filling
                        alignment:
                            Alignment
                                .center, // Center crop for better subject focus
                        errorBuilder: (context, error, stackTrace) {
                          return Center(
                            child: Icon(
                              Icons.image_not_supported_outlined,
                              size: 40,
                              color: Colors.grey.shade400,
                            ),
                          );
                        },
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Center(
                            child: CircularProgressIndicator(
                              value:
                                  loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                      : null,
                              strokeWidth: 2,
                              color: Colors.grey.shade400,
                            ),
                          );
                        },
                      ),
                    )
                    : Center(
                      child: Icon(
                        Icons.panorama_outlined,
                        size: 40,
                        color: Colors.grey.shade400,
                      ),
                    ),
          ),
        ),

        // Favorite button - star icon (unified style)
        Positioned(
          top: 12,
          right: 12,
          child: GestureDetector(
            onTap: () {
              setState(() {
                _isFavorited = !_isFavorited;
              });
              widget.onFavoriteToggle?.call();
            },
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white,
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
                _isFavorited ? Icons.star : Icons.star_border,
                color: _isFavorited ? Colors.amber : Colors.grey.shade700,
                size: 18,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // User info row (Airbnb style - minimal, at bottom of card)
  Widget _buildUserInfo() {
    return Row(
      children: [
        // User Avatar (circular)
        _isLoading || _publisher == null || _publisher!.avatarUrl.isEmpty
            ? CircleAvatar(
              radius: 16,
              backgroundColor: Colors.grey.shade200,
              child: Icon(Icons.person, color: Colors.grey.shade500, size: 18),
            )
            : CircleAvatar(
              radius: 16,
              backgroundImage: NetworkImage(_publisher!.avatarUrl),
              backgroundColor: Colors.grey.shade200,
            ),
        const SizedBox(width: 8),

        // Username + verification
        Expanded(
          child: Row(
            children: [
              Flexible(
                child: Text(
                  _isLoading ||
                          _publisher == null ||
                          _publisher!.displayName.isEmpty
                      ? 'Wisher: ${widget.wish.userId.substring(0, min(8, widget.wish.userId.length))}...'
                      : _publisher!.displayName,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              const SizedBox(width: 4),

              // Simple verification dot
              if (_publisher != null)
                Icon(Icons.verified, size: 14, color: Colors.teal.shade700),

              // Pro badge if user has Pro membership
              if (_publisher != null && _isProMember)
                Container(
                  margin: const EdgeInsets.only(left: 4),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade700,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'PRO',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ),

        // Posted date (right aligned, subtle)
        Text(
          _formatPostDate(widget.wish.createdAt),
          style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
        ),
      ],
    );
  }

  Widget _buildContentSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title (Airbnb style - clean, larger)
        Text(
          widget.wish.title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            height: 1.3,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 8),

        // Budget (directly below title as requested)
        Row(
          children: [
            Icon(
              Icons.payments_outlined,
              size: 14,
              color: Colors.grey.shade700,
            ),
            const SizedBox(width: 4),
            Text(
              widget.wish.formattedBudget,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),

        // Location (below budget as requested)
        Row(
          children: [
            Icon(Icons.location_on, size: 14, color: Colors.grey.shade700),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                widget.wish.location.isNotEmpty
                    ? widget.wish.location
                    : 'Location not specified',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),

        // Date (below location)
        Row(
          children: [
            Icon(Icons.calendar_today, size: 14, color: Colors.grey.shade700),
            const SizedBox(width: 4),
            Text(
              _formatWishDate(widget.wish.preferredDate),
              style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Category tag (at the bottom as in Airbnb)
        if (widget.wish.categories.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 4),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              widget.wish.categories.first,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade700,
              ),
            ),
          ),

        const SizedBox(height: 12),

        // User info (at bottom as in Airbnb)
        _buildUserInfo(),
      ],
    );
  }

  Widget _buildThirdRow() {
    // We no longer need this row since we moved everything to the second row
    return const SizedBox.shrink();
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
