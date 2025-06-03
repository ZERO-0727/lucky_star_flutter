import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class InterestEditingPage extends StatefulWidget {
  final List<String> selectedInterests;
  final int maxSelections;
  
  const InterestEditingPage({
    super.key,
    this.selectedInterests = const [],
    this.maxSelections = 20,
  });

  @override
  State<InterestEditingPage> createState() => _InterestEditingPageState();
}

class _InterestEditingPageState extends State<InterestEditingPage> {
  late List<String> _selectedInterests;
  bool _showAll = false;
  final int _initialDisplayCount = 12;
  
  // Predefined list of interests with their icons
  final List<Map<String, dynamic>> _availableInterests = [
    {'name': 'Food', 'icon': Icons.restaurant},
    {'name': 'Outdoors', 'icon': Icons.landscape},
    {'name': 'Live music', 'icon': Icons.music_note},
    {'name': 'Museums', 'icon': Icons.museum},
    {'name': 'History', 'icon': Icons.history_edu},
    {'name': 'Wine', 'icon': Icons.wine_bar},
    {'name': 'Photography', 'icon': Icons.camera_alt},
    {'name': 'Animals', 'icon': Icons.pets},
    {'name': 'Architecture', 'icon': Icons.architecture},
    {'name': 'Water sports', 'icon': Icons.surfing},
    {'name': 'Live sports', 'icon': Icons.sports_basketball},
    {'name': 'Hiking', 'icon': Icons.hiking},
    {'name': 'Cooking', 'icon': Icons.soup_kitchen},
    {'name': 'Art', 'icon': Icons.palette},
    {'name': 'Shopping', 'icon': Icons.shopping_bag},
    {'name': 'Yoga', 'icon': Icons.self_improvement},
    {'name': 'Reading', 'icon': Icons.menu_book},
    {'name': 'Dancing', 'icon': Icons.nightlife},
    {'name': 'Gaming', 'icon': Icons.sports_esports},
    {'name': 'Movies', 'icon': Icons.movie},
    {'name': 'Technology', 'icon': Icons.devices},
    {'name': 'Fitness', 'icon': Icons.fitness_center},
    {'name': 'Coffee', 'icon': Icons.coffee},
    {'name': 'Gardening', 'icon': Icons.yard},
  ];

  @override
  void initState() {
    super.initState();
    // Initialize with the interests passed from MyPage
    _selectedInterests = List.from(widget.selectedInterests);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Edit Profile',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'What are you into?',
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Pick some interests you enjoy that you want to show on your profile.',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Interests',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildInterestsGrid(),
                    const SizedBox(height: 16),
                    if (_availableInterests.length > _initialDisplayCount)
                      Center(
                        child: TextButton(
                          onPressed: () {
                            setState(() {
                              _showAll = !_showAll;
                            });
                          },
                          child: Text(
                            _showAll ? 'Show less' : 'Show all',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              color: const Color(0xFF7153DF),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _buildInterestsGrid() {
    final displayedInterests = _showAll 
        ? _availableInterests 
        : _availableInterests.take(_initialDisplayCount).toList();

    return Wrap(
      spacing: 8,
      runSpacing: 12,
      children: displayedInterests.map((interest) {
        final isSelected = _selectedInterests.contains(interest['name']);
        
        return GestureDetector(
          onTap: () {
            setState(() {
              if (isSelected) {
                _selectedInterests.remove(interest['name']);
              } else {
                if (_selectedInterests.length < widget.maxSelections) {
                  _selectedInterests.add(interest['name']);
                } else {
                  // Show a snackbar if max selections reached
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'You can select up to ${widget.maxSelections} interests',
                        style: GoogleFonts.poppins(),
                      ),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              }
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFF7153DF).withOpacity(0.1) : Colors.grey[100],
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected ? const Color(0xFF7153DF) : Colors.grey[300]!,
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  interest['icon'],
                  size: 18,
                  color: isSelected ? const Color(0xFF7153DF) : Colors.grey[700],
                ),
                const SizedBox(width: 6),
                Text(
                  interest['name'],
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: isSelected ? const Color(0xFF7153DF) : Colors.grey[800],
                    fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '${_selectedInterests.length}/${widget.maxSelections} selected',
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: Colors.grey[700],
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              // Return the selected interests to the previous screen
              Navigator.pop(context, _selectedInterests);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7153DF),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Save',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w500,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
