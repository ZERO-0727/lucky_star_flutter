import 'dart:ui';
import 'package:flutter/material.dart';
import 'user_detail_page.dart';
import 'models/user_model.dart';
import 'services/user_service.dart';
import 'widgets/user_profile_card.dart';

class UserPlazaScreen extends StatefulWidget {
  const UserPlazaScreen({super.key});

  @override
  State<UserPlazaScreen> createState() => _UserPlazaScreenState();
}

class _UserPlazaScreenState extends State<UserPlazaScreen> {
  final List<String> _allFilters = [
    'All',
    'Verified',
    'Pro Users',
    'Recently Active',
    'Open to Exchange',
    'By Request Only',
    'Unavailable',
  ];
  int _selectedFilter = 0;
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
      switch (_selectedFilter) {
        case 1: // Verified
          users = await _userService.getVerifiedUsers();
          break;
        case 2: // Pro Users
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
        case 3: // Recently Active
          users = await _userService.getAllUsers();
          users.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
          break;
        case 4: // Open to Exchange
          users = await _userService.getAllUsers();
          users =
              users
                  .where(
                    (user) =>
                        user.status.toLowerCase() == 'open to exchange' ||
                        user.status.toLowerCase() == 'available',
                  )
                  .toList();
          break;
        case 5: // By Request Only
          users = await _userService.getAllUsers();
          users =
              users
                  .where(
                    (user) =>
                        user.status.toLowerCase() == 'by request only' ||
                        user.status.toLowerCase() == 'busy' ||
                        user.status.toLowerCase() == 'limited',
                  )
                  .toList();
          break;
        case 6: // Unavailable
          users = await _userService.getAllUsers();
          users =
              users
                  .where(
                    (user) =>
                        user.status.toLowerCase() == 'unavailable' ||
                        user.status.toLowerCase() == 'not available',
                  )
                  .toList();
          break;
        default: // All
          users = await _userService.getAllUsers();
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
        title: const Text('Soul'),
        centerTitle: true,
        backgroundColor: const Color(0xFF7153DF),
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // Filter Chips at Top
              _buildTopFilterChips(),

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
                            padding: const EdgeInsets.only(
                              left: 12,
                              right: 12,
                              top: 12,
                              bottom: 100, // Space for floating button
                            ),
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
                                            entryPath:
                                                'user_plaza', // Track entry from User Plaza
                                          ),
                                    ),
                                  );
                                },
                                onFavoriteChanged: () {
                                  // Optionally refresh the list or show feedback
                                },
                              );
                            },
                          ),
                        ),
              ),
            ],
          ),

          // Floating Search Button - Bottom Right (66x66px)
          Positioned(
            bottom: 30,
            right: 20,
            child: _buildFloatingSearchButton(),
          ),
        ],
      ),
    );
  }

  Widget _buildTopFilterChips() {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: List.generate(
            _allFilters.length,
            (idx) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(_allFilters[idx]),
                selected: _selectedFilter == idx,
                onSelected: (selected) {
                  if (selected) {
                    setState(() => _selectedFilter = idx);
                    _loadUsers();
                  }
                },
                selectedColor: const Color(0xFF7153DF),
                backgroundColor: Colors.grey[100],
                labelStyle: TextStyle(
                  color: _selectedFilter == idx ? Colors.white : Colors.black87,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(
                    color:
                        _selectedFilter == idx
                            ? const Color(0xFF7153DF)
                            : Colors.grey[300]!,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingSearchButton() {
    return GestureDetector(
      onTap: () {
        _showSearchDialog();
      },
      child: Container(
        width: 66,
        height: 66,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withOpacity(0.9),
          border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipOval(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.8),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.search,
                size: 28,
                color: Color(0xFF7153DF),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Search Users'),
            content: TextField(
              decoration: const InputDecoration(
                hintText: 'Enter search terms...',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) {
                setState(() => _search = value);
              },
              onSubmitted: (value) {
                Navigator.of(context).pop();
                _loadUsers();
              },
              autofocus: true,
            ),
            actions: [
              TextButton(
                onPressed: () {
                  setState(() => _search = '');
                  Navigator.of(context).pop();
                  _loadUsers();
                },
                child: const Text('Clear'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _loadUsers();
                },
                child: const Text('Search'),
              ),
            ],
          ),
    );
  }
}
