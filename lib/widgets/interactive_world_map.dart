import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart' as svg;

class InteractiveWorldMap extends StatefulWidget {
  final List<String> visitedCountries;
  final bool isEditable;
  final Function(String, bool) onCountryToggled;

  const InteractiveWorldMap({
    super.key,
    required this.visitedCountries,
    this.isEditable = false,
    required this.onCountryToggled,
  });

  @override
  State<InteractiveWorldMap> createState() => _InteractiveWorldMapState();
}

class _InteractiveWorldMapState extends State<InteractiveWorldMap> {
  // Map of country codes to country names
  final Map<String, String> _countryMap = {
    'US': 'United States',
    'CA': 'Canada',
    'MX': 'Mexico',
    'BR': 'Brazil',
    'AR': 'Argentina',
    'GB': 'United Kingdom',
    'FR': 'France',
    'DE': 'Germany',
    'IT': 'Italy',
    'ES': 'Spain',
    'RU': 'Russia',
    'CN': 'China',
    'JP': 'Japan',
    'IN': 'India',
    'AU': 'Australia',
    // Add more countries as needed
  };

  // Map of country codes to SVG path data
  final Map<String, String> _countryPaths = {
    // These are simplified path examples - in a real implementation, 
    // you would use actual country boundary paths
    'US': 'M 50,80 L 120,80 L 120,120 L 50,120 Z',
    'CA': 'M 50,40 L 120,40 L 120,75 L 50,75 Z',
    'MX': 'M 50,125 L 100,125 L 100,150 L 50,150 Z',
    'BR': 'M 120,150 L 160,150 L 160,200 L 120,200 Z',
    'AR': 'M 120,205 L 150,205 L 150,240 L 120,240 Z',
    'GB': 'M 200,60 L 210,60 L 210,70 L 200,70 Z',
    'FR': 'M 210,75 L 230,75 L 230,90 L 210,90 Z',
    'DE': 'M 230,60 L 250,60 L 250,75 L 230,75 Z',
    'IT': 'M 230,95 L 245,95 L 245,115 L 230,115 Z',
    'ES': 'M 190,95 L 215,95 L 215,115 L 190,115 Z',
    'RU': 'M 260,40 L 350,40 L 350,90 L 260,90 Z',
    'CN': 'M 320,100 L 370,100 L 370,140 L 320,140 Z',
    'JP': 'M 380,100 L 390,100 L 390,120 L 380,120 Z',
    'IN': 'M 300,140 L 330,140 L 330,170 L 300,170 Z',
    'AU': 'M 360,200 L 400,200 L 400,230 L 360,230 Z',
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 250,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Stack(
        children: [
          // Ocean background
          Container(
            color: Colors.blue.shade100,
          ),
          
          // Countries
          ..._countryPaths.entries.map((entry) {
            final countryCode = entry.key;
            final pathData = entry.value;
            final isVisited = widget.visitedCountries.contains(_countryMap[countryCode]);
            
            return GestureDetector(
              onTap: widget.isEditable 
                ? () => widget.onCountryToggled(_countryMap[countryCode]!, !isVisited)
                : null,
              child: CustomPaint(
                size: const Size(400, 250),
                painter: CountryPainter(
                  pathData: pathData,
                  isVisited: isVisited,
                  isEditable: widget.isEditable,
                ),
              ),
            );
          }).toList(),
          
          // Legend
          Positioned(
            bottom: 10,
            right: 10,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.8),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 16,
                    height: 16,
                    color: const Color(0xFF7153DF),
                  ),
                  const SizedBox(width: 4),
                  const Text('Visited'),
                  const SizedBox(width: 8),
                  Container(
                    width: 16,
                    height: 16,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(width: 4),
                  const Text('Not visited'),
                ],
              ),
            ),
          ),
          
          // Editable mode indicator
          if (widget.isEditable)
            Positioned(
              top: 10,
              left: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.edit, color: Colors.white, size: 14),
                    SizedBox(width: 4),
                    Text(
                      'Tap countries to toggle',
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class CountryPainter extends CustomPainter {
  final String pathData;
  final bool isVisited;
  final bool isEditable;
  
  CountryPainter({
    required this.pathData,
    required this.isVisited,
    this.isEditable = false,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final path = parseSvgPathData(pathData);
    
    final paint = Paint()
      ..color = isVisited ? const Color(0xFF7153DF) : Colors.grey.shade400
      ..style = PaintingStyle.fill;
    
    canvas.drawPath(path, paint);
    
    // Add border for editable mode
    if (isEditable) {
      final borderPaint = Paint()
        ..color = Colors.black.withOpacity(0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1;
      
      canvas.drawPath(path, borderPaint);
    }
  }
  
  @override
  bool shouldRepaint(covariant CountryPainter oldDelegate) {
    return oldDelegate.isVisited != isVisited || 
           oldDelegate.isEditable != isEditable;
  }
  
  // Simple SVG path parser
  Path parseSvgPathData(String pathData) {
    final path = Path();
    final commands = pathData.split(' ');
    
    for (int i = 0; i < commands.length; i++) {
      final command = commands[i];
      
      if (command == 'M') {
        final x = double.parse(commands[++i]);
        final y = double.parse(commands[++i]);
        path.moveTo(x, y);
      } else if (command == 'L') {
        final x = double.parse(commands[++i]);
        final y = double.parse(commands[++i]);
        path.lineTo(x, y);
      } else if (command == 'Z') {
        path.close();
      }
      // Add more path commands as needed (C, Q, etc.)
    }
    
    return path;
  }
}

// A more complete implementation using a proper SVG map
// with accurate country boundaries from a real SVG file
class WorldMapSvg extends StatefulWidget {
  final List<String> visitedCountries;
  final bool isEditable;
  final Function(String, bool) onCountryToggled;

  const WorldMapSvg({
    super.key,
    required this.visitedCountries,
    this.isEditable = false,
    required this.onCountryToggled,
  });

  @override
  State<WorldMapSvg> createState() => _WorldMapSvgState();
}

class _WorldMapSvgState extends State<WorldMapSvg> {
  // Map of country IDs to country names
  final Map<String, String> _countryMap = {
    'US': 'United States',
    'CA': 'Canada',
    'MX': 'Mexico',
    'BR': 'Brazil',
    'AR': 'Argentina',
    'GB': 'United Kingdom',
    'FR': 'France',
    'DE': 'Germany',
    'IT': 'Italy',
    'ES': 'Spain',
    'RU': 'Russia',
    'CN': 'China',
    'JP': 'Japan',
    'IN': 'India',
    'AU': 'Australia',
  };
  
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 250,
      decoration: BoxDecoration(
        color: Colors.blue.shade100, // Ocean color
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Stack(
        children: [
          // SVG World Map
          svg.SvgPicture.asset(
            'assets/svg/world_map_simplified.svg',
            width: double.infinity,
            height: double.infinity,
            // Use color filter for the base map
            colorFilter: ColorFilter.mode(
              Colors.grey.shade300, // Default country color
              BlendMode.srcIn,
            ),
          ),
          
          // Clickable country overlays
          ..._countryMap.entries.map((entry) {
            final countryId = entry.key;
            final countryName = entry.value;
            final isVisited = widget.visitedCountries.contains(countryName);
            
            return ClipPath(
              clipper: _CountryClipper(countryId),
              child: GestureDetector(
                onTap: widget.isEditable 
                  ? () => widget.onCountryToggled(countryName, !isVisited)
                  : null,
                child: Container(
                  color: isVisited 
                    ? const Color(0xFF7153DF) 
                    : Colors.grey.shade400,
                  width: double.infinity,
                  height: double.infinity,
                ),
              ),
            );
          }).toList(),
          
          // Legend
          Positioned(
            bottom: 10,
            right: 10,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.8),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 16,
                    height: 16,
                    color: const Color(0xFF7153DF),
                  ),
                  const SizedBox(width: 4),
                  const Text('Visited'),
                  const SizedBox(width: 8),
                  Container(
                    width: 16,
                    height: 16,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(width: 4),
                  const Text('Not visited'),
                ],
              ),
            ),
          ),
          
          // Edit mode indicator
          if (widget.isEditable)
            Positioned(
              top: 10,
              left: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.edit, color: Colors.white, size: 14),
                    SizedBox(width: 4),
                    Text(
                      'Tap countries to toggle',
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// Custom clipper for each country based on SVG path
class _CountryClipper extends CustomClipper<Path> {
  final String countryId;
  
  _CountryClipper(this.countryId);
  
  @override
  Path getClip(Size size) {
    // This would normally extract the path from the SVG
    // For now, we'll use simplified paths from our _countryPaths map
    final pathData = _getPathForCountry(countryId);
    return _parseSvgPathData(pathData, size);
  }
  
  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
  
  String _getPathForCountry(String countryId) {
    // Simplified paths - in a real implementation, these would be extracted from the SVG
    final Map<String, String> _countryPaths = {
      'US': 'M 50,80 L 120,80 L 120,120 L 50,120 Z',
      'CA': 'M 50,40 L 120,40 L 120,75 L 50,75 Z',
      'MX': 'M 50,125 L 100,125 L 100,150 L 50,150 Z',
      'BR': 'M 120,150 L 160,150 L 160,200 L 120,200 Z',
      'AR': 'M 120,205 L 150,205 L 150,240 L 120,240 Z',
      'GB': 'M 200,60 L 210,60 L 210,70 L 200,70 Z',
      'FR': 'M 210,75 L 230,75 L 230,90 L 210,90 Z',
      'DE': 'M 230,60 L 250,60 L 250,75 L 230,75 Z',
      'IT': 'M 230,95 L 245,95 L 245,115 L 230,115 Z',
      'ES': 'M 190,95 L 215,95 L 215,115 L 190,115 Z',
      'RU': 'M 260,40 L 350,40 L 350,90 L 260,90 Z',
      'CN': 'M 320,100 L 370,100 L 370,140 L 320,140 Z',
      'JP': 'M 380,100 L 390,100 L 390,120 L 380,120 Z',
      'IN': 'M 300,140 L 330,140 L 330,170 L 300,170 Z',
      'AU': 'M 360,200 L 400,200 L 400,230 L 360,230 Z',
    };
    
    return _countryPaths[countryId] ?? 'M 0,0 Z'; // Empty path if not found
  }
  
  // Simple SVG path parser
  Path _parseSvgPathData(String pathData, Size size) {
    final path = Path();
    final commands = pathData.split(' ');
    
    for (int i = 0; i < commands.length; i++) {
      final command = commands[i];
      
      if (command == 'M') {
        final x = double.parse(commands[++i]);
        final y = double.parse(commands[++i]);
        path.moveTo(x, y);
      } else if (command == 'L') {
        final x = double.parse(commands[++i]);
        final y = double.parse(commands[++i]);
        path.lineTo(x, y);
      } else if (command == 'Z') {
        path.close();
      }
      // Add more path commands as needed (C, Q, etc.)
    }
    
    return path;
  }
}

