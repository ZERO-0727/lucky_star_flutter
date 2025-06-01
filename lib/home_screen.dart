import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

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
        title: const Text('Lucky Star Home'),
        backgroundColor: const Color(0xFF7153DF),
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
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Hi Zero, here’s your journey today',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 8),
        Text(
          'Stay connected and discover new experiences',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildLuckyStarAvatars() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'My LuckyStar',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: 8, // Dummy data
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.grey[300],
                      child: const Icon(Icons.person, size: 30),
                    ),
                    const SizedBox(height: 4),
                    Text('User $index', style: const TextStyle(fontSize: 12)),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDiscoverExperiences() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Discover Experiences',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: 5, // Dummy data
            itemBuilder: (context, index) {
              return Container(
                width: 180,
                margin: const EdgeInsets.only(right: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(12),
                        ),
                        child: Container(
                          color: Colors.blueGrey,
                          child: const Center(
                            child: Icon(
                              Icons.image,
                              size: 60,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Experience $index',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Location',
                            style: TextStyle(fontSize: 12),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.people, size: 16),
                              const SizedBox(width: 4),
                              Text(
                                '${index * 3} RSVPs',
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
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMyWishes() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'My Wishes',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
        const Text(
          'My Exchanges',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
              Text('Your reputation score: 4.8/5.0'),
            ],
          ),
          ElevatedButton(
            onPressed: () {},
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
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Upcoming Event',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          ListTile(
            leading: Icon(Icons.event, color: Color(0xFF7153DF)),
            title: Text('Music Festival'),
            subtitle: Text('Central Park • June 15, 2025'),
            trailing: Chip(
              label: Text('Confirmed', style: TextStyle(color: Colors.white)),
              backgroundColor: Colors.green,
            ),
          ),
        ],
      ),
    );
  }
}
