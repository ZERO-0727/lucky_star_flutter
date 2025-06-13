import 'package:flutter/material.dart';
import '../models/wish_model.dart';
import '../wish_detail_screen.dart';

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

  @override
  void initState() {
    super.initState();
    _isFavorited = widget.isFavorited;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // First Row - User Info + Verification + Favorite
              _buildFirstRow(),
              const SizedBox(height: 12),

              // Second Row - Image + Title
              _buildSecondRow(),
              const SizedBox(height: 12),

              // Third Row - Tags & Budget
              _buildThirdRow(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFirstRow() {
    return Row(
      children: [
        // Left Side - User Avatar + Username
        Expanded(
          child: Row(
            children: [
              // User Avatar (circular)
              CircleAvatar(
                radius: 18,
                backgroundColor: Theme.of(context).primaryColor,
                child: const Icon(Icons.person, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 8),

              // Username (bold, primary color)
              Expanded(
                child: Text(
                  'Wisher: ${widget.wish.userId.substring(0, 8)}...',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),

        // Right Side - Certifications + Favorite
        Row(
          children: [
            // Web2 Certification Badge (green check icon, placeholder)
            Container(
              width: 24,
              height: 24,
              decoration: const BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check, color: Colors.white, size: 14),
            ),
            const SizedBox(width: 6),

            // Web3 Certification Badge (blue shield icon, placeholder)
            Container(
              width: 24,
              height: 24,
              decoration: const BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.shield, color: Colors.white, size: 14),
            ),
            const SizedBox(width: 6),

            // Favorite Button (star icon, toggles between filled and outline)
            GestureDetector(
              onTap: () {
                setState(() {
                  _isFavorited = !_isFavorited;
                });
                widget.onFavoriteToggle?.call();
              },
              child: Icon(
                _isFavorited ? Icons.star : Icons.star_border,
                color: _isFavorited ? Colors.amber : Colors.grey,
                size: 24,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSecondRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left Side - Thumbnail Image + Location + Date
        Column(
          children: [
            // Thumbnail Image (80×80 px)
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child:
                    widget.wish.photoUrls.isNotEmpty
                        ? Container(
                          color: Colors.white,
                          child: Image.network(
                            widget.wish.photoUrls.first,
                            width: 80,
                            height: 80,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.grey.shade200,
                                child: Icon(
                                  Icons.image,
                                  size: 40,
                                  color: Colors.grey.shade400,
                                ),
                              );
                            },
                          ),
                        )
                        : Icon(
                          Icons.image,
                          size: 40,
                          color: Colors.grey.shade400,
                        ),
              ),
            ),
            const SizedBox(height: 8),

            // Location and Date (vertically stacked, centered under image)
            SizedBox(
              width: 80,
              child: Column(
                children: [
                  // Location
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 12,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(
                          widget.wish.location.isNotEmpty
                              ? widget.wish.location
                              : 'Unknown',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey.shade600,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),

                  // Date
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 12,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(
                          _formatDate(widget.wish.preferredDate),
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey.shade600,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(width: 16),

        // Right Side - Wish Title
        Expanded(
          child: Text(
            widget.wish.title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildThirdRow() {
    return Row(
      children: [
        // Left Side - Category Tag
        if (widget.wish.categories.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Theme.of(context).primaryColor.withOpacity(0.3),
              ),
            ),
            child: Text(
              widget.wish.categories.first,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).primaryColor,
              ),
            ),
          ),

        const Spacer(),

        // Right Side - Budget Info
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.orange.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.orange.shade300),
          ),
          child: Text(
            widget.wish.formattedBudget,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.orange.shade700,
            ),
          ),
        ),
      ],
    );
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
}
