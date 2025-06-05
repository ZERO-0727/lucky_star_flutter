import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'users';

  // Get a reference to the users collection
  CollectionReference<Map<String, dynamic>> get _usersCollection =>
      _firestore.collection(_collection);

  // Create a new user document
  Future<UserModel> createUser(UserModel user) async {
    try {
      // If userId is empty, let Firestore generate an ID
      final String userId =
          user.userId.isEmpty ? _usersCollection.doc().id : user.userId;

      // Create a new user with the generated or provided ID
      final UserModel newUser = user.copyWith(
        userId: userId,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Save to Firestore
      await _usersCollection.doc(userId).set(newUser.toFirestore());

      return newUser;
    } catch (e) {
      print('Error creating user: $e');
      rethrow;
    }
  }

  // Get a user by ID
  Future<UserModel?> getUserById(String userId) async {
    try {
      final DocumentSnapshot doc = await _usersCollection.doc(userId).get();

      if (!doc.exists) {
        return null;
      }

      return UserModel.fromFirestore(doc);
    } catch (e) {
      print('Error getting user by ID: $e');
      rethrow;
    }
  }

  // Get a stream of a user by ID (for real-time updates)
  Stream<UserModel?> getUserStream(String userId) {
    return _usersCollection.doc(userId).snapshots().map((doc) {
      if (!doc.exists) {
        return null;
      }
      return UserModel.fromFirestore(doc);
    });
  }

  // Update a user document
  Future<UserModel> updateUser(UserModel user) async {
    try {
      // Ensure we have a valid userId
      if (user.userId.isEmpty) {
        throw Exception('Cannot update user with empty userId');
      }

      // Create an updated user with the current timestamp
      final UserModel updatedUser = user.copyWith(updatedAt: DateTime.now());

      // Update in Firestore
      await _usersCollection.doc(user.userId).update(updatedUser.toFirestore());

      return updatedUser;
    } catch (e) {
      print('Error updating user: $e');
      rethrow;
    }
  }

  // Update specific fields of a user document
  Future<UserModel?> updateUserFields(
    String userId,
    Map<String, dynamic> fields,
  ) async {
    try {
      // Ensure we have a valid userId
      if (userId.isEmpty) {
        throw Exception('Cannot update user with empty userId');
      }

      // Add the updated timestamp
      fields['updatedAt'] = FieldValue.serverTimestamp();

      // Update in Firestore
      await _usersCollection.doc(userId).update(fields);

      // Fetch and return the updated user
      return await getUserById(userId);
    } catch (e) {
      print('Error updating user fields: $e');
      rethrow;
    }
  }

  // Delete a user document
  Future<void> deleteUser(String userId) async {
    try {
      await _usersCollection.doc(userId).delete();
    } catch (e) {
      print('Error deleting user: $e');
      rethrow;
    }
  }

  // Get all users (with optional limit)
  Future<List<UserModel>> getAllUsers({int limit = 20}) async {
    try {
      final QuerySnapshot querySnapshot =
          await _usersCollection
              .orderBy('createdAt', descending: true)
              .limit(limit)
              .get();

      return querySnapshot.docs
          .map((doc) => UserModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error getting all users: $e');
      rethrow;
    }
  }

  // Search users by displayName
  Future<List<UserModel>> searchUsersByName(
    String query, {
    int limit = 20,
  }) async {
    try {
      // Convert query to lowercase for case-insensitive search
      final String searchQuery = query.toLowerCase();

      // Get all users and filter in memory
      // Note: Firestore doesn't support case-insensitive search directly
      // For production, consider using a third-party search service like Algolia
      final QuerySnapshot querySnapshot =
          await _usersCollection
              .orderBy('displayName')
              .limit(limit * 5) // Get more to filter
              .get();

      final List<UserModel> allUsers =
          querySnapshot.docs
              .map((doc) => UserModel.fromFirestore(doc))
              .toList();

      // Filter users whose displayName contains the search query (case-insensitive)
      final List<UserModel> filteredUsers =
          allUsers
              .where(
                (user) => user.displayName.toLowerCase().contains(searchQuery),
              )
              .take(limit)
              .toList();

      return filteredUsers;
    } catch (e) {
      print('Error searching users by name: $e');
      rethrow;
    }
  }

  // Get users by status (Available, Limited, Unavailable)
  Future<List<UserModel>> getUsersByStatus(
    String status, {
    int limit = 20,
  }) async {
    try {
      final QuerySnapshot querySnapshot =
          await _usersCollection
              .where('status', isEqualTo: status)
              .limit(limit)
              .get();

      return querySnapshot.docs
          .map((doc) => UserModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error getting users by status: $e');
      rethrow;
    }
  }

  // Get verified users
  Future<List<UserModel>> getVerifiedUsers({int limit = 20}) async {
    try {
      final QuerySnapshot querySnapshot =
          await _usersCollection
              .where('isVerified', isEqualTo: true)
              .limit(limit)
              .get();

      return querySnapshot.docs
          .map((doc) => UserModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error getting verified users: $e');
      rethrow;
    }
  }

  // Increment a user's statistics field
  Future<void> incrementUserStatistic(
    String userId,
    String statisticField, {
    int amount = 1,
  }) async {
    try {
      await _usersCollection.doc(userId).update({
        'statistics.$statisticField': FieldValue.increment(amount),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error incrementing user statistic: $e');
      rethrow;
    }
  }

  // Add a country to a user's visited countries list
  Future<void> addVisitedCountry(String userId, String country) async {
    try {
      await _usersCollection.doc(userId).update({
        'visitedCountries': FieldValue.arrayUnion([country]),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error adding visited country: $e');
      rethrow;
    }
  }

  // Remove a country from a user's visited countries list
  Future<void> removeVisitedCountry(String userId, String country) async {
    try {
      await _usersCollection.doc(userId).update({
        'visitedCountries': FieldValue.arrayRemove([country]),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error removing visited country: $e');
      rethrow;
    }
  }

  // Add an interest to a user's interests list
  Future<void> addInterest(String userId, String interest) async {
    try {
      await _usersCollection.doc(userId).update({
        'interests': FieldValue.arrayUnion([interest]),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error adding interest: $e');
      rethrow;
    }
  }

  // Remove an interest from a user's interests list
  Future<void> removeInterest(String userId, String interest) async {
    try {
      await _usersCollection.doc(userId).update({
        'interests': FieldValue.arrayRemove([interest]),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error removing interest: $e');
      rethrow;
    }
  }

  // Update a user's verification status
  Future<void> updateVerificationStatus(String userId, bool isVerified) async {
    try {
      await _usersCollection.doc(userId).update({
        'isVerified': isVerified,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating verification status: $e');
      rethrow;
    }
  }

  // Add a verification badge to a user
  Future<void> addVerificationBadge(String userId, String badge) async {
    try {
      await _usersCollection.doc(userId).update({
        'verificationBadges': FieldValue.arrayUnion([badge]),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error adding verification badge: $e');
      rethrow;
    }
  }

  // Remove a verification badge from a user
  Future<void> removeVerificationBadge(String userId, String badge) async {
    try {
      await _usersCollection.doc(userId).update({
        'verificationBadges': FieldValue.arrayRemove([badge]),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error removing verification badge: $e');
      rethrow;
    }
  }
}
