import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'my_wishes_page.dart';
import 'my_published_experiences_page.dart';
import 'trust_reputation_page.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late TabController _wishesTabController;
  late TabController _exchangesTabController;

  @override
  void initState() {
    super.initState();
    _wishesTabController = TabController(length: 2, vsync: this);
    _exchangesTabController = TabController(length: 3, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Lucky Star',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        backgroundColor: const Color(0xFF7153DF),
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.notifications), onPressed: () {}),
          PopupMenuButton<String>(
            icon: const Icon(Icons.person),
            onSelected: (value) {
              switch (value) {
                case 'profile':
                  Navigator.pushNamed(context, '/profile');
                  break;
                case 'my_page':
                  Navigator.pushNamed(context, '/my-page');
                  break;
              }
            },
            itemBuilder:
                (BuildContext context) => <PopupMenuEntry<String>>[
                  const PopupMenuItem<String>(
                    value: 'profile',
                    child: ListTile(
                      leading: Icon(Icons.account_circle),
                      title: Text('Profile'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  const PopupMenuItem<String>(
                    value: 'my_page',
                    child: ListTile(
                      leading: Icon(Icons.dashboard),
                      title: Text('My Page'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header with greeting
          _buildHeader(),
          const SizedBox(height: 20),

          // My LuckyStar horizontal list
          _buildLuckyStarAvatars(),
          const SizedBox(height: 20),

          // Wishes Wall Preview
          _buildWishesWallPreview(),
          const SizedBox(height: 20),

          // Discover Experiences
          _buildDiscoverExperiences(),
          const SizedBox(height: 20),

          // My Wishes tabbed view
          _buildMyWishes(),
          const SizedBox(height: 20),

          // My Exchanges tabbed view
          _buildMyExchanges(),
          const SizedBox(height: 20),

          // Trust & Reputation
          _buildTrustReputation(),
          const SizedBox(height: 20),

          // Calendar preview
          _buildCalendarPreview(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Welcome to Lucky Star',
          style: GoogleFonts.poppins(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF7153DF),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Discover new experiences and connect with like-minded individuals',
          style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildLuckyStarAvatars() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'My Connections',
          style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 120,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _buildConnectionCard(
                'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=150',
                'Emma',
                'Travel Enthusiast',
              ),
              _buildConnectionCard(
                'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150',
                'John',
                'Foodie',
              ),
              _buildConnectionCard(
                'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=150',
                'Sarah',
                'Photographer',
              ),
              _buildConnectionCard(
                'https://images.unsplash.com/photo-1522075469751-3a6694fb2f61?w=150',
                'Mike',
                'Tech Expert',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildConnectionCard(String imageUrl, String name, String role) {
    return Container(
      margin: const EdgeInsets.only(right: 12),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF7153DF), width: 2),
              image: DecorationImage(
                image: NetworkImage(imageUrl),
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            name,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            role,
            style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildDiscoverExperiences() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Featured Experiences',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pushNamed(context, '/share-experiences');
              },
              child: Text(
                'See All',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: const Color(0xFF7153DF),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 250,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _buildExperienceCard(
                'https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=300',
                'Cooking Class',
                'Learn authentic Italian cooking',
                'Tokyo',
                45,
              ),
              _buildExperienceCard(
                'https://images.unsplash.com/photo-1512314889869-02171f8a44cc?w=300',
                'Photography Tour',
                'Explore city through lens',
                'Osaka',
                28,
              ),
              _buildExperienceCard(
                'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?w=300',
                'Art Workshop',
                'Painting & creativity',
                'Kyoto',
                32,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildExperienceCard(
    String imageUrl,
    String title,
    String description,
    String location,
    int rsvps,
  ) {
    return Container(
      width: 280,
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Image.network(
              imageUrl,
              height: 150,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      location,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.people, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      '$rsvps RSVPs',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey[600],
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

  Widget _buildMyWishes() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'My Wishes',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const MyWishesPage()),
                );
              },
              child: const Text(
                'View All',
                style: TextStyle(color: Color(0xFF7153DF)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TabBar(
          controller: _wishesTabController,
          labelColor: const Color(0xFF7153DF),
          unselectedLabelColor: Colors.grey,
          tabs: const [Tab(text: 'Pending'), Tab(text: 'Fulfilled')],
        ),
        SizedBox(
          height: 150,
          child: TabBarView(
            controller: _wishesTabController,
            children: [_buildWishList(), _buildWishList()],
          ),
        ),
      ],
    );
  }

  Widget _buildWishList() {
    return ListView.builder(
      itemCount: 3, // Dummy data
      itemBuilder: (context, index) {
        return ListTile(
          leading: const Icon(Icons.star, color: Colors.amber),
          title: Text('Wish $index'),
          subtitle: const Text('Status: Pending'),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        );
      },
    );
  }

  Widget _buildMyExchanges() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'My Exchanges',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MyPublishedExperiencesPage(),
                  ),
                );
              },
              child: const Text(
                'View All',
                style: TextStyle(color: Color(0xFF7153DF)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TabBar(
          controller: _exchangesTabController,
          labelColor: const Color(0xFF7153DF),
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: 'Participating'),
            Tab(text: 'Saved'),
            Tab(text: 'Recommended'),
          ],
        ),
        SizedBox(
          height: 150,
          child: TabBarView(
            controller: _exchangesTabController,
            children: [
              _buildExchangeList(),
              _buildExchangeList(),
              _buildExchangeList(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildExchangeList() {
    return ListView.builder(
      itemCount: 3, // Dummy data
      itemBuilder: (context, index) {
        return ListTile(
          leading: const Icon(Icons.swap_horiz, color: Color(0xFF7153DF)),
          title: Text('Exchange $index'),
          subtitle: const Text('Status: Active'),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        );
      },
    );
  }

  Widget _buildTrustReputation() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Trust & Reputation',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('Your reputation score: 100/100'),
            ],
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const TrustReputationPage(),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7153DF),
            ),
            child: const Text('Edit', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarPreview() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Upcoming Event',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const ListTile(
            leading: Icon(Icons.event, color: Color(0xFF7153DF)),
            title: Text('Music Festival'),
            subtitle: Text('Central Park • June 15, 2025'),
            trailing: Chip(
              label: Text('Confirmed', style: TextStyle(color: Colors.white)),
              backgroundColor: Colors.green,
            ),
          ),
          const SizedBox(height: 16),
          // Firebase Test Button
          Center(
            child: Column(
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pushNamed(context, '/firebase-test');
                  },
                  icon: const Icon(Icons.storage),
                  label: const Text('Test Firebase Connection'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7153DF),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pushNamed(context, '/firebase-auth-debug');
                  },
                  icon: const Icon(Icons.bug_report),
                  label: const Text('Firebase Auth Debug'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWishesWallPreview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Wishes Wall',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pushNamed(context, '/wish-wall');
              },
              child: Text(
                'See All',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: const Color(0xFF7153DF),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 180,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _buildWishCard(
                'Language Exchange',
                'Looking for a native English speaker for language practice',
                'Tokyo',
                'Jun 20, 2025',
                12,
              ),
              _buildWishCard(
                'Photography Partner',
                'Need someone to explore night photography in the city',
                'Shibuya',
                'Jun 25, 2025',
                8,
              ),
              _buildWishCard(
                'Hiking Buddy',
                'Planning a weekend hike, looking for experienced hikers',
                'Mt. Fuji',
                'Jul 5, 2025',
                15,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWishCard(
    String title,
    String description,
    String location,
    String date,
    int rsvpCount,
  ) {
    return Container(
      width: 250,
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Wish header with star icon
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: Color(0xFFF5F0FF),
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                const Icon(Icons.star, color: Color(0xFFFFD700), size: 24),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF7153DF),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          // Wish content
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  description,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.grey[800],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.location_on, size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      location,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 14,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      date,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.people, size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      '$rsvpCount people interested',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey[600],
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
}
