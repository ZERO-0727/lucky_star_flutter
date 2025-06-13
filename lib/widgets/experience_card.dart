import 'package:flutter/material.dart';
import '../models/experience_model.dart';
import '../experience_detail_screen.dart';

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

class _ExperienceCardState extends State<ExperienceCard> {
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
                  (context) => ExperienceDetailScreen(
                    experienceId: widget.experience.experienceId,
                    experience: widget.experience,
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

              // Second Row - Image + Title + Tags
              _buildSecondRow(),
              const SizedBox(height: 12),

              // Third Row - Available Slots (tags moved to second row)
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
                  'Host: ${widget.experience.userId.substring(0, 8)}...',
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
                    widget.experience.photoUrls.isNotEmpty
                        ? Container(
                          color: Colors.white,
                          child: Image.network(
                            widget.experience.photoUrls.first,
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
                        size: 14,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(
                          widget.experience.location ?? 'Unknown',
                          style: TextStyle(
                            fontSize: 12,
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
                        size: 14,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(
                          _formatDate(widget.experience.createdAt),
                          style: TextStyle(
                            fontSize: 12,
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

        // Right Side - Experience Title + Tags
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Experience Title
              Text(
                widget.experience.title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),

              // Category Tag (moved from third row)
              if (widget.experience.tags.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Theme.of(context).primaryColor.withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    widget.experience.tags.first,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildThirdRow() {
    return Row(
      children: [
        const Spacer(),

        // Right Side - Available Slots (tags moved to second row)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.green.shade300),
          ),
          child: Text(
            '${widget.experience.availableSlots - widget.experience.currentParticipants} slots',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.green.shade700,
            ),
          ),
        ),
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
}
