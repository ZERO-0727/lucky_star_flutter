import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'widgets/avatar_placeholder.dart';
import 'account_settings_page.dart';
import 'language_selection_page.dart';
import 'interest_editing_page.dart';
import 'services/favorites_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'models/experience_model.dart';
import 'models/wish_model.dart';

class MyPage extends StatefulWidget {
  const MyPage({super.key});

  @override
  State<MyPage> createState() => _MyPageState();
}

class _MyPageState extends State<MyPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedAvailability = 'Available';
  final List<String> _availabilityOptions = [
    'Available',
    'Busy',
    'Available Weekends Only',
    'Not Available',
  ];

  final Map<String, dynamic> _userData = {
    'name': 'Sarah Johnson',
    'location': 'Tokyo, Japan',
    'gender': 'Female',
    'bio': 'Passionate traveler and photographer.',
    'stats': {'experiencesShared': 24, 'starsReceived': 87, 'requestsSent': 15},
    'verifications': {'worldcoin': true, 'traditionalId': true},
    'languages': ['English', 'Japanese', 'Spanish'],
    'interests': ['Photography', 'Hiking', 'Cooking', 'Art'],
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AccountSettingsPage(),
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildProfileHeader(),
              _buildStatisticsPanel(),
              _buildTabsSection(),
              _buildTagSection('Languages', _userData['languages']),
              _buildTagSection('Interests', _userData['interests']),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
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
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFF7153DF),
                        width: 2,
                      ),
                    ),
                    child: const AvatarPlaceholder(size: 100),
                  ),
                  if (_userData['verifications']['worldcoin'] == true)
                    Positioned(
                      bottom: 0,
                      right: 25,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00C853),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(
                          Icons.verified_user,
                          color: Colors.white,
                          size: 14,
                        ),
                      ),
                    ),
                  if (_userData['verifications']['traditionalId'] == true)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2196F3),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(
                          Icons.badge,
                          color: Colors.white,
                          size: 14,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _userData['name'],
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 16,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _userData['location'],
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.person, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          _userData['gender'],
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
          const SizedBox(height: 20),
          Text(
            'About You',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _userData['bio'],
            style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[800]),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/edit-profile');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7153DF),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Edit Profile'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedAvailability,
                      isExpanded: true,
                      icon: const Icon(Icons.arrow_drop_down),
                      items:
                          _availabilityOptions.map((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setState(() {
                            _selectedAvailability = newValue;
                          });
                        }
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsPanel() {
    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.only(top: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            'Experiences',
            _userData['stats']['experiencesShared'].toString(),
            Icons.explore,
          ),
          _buildStatItem(
            'Stars',
            _userData['stats']['starsReceived'].toString(),
            Icons.star,
          ),
          _buildStatItem(
            'Requests',
            _userData['stats']['requestsSent'].toString(),
            Icons.send,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFF7153DF), size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF7153DF),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildTabsSection() {
    return Container(
      height: 320,
      margin: const EdgeInsets.only(top: 16),
      decoration: BoxDecoration(
        color: Colors.white,
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
        children: [
          TabBar(
            controller: _tabController,
            labelColor: const Color(0xFF7153DF),
            unselectedLabelColor: Colors.grey,
            indicatorColor: const Color(0xFF7153DF),
            tabs: const [
              Tab(icon: Icon(Icons.star), text: 'Favorites'),
              Tab(icon: Icon(Icons.upload), text: 'Published'),
              Tab(icon: Icon(Icons.history), text: 'Records'),
              Tab(icon: Icon(Icons.star_rate), text: 'Ratings'),
            ],
          ),
          SizedBox(
            height: 250,
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildFavoritesTab(),
                _buildPublishedTab(),
                _buildRecordsTab(),
                _buildRatingsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFavoritesTab() {
    return FutureBuilder<Map<String, List<dynamic>>>(
      future: _loadFavorites(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('Error loading favorites: ${snapshot.error}'),
          );
        }

        final favorites = snapshot.data ?? {'experiences': [], 'wishes': []};
        final favoriteExperiences = favorites['experiences'] ?? [];
        final favoriteWishes = favorites['wishes'] ?? [];

        if (favoriteExperiences.isEmpty && favoriteWishes.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.star_border, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No favorites yet',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
                Text(
                  'Tap the star icon on posts to add them here',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (favoriteExperiences.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Text(
                    'Favorite Experiences',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF7153DF),
                    ),
                  ),
                ),
                ...favoriteExperiences
                    .map(
                      (experience) => _buildFavoriteExperienceCard(experience),
                    )
                    .toList(),
              ],
              if (favoriteWishes.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Text(
                    'Favorite Wishes',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange.shade700,
                    ),
                  ),
                ),
                ...favoriteWishes
                    .map((wish) => _buildFavoriteWishCard(wish))
                    .toList(),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildPublishedTab() {
    return const Center(child: Text('Published content coming soon'));
  }

  Widget _buildRecordsTab() {
    return const Center(child: Text('Records coming soon'));
  }

  Widget _buildRatingsTab() {
    return const Center(child: Text('Ratings coming soon'));
  }

  Widget _buildTagSection(String title, List<dynamic> tags) {
    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.only(top: 16),
      decoration: BoxDecoration(
        color: Colors.white,
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit, size: 20),
                onPressed: () {
                  _showTagEditor(context, title, tags);
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                tags.map((tag) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F0FF),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFF7153DF).withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      tag,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: const Color(0xFF7153DF),
                      ),
                    ),
                  );
                }).toList(),
          ),
        ],
      ),
    );
  }

  Future<Map<String, List<dynamic>>> _loadFavorites() async {
    try {
      final favoriteExperienceIds =
          await FavoritesService.getFavoriteExperiences();
      final favoriteWishIds = await FavoritesService.getFavoriteWishes();

      final favoriteExperiences = <ExperienceModel>[];
      final favoriteWishes = <WishModel>[];

      final currentUserId = FirebaseAuth.instance.currentUser?.uid;

      for (final id in favoriteExperienceIds) {
        try {
          final doc =
              await FirebaseFirestore.instance
                  .collection('experiences')
                  .doc(id)
                  .get();
          if (doc.exists) {
            final experience = ExperienceModel.fromFirestore(doc);
            if (experience.userId != currentUserId) {
              favoriteExperiences.add(experience);
            }
          }
        } catch (e) {
          print('Error loading experience $id: $e');
        }
      }

      for (final id in favoriteWishIds) {
        try {
          final doc =
              await FirebaseFirestore.instance
                  .collection('wishes')
                  .doc(id)
                  .get();
          if (doc.exists) {
            final wish = WishModel.fromFirestore(doc);
            if (wish.userId != currentUserId) {
              favoriteWishes.add(wish);
            }
          }
        } catch (e) {
          print('Error loading wish $id: $e');
        }
      }

      return {'experiences': favoriteExperiences, 'wishes': favoriteWishes};
    } catch (e) {
      print('Error loading favorites: $e');
      return {'experiences': [], 'wishes': []};
    }
  }

  Widget _buildFavoriteExperienceCard(ExperienceModel experience) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(
            context,
            '/experience-detail',
            arguments: {
              'experienceId': experience.experienceId,
              'experience': experience,
            },
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                bottomLeft: Radius.circular(12),
              ),
              child: Container(
                width: 80,
                height: 80,
                color: Colors.grey.shade300,
                child:
                    experience.photoUrls.isNotEmpty
                        ? Image.network(
                          experience.photoUrls.first,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(Icons.image, color: Colors.grey);
                          },
                        )
                        : const Icon(Icons.explore, color: Colors.grey),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      experience.title,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      experience.location,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.people, size: 12, color: Colors.blue),
                        const SizedBox(width: 4),
                        Text(
                          '${experience.availableSlots} slots',
                          style: GoogleFonts.poppins(fontSize: 10),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFavoriteWishCard(WishModel wish) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(
            context,
            '/wish-detail',
            arguments: {'wishId': wish.wishId, 'wish': wish},
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Row(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.orange.shade100,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                ),
              ),
              child: Icon(Icons.star, color: Colors.orange.shade700, size: 40),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      wish.title,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      wish.location,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.schedule,
                          size: 12,
                          color: Colors.orange,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          wish.preferredDate != null
                              ? 'Has date preference'
                              : 'Flexible',
                          style: GoogleFonts.poppins(fontSize: 10),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showTagEditor(BuildContext context, String title, List<dynamic> tags) {
    if (title == 'Languages') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const LanguageSelectionPage()),
      );
    } else if (title == 'Interests') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const InterestEditingPage()),
      );
    }
  }
}
