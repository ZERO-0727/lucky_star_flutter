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
}
