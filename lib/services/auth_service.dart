import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Auth state changes stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign up with email and password - simplified version
  Future<UserCredential> signUpWithEmailAndPassword({
    required String email,
    required String password,
    String displayName = 'New User',
    bool sendVerificationEmail = true,
  }) async {
    print('Starting signUpWithEmailAndPassword with email: $email');

    // Step 1: Create the user account with Firebase Auth
    print('STEP 1: Creating Firebase Auth account...');
    UserCredential userCredential;

    try {
      userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      print(
        'Firebase Auth account created successfully: ${userCredential.user?.uid}',
      );
    } on FirebaseAuthException catch (e) {
      print('FirebaseAuthException during account creation:');
      print('Code: ${e.code}');
      print('Message: ${e.message}');
      print('Stack: ${e.stackTrace}');
      throw _handleAuthException(e);
    } catch (e, stack) {
      print('Unexpected error during account creation:');
      print('Error type: ${e.runtimeType}');
      print('Error message: $e');
      print('Stack trace: $stack');
      throw Exception('Account creation failed: $e');
    }

    // Step 2: Update the user's display name
    print('STEP 2: Updating display name to: $displayName');
    try {
      if (userCredential.user == null) {
        print('ERROR: User is null after account creation');
        throw Exception('User account was created but user object is null');
      }

      await userCredential.user!.updateDisplayName(displayName);
      print('Display name updated successfully');
    } catch (e, stack) {
      print('Error updating display name:');
      print('Error type: ${e.runtimeType}');
      print('Error message: $e');
      print('Stack trace: $stack');
      // Continue despite this error - not critical
    }

    // Step 3: Send email verification if requested
    if (sendVerificationEmail && userCredential.user != null) {
      print('STEP 3: Sending email verification');
      try {
        await userCredential.user!.sendEmailVerification();
        print('Email verification sent successfully');
      } catch (e, stack) {
        print('Error sending email verification:');
        print('Error type: ${e.runtimeType}');
        print('Error message: $e');
        print('Stack trace: $stack');
        // Continue despite this error - not critical
      }
    }

    // Step 4: Create the Firestore document
    print('STEP 4: Creating Firestore document');
    try {
      if (userCredential.user != null) {
        await _createUserDocument(userCredential.user!.uid, displayName);
        print('Firestore document created successfully');
      } else {
        print(
          'WARNING: Skipping Firestore document creation because user is null',
        );
      }
    } catch (e, stack) {
      print('Error creating Firestore document:');
      print('Error type: ${e.runtimeType}');
      print('Error message: $e');
      print('Stack trace: $stack');

      // If Firestore fails but Auth succeeded, we'll still return the UserCredential
      // but log the error for debugging
      print('WARNING: Auth succeeded but Firestore document creation failed');
    }

    print('Sign-up process completed successfully');
    return userCredential;
  }

  // Test function for Firebase Auth only (no Firestore)
  Future<UserCredential> testCreateAuthAccount({
    required String email,
    required String password,
  }) async {
    print('TEST: Creating Firebase Auth account only...');
    print('TEST: Email: $email');

    try {
      // Only create the Firebase Auth account, nothing else
      final UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);

      print('TEST: Auth account created successfully');
      print('TEST: User ID: ${userCredential.user?.uid}');
      return userCredential;
    } on FirebaseAuthException catch (e) {
      print('TEST ERROR: FirebaseAuthException');
      print('TEST ERROR: Code: ${e.code}');
      print('TEST ERROR: Message: ${e.message}');
      throw Exception('TEST Auth Error: ${e.message}');
    } catch (e, stack) {
      print('TEST ERROR: Unknown error type: ${e.runtimeType}');
      print('TEST ERROR: Message: $e');
      print('TEST ERROR: Stack: $stack');
      throw Exception('TEST Unknown Error: $e');
    }
  }

  // Sign in with email and password
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Delete account
  Future<void> deleteAccount() async {
    try {
      final User? user = _auth.currentUser;

      if (user != null) {
        // Delete user document from Firestore
        await _firestore.collection('users').doc(user.uid).delete();

        // Delete the user account
        await user.delete();
      }
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Create a new user document in Firestore
  Future<void> _createUserDocument(String userId, String displayName) async {
    final now = DateTime.now();

    // Verify we have a valid user before proceeding
    if (_auth.currentUser == null) {
      print('ERROR: Cannot create user document - currentUser is null');
      throw Exception('Cannot create user document: No authenticated user');
    }

    print('Preparing Firestore document for user: $userId');
    final userData = {
      'userId': userId,
      'displayName': displayName,
      'email': _auth.currentUser?.email,
      'createdAt': now,
      'updatedAt': now,
      'bio': '',
      'avatarUrl': '',
      'interests': [],
      'visitedCountries': [],
      'verificationBadges': [],
      'referenceCount': 0,
      'statistics': {
        'experiencesCount': 0,
        'wishesFullfilledCount': 0,
        'responseRate': 0,
      },
      'isVerified': false,
    };

    try {
      print('Writing user data to Firestore...');
      // Use set with merge option to avoid overwriting existing data
      await _firestore
          .collection('users')
          .doc(userId)
          .set(userData, SetOptions(merge: true))
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              print('ERROR: Firestore write operation timed out');
              throw Exception(
                'Database operation timed out. Please try again.',
              );
            },
          );
      print('Successfully created user document in Firestore');
    } on FirebaseException catch (e) {
      print('Firestore FirebaseException: ${e.code} - ${e.message}');
      print('Stack trace: ${e.stackTrace}');
      throw Exception('Database error: ${e.message}');
    } catch (e, stack) {
      print('Firestore write error type: ${e.runtimeType}');
      print('Firestore write error message: $e');
      print('Stack trace: $stack');
      throw Exception('Failed to create user profile: ${e.toString()}');
    }
  }

  // Handle Firebase Auth exceptions
  Exception _handleAuthException(FirebaseAuthException e) {
    String message;
    print('Firebase Error Code: ${e.code}');
    print('Firebase Error Message: ${e.message}');
    print('Firebase Error Stack: ${e.stackTrace}');

    // Log detailed information for debugging
    print(
      '[AuthService] Handling FirebaseAuthException:'
              '\nCode: ' +
          e.code.toString() +
          '\nMessage: ' +
          (e.message ?? '') +
          '\nStack: ' +
          (e.stackTrace?.toString() ?? ''),
    );

    switch (e.code) {
      case 'email-already-in-use':
        message = 'The email address is already in use by another account.';
        break;
      case 'invalid-email':
        message = 'The email address is invalid.';
        break;
      case 'operation-not-allowed':
        message = 'Email/password accounts are not enabled.';
        break;
      case 'weak-password':
        message = 'The password is too weak.';
        break;
      case 'user-disabled':
        message = 'This user has been disabled.';
        break;
      case 'user-not-found':
        message = 'No user found for that email.';
        break;
      case 'wrong-password':
        message = 'Wrong password provided for that user.';
        break;
      case 'requires-recent-login':
        message =
            'This operation is sensitive and requires recent authentication. Log in again before retrying.';
        break;
      case 'network-request-failed':
        message =
            'Network error. Please check your internet connection and try again.';
        break;
      case 'too-many-requests':
        message =
            'Too many unsuccessful login attempts. Please try again later.';
        break;
      case 'user-token-expired':
        message = 'Your session has expired. Please sign in again.';
        break;
      case 'invalid-credential':
        message = 'The authentication credential is invalid. Please try again.';
        break;
      case 'account-exists-with-different-credential':
        message =
            'An account already exists with the same email but different sign-in credentials.';
        break;
      case 'invalid-verification-code':
        message = 'The verification code is invalid. Please try again.';
        break;
      case 'invalid-verification-id':
        message = 'The verification ID is invalid. Please try again.';
        break;
      case 'quota-exceeded':
        message = 'Quota exceeded. Please try again later.';
        break;
      default:
        if (e.message != null && e.message!.isNotEmpty) {
          message = 'Authentication error: ${e.message}';
        } else {
          message =
              'An unknown authentication error occurred. Please try again.';
        }
    }

    return Exception(message);
  }
}
