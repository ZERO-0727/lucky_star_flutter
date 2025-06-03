import 'package:flutter/material.dart';

class UserDetailPage extends StatefulWidget {
  final String userId;
  final String displayName;
  final String introduction;
  final bool isWorldcoinVerified;
  final bool isGovernmentIdVerified;
  final int referenceCount;
  final List<String> interests;
  final int experiencesCount;
  final int wishesFulfilledCount;
  final List<String> visitedCountries;
  final bool hasPublishedExperience;

  const UserDetailPage({
    super.key,
    required this.userId,
    this.displayName = 'User Name',
    this.introduction = 'Hello World',
    this.isWorldcoinVerified = false,
    this.isGovernmentIdVerified = false,
    this.referenceCount = 0,
    this.interests = const ['Hiking', 'Photography', 'Food'],
    this.experiencesCount = 0,
    this.wishesFulfilledCount = 0,
    this.visitedCountries = const ['Japan', 'United States', 'France'],
    this.hasPublishedExperience = false,
  });

  @override
  State<UserDetailPage> createState() => _UserDetailPageState();
}

class _UserDetailPageState extends State<UserDetailPage> {
  
  // Countries the user has visited (will be initialized in initState)
  late List<String> _visitedCountries;
  
  // Flag to track if the map is in edit mode
  bool _isEditingMap = false;
  
  // Flag to track if the user has sent a message
  bool _hasMessageSent = false;

  @override
  void initState() {
    super.initState();
    _visitedCountries = List.from(widget.visitedCountries);
  }

  void _toggleCountry(String country) {
    if (!_isEditingMap) return;
    
    setState(() {
      if (_visitedCountries.contains(country)) {
        _visitedCountries.remove(country);
      } else {
        _visitedCountries.add(country);
      }
    });
  }

  void _toggleEditMode() {
    setState(() {
      _isEditingMap = !_isEditingMap;
    });
  }

  void _sendMessage() {
    setState(() {
      _hasMessageSent = true;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Message sent! You can send another message after they reply.'),
      ),
    );
  }

