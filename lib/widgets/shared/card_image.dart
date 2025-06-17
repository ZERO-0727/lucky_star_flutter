import 'package:flutter/material.dart';

/// A unified image component for displaying images in cards (WishCard, ExperienceCard, etc.)
/// Ensures consistent image display behavior across the app
class CardImage extends StatelessWidget {
  final List<String> photoUrls;
  final double height;
  final Color backgroundColor;
  final EdgeInsets padding;
  final BoxFit fit;
  final String emptyStateIcon;
  final String emptyStateText;
  final Color? progressIndicatorColor;

  const CardImage({
    super.key,
    required this.photoUrls,
    this.height = 180.0,
    this.backgroundColor = const Color(0xFFF5F5F5),
    this.padding = const EdgeInsets.all(8.0),
    this.fit = BoxFit.contain,
    this.emptyStateIcon = 'panorama',
    this.emptyStateText = 'No image available',
    this.progressIndicatorColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = progressIndicatorColor ?? theme.primaryColor;

    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child:
          photoUrls.isNotEmpty
              ? Padding(
                padding: padding,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    photoUrls.first,
                    fit: fit,
                    alignment: Alignment.center,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;

                      return Stack(
                        alignment: Alignment.center,
                        children: [
                          if (loadingProgress.expectedTotalBytes != null)
                            CircularProgressIndicator(
                              value:
                                  loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!,
                              strokeWidth: 2,
                              color: primaryColor.withOpacity(0.5),
                              backgroundColor: Colors.grey.shade300,
                            ),
                        ],
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.image_not_supported_outlined,
                              size: 40,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "Image could not be loaded",
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              )
              : Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _getIconData(emptyStateIcon),
                      size: 50,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      emptyStateText,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
    );
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'star':
        return Icons.star_border_rounded;
      case 'panorama':
        return Icons.panorama_outlined;
      default:
        return Icons.image_outlined;
    }
  }
}
