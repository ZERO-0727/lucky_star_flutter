import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'user_detail_page.dart';
import 'models/user_model.dart';
import 'services/user_service.dart';
import 'widgets/user_profile_card.dart';

class UserPlazaScreen extends StatefulWidget {
  const UserPlazaScreen({Key? key}) : super(key: key);

  @override
  State<UserPlazaScreen> createState() => _UserPlazaScreenState();
}

class _UserPlazaScreenState extends State<UserPlazaScreen> {
  final List<String> _mainFilters = ['All', 'Verified', 'Pro Users', 'Recent'];
  final List<String> _statusFilters = ['Available', 'Limited', 'Unavailable'];
  int _selectedMainFilter = 0;
  int _selectedStatusFilter = 0;
  String _search = '';
  bool _isLoading = true;
  List<UserModel> _users = [];
  final UserService _userService = UserService();

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      List<UserModel> users;

      // Apply filters based on selection
      switch (_selectedMainFilter) {
        case 1: // Verified
          users = await _userService.getVerifiedUsers();
          break;
        case 2: // Pro Users
          // Assuming Pro users have a specific status or badge
          users = await _userService.getAllUsers();
          users =
              users
                  .where(
                    (user) =>
                        user.verificationBadges.contains('Pro') ||
                        user.trustScore > 80,
                  )
                  .toList();
          break;
        case 3: // Recent
          users = await _userService.getAllUsers();
          users.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          break;
        default: // All
          users = await _userService.getAllUsers();
      }

      // Apply status filter if selected
      if (_selectedStatusFilter > 0) {
        final String statusFilter = _statusFilters[_selectedStatusFilter];
        users = users.where((user) => user.status == statusFilter).toList();
      }

      // Apply search filter if text is entered
      if (_search.isNotEmpty) {
        final String searchLower = _search.toLowerCase();
        users =
            users
                .where(
                  (user) =>
                      user.displayName.toLowerCase().contains(searchLower) ||
                      user.location.toLowerCase().contains(searchLower),
                )
                .toList();
      }

      if (mounted) {
        setState(() {
          _users = users;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading users: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load users: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Plaza'),
        centerTitle: true,
        backgroundColor: const Color(0xFF7153DF),
        foregroundColor: Colors.white,
      ),
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
                    onSelected: (selected) {
                      if (selected) {
                        setState(() => _selectedMainFilter = idx);
                        _loadUsers();
                      }
                    },
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
                    onSelected: (selected) {
                      if (selected) {
                        setState(() => _selectedStatusFilter = idx);
                        _loadUsers();
                      }
                    },
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
              onChanged: (value) {
                setState(() => _search = value);
                // Debounce search to avoid too many requests
                Future.delayed(const Duration(milliseconds: 500), () {
                  if (_search == value) {
                    _loadUsers();
                  }
                });
              },
            ),
          ),
          const SizedBox(height: 12),
          // User Cards
          Expanded(
            child:
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _users.isEmpty
                    ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.person_search,
                            size: 64,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No users found',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton(
                            onPressed: _loadUsers,
                            child: const Text('Refresh'),
                          ),
                        ],
                      ),
                    )
                    : RefreshIndicator(
                      onRefresh: _loadUsers,
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        itemCount: _users.length,
                        itemBuilder: (context, index) {
                          final user = _users[index];
                          return UserProfileCard(
                            user: user,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (context) => UserDetailPage(
                                        userId: user.userId,
                                        displayName: user.displayName,
                                      ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
          ),
        ],
      ),
    );
  }
}