  void _joinExperience() {
    if (widget.experiencesCount > 1) {
      // Navigate to experience selection screen
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Redirecting to experience selection...'),
        ),
      );
    } else {
      // Automatically join the single experience
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You have joined this experience!'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // No AppBar - we'll use a custom header instead
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // Main scrollable content
          SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 80), // Add padding for bottom buttons
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Cover image and profile header
                _buildProfileHeader(),
                
                // Introduction
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    widget.introduction,
                    style: const TextStyle(
                      fontSize: 18,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
                
                // Verification Badges
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    children: [
                      const Text(
                        'Verification: ',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (widget.isWorldcoinVerified)
                        Chip(
                          label: const Text('Worldcoin'),
                          avatar: const Icon(Icons.verified_user, size: 16),
                          backgroundColor: Colors.green.shade100,
                        ),
                      const SizedBox(width: 8),
                      if (widget.isGovernmentIdVerified)
                        Chip(
                          label: const Text('Government ID'),
                          avatar: const Icon(Icons.badge, size: 16),
                          backgroundColor: Colors.blue.shade100,
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                
                // Reference Count
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    children: [
                      const Icon(Icons.people, color: Colors.grey),
                      const SizedBox(width: 8),
                      Text(
                        '${widget.referenceCount} References',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                
                // Interests
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Interests',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: widget.interests.map((interest) {
                          return Chip(
                            label: Text(interest),
                            backgroundColor: const Color(0xFF7153DF).withOpacity(0.2),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                
                // Statistics Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Statistics',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStatItem(
                            Icons.explore,
                            widget.experiencesCount.toString(),
                            'Experiences',
                          ),
                          _buildStatItem(
                            Icons.star,
                            widget.wishesFulfilledCount.toString(),
                            'Wishes Fulfilled',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                
                // Countries Visited Map
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Countries Visited',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: _toggleEditMode,
                            icon: Icon(_isEditingMap ? Icons.check : Icons.edit),
                            label: Text(_isEditingMap ? 'Done' : 'Edit'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _isEditingMap 
                                  ? Colors.green 
                                  : const Color(0xFF7153DF),
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      // Simple visual representation of a world map with countries
                      Container(
                        height: 200,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: _buildCountriesGrid(),
                      ),
                      if (_isEditingMap)
                        const Padding(
                          padding: EdgeInsets.only(top: 8.0),
                          child: Text(
                            'Tap on a country to mark it as visited/not visited',
                            style: TextStyle(
                              fontStyle: FontStyle.italic,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 100), // Extra space for bottom buttons
              ],
            ),
          ),
          
          // Fixed bottom buttons
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Row(
                children: [
                  if (widget.hasPublishedExperience)
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _joinExperience,
                        icon: const Icon(Icons.group_add),
                        label: const Text('Join This Experience'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF7153DF),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  if (widget.hasPublishedExperience)
                    const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _hasMessageSent ? null : _sendMessage,
                      icon: const Icon(Icons.message),
                      label: const Text('Send Message'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF7153DF),
                        side: const BorderSide(color: Color(0xFF7153DF)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFF7153DF), size: 32),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildCountriesGrid() {
    // A more visually appealing representation of visited countries
    return Column(
      children: [
        // World map image with overlay
        Container(
          height: 180,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Stack(
              children: [
                // World map background
                Image.network(
                  'https://images.unsplash.com/photo-1526778548025-fa2f459cd5ce?ixlib=rb-4.0.3&ixid=MnwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8&auto=format&fit=crop&w=1170&q=80',
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.blue.shade100,
                      child: const Center(
                        child: Icon(Icons.public, size: 80, color: Colors.blue),
                      ),
                    );
                  },
                ),
                
                // Semi-transparent overlay
                Container(
                  color: const Color(0xFF7153DF).withOpacity(0.2),
                ),
                
                // Edit mode indicator
                if (_isEditingMap)
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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
                            'Edit Mode',
                            style: TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // List of visited countries
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _visitedCountries.map((country) {
            return GestureDetector(
              onTap: _isEditingMap ? () => _toggleCountry(country) : null,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF7153DF),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: _isEditingMap ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ] : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.place, color: Colors.white, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      country,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (_isEditingMap)
                      const Padding(
                        padding: EdgeInsets.only(left: 4),
                        child: Icon(Icons.close, color: Colors.white, size: 16),
                      ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        
        // Add country button in edit mode
        if (_isEditingMap)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: OutlinedButton.icon(
              onPressed: () {
                // Show a dialog to add a new country
                showDialog(
                  context: context,
                  builder: (context) => _buildAddCountryDialog(),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('Add Country'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF7153DF),
                side: const BorderSide(color: Color(0xFF7153DF)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
            ),
          ),
      ],
    );
  }
  
  // Dialog to add a new country
  Widget _buildAddCountryDialog() {
    final TextEditingController controller = TextEditingController();
    final List<String> commonCountries = [
      'United States', 'Canada', 'Mexico', 'Brazil', 'Argentina',
      'United Kingdom', 'France', 'Germany', 'Italy', 'Spain',
      'Russia', 'China', 'Japan', 'South Korea', 'India',
      'Australia', 'New Zealand', 'Thailand', 'Egypt', 'South Africa'
    ]..sort();
    
    return AlertDialog(
      title: const Text('Add a Country'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Country Name',
                hintText: 'Enter a country name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Or select from common countries:'),
            const SizedBox(height: 8),
            SizedBox(
              height: 200,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: commonCountries.length,
                itemBuilder: (context, index) {
                  final country = commonCountries[index];
                  final isAlreadyVisited = _visitedCountries.contains(country);
                  
                  return ListTile(
                    title: Text(country),
                    trailing: isAlreadyVisited
                        ? const Icon(Icons.check_circle, color: Colors.green)
                        : null,
                    enabled: !isAlreadyVisited,
                    onTap: isAlreadyVisited
                        ? null
                        : () {
                            setState(() {
                              _visitedCountries.add(country);
                            });
                            Navigator.pop(context);
                          },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            final countryName = controller.text.trim();
            if (countryName.isNotEmpty && !_visitedCountries.contains(countryName)) {
              setState(() {
                _visitedCountries.add(countryName);
              });
            }
            Navigator.pop(context);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF7153DF),
          ),
          child: const Text('Add'),
        ),
      ],
    );
  }
  
  // Build the profile header with large cover image
  Widget _buildProfileHeader() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Cover image with gradient overlay
        Container(
          height: 220,
          width: double.infinity,
          decoration: BoxDecoration(
            // Fallback gradient in case image fails to load
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.purple.shade700,
                Colors.purple.shade500,
              ],
            ),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Background image
              Image.network(
                'https://images.unsplash.com/photo-1488646953014-85cb44e25828?ixlib=rb-4.0.3&ixid=MnwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8&auto=format&fit=crop&w=1035&q=80',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  // Return empty container if image fails to load
                  // Gradient will still show
                  return Container();
                },
              ),
              // Gradient overlay for better text visibility
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.1),
                      Colors.black.withOpacity(0.5),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        
        // Back button
        Positioned(
          top: 40,
          left: 16,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
        
        // User name and verification badges
        Positioned(
          bottom: 20,
          left: 20,
          right: 20,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // User avatar
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: ClipOval(
                  child: Image.network(
                    'https://randomuser.me/api/portraits/women/44.jpg',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(Icons.person, size: 50, color: Colors.grey);
                    },
                  ),
                ),
              ),
              const SizedBox(width: 16),
              
              // User name and verification badges
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // User name
                    Text(
                      widget.displayName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        shadows: [
                          Shadow(
                            offset: Offset(1.0, 1.0),
                            blurRadius: 3.0,
                            color: Colors.black54,
                          ),
                        ],
                      ),
                    ),
                    
                    // Verification badges in a row
                    Row(
                      children: [
                        if (widget.isWorldcoinVerified)
                          Container(
                            margin: const EdgeInsets.only(right: 8, top: 4),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.verified_user, color: Colors.white, size: 14),
                                SizedBox(width: 4),
                                Text(
                                  'Worldcoin',
                                  style: TextStyle(color: Colors.white, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        if (widget.isGovernmentIdVerified)
                          Container(
                            margin: const EdgeInsets.only(top: 4),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.badge, color: Colors.white, size: 14),
                                SizedBox(width: 4),
                                Text(
                                  'ID Verified',
                                  style: TextStyle(color: Colors.white, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
