import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'sendgrid_service.dart';

// Class to track verification attempts
class _VerificationAttempt {
  DateTime lastAttempt;
  int attemptCount;

  _VerificationAttempt(this.lastAttempt, this.attemptCount);
}

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Track email sending to avoid Firebase rate limits
  static DateTime? _lastEmailSentTime;
  static int _emailSendCounter = 0;
  static DateTime? _dailyCounterReset;
  static const int _maxDailyEmails = 10; // Lower threshold to be safer
  static const Duration _minEmailInterval = Duration(
    minutes: 5,
  ); // Increased interval

  // Track verification attempts per user
  static final Map<String, _VerificationAttempt> _userVerificationAttempts = {};

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Auth state changes stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign up with email and password - enhanced version with better error handling for email verification
  Future<UserCredential> signUpWithEmailAndPassword({
    required String email,
    required String password,
    String displayName = 'New User',
    bool sendVerificationEmail = true,
  }) async {
    print('Starting signUpWithEmailAndPassword with email: $email');
    print('Firebase Auth instance: ${_auth.toString()}');
    print('Current app name: ${_auth.app.name}');

    // Step 1: Create the user account with Firebase Auth
    print('STEP 1: Creating Firebase Auth account...');
    UserCredential userCredential;

    try {
      userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final userId = userCredential.user?.uid;
      print('Firebase Auth account created successfully: $userId');

      if (userCredential.user == null) {
        print('WARNING: User object is null after account creation!');
      } else {
        print('User email: ${userCredential.user!.email}');
        print('Email verified status: ${userCredential.user!.emailVerified}');
      }
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

      // Force a reload to ensure we have the latest user data
      await userCredential.user!.reload();
      print('User reloaded after display name update');
      print('Current display name: ${userCredential.user!.displayName}');
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
        // Use our improved verification email sender with rate limiting
        await sendVerificationEmailWithRateLimiting(userCredential.user!);
        print('Email verification sent successfully');
      } catch (e) {
        print('Error during verification email sending: $e');
        // Don't throw here - allow account creation to succeed even if email fails
        // The user can request another verification email later
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

    // Step 5: Sign out the user so they must verify email and log in again
    print('STEP 5: Signing out user to require email verification');
    try {
      await _auth.signOut();
      print('User signed out successfully - they must verify email and log in');
    } catch (e, stack) {
      print('Error signing out user:');
      print('Error type: ${e.runtimeType}');
      print('Error message: $e');
      print('Stack trace: $stack');
      // Continue despite this error - not critical
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
      final user = _auth.currentUser;
      if (user != null) {
        final uid = user.uid;

        // Delete user data from all collections
        final collections = [
          'users',
          'experiences',
          'wish_wall',
          'posts',
          'comments',
        ];
        final batch = FirebaseFirestore.instance.batch();

        for (final collection in collections) {
          final docRef = FirebaseFirestore.instance
              .collection(collection)
              .doc(uid);
          batch.delete(docRef);
        }

        await batch.commit();

        // Delete user from Firebase Authentication
        await user.delete();

        // Sign out the user
        await signOut();
      }
    } catch (e) {
      print('Error deleting account: $e');
      rethrow;
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

  // Method to send verification email with improved rate limiting and error handling
  Future<void> sendVerificationEmailWithRateLimiting(User user) async {
    try {
      // Check if user is null
      if (user == null) {
        print('Error: User is null when attempting to send verification email');
        return;
      }

      // Check if email is already verified
      await user.reload();
      user = _auth.currentUser!;
      if (user.emailVerified) {
        print('User ${user.uid} email ${user.email} is already verified');
        return;
      }

      // Log current timestamp for debugging
      print(
        'Attempting to send verification email to ${user.email} at ${DateTime.now().toIso8601String()}',
      );

      // Check rate limiting conditions
      final today = DateTime.now().toIso8601String().split('T')[0];
      if (_dailyCounterReset == null ||
          DateTime.now().difference(_dailyCounterReset!).inHours >= 24) {
        print('Resetting daily email counter');
        _emailSendCounter = 0;
        _dailyCounterReset = DateTime.now();
      }

      if (_emailSendCounter >= _maxDailyEmails) {
        print(
          'Daily email limit reached for $today. Sent: $_emailSendCounter, Max: $_maxDailyEmails',
        );
        throw Exception(
          'Too many verification emails have been sent today. '
          'Please try again tomorrow or contact support.',
        );
      }

      final userId = user.uid;
      final userAttempt = _userVerificationAttempts[userId];

      if (userAttempt != null) {
        final timeSince = DateTime.now().difference(userAttempt.lastAttempt);
        final minutesBetweenAttempts =
            2 * userAttempt.attemptCount; // Progressive backoff
        final requiredWait = Duration(minutes: minutesBetweenAttempts);

        if (timeSince < requiredWait) {
          final waitMinutes =
              (requiredWait.inMinutes - timeSince.inMinutes).toInt();
          print('User-specific rate limit: Wait ${waitMinutes} more minutes');
          throw Exception(
            'Please wait about ${waitMinutes + 1} minutes before requesting '
            'another verification email.',
          );
        }
      }

      // Global rate limiting check
      if (_lastEmailSentTime != null) {
        final timeSince = DateTime.now().difference(_lastEmailSentTime!);
        if (timeSince < _minEmailInterval) {
          final waitNeeded = _minEmailInterval - timeSince;
          print(
            'Global rate limit: Must wait ${waitNeeded.inSeconds} more seconds',
          );
          throw Exception(
            'Please wait ${waitNeeded.inMinutes + 1} minutes before requesting '
            'another verification email.',
          );
        }
      }

      // All checks passed, attempt to send email
      try {
        print('Sending verification email to: ${user.email}');
        print('User ID: ${user.uid}');

        // Configure ActionCodeSettings with your app's domain
        final actionCodeSettings = ActionCodeSettings(
          url: 'https://your-app-domain.firebaseapp.com',
          handleCodeInApp: true,
          androidPackageName: 'com.example.yourapp',
          iOSBundleId: 'com.example.yourapp',
        );

        // Send the verification email with ActionCodeSettings
        await user.sendEmailVerification(actionCodeSettings);

        print('Verification email sent via standard Firebase method');
      } on FirebaseAuthException catch (firebaseError) {
        print('Firebase method failed: $firebaseError');

        // Special handling for too-many-requests errors
        if (firebaseError is FirebaseAuthException &&
            firebaseError.code == 'too-many-requests') {
          throw Exception(
            'Firebase rate limit reached. Please wait at least 30 minutes '
            'before requesting another verification email.',
          );
        }

        // Re-throw the original error
        throw firebaseError;
      } catch (e) {
        print('Unexpected error sending verification email: $e');
        throw Exception('Failed to send verification email: $e');
      }

      // Update tracking variables
      _lastEmailSentTime = DateTime.now();
      _emailSendCounter++;

      // Update per-user tracking
      if (userAttempt == null) {
        _userVerificationAttempts[userId] = _VerificationAttempt(
          DateTime.now(),
          1,
        );
      } else {
        userAttempt.lastAttempt = DateTime.now();
        userAttempt.attemptCount++;
      }

      print('Verification email sent successfully (count: $_emailSendCounter)');
      print(
        'User attempt count: ${_userVerificationAttempts[userId]?.attemptCount ?? 1}',
      );

      // Additional instructions for the user
      print('Recommend user to check spam/junk folders');
      print('Recommend user to add Firebase email to contacts');
    } catch (e) {
      print('Error sending verification email to ${user.email}: $e');
      if (e is FirebaseAuthException) {
        print(
          'FirebaseAuthException details - Code: ${e.code}, Message: ${e.message}',
        );
      }
    }
  }

  // Advanced alternative that tries multiple approaches to send verification email
  Future<bool> sendVerificationEmailAdvanced(User user) async {
    print('Attempting advanced verification email sending...');

    try {
      // First try - standard method
      print('Attempt 1: Standard Firebase method');
      await user.sendEmailVerification();
      print('Standard method succeeded');
      return true;
    } catch (e) {
      print('Standard method failed: $e');

      // Second try after a short delay
      try {
        print('Attempt 2: With delay and reload');
        await Future.delayed(const Duration(seconds: 2));
        await user.reload();
        await user.sendEmailVerification();
        print('Second attempt succeeded');
        return true;
      } catch (e2) {
        print('All verification email attempts failed');
        print('Final error: $e2');
        return false;
      }
    }
  }

  // Custom email verification with SendGrid
  Future<void> sendCustomVerificationEmail(User user) async {
    try {
      print('Generating custom email verification link');

      // Generate email verification token
      final token = await user.getIdToken();

      // Create custom verification link with your domain
      final verificationLink =
          'https://your-app-domain.com/verify-email?token=$token';
      print('Verification link: $verificationLink');

      // Create the HTML email content
      final htmlContent = '''
        <h2>Email Verification</h2>
        <p>Hello,</p>
        <p>Please click the link below to verify your email address:</p>
        <p><a href="$verificationLink">Verify Email</a></p>
        <p>If you did not request this verification, please ignore this email.</p>
        <p>Thank you,<br>Your App Team</p>
      ''';

      // Create a plain text alternative
      final plainText =
          'Please verify your email by visiting this link: $verificationLink';

      // Create the email message using our new SendGridService
      final apiKey = dotenv.env['SENDGRID_API_KEY'] ?? 'YOUR_SENDGRID_API_KEY';
      final sendGridService = SendGridService(apiKey: apiKey);

      // Create an HTML email with a plain text alternative
      final message = SendGridService.createHtmlEmail(
        toEmail: user.email!,
        fromEmail: 'noreply@your-app-domain.com',
        fromName: 'Your App Name',
        subject: 'Verify your email address',
        htmlContent: htmlContent,
        plainText: plainText,
      );

      print('Sending custom verification email to ${user.email}');
      await sendGridService.sendEmail(message);
      print('Custom verification email sent successfully');
    } catch (e) {
      print('Error sending custom verification email: $e');
      rethrow;
    }
  }

  // Phone number authentication
  Future<void> verifyPhoneNumber(
    String phoneNumber,
    Function(String) onCodeSent,
    Function(FirebaseAuthException) onVerificationFailed,
    Function(PhoneAuthCredential) onVerificationCompleted,
  ) async {
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: onVerificationCompleted,
        verificationFailed: onVerificationFailed,
        codeSent: (verificationId, forceResendingToken) {
          onCodeSent(verificationId);
        },
        codeAutoRetrievalTimeout: (verificationId) {},
        timeout: const Duration(seconds: 120),
      );
    } catch (e) {
      throw Exception('Phone verification failed: ${e.toString()}');
    }
  }

  Future<UserCredential> signInWithPhoneNumber(
    String verificationId,
    String smsCode,
  ) async {
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );
      return await _auth.signInWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Change password
  Future<void> changePassword(
    String currentPassword,
    String newPassword,
  ) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('No user is signed in');
    }

    // Reauthenticate user
    final credential = EmailAuthProvider.credential(
      email: user.email!,
      password: currentPassword,
    );
    await user.reauthenticateWithCredential(credential);

    // Update password
    await user.updatePassword(newPassword);
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
