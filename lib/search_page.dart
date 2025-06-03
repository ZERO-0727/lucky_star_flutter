import 'package:flutter/material.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  String? _selectedCategory;
  String? _selectedMapFilter;
  
  // Sample interest categories
  final List<Map<String, dynamic>> _interestCategories = [
    {
      'name': 'Language Exchange',
      'icon': Icons.language,
      'subcategories': ['English Practice', 'Japanese Learning', 'Spanish Conversation', 'French Study Group']
    },
    {
      'name': 'Meetup',
      'icon': Icons.people,
      'subcategories': ['Coffee Chat', 'Networking Event', 'International Mixer', 'Cultural Exchange']
    },
    {
      'name': 'Shopping Together',
      'icon': Icons.shopping_bag,
      'subcategories': ['Fashion Shopping', 'Grocery Shopping', 'Souvenir Hunting', 'Flea Market Trip']
    },
    {
      'name': 'Hiking',
      'icon': Icons.terrain,
      'subcategories': ['Mountain Trails', 'Nature Walks', 'Urban Hiking', 'Scenic Routes']
    },
    {
      'name': 'Food Tour',
      'icon': Icons.restaurant,
      'subcategories': ['Local Cuisine', 'Street Food', 'Fine Dining', 'Food Markets']
    },
    {
      'name': 'Photography',
      'icon': Icons.camera_alt,
      'subcategories': ['City Landscapes', 'Portrait Photography', 'Night Photography', 'Nature Shots']
    },
    {
      'name': 'Sightseeing',
      'icon': Icons.tour,
      'subcategories': ['Historical Sites', 'Museums', 'Landmarks', 'Hidden Gems']
    },
    {
      'name': 'Sports',
      'icon': Icons.sports_soccer,
      'subcategories': ['Soccer Games', 'Basketball', 'Tennis', 'Yoga Classes']
    },
    {
      'name': 'Art & Culture',
      'icon': Icons.palette,
      'subcategories': ['Gallery Visits', 'Traditional Crafts', 'Theater Shows', 'Music Events']
    },
    {
      'name': 'Nightlife',
      'icon': Icons.nightlife,
      'subcategories': ['Bar Hopping', 'Clubs', 'Live Music', 'Night Markets']
    },
  ];
  
  // Map filter options
  final List<Map<String, dynamic>> _mapFilters = [
    {'name': 'I\'m flexible', 'type': 'flexible'},
    {'name': 'Europe', 'type': 'continent'},
    {'name': 'Asia', 'type': 'continent'},
    {'name': 'North America', 'type': 'continent'},
    {'name': 'South America', 'type': 'continent'},
    {'name': 'Africa', 'type': 'continent'},
    {'name': 'Oceania', 'type': 'continent'},
    {'name': 'Japan', 'type': 'country'},
    {'name': 'Italy', 'type': 'country'},
    {'name': 'France', 'type': 'country'},
    {'name': 'United States', 'type': 'country'},
    {'name': 'Thailand', 'type': 'country'},
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Search input field
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search for experiences, wishes, or users...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[200],
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onChanged: (value) {
                // Handle search input
                setState(() {});
              },
            ),
          ),
          
          // Map filter section (optional)
          _buildMapFilterSection(),
          
          // Main content area with categories and details
          Expanded(
            child: Row(
              children: [
                // Left side - Categories list
                SizedBox(
                  width: 120,
                  child: _buildCategoriesList(),
                ),
                
                // Vertical divider
                VerticalDivider(
                  width: 1,
                  thickness: 1,
                  color: Colors.grey[300],
                ),
                
                // Right side - Subcategories or related content
                Expanded(
                  child: _buildSubcategoriesContent(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildMapFilterSection() {
    return Container(
      height: 100,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              'Where',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              itemCount: _mapFilters.length,
              itemBuilder: (context, index) {
                final filter = _mapFilters[index];
                final isSelected = filter['name'] == _selectedMapFilter;
                
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedMapFilter = isSelected ? null : filter['name'];
                      });
                    },
                    child: Column(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFF7153DF).withOpacity(0.2) : Colors.grey[200],
                            borderRadius: BorderRadius.circular(12),
                            border: isSelected
                                ? Border.all(color: const Color(0xFF7153DF), width: 2)
                                : null,
                          ),
                          child: Center(
                            child: filter['type'] == 'flexible'
                                ? const Icon(Icons.public, size: 28)
                                : filter['type'] == 'continent'
                                    ? const Icon(Icons.map, size: 28)
                                    : const Icon(Icons.location_on, size: 28),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          filter['name'],
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isSelected ? const Color(0xFF7153DF) : Colors.grey[800],
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildCategoriesList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _interestCategories.length,
      itemBuilder: (context, index) {
        final category = _interestCategories[index];
        final isSelected = category['name'] == _selectedCategory;
        
        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedCategory = category['name'];
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFF7153DF).withOpacity(0.1) : Colors.transparent,
              border: Border(
                left: BorderSide(
                  color: isSelected ? const Color(0xFF7153DF) : Colors.transparent,
                  width: 4,
                ),
              ),
            ),
            child: Column(
              children: [
                Icon(
                  category['icon'],
                  color: isSelected ? const Color(0xFF7153DF) : Colors.grey[600],
                  size: 24,
                ),
                const SizedBox(height: 4),
                Text(
                  category['name'],
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? const Color(0xFF7153DF) : Colors.grey[800],
                  ),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildSubcategoriesContent() {
    // If no category is selected, show a placeholder
    if (_selectedCategory == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.category_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Select a category',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Choose an interest category from the left',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }
    
    // Find the selected category and its subcategories
    final selectedCategoryData = _interestCategories.firstWhere(
      (category) => category['name'] == _selectedCategory,
      orElse: () => {'name': '', 'subcategories': []},
    );
    
    final List<String> subcategories = List<String>.from(selectedCategoryData['subcategories'] ?? []);
    
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _selectedCategory ?? '',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF7153DF),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Explore ${subcategories.length} related activities',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.2,
              ),
              itemCount: subcategories.length,
              itemBuilder: (context, index) {
                return _buildSubcategoryCard(subcategories[index]);
              },
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSubcategoryCard(String subcategory) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          // Handle subcategory selection
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Selected: $subcategory')),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _getIconForSubcategory(subcategory),
                size: 32,
                color: const Color(0xFF7153DF),
              ),
              const SizedBox(height: 8),
              Text(
                subcategory,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                'Tap to explore',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  IconData _getIconForSubcategory(String subcategory) {
    // Map subcategories to appropriate icons
    if (subcategory.contains('English') || subcategory.contains('Japanese') || 
        subcategory.contains('Spanish') || subcategory.contains('French')) {
      return Icons.translate;
    } else if (subcategory.contains('Coffee') || subcategory.contains('Food') || 
               subcategory.contains('Dining') || subcategory.contains('Cuisine')) {
      return Icons.restaurant;
    } else if (subcategory.contains('Shopping') || subcategory.contains('Market')) {
      return Icons.shopping_bag;
    } else if (subcategory.contains('Hiking') || subcategory.contains('Mountain') || 
               subcategory.contains('Nature') || subcategory.contains('Trail')) {
      return Icons.terrain;
    } else if (subcategory.contains('Photography') || subcategory.contains('Camera') || 
               subcategory.contains('Photo')) {
      return Icons.camera_alt;
    } else if (subcategory.contains('Museum') || subcategory.contains('Gallery') || 
               subcategory.contains('Art')) {
      return Icons.museum;
    } else if (subcategory.contains('Night') || subcategory.contains('Bar') || 
               subcategory.contains('Club')) {
      return Icons.nightlife;
    } else if (subcategory.contains('Sport') || subcategory.contains('Soccer') || 
               subcategory.contains('Basketball') || subcategory.contains('Tennis')) {
      return Icons.sports;
    }
    
    // Default icon
    return Icons.star;
  }
}
