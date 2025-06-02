import 'package:flutter/material.dart';
import 'plaza_post_detail_screen.dart';
import 'create_plaza_post_page.dart';

class PlazaFeedScreen extends StatefulWidget {
  const PlazaFeedScreen({super.key});

  @override
  State<PlazaFeedScreen> createState() => _PlazaFeedScreenState();
}

class _PlazaFeedScreenState extends State<PlazaFeedScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isGridView = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Plaza Feed'),
        actions: [
          IconButton(
            icon: Icon(_isGridView ? Icons.view_list : Icons.grid_view),
            onPressed: () {
              setState(() {
                _isGridView = !_isGridView;
              });
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'All Posts'),
            Tab(text: 'Trending'),
            Tab(text: 'Recommended'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreatePlazaPostPage()),
          );
        },
        backgroundColor: const Color(0xFF7153DF),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildFeedContent(),
          _buildFeedContent(),
          _buildFeedContent(),
        ],
      ),
    );
  }

  Widget _buildFeedContent() {
    if (_isGridView) {
      return GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.7,
        ),
        itemCount: 10,
        itemBuilder: (context, index) => _buildPostCard(context, index),
      );
    } else {
      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 10,
        itemBuilder:
            (context, index) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _buildPostCard(context, index),
            ),
      );
    }
  }

  Widget _buildPostCard(BuildContext context, int index) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User info
          ListTile(
            leading: const CircleAvatar(
              backgroundColor: Colors.grey,
              child: Icon(Icons.person, color: Colors.white),
            ),
            title: Text('User $index'),
            subtitle: const Text('2 hours ago'),
          ),

          // Post image
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(12),
                ),
              ),
              child: const Center(
                child: Icon(Icons.image, size: 60, color: Colors.grey),
              ),
            ),
          ),

          // Caption
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'This is a sample post caption. It can be longer and will be truncated if needed...',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // Tags
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Wrap(
              spacing: 8,
              children: [
                Chip(label: Text('#Tag1')),
                Chip(label: Text('#Tag2')),
              ],
            ),
          ),

          // Action buttons
          OverflowBar(
            alignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                icon: const Icon(Icons.favorite_border),
                onPressed: () {},
              ),
              IconButton(
                icon: const Icon(Icons.bookmark_border),
                onPressed: () {},
              ),
              IconButton(icon: const Icon(Icons.share), onPressed: () {}),
            ],
          ),
          // View Details button (placeholder for navigation)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) => PlazaPostDetailScreen(
                            title: 'Sample Post $index',
                            displayName: 'User $index',
                            timestamp: '2 hours ago',
                            description:
                                'This is a sample post caption. It can be longer and will be truncated if needed...',
                          ),
                    ),
                  );
                },
                child: const Text('View Details'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
