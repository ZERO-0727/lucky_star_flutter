import 'package:flutter/material.dart';
import 'user_detail_page.dart';

class UserPlazaScreen extends StatefulWidget {
  const UserPlazaScreen({Key? key}) : super(key: key);

  @override
  State<UserPlazaScreen> createState() => _UserPlazaScreenState();
}

class _UserPlazaScreenState extends State<UserPlazaScreen> {
  final List<String> _mainFilters = ['All', 'Verified', 'Pro Users', 'Recent'];
  final List<String> _statusFilters = [
    'Open to Exchange',
    'By Request Only',
    'Unavailable',
  ];
  int _selectedMainFilter = 0;
  int _selectedStatusFilter = 0;
  String _search = '';

  final List<Map<String, dynamic>> _users = List.generate(
    10,
    (i) => {
      'username': 'User $i',
      'avatar': null,
      'status': i % 3 == 0 ? 'Pro' : (i % 3 == 1 ? 'Limited' : 'Unavailable'),
      'location': 'Location $i',
      'stats': {
        'experiences': 5 + i % 7,
        'wishes': 2 + i % 5,
        'response': 88 + i % 13,
      },
      'languages': [
        'English',
        if (i % 2 == 0) 'Japanese',
        if (i % 3 == 0) 'Photography',
      ],
    },
  );

  List<Map<String, dynamic>> get _filteredUsers {
    var filtered =
        _users
            .where(
              (u) =>
                  u['username'].toLowerCase().contains(_search.toLowerCase()),
            )
            .toList();
    // Add more filter logic here if needed
    return filtered;
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Pro':
        return const Color(0xFF7153DF); // Purple for Pro
      case 'Available':
        return const Color(0xFF4CAF50); // Green for Available
      case 'Limited':
        return const Color(0xFFFFA726); // Orange for Limited
      case 'Unavailable':
        return const Color(0xFFE57373); // Red for Unavailable
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('User Plaza'), centerTitle: true),
      body: Column(
        children: [
          const SizedBox(height: 8),
          // Main Filters
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: List.generate(
                _mainFilters.length,
                (idx) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(_mainFilters[idx]),
                    selected: _selectedMainFilter == idx,
                    onSelected:
                        (_) => setState(() => _selectedMainFilter = idx),
                    selectedColor: const Color(0xFF7153DF),
                    labelStyle: TextStyle(
                      color:
                          _selectedMainFilter == idx
                              ? Colors.white
                              : Colors.black87,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Status Filters
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: List.generate(
                _statusFilters.length,
                (idx) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(_statusFilters[idx]),
                    selected: _selectedStatusFilter == idx,
                    onSelected:
                        (_) => setState(() => _selectedStatusFilter = idx),
                    selectedColor: Colors.grey[800],
                    labelStyle: TextStyle(
                      color:
                          _selectedStatusFilter == idx
                              ? Colors.white
                              : Colors.black87,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search users...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
              onChanged: (v) => setState(() => _search = v),
            ),
          ),
          const SizedBox(height: 12),
          // User Cards
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: _filteredUsers.length,
              itemBuilder: (context, idx) {
                final user = _filteredUsers[idx];
                final statusColor = _getStatusColor(user['status']);
                final statusText = user['status'];

                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => UserDetailPage(
                              userId: user['username'],
                              displayName: user['username'],
                            ),
                      ),
                    );
                  },
                  child: Card(
                    margin: const EdgeInsets.only(bottom: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    color: const Color(
                      0xFFFFF8E1,
                    ), // Light cream background for cards
                    child: Stack(
                      children: [
                        // Main content
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Avatar
                              CircleAvatar(
                                radius: 30,
                                backgroundColor: Colors.grey[300],
                                child: Icon(
                                  Icons.person,
                                  color: Colors.grey[700],
                                  size: 36,
                                ),
                              ),
                              const SizedBox(width: 16),
                              // User info
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Username and status label
                                    Row(
                                      children: [
                                        Text(
                                          user['username'],
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        if (user['status'] == 'Pro')
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF7153DF),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: const Text(
                                              'Pro',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    // Location
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.location_on,
                                          size: 16,
                                          color: Colors.grey,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          user['location'],
                                          style: const TextStyle(
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    // Stats
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        // Experiences
                                        Column(
                                          children: [
                                            Text(
                                              '${user['stats']['experiences']}',
                                              style: const TextStyle(
                                                fontSize: 20,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const Text(
                                              'Experiences',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey,
                                              ),
                                            ),
                                          ],
                                        ),
                                        // Wishes Fulfilled
                                        Column(
                                          children: [
                                            Text(
                                              '${user['stats']['wishes']}',
                                              style: const TextStyle(
                                                fontSize: 20,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const Text(
                                              'Wishes Fulfilled',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey,
                                              ),
                                            ),
                                          ],
                                        ),
                                        // Response Rate
                                        Column(
                                          children: [
                                            Text(
                                              '${user['stats']['response']}%',
                                              style: const TextStyle(
                                                fontSize: 20,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const Text(
                                              'Response Rate',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    // Language tags
                                    Wrap(
                                      spacing: 6,
                                      runSpacing: 6,
                                      children: List.generate(
                                        user['languages'].length,
                                        (langIdx) => Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(
                                              16,
                                            ),
                                            border: Border.all(
                                              color: const Color(0xFFE0E0E0),
                                            ),
                                          ),
                                          child: Text(
                                            user['languages'][langIdx],
                                            style: const TextStyle(
                                              fontSize: 13,
                                              color: Color(0xFF7153DF),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Status badge in top right corner
                        Positioned(
                          top: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor,
                              borderRadius: const BorderRadius.only(
                                topRight: Radius.circular(16),
                                bottomLeft: Radius.circular(16),
                              ),
                            ),
                            child: Text(
                              statusText,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
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
}
