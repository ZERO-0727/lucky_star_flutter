import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'services/favorites_service.dart';
import 'services/experience_service.dart';
import 'models/experience_model.dart';
import 'experience_detail_screen.dart';
import 'widgets/experience_card.dart';

class AllFavoriteExperiencesPage extends StatefulWidget {
  const AllFavoriteExperiencesPage({super.key});

  @override
  State<AllFavoriteExperiencesPage> createState() =>
      _AllFavoriteExperiencesPageState();
}

class _AllFavoriteExperiencesPageState
    extends State<AllFavoriteExperiencesPage> {
  final ExperienceService _experienceService = ExperienceService();
  List<ExperienceModel> _favoriteExperiences = [];
  bool _isLoading = true;
  String? _currentUserId;

  // Track local favorite states for non-intrusive toggling
  Map<String, bool> _localFavoriteStates = {};

  @override
  void initState() {
    super.initState();
    _currentUserId = FirebaseAuth.instance.currentUser?.uid;
    _loadFavoriteExperiences();
  }

  Future<void> _loadFavoriteExperiences() async {
    if (_currentUserId == null) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      setState(() {
        _isLoading = true;
      });

      // Get favorite experience IDs
      final favoriteExperienceIds =
          await FavoritesService.getFavoriteExperiences();
      final List<ExperienceModel> loadedExperiences = [];

      // Load experience data for each favorite
      for (final experienceId in favoriteExperienceIds) {
        try {
          final experience = await _experienceService.getExperience(
            experienceId,
          );
          if (experience != null) {
            loadedExperiences.add(experience);
          }
        } catch (e) {
          print('Error loading favorite experience $experienceId: $e');
          // Continue loading other experiences even if one fails
        }
      }

      if (mounted) {
        setState(() {
          _favoriteExperiences = loadedExperiences;
          _isLoading = false;
          // Initialize local favorite states - all items start as favorited
          _localFavoriteStates = {};
          for (final experience in loadedExperiences) {
            _localFavoriteStates[experience.experienceId] = true;
          }
        });
      }
    } catch (e) {
      print('Error loading favorite experiences: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _onFavoriteToggle(String experienceId) async {
    // Non-intrusive favorite toggle - update local state and Firestore
    // but don't remove from UI immediately

    try {
      // Toggle local state immediately for UI feedback
      setState(() {
        _localFavoriteStates[experienceId] =
            !(_localFavoriteStates[experienceId] ?? true);
      });

      // Update Firestore in the background
      await FavoritesService.toggleExperienceFavorite(experienceId);

      print(
        'Favorite state updated for experience $experienceId: ${_localFavoriteStates[experienceId]}',
      );
    } catch (e) {
      print('Error toggling favorite for experience $experienceId: $e');

      // Revert local state if Firestore update failed
      setState(() {
        _localFavoriteStates[experienceId] =
            !(_localFavoriteStates[experienceId] ?? true);
      });

      // Show error message to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to update favorite status. Please try again.',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Favorite Experiences',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF7153DF),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body:
          _isLoading
              ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF7153DF)),
              )
              : _favoriteExperiences.isEmpty
              ? _buildEmptyState()
              : _buildExperiencesList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: const Color(0xFF7153DF).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.explore_off,
                size: 60,
                color: const Color(0xFF7153DF).withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Favorite Experiences Yet',
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Start exploring experiences and tap the star icon to save them here for easy access.',
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: Colors.grey[600],
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pushNamed(context, '/share-experiences');
              },
              icon: const Icon(Icons.explore, size: 20),
              label: Text(
                'Explore Experiences',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7153DF),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExperiencesList() {
    return RefreshIndicator(
      onRefresh: _loadFavoriteExperiences,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _favoriteExperiences.length,
        itemBuilder: (context, index) {
          final experience = _favoriteExperiences[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: ExperienceCard(
              experience: experience,
              onFavoriteToggle:
                  () => _onFavoriteToggle(experience.experienceId),
              isFavorited:
                  _localFavoriteStates[experience.experienceId] ?? true,
            ),
          );
        },
      ),
    );
  }
}
