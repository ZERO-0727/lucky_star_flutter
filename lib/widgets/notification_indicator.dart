import 'package:flutter/material.dart';

/// A notification indicator widget that displays a blue dot when there are unread items
class NotificationIndicator extends StatelessWidget {
  final Widget child;
  final int unreadCount;
  final Color badgeColor;
  final double badgeSize;

  const NotificationIndicator({
    super.key,
    required this.child,
    this.unreadCount = 0,
    this.badgeColor = const Color(0xFF2196F3), // Blue color
    this.badgeSize = 8.0,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        if (unreadCount > 0)
          Positioned(
            right: -2,
            top: -2,
            child: Container(
              width: badgeSize,
              height: badgeSize,
              decoration: BoxDecoration(
                color: badgeColor,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.0),
              ),
            ),
          ),
      ],
    );
  }
}
