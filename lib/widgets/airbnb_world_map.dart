import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart' as svg;
import 'dart:ui' as ui;

class AirbnbWorldMap extends StatefulWidget {
  final List<String> visitedCountries;
  final bool isEditable;
  final Function(String, bool)? onCountryToggled;
  final Color visitedColor;
  final Color unvisitedColor;
  final Color backgroundColor;

  const AirbnbWorldMap({
    super.key,
    required this.visitedCountries,
    this.isEditable = false,
    this.onCountryToggled,
    this.visitedColor = const Color(0xFF7153DF),
    this.unvisitedColor = const Color(0xFFE0E0E0),
    this.backgroundColor = const Color(0xFFF5F5F5),
  });

  @override
  State<AirbnbWorldMap> createState() => _AirbnbWorldMapState();
}

class _AirbnbWorldMapState extends State<AirbnbWorldMap>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  String? _hoveredCountry;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 300,
      decoration: BoxDecoration(
        color: widget.backgroundColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            // Background gradient
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    widget.backgroundColor,
                    widget.backgroundColor.withOpacity(0.95),
                  ],
                ),
              ),
            ),

            // World map
            FadeTransition(
              opacity: _fadeAnimation,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: CustomPaint(
                    size: const Size(double.infinity, 260),
                    painter: WorldMapPainter(
                      visitedCountries: widget.visitedCountries,
                      visitedColor: widget.visitedColor,
                      unvisitedColor: widget.unvisitedColor,
                      hoveredCountry: _hoveredCountry,
                    ),
                  ),
                ),
              ),
            ),

            // Interactive overlay
            if (widget.isEditable)
              Positioned.fill(child: _buildInteractiveOverlay()),

            // Legend
            Positioned(
              bottom: 16,
              left: 16,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: _buildLegend(),
              ),
            ),

            // Stats
            Positioned(
              top: 16,
              right: 16,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: _buildStats(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInteractiveOverlay() {
    return Container(); // Placeholder for interactive regions
  }

  Widget _buildLegend() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: widget.visitedColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            'Visited',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: widget.unvisitedColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            'Not visited',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStats() {
    final visitedCount = widget.visitedCountries.length;
    final percentage =
        (visitedCount / 195 * 100).round(); // 195 countries in the world

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$visitedCount countries',
            style: TextStyle(
              fontSize: 14,
              color: widget.visitedColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            '$percentage% explored',
            style: TextStyle(fontSize: 11, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}

class WorldMapPainter extends CustomPainter {
  final List<String> visitedCountries;
  final Color visitedColor;
  final Color unvisitedColor;
  final String? hoveredCountry;

  WorldMapPainter({
    required this.visitedCountries,
    required this.visitedColor,
    required this.unvisitedColor,
    this.hoveredCountry,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..style = PaintingStyle.fill
          ..strokeWidth = 0.5;

    // Draw simplified continents
    _drawContinent(
      canvas,
      size,
      _getNorthAmericaPath(size),
      'North America',
      paint,
    );
    _drawContinent(
      canvas,
      size,
      _getSouthAmericaPath(size),
      'South America',
      paint,
    );
    _drawContinent(canvas, size, _getEuropePath(size), 'Europe', paint);
    _drawContinent(canvas, size, _getAfricaPath(size), 'Africa', paint);
    _drawContinent(canvas, size, _getAsiaPath(size), 'Asia', paint);
    _drawContinent(canvas, size, _getOceaniaPath(size), 'Oceania', paint);
  }

  void _drawContinent(
    Canvas canvas,
    Size size,
    Path path,
    String name,
    Paint paint,
  ) {
    // Determine if any country in this continent is visited
    final isVisited = _isContinentVisited(name);

    // Fill color with opacity
    paint.color =
        isVisited
            ? visitedColor.withOpacity(0.8)
            : unvisitedColor.withOpacity(0.4);
    paint.style = PaintingStyle.fill;
    canvas.drawPath(path, paint);

    // Border
    paint.color =
        isVisited
            ? visitedColor.withOpacity(0.9)
            : unvisitedColor.withOpacity(0.6);
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 1.0;
    canvas.drawPath(path, paint);
  }

  bool _isContinentVisited(String continent) {
    // Map countries to continents
    final continentCountries = {
      'North America': ['United States', 'Canada', 'Mexico'],
      'South America': ['Brazil', 'Argentina'],
      'Europe': ['United Kingdom', 'France', 'Germany', 'Italy', 'Spain'],
      'Africa': [],
      'Asia': ['Russia', 'China', 'Japan', 'India'],
      'Oceania': ['Australia'],
    };

    final countries = continentCountries[continent] ?? [];
    return countries.any((country) => visitedCountries.contains(country));
  }

  Path _getNorthAmericaPath(Size size) {
    final path = Path();
    final w = size.width;
    final h = size.height;

    path.moveTo(w * 0.15, h * 0.25);
    path.quadraticBezierTo(w * 0.25, h * 0.15, w * 0.35, h * 0.2);
    path.lineTo(w * 0.3, h * 0.35);
    path.quadraticBezierTo(w * 0.25, h * 0.4, w * 0.2, h * 0.45);
    path.lineTo(w * 0.15, h * 0.4);
    path.close();

    return path;
  }

  Path _getSouthAmericaPath(Size size) {
    final path = Path();
    final w = size.width;
    final h = size.height;

    path.moveTo(w * 0.25, h * 0.5);
    path.quadraticBezierTo(w * 0.3, h * 0.55, w * 0.28, h * 0.7);
    path.lineTo(w * 0.25, h * 0.8);
    path.quadraticBezierTo(w * 0.22, h * 0.75, w * 0.2, h * 0.65);
    path.lineTo(w * 0.22, h * 0.55);
    path.close();

    return path;
  }

  Path _getEuropePath(Size size) {
    final path = Path();
    final w = size.width;
    final h = size.height;

    path.moveTo(w * 0.45, h * 0.25);
    path.lineTo(w * 0.52, h * 0.22);
    path.lineTo(w * 0.55, h * 0.28);
    path.lineTo(w * 0.5, h * 0.32);
    path.lineTo(w * 0.45, h * 0.3);
    path.close();

    return path;
  }

  Path _getAfricaPath(Size size) {
    final path = Path();
    final w = size.width;
    final h = size.height;

    path.moveTo(w * 0.48, h * 0.35);
    path.quadraticBezierTo(w * 0.52, h * 0.4, w * 0.5, h * 0.55);
    path.lineTo(w * 0.48, h * 0.65);
    path.quadraticBezierTo(w * 0.45, h * 0.6, w * 0.43, h * 0.5);
    path.lineTo(w * 0.45, h * 0.4);
    path.close();

    return path;
  }

  Path _getAsiaPath(Size size) {
    final path = Path();
    final w = size.width;
    final h = size.height;

    path.moveTo(w * 0.55, h * 0.2);
    path.lineTo(w * 0.75, h * 0.18);
    path.lineTo(w * 0.8, h * 0.25);
    path.lineTo(w * 0.78, h * 0.35);
    path.lineTo(w * 0.7, h * 0.4);
    path.lineTo(w * 0.6, h * 0.35);
    path.lineTo(w * 0.55, h * 0.3);
    path.close();

    return path;
  }

  Path _getOceaniaPath(Size size) {
    final path = Path();
    final w = size.width;
    final h = size.height;

    path.moveTo(w * 0.7, h * 0.6);
    path.lineTo(w * 0.8, h * 0.58);
    path.lineTo(w * 0.82, h * 0.65);
    path.lineTo(w * 0.75, h * 0.68);
    path.lineTo(w * 0.7, h * 0.65);
    path.close();

    return path;
  }

  @override
  bool shouldRepaint(covariant WorldMapPainter oldDelegate) {
    return oldDelegate.visitedCountries != visitedCountries ||
        oldDelegate.hoveredCountry != hoveredCountry;
  }
}
