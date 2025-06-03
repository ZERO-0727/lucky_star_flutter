import 'package:flutter/material.dart';

class MyPublishedExperiencesPage extends StatefulWidget {
  const MyPublishedExperiencesPage({super.key});

  @override
  State<MyPublishedExperiencesPage> createState() => _MyPublishedExperiencesPageState();
}

class _MyPublishedExperiencesPageState extends State<MyPublishedExperiencesPage> {
  // Mock data for published experiences
  final List<Map<String, dynamic>> _experiences = [
    {
      'id': '1',
      'title': 'Tokyo Night Photography Tour',
      'description': 'Join me for a night photography tour around Tokyo\'s most iconic locations. I\'ll show you the best spots for night shots and help with camera settings.',
      'imageUrl': 'https://images.unsplash.com/photo-1533923156502-be31530547c4?w=500',
      'tags': ['Photography', 'Tokyo', 'Night'],
      'postedDate': 'Mar 10, 2025',
    },
    {
      'id': '2',
      'title': 'Traditional Tea Ceremony Experience',
      'description': 'Experience an authentic Japanese tea ceremony in a traditional setting. Learn about the history and cultural significance of this important tradition.',
      'imageUrl': 'https://images.unsplash.com/photo-1576091160399-112ba8d25d1d?w=500',
      'tags': ['Culture', 'Japan', 'Tea'],
      'postedDate': 'Feb 28, 2025',
    },
    {
      'id': '3',
      'title': 'Mount Fuji Sunrise Hike',
      'description': 'Guided hiking experience to see the sunrise from Mount Fuji. Transportation from Tokyo included, along with all necessary equipment.',
      'imageUrl': 'https://images.unsplash.com/photo-1570459027562-4a916cc6f2e7?w=500',
      'tags': ['Hiking', 'Nature', 'Adventure'],
      'postedDate': 'Feb 15, 2025',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Published Experiences'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _experiences.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _experiences.length,
              itemBuilder: (context, index) {
                final experience = _experiences[index];
                return _buildExperienceCard(experience);
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Navigate to add experience page
          Navigator.pushNamed(context, '/post-experience');
        },
        backgroundColor: const Color(0xFF7153DF),
        icon: const Icon(Icons.add),
        label: const Text('Add New Experience'),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.explore_off,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No experiences published yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your published experiences will appear here',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              // Navigate to add experience page
              Navigator.pushNamed(context, '/post-experience');
            },
            icon: const Icon(Icons.add),
            label: const Text('Add New Experience'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7153DF),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExperienceCard(Map<String, dynamic> experience) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Image.network(
              experience['imageUrl'],
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  height: 200,
                  color: Colors.grey[300],
                  child: const Center(
                    child: Icon(Icons.image, size: 50, color: Colors.grey),
                  ),
                );
              },
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Text(
                  experience['title'],
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                
                // Description
                Text(
                  experience['description'],
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 16),
                
                // Tags
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: (experience['tags'] as List<String>).map((tag) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F0FF),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFF7153DF).withOpacity(0.3)),
                      ),
                      child: Text(
                        tag,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF7153DF),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                
                // Posted date
                Row(
                  children: [
                    Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      'Posted: ${experience['postedDate']}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Action buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // Edit button
                    OutlinedButton.icon(
                      onPressed: () {
                        // Edit experience logic
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Edit experience ${experience['id']} coming soon')),
                        );
                      },
                      icon: const Icon(Icons.edit, size: 16),
                      label: const Text('Edit'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF7153DF),
                        side: const BorderSide(color: Color(0xFF7153DF)),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                    const SizedBox(width: 12),
                    
                    // Delete button
                    OutlinedButton.icon(
                      onPressed: () {
                        _showDeleteConfirmation(experience);
                      },
                      icon: const Icon(Icons.delete_outline, size: 16),
                      label: const Text('Delete'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(Map<String, dynamic> experience) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Experience'),
        content: Text('Are you sure you want to delete "${experience['title']}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _experiences.removeWhere((item) => item['id'] == experience['id']);
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Experience deleted successfully')),
              );
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
