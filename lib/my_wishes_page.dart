import 'package:flutter/material.dart';

class MyWishesPage extends StatefulWidget {
  const MyWishesPage({super.key});

  @override
  State<MyWishesPage> createState() => _MyWishesPageState();
}

class _MyWishesPageState extends State<MyWishesPage> {
  // Mock data for wishes
  final List<Map<String, dynamic>> _wishes = [
    {
      'id': '1',
      'title': 'Local Food Tour in Kyoto',
      'description': 'Looking for someone to show me the best local food spots in Kyoto, especially places that tourists don\'t usually find.',
      'imageUrl': 'https://images.unsplash.com/photo-1545079968-1feb95494244?w=500',
      'createdDate': 'Jan 15, 2025',
    },
    {
      'id': '2',
      'title': 'Photography Partner for Mt. Fuji',
      'description': 'Planning a trip to Mt. Fuji next month and looking for a photography enthusiast to join me. Would love to capture sunrise views.',
      'imageUrl': 'https://images.unsplash.com/photo-1570459027562-4a916cc6f2e7?w=500',
      'createdDate': 'Feb 3, 2025',
    },
    {
      'id': '3',
      'title': 'Language Exchange - English/Japanese',
      'description': 'Native English speaker looking to practice Japanese conversation. Happy to help with English in return. Preferably in Tokyo area.',
      'imageUrl': 'https://images.unsplash.com/photo-1456513080510-7bf3a84b82f8?w=500',
      'createdDate': 'Feb 20, 2025',
    },
    {
      'id': '4',
      'title': 'Hiking Partner for Hakone',
      'description': 'Planning a weekend hiking trip to Hakone. Looking for experienced hikers who know the area well.',
      'imageUrl': 'https://images.unsplash.com/photo-1551632811-561732d1e306?w=500',
      'createdDate': 'Mar 5, 2025',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Wishes'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _wishes.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _wishes.length,
              itemBuilder: (context, index) {
                final wish = _wishes[index];
                return _buildWishCard(wish);
              },
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.star_border,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No wishes yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your posted wishes will appear here',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              // Navigate to create wish page
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Create wish feature coming soon')),
              );
            },
            icon: const Icon(Icons.add),
            label: const Text('Create a Wish'),
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

  Widget _buildWishCard(Map<String, dynamic> wish) {
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
              wish['imageUrl'],
              height: 180,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  height: 180,
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
                  wish['title'],
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                
                // Description
                Text(
                  wish['description'],
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 16),
                
                // Created date
                Row(
                  children: [
                    Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      'Created: ${wish['createdDate']}',
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
                        // Edit wish logic
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Edit wish ${wish['id']} coming soon')),
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
                        _showDeleteConfirmation(wish);
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

  void _showDeleteConfirmation(Map<String, dynamic> wish) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Wish'),
        content: Text('Are you sure you want to delete "${wish['title']}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _wishes.removeWhere((item) => item['id'] == wish['id']);
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Wish deleted successfully')),
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
