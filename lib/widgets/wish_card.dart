import 'package:flutter/material.dart';
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

  @override
  void didUpdateWidget(WishCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update local state when parent state changes
    if (oldWidget.isFavorited != widget.isFavorited) {
      setState(() {
        _isFavorited = widget.isFavorited;
      });
    }
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

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
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
        child: Padding(
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

              // Row 3: Title + Row 4: Description + Row 5: Location/Budget + Optional image
              _buildMainContent(),
            ],
          ),
        ),
      ),
    );
  }

  // Row 1: Small avatar + username + verified + "・" + date
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
              ? 'Anonymous'
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
          _formatTimeAgo(widget.wish.createdAt),
          style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
        ),

        const Spacer(),

        // Favorite button (moved to top right)
        InkWell(
          onTap: () {
            // Don't update local state here - let parent handle it
            widget.onFavoriteToggle?.call();
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Icon(
              widget.isFavorited ? Icons.star : Icons.star_border,
              color: widget.isFavorited ? Colors.amber : Colors.grey.shade400,
              size: 20,
            ),
          ),
        ),
      ],
    );
  }

  // Row 2: Category chip
  Widget _buildCategoryChip() {
    if (widget.wish.categories.isEmpty) {
      return const SizedBox.shrink();
    }

    final category = widget.wish.categories.first; // Show only first category

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

  // Main content area with title, description, location/budget, and optional image
  Widget _buildMainContent() {
    final bool hasImages = widget.wish.photoUrls.isNotEmpty;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left side: text content
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title (max 50 characters)
              Text(
                widget.wish.title.length > 50
                    ? '${widget.wish.title.substring(0, 50)}...'
                    : widget.wish.title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  height: 1.2,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 6),

              // Description (max 4 lines)
              if (widget.wish.description.isNotEmpty)
                Text(
                  widget.wish.description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                    height: 1.3,
                  ),
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                ),

              const SizedBox(height: 8),

              // Location and budget row
              Row(
                children: [
                  // Location
                  if (widget.wish.location.isNotEmpty) ...[
                    Icon(
                      Icons.location_on_outlined,
                      size: 14,
                      color: Colors.grey.shade500,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        widget.wish.location,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],

                  const Spacer(),

                  // Budget (if available)
                  if (widget.wish.budget != null && widget.wish.budget! > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green.shade100),
                      ),
                      child: Text(
                        widget.wish.formattedBudget,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.green.shade700,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),

        // Right side: optional image
        if (hasImages) ...[
          const SizedBox(width: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: 80,
              height: 80,
              child: Image.network(
                widget.wish.photoUrls.first,
                width: 80,
                height: 80,
                fit:
                    BoxFit.cover, // This will crop the image to fill the square
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 80,
                    height: 80,
                    color: Colors.grey.shade300,
                    child: const Icon(
                      Icons.broken_image,
                      size: 30,
                      color: Colors.grey,
                    ),
                  );
                },
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    width: 80,
                    height: 80,
                    color: Colors.grey.shade100,
                    child: Center(
                      child: CircularProgressIndicator(
                        value:
                            loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                : null,
                        strokeWidth: 2,
                        color: Colors.blue.shade300,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
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
