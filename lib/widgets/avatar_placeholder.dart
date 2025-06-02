import 'package:flutter/material.dart';

class AvatarPlaceholder extends StatelessWidget {
  final double size;
  final Color backgroundColor;
  final Color iconColor;

  const AvatarPlaceholder({
    super.key,
    this.size = 60.0,
    this.backgroundColor = const Color(0xFFE0E0E0),
    this.iconColor = const Color(0xFF7153DF),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Icon(
          Icons.person,
          size: size * 0.6,
          color: iconColor,
        ),
      ),
    );
  }
}
