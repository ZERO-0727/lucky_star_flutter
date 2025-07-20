import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FavoritesService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user ID
  static String? get _currentUserId => _auth.currentUser?.uid;

  // Add experience to favorites
  static Future<bool> addExperienceToFavorites(String experienceId) async {
    if (_currentUserId == null) return false;

    try {
      await _firestore.collection('users').doc(_currentUserId).update({
        'favorite_experiences': FieldValue.arrayUnion([experienceId]),
      });
      return true;
    } catch (e) {
      print('Error adding experience to favorites: $e');
      return false;
    }
  }

  // Remove experience from favorites
  static Future<bool> removeExperienceFromFavorites(String experienceId) async {
    if (_currentUserId == null) return false;

    try {
      await _firestore.collection('users').doc(_currentUserId).update({
        'favorite_experiences': FieldValue.arrayRemove([experienceId]),
      });
      return true;
    } catch (e) {
      print('Error removing experience from favorites: $e');
      return false;
    }
  }

  // Add wish to favorites
  static Future<bool> addWishToFavorites(String wishId) async {
    if (_currentUserId == null) return false;

    try {
      await _firestore.collection('users').doc(_currentUserId).update({
        'favorite_wishes': FieldValue.arrayUnion([wishId]),
      });
      return true;
    } catch (e) {
      print('Error adding wish to favorites: $e');
      return false;
    }
  }

  // Remove wish from favorites
  static Future<bool> removeWishFromFavorites(String wishId) async {
    if (_currentUserId == null) return false;

    try {
      await _firestore.collection('users').doc(_currentUserId).update({
        'favorite_wishes': FieldValue.arrayRemove([wishId]),
      });
      return true;
    } catch (e) {
      print('Error removing wish from favorites: $e');
      return false;
    }
  }

  // Check if experience is favorited
  static Future<bool> isExperienceFavorited(String experienceId) async {
    if (_currentUserId == null) return false;

    try {
      final userDoc =
          await _firestore.collection('users').doc(_currentUserId).get();
      if (!userDoc.exists) return false;

      final data = userDoc.data() as Map<String, dynamic>?;
      final favoriteExperiences =
          data?['favorite_experiences'] as List<dynamic>?;

      return favoriteExperiences?.contains(experienceId) ?? false;
    } catch (e) {
      print('Error checking if experience is favorited: $e');
      return false;
    }
  }

  // Check if wish is favorited
  static Future<bool> isWishFavorited(String wishId) async {
    if (_currentUserId == null) return false;

    try {
      final userDoc =
          await _firestore.collection('users').doc(_currentUserId).get();
      if (!userDoc.exists) return false;

      final data = userDoc.data() as Map<String, dynamic>?;
      final favoriteWishes = data?['favorite_wishes'] as List<dynamic>?;

      return favoriteWishes?.contains(wishId) ?? false;
    } catch (e) {
      print('Error checking if wish is favorited: $e');
      return false;
    }
  }

  // Get user's favorite experiences
  static Future<List<String>> getFavoriteExperiences() async {
    if (_currentUserId == null) return [];

    try {
      final userDoc =
          await _firestore.collection('users').doc(_currentUserId).get();
      if (!userDoc.exists) return [];

      final data = userDoc.data() as Map<String, dynamic>?;
      final favoriteExperiences =
          data?['favorite_experiences'] as List<dynamic>?;

      return favoriteExperiences?.cast<String>() ?? [];
    } catch (e) {
      print('Error getting favorite experiences: $e');
      return [];
    }
  }

  // Get user's favorite wishes
  static Future<List<String>> getFavoriteWishes() async {
    if (_currentUserId == null) return [];

    try {
      final userDoc =
          await _firestore.collection('users').doc(_currentUserId).get();
      if (!userDoc.exists) return [];

      final data = userDoc.data() as Map<String, dynamic>?;
      final favoriteWishes = data?['favorite_wishes'] as List<dynamic>?;

      return favoriteWishes?.cast<String>() ?? [];
    } catch (e) {
      print('Error getting favorite wishes: $e');
      return [];
    }
  }

  // Toggle experience favorite status
  static Future<bool> toggleExperienceFavorite(String experienceId) async {
    final isFavorited = await isExperienceFavorited(experienceId);

    if (isFavorited) {
      return await removeExperienceFromFavorites(experienceId);
    } else {
      return await addExperienceToFavorites(experienceId);
    }
  }

  // Toggle wish favorite status
  static Future<bool> toggleWishFavorite(String wishId) async {
    final isFavorited = await isWishFavorited(wishId);

    if (isFavorited) {
      return await removeWishFromFavorites(wishId);
    } else {
      return await addWishToFavorites(wishId);
    }
  }

  // Get favorite experiences count
  static Future<int> getFavoriteExperiencesCount() async {
    final favorites = await getFavoriteExperiences();
    return favorites.length;
  }

  // Get favorite wishes count
  static Future<int> getFavoriteWishesCount() async {
    final favorites = await getFavoriteWishes();
    return favorites.length;
  }

  // ==================== USER FAVORITES ====================

  // Add user to favorites using map structure
  static Future<bool> addUserToFavorites(String userId) async {
    if (_currentUserId == null) return false;

    try {
      await _firestore.collection('users').doc(_currentUserId).update({
        'favorite_users_map.$userId': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      print('Error adding user to favorites: $e');
      return false;
    }
  }

  // Remove user from favorites
  static Future<bool> removeUserFromFavorites(String userId) async {
    if (_currentUserId == null) return false;

    try {
      await _firestore.collection('users').doc(_currentUserId).update({
        'favorite_users_map.$userId': FieldValue.delete(),
      });
      return true;
    } catch (e) {
      print('Error removing user from favorites: $e');
      return false;
    }
  }

  // Check if user is favorited
  static Future<bool> isUserFavorited(String userId) async {
    if (_currentUserId == null) return false;

    try {
      final userDoc =
          await _firestore.collection('users').doc(_currentUserId).get();
      if (!userDoc.exists) return false;

      final data = userDoc.data() as Map<String, dynamic>?;
      final favoriteUsersMap =
          data?['favorite_users_map'] as Map<String, dynamic>?;

      return favoriteUsersMap?.containsKey(userId) ?? false;
    } catch (e) {
      print('Error checking if user is favorited: $e');
      return false;
    }
  }

  // Get user's favorite users (returns list of user IDs sorted by most recent)
  static Future<List<String>> getFavoriteUsers() async {
    if (_currentUserId == null) return [];

    try {
      final userDoc =
          await _firestore.collection('users').doc(_currentUserId).get();
      if (!userDoc.exists) return [];

      final data = userDoc.data() as Map<String, dynamic>?;
      final favoriteUsersMap =
          data?['favorite_users_map'] as Map<String, dynamic>?;

      if (favoriteUsersMap == null || favoriteUsersMap.isEmpty) return [];

      // Convert map to list and sort by timestamp (most recent first)
      final favoritesList =
          favoriteUsersMap.entries
              .map(
                (entry) => {
                  'userId': entry.key,
                  'timestamp': entry.value as Timestamp?,
                },
              )
              .toList();

      favoritesList.sort((a, b) {
        final aTimestamp = a['timestamp'] as Timestamp?;
        final bTimestamp = b['timestamp'] as Timestamp?;

        if (aTimestamp == null && bTimestamp == null) return 0;
        if (aTimestamp == null) return 1;
        if (bTimestamp == null) return -1;

        return bTimestamp.compareTo(aTimestamp); // Most recent first
      });

      return favoritesList.map((item) => item['userId'] as String).toList();
    } catch (e) {
      print('Error getting favorite users: $e');
      return [];
    }
  }

  // Toggle user favorite status
  static Future<bool> toggleUserFavorite(String userId) async {
    final isFavorited = await isUserFavorited(userId);

    if (isFavorited) {
      return await removeUserFromFavorites(userId);
    } else {
      return await addUserToFavorites(userId);
    }
  }

  // Get favorite users count
  static Future<int> getFavoriteUsersCount() async {
    final favorites = await getFavoriteUsers();
    return favorites.length;
  }

  // Initialize user favorites (called when user signs up) - Updated
  static Future<void> initializeUserFavorites(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).set({
        'favorite_experiences': [],
        'favorite_wishes': [],
        'favorite_users': [],
      }, SetOptions(merge: true));
    } catch (e) {
      print('Error initializing user favorites: $e');
    }
  }

  // ==================== POPULARITY RANKING METHODS ====================

  /// Get experiences with their favorites count, sorted by popularity
  /// Filters: >3 favorites, within last 1 month, returns top N
  static Future<List<Map<String, dynamic>>> getPopularExperiences({
    int limit = 3,
    int minFavorites = 3,
    int maxDaysOld = 30,
  }) async {
    try {
      print('🔍 Getting popular experiences with criteria:');
      print('  - Min favorites: $minFavorites');
      print('  - Max days old: $maxDaysOld');
      print('  - Limit: $limit');

      // Get all users with their favorite experiences
      final usersSnapshot =
          await _firestore
              .collection('users')
              .where('favorite_experiences', isNotEqualTo: [])
              .get();

      // Count favorites for each experience with timestamps
      final Map<String, List<DateTime>> experienceFavorites = {};
      final oneMonthAgo = DateTime.now().subtract(Duration(days: maxDaysOld));

      for (final userDoc in usersSnapshot.docs) {
        final userData = userDoc.data();
        final favoriteExperiences =
            userData['favorite_experiences'] as List<dynamic>?;

        if (favoriteExperiences != null) {
          for (final experienceId in favoriteExperiences) {
            // For now, we don't have timestamp data on when favorites were added
            // So we'll use a recent timestamp as approximation
            experienceFavorites.putIfAbsent(experienceId, () => []);
            experienceFavorites[experienceId]!.add(DateTime.now());
          }
        }
      }

      print(
        '📊 Found ${experienceFavorites.length} experiences with favorites',
      );

      // Filter experiences with >minFavorites and get experience details
      final List<Map<String, dynamic>> popularExperiences = [];

      for (final entry in experienceFavorites.entries) {
        final experienceId = entry.key;
        final favoriteDates = entry.value;

        // Filter favorites within time range
        final recentFavorites =
            favoriteDates.where((date) => date.isAfter(oneMonthAgo)).toList();
        final favoritesCount = recentFavorites.length;

        if (favoritesCount > minFavorites) {
          try {
            // Get experience document
            final experienceDoc =
                await _firestore
                    .collection('experiences')
                    .doc(experienceId)
                    .get();

            if (experienceDoc.exists) {
              final experienceData = experienceDoc.data()!;
              experienceData['id'] = experienceDoc.id;
              experienceData['favoritesCount'] = favoritesCount;
              popularExperiences.add(experienceData);
            }
          } catch (e) {
            print('Error getting experience $experienceId: $e');
          }
        }
      }

      print(
        '🎯 Found ${popularExperiences.length} experiences meeting criteria',
      );

      // Sort by favorites count (descending)
      popularExperiences.sort(
        (a, b) =>
            (b['favoritesCount'] as int).compareTo(a['favoritesCount'] as int),
      );

      // Return top N
      final result = popularExperiences.take(limit).toList();
      print('✅ Returning top $limit popular experiences');

      return result;
    } catch (e) {
      print('Error getting popular experiences: $e');
      return [];
    }
  }

  /// Get wishes with their favorites count, sorted by popularity
  /// Filters: >3 favorites, within last 1 month, returns top N
  static Future<List<Map<String, dynamic>>> getPopularWishes({
    int limit = 3,
    int minFavorites = 3,
    int maxDaysOld = 30,
  }) async {
    try {
      print('🔍 Getting popular wishes with criteria:');
      print('  - Min favorites: $minFavorites');
      print('  - Max days old: $maxDaysOld');
      print('  - Limit: $limit');

      // Get all users with their favorite wishes
      final usersSnapshot =
          await _firestore
              .collection('users')
              .where('favorite_wishes', isNotEqualTo: [])
              .get();

      // Count favorites for each wish with timestamps
      final Map<String, List<DateTime>> wishFavorites = {};
      final oneMonthAgo = DateTime.now().subtract(Duration(days: maxDaysOld));

      for (final userDoc in usersSnapshot.docs) {
        final userData = userDoc.data();
        final favoriteWishes = userData['favorite_wishes'] as List<dynamic>?;

        if (favoriteWishes != null) {
          for (final wishId in favoriteWishes) {
            // For now, we don't have timestamp data on when favorites were added
            // So we'll use a recent timestamp as approximation
            wishFavorites.putIfAbsent(wishId, () => []);
            wishFavorites[wishId]!.add(DateTime.now());
          }
        }
      }

      print('📊 Found ${wishFavorites.length} wishes with favorites');

      // Filter wishes with >minFavorites and get wish details
      final List<Map<String, dynamic>> popularWishes = [];

      for (final entry in wishFavorites.entries) {
        final wishId = entry.key;
        final favoriteDates = entry.value;

        // Filter favorites within time range
        final recentFavorites =
            favoriteDates.where((date) => date.isAfter(oneMonthAgo)).toList();
        final favoritesCount = recentFavorites.length;

        if (favoritesCount > minFavorites) {
          try {
            // Get wish document
            final wishDoc =
                await _firestore.collection('wishes').doc(wishId).get();

            if (wishDoc.exists) {
              final wishData = wishDoc.data()!;
              wishData['id'] = wishDoc.id;
              wishData['favoritesCount'] = favoritesCount;
              popularWishes.add(wishData);
            }
          } catch (e) {
            print('Error getting wish $wishId: $e');
          }
        }
      }

      print('🎯 Found ${popularWishes.length} wishes meeting criteria');

      // Sort by favorites count (descending)
      popularWishes.sort(
        (a, b) =>
            (b['favoritesCount'] as int).compareTo(a['favoritesCount'] as int),
      );

      // Return top N
      final result = popularWishes.take(limit).toList();
      print('✅ Returning top $limit popular wishes');

      return result;
    } catch (e) {
      print('Error getting popular wishes: $e');
      return [];
    }
  }

  /// Get favorites count for a specific experience
  static Future<int> getExperienceFavoritesCount(String experienceId) async {
    try {
      final usersSnapshot =
          await _firestore
              .collection('users')
              .where('favorite_experiences', arrayContains: experienceId)
              .get();

      return usersSnapshot.docs.length;
    } catch (e) {
      print('Error getting experience favorites count: $e');
      return 0;
    }
  }

  /// Get favorites count for a specific wish
  static Future<int> getWishFavoritesCount(String wishId) async {
    try {
      final usersSnapshot =
          await _firestore
              .collection('users')
              .where('favorite_wishes', arrayContains: wishId)
              .get();

      return usersSnapshot.docs.length;
    } catch (e) {
      print('Error getting wish favorites count: $e');
      return 0;
    }
  }
}
