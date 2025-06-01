import 'package:flutter/material.dart';

class WishWallScreen extends StatefulWidget {
  const WishWallScreen({super.key});

  @override
  State<WishWallScreen> createState() => _WishWallScreenState();
}

class _WishWallScreenState extends State<WishWallScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _selectedDateFilter;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Wish Wall'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [Tab(text: 'Wish Wall'), Tab(text: 'Share Experience')],
        ),
      ),
      body: Column(
        children: [
          // Date filter selector
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: DropdownButtonFormField<String>(
              value: _selectedDateFilter,
              decoration: const InputDecoration(
                labelText: 'Filter by Date',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'today', child: Text('Today')),
                DropdownMenuItem(value: 'this_week', child: Text('This Week')),
                DropdownMenuItem(
                  value: 'this_month',
                  child: Text('This Month'),
                ),
                DropdownMenuItem(value: 'all', child: Text('All Time')),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedDateFilter = value;
                });
              },
            ),
          ),

          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [_buildWishList(), _buildShareExperience()],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showOptions,
        backgroundColor: const Color(0xFF7153DF),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
    void _showOptions() {
      showModalBottomSheet(
        context: context,
        builder: (BuildContext context) {
          return SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.explore),
                  title: const Text('Share Experience'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PostExperienceScreen(),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.star),
                  title: const Text('Make a Wish'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const RequestExperienceScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        },
      );
    }
  }

  Widget _buildWishList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 8, // Dummy data
      itemBuilder: (context, index) => _buildWishCard(index),
    );
  }

  Widget _buildShareExperience() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 8, // Dummy data
      itemBuilder: (context, index) => _buildExperienceCard(index),
    );
  }

  Widget _buildWishCard(int index) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image and title
          Stack(
            children: [
              Container(
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.blueGrey[100],
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                ),
                child: const Center(
                  child: Icon(Icons.image, size: 60, color: Colors.grey),
                ),
              ),
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.verified, size: 16, color: Colors.white),
                      SizedBox(width: 4),
                      Text(
                        'Secure',
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title and bookmark
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Wish $index',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Icon(Icons.bookmark_border, color: Colors.grey),
                  ],
                ),
                const SizedBox(height: 8),

                // User info
                Row(
                  children: [
                    const CircleAvatar(
                      radius: 16,
                      backgroundColor: Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    Text('User $index', style: const TextStyle(fontSize: 14)),
                  ],
                ),
                const SizedBox(height: 8),

                // Tags
                const Wrap(
                  spacing: 8,
                  children: [
                    Chip(label: Text('Tag1', style: TextStyle(fontSize: 12))),
                    Chip(label: Text('Tag2', style: TextStyle(fontSize: 12))),
                  ],
                ),
                const SizedBox(height: 8),

                // Location and time
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    const Text('Location', style: TextStyle(fontSize: 12)),
                    const Spacer(),
                    const Icon(Icons.access_time, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      '${index + 1}h ago',
                      style: const TextStyle(fontSize: 12),
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

  Widget _buildExperienceCard(int index) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image and favorite star
          Stack(
            children: [
              Container(
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.blueGrey[100],
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                ),
                child: const Center(
                  child: Icon(Icons.image, size: 60, color: Colors.grey),
                ),
              ),
              Positioned(
                top: 12,
                right: 12,
                child: Icon(
                  Icons.star,
                  size: 24,
                  color: index % 2 == 0 ? Colors.red : Colors.grey,
                ),
              ),
            ],
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title and bookmark
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Experience $index',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Icon(Icons.bookmark_border, color: Colors.grey),
                  ],
                ),
                const SizedBox(height: 8),

                // User info
                Row(
                  children: [
                    const CircleAvatar(
                      radius: 16,
                      backgroundColor: Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    Text('User $index', style: const TextStyle(fontSize: 14)),
                  ],
                ),
                const SizedBox(height: 8),

                // Tags
                const Wrap(
                  spacing: 8,
                  children: [
                    Chip(
                      label: Text('Experience', style: TextStyle(fontSize: 12)),
                    ),
                    Chip(label: Text('Fun', style: TextStyle(fontSize: 12))),
                  ],
                ),
                const SizedBox(height: 8),

                // Location and time
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    const Text('Central Park', style: TextStyle(fontSize: 12)),
                    const Spacer(),
                    const Icon(Icons.access_time, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      'Jun ${index + 10}',
                      style: const TextStyle(fontSize: 12),
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
}
