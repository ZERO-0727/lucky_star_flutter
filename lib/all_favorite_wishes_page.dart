import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'services/favorites_service.dart';
import 'services/wish_service.dart';
import 'models/wish_model.dart';
import 'wish_detail_screen.dart';
import 'widgets/wish_card.dart';

class AllFavoriteWishesPage extends StatefulWidget {
  const AllFavoriteWishesPage({super.key});

  @override
  State<AllFavoriteWishesPage> createState() => _AllFavoriteWishesPageState();
}

class _AllFavoriteWishesPageState extends State<AllFavoriteWishesPage> {
  final WishService _wishService = WishService();
  List<WishModel> _favoriteWishes = [];
  bool _isLoading = true;
  String? _currentUserId;

  // Track local favorite states for non-intrusive toggling
  Map<String, bool> _localFavoriteStates = {};

  @override
  void initState() {
    super.initState();
    _currentUserId = FirebaseAuth.instance.currentUser?.uid;
    _loadFavoriteWishes();
  }

  Future<void> _loadFavoriteWishes() async {
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

      // Get favorite wish IDs
      final favoriteWishIds = await FavoritesService.getFavoriteWishes();
      final List<WishModel> loadedWishes = [];

      // Load wish data for each favorite
      for (final wishId in favoriteWishIds) {
        try {
          final wish = await _wishService.getWish(wishId);
          if (wish != null) {
            loadedWishes.add(wish);
          }
        } catch (e) {
          print('Error loading favorite wish $wishId: $e');
          // Continue loading other wishes even if one fails
        }
      }

      if (mounted) {
        setState(() {
          _favoriteWishes = loadedWishes;
          _isLoading = false;
          // Initialize local favorite states - all items start as favorited
          _localFavoriteStates = {};
          for (final wish in loadedWishes) {
            _localFavoriteStates[wish.wishId] = true;
          }
        });
      }
    } catch (e) {
      print('Error loading favorite wishes: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _onFavoriteToggle(String wishId) async {
    // Non-intrusive favorite toggle - update local state and Firestore
    // but don't remove from UI immediately

    try {
      // Toggle local state immediately for UI feedback
      setState(() {
        _localFavoriteStates[wishId] = !(_localFavoriteStates[wishId] ?? true);
      });

      // Update Firestore in the background
      await FavoritesService.toggleWishFavorite(wishId);

      print(
        'Favorite state updated for wish $wishId: ${_localFavoriteStates[wishId]}',
      );
    } catch (e) {
      print('Error toggling favorite for wish $wishId: $e');

      // Revert local state if Firestore update failed
      setState(() {
        _localFavoriteStates[wishId] = !(_localFavoriteStates[wishId] ?? true);
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
          'Favorite Wishes',
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
              : _favoriteWishes.isEmpty
              ? _buildEmptyState()
              : _buildWishesList(),
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
                Icons.star_border,
                size: 60,
                color: const Color(0xFF7153DF).withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Favorite Wishes Yet',
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Start exploring wishes and tap the star icon to save them here for easy access.',
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
                Navigator.pushNamed(context, '/wish-wall');
              },
              icon: const Icon(Icons.explore, size: 20),
              label: Text(
                'Explore Wishes',
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

  Widget _buildWishesList() {
    return RefreshIndicator(
      onRefresh: _loadFavoriteWishes,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _favoriteWishes.length,
        itemBuilder: (context, index) {
          final wish = _favoriteWishes[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: WishCard(
              wish: wish,
              onFavoriteToggle: () => _onFavoriteToggle(wish.wishId),
              isFavorited: _localFavoriteStates[wish.wishId] ?? true,
            ),
          );
        },
      ),
    );
  }
}
