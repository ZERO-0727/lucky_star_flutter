import 'package:flutter/material.dart';
import 'widgets/interactive_world_map.dart';
import 'widgets/airbnb_world_map.dart';

class UserDetailPage extends StatelessWidget {
  final String userId;
  final String displayName;

  const UserDetailPage({
    Key? key,
    required this.userId,
    required this.displayName,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Placeholder data for demo
    final String bio =
        'Hello from $displayName. I love traveling and meeting new people!';
    final List<String> interestTags = [
      'Hiking',
      'Photography',
      'Food',
      'Art',
      'Music',
    ];
    final List<String> visitedCountries = [
      'Japan',
      'United States',
      'France',
      'Italy',
      'Australia',
    ];
    final int referenceCount = 3;
    final Map<String, int> stats = {
      'Experiences': 5,
      'Wishes Fulfilled': 2,
      'Response Rate': 90,
    };
    final List<String> badges = ['Worldcoin', 'Government ID'];

    return Scaffold(
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // Banner and Profile Image
              SliverAppBar(
                expandedHeight: 220,
                pinned: true,
                backgroundColor: Colors.transparent,
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Banner image - using a placeholder with travel theme
                      Image.network(
                        'https://images.unsplash.com/photo-1452421822248-d4c2b47f0c81',
                        fit: BoxFit.cover,
                      ),
                      // Gradient overlay for better text visibility
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.5),
                            ],
                          ),
                        ),
                      ),
                      // User name (bold, left-aligned, inside banner)
                      Positioned(
                        left: 24,
                        bottom: 56,
                        child: Text(
                          displayName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            shadows: [
                              Shadow(
                                color: Colors.black54,
                                offset: Offset(0, 1),
                                blurRadius: 2,
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Verification badges (bottom-left, horizontal)
                      Positioned(
                        left: 24,
                        bottom: 24,
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green[100],
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.check_circle,
                                    color: Colors.green[700],
                                    size: 16,
                                  ),
                                  const SizedBox(width: 4),
                                  const Text(
                                    'World ID',
                                    style: TextStyle(
                                      color: Colors.green,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.blue[100],
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.verified_user,
                                    color: Colors.blue[700],
                                    size: 16,
                                  ),
                                  const SizedBox(width: 4),
                                  const Text(
                                    'Government ID',
                                    style: TextStyle(
                                      color: Colors.blue,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
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
                            color: Colors.white.withOpacity(0.7),
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.arrow_back),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Profile Avatar (overlapping the banner)
              SliverToBoxAdapter(
                child: Transform.translate(
                  offset: const Offset(0, -60),
                  child: Align(
                    alignment: Alignment.center,
                    child: CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.white,
                      child: CircleAvatar(
                        radius: 46,
                        backgroundColor: Colors.grey[300],
                        child: Icon(
                          Icons.person,
                          size: 60,
                          color: Colors.grey[700],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // User Info
              SliverToBoxAdapter(
                child: Transform.translate(
                  offset: const Offset(0, -50),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Username and Verification Badges (moved to banner)
                        const SizedBox(height: 0),

                        // Bio
                        Center(
                          child: Text(
                            bio,
                            style: const TextStyle(
                              fontSize: 16,
                              fontStyle: FontStyle.italic,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // References
                        Row(
                          children: [
                            const Icon(Icons.people, color: Colors.grey),
                            const SizedBox(width: 8),
                            Text(
                              '$referenceCount References',
                              style: const TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Interests
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
                          children:
                              interestTags
                                  .map(
                                    (tag) => Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.purple[50],
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        tag,
                                        style: TextStyle(
                                          color: Colors.purple[700],
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList(),
                        ),
                        const SizedBox(height: 24),

                        // Statistics
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
                            _buildStatTile(
                              'Experiences',
                              stats['Experiences']!,
                              Icons.explore,
                              const Color(0xFF7153DF),
                            ),
                            _buildStatTile(
                              'Wishes Fulfilled',
                              stats['Wishes Fulfilled']!,
                              Icons.star,
                              Colors.amber,
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Countries Visited
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
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.purple[100],
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.edit,
                                    color: Colors.purple[700],
                                    size: 16,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Edit',
                                    style: TextStyle(color: Colors.purple[700]),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // World Map
                        AirbnbWorldMap(
                          visitedCountries: visitedCountries,
                          isEditable: false,
                          visitedColor: const Color(0xFF7153DF),
                          unvisitedColor: Colors.grey.shade300,
                          backgroundColor: Colors.blue.shade50,
                        ),
                        const SizedBox(height: 16),

                        // Country Tags
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children:
                              visitedCountries
                                  .map(
                                    (country) => Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.blue[50],
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: Colors.blue.shade200,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            Icons.location_on,
                                            size: 16,
                                            color: Colors.blue,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            country,
                                            style: const TextStyle(
                                              color: Colors.blue,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  )
                                  .toList(),
                        ),

                        const SizedBox(height: 100), // Space for bottom buttons
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Fixed Action Buttons
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
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
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.group_add),
                      label: const Text('Join This Experience'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7153DF),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.message),
                      label: const Text('Send Message'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF7153DF),
                        side: const BorderSide(color: Color(0xFF7153DF)),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
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

  Widget _buildStatTile(
    String label,
    int value,
    IconData icon,
    Color color, {
    bool isPercent = false,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 36),
        const SizedBox(height: 8),
        Text(
          isPercent ? '$value%' : '$value',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 14, color: Colors.grey)),
      ],
    );
  }
}
