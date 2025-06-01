import 'package:flutter/material.dart';

class UserPlazaScreen extends StatefulWidget {
  const UserPlazaScreen({super.key});

  @override
  State<UserPlazaScreen> createState() => _UserPlazaScreenState();
}

class _UserPlazaScreenState extends State<UserPlazaScreen> {
  String _selectedFilter1 = 'All';
  String _selectedFilter2 = 'Open to Exchange';

  final List<String> _filterOptions1 = [
    'All',
    'Verified',
    'Pro Users',
    'Recent',
  ];
  final List<String> _filterOptions2 = [
    'Open to Exchange',
    'By Request Only',
    'Unavailable',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('User Plaza')),
      body: Column(
        children: [
          // Top filter row 1
          SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _filterOptions1.length,
              itemBuilder: (context, index) {
                final option = _filterOptions1[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 8,
                  ),
                  child: ChoiceChip(
                    label: Text(option),
                    selected: _selectedFilter1 == option,
                    onSelected: (selected) {
                      setState(() {
                        _selectedFilter1 = option;
                      });
                    },
                  ),
                );
              },
            ),
          ),

          // Top filter row 2
          SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _filterOptions2.length,
              itemBuilder: (context, index) {
                final option = _filterOptions2[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 8,
                  ),
                  child: ChoiceChip(
                    label: Text(option),
                    selected: _selectedFilter2 == option,
                    onSelected: (selected) {
                      setState(() {
                        _selectedFilter2 = option;
                      });
                    },
                  ),
                );
              },
            ),
          ),

          // Search bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search users...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
          ),

          // User cards
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: 10, // Dummy data
              itemBuilder: (context, index) => _buildUserCard(index),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserCard(int index) {
    // Generate coffee-style background colors
    final bgColors = [
      const Color(0xFFF8E9D7), // Light beige
      const Color(0xFFE6D3C4), // Tan
      const Color(0xFFD7C1A9), // Medium brown
    ];

    return Card(
      elevation: 3,
      color: bgColors[index % bgColors.length],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row: Avatar, name, pro badge, availability
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.grey,
                  child: Icon(Icons.person, size: 30, color: Colors.white),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'User $index',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (index % 3 == 0) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF7153DF),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Row(
                                children: [
                                  Icon(
                                    Icons.diamond,
                                    size: 14,
                                    color: Colors.white,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    'Pro',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.location_on, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            'Location $index',
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color:
                        index % 3 == 0
                            ? Colors.green
                            : (index % 3 == 1 ? Colors.orange : Colors.red),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    index % 3 == 0
                        ? 'Available'
                        : (index % 3 == 1 ? 'Limited' : 'Unavailable'),
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Stats row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatColumn('Experiences', '${index * 3 + 5}'),
                _buildStatColumn('Wishes Fulfilled', '${index * 2 + 2}'),
                _buildStatColumn('Response Rate', '${90 - index}%'),
              ],
            ),
            const SizedBox(height: 16),

            // Tags
            const Wrap(
              spacing: 8,
              children: [
                Chip(label: Text('English')),
                Chip(label: Text('Japanese')),
                Chip(label: Text('Photography')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumn(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
