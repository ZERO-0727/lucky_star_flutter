import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseAuthDebugScreen extends StatefulWidget {
  const FirebaseAuthDebugScreen({Key? key}) : super(key: key);

  @override
  State<FirebaseAuthDebugScreen> createState() =>
      _FirebaseAuthDebugScreenState();
}

class _FirebaseAuthDebugScreenState extends State<FirebaseAuthDebugScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String _status = 'Ready to test';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _emailController.text =
        'test${DateTime.now().millisecondsSinceEpoch}@example.com';
    _passwordController.text = 'Test123456';
    _nameController.text = 'Test User';
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  // Test 1: Create Firebase Auth account only
  Future<void> _testCreateAuthOnly() async {
    setState(() {
      _isLoading = true;
      _status = 'Testing Firebase Auth account creation...';
    });

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();

      print('DEBUG: Creating Firebase Auth account only...');
      print('DEBUG: Email: $email');
      print('DEBUG: Password length: ${password.length}');
      print('DEBUG: Firebase Auth instance: ${_auth.app.name}');
      print(
        'DEBUG: Firebase Auth currentUser: ${_auth.currentUser?.uid ?? "null"}',
      );

      // Add a timeout to detect hanging operations
      final UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password)
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw TimeoutException(
                'Firebase Auth operation timed out after 30 seconds',
              );
            },
          );

      print('DEBUG: Auth account created successfully');
      print('DEBUG: User ID: ${userCredential.user?.uid}');
      print('DEBUG: Email verified: ${userCredential.user?.emailVerified}');
      print('DEBUG: Provider data: ${userCredential.user?.providerData}');

      setState(() {
        _status =
            'SUCCESS: Auth account created!\nUID: ${userCredential.user?.uid}';
        _isLoading = false;
      });
    } on FirebaseAuthException catch (e) {
      print('DEBUG ERROR: FirebaseAuthException');
      print('DEBUG ERROR: Code: ${e.code}');
      print('DEBUG ERROR: Message: ${e.message}');
      print('DEBUG ERROR: Stack trace: ${e.stackTrace}');
      print('DEBUG ERROR: Email credential: ${e.email}');
      print('DEBUG ERROR: Tenant ID: ${e.tenantId}');

      String detailedError = 'AUTH ERROR: ${e.code}\nMessage: ${e.message}';

      // Add specific guidance based on error code
      switch (e.code) {
        case 'email-already-in-use':
          detailedError +=
              '\n\nThis email is already registered. Try logging in instead.';
          break;
        case 'invalid-email':
          detailedError += '\n\nThe email address format is invalid.';
          break;
        case 'operation-not-allowed':
          detailedError +=
              '\n\nEmail/password sign-up is not enabled in Firebase Console.';
          break;
        case 'weak-password':
          detailedError +=
              '\n\nThe password is too weak. Use at least 6 characters.';
          break;
        case 'network-request-failed':
          detailedError += '\n\nNetwork error. Check your internet connection.';
          break;
      }

      setState(() {
        _status = detailedError;
        _isLoading = false;
      });
    } on TimeoutException catch (e) {
      print('DEBUG ERROR: TimeoutException');
      print('DEBUG ERROR: Message: $e');

      setState(() {
        _status =
            'TIMEOUT ERROR: Firebase Auth operation took too long.\nThis may indicate network issues or Firebase configuration problems.';
        _isLoading = false;
      });
    } catch (e) {
      print('DEBUG ERROR: Unknown error type: ${e.runtimeType}');
      print('DEBUG ERROR: Message: $e');
      print('DEBUG ERROR: ToString: ${e.toString()}');

      // Try to extract more information from the error
      final errorString = e.toString();
      String detailedError = 'UNKNOWN ERROR: ${e.runtimeType}\nMessage: $e';

      if (errorString.contains('network')) {
        detailedError +=
            '\n\nThis appears to be a network-related issue. Check your internet connection.';
      } else if (errorString.contains('permission') ||
          errorString.contains('denied')) {
        detailedError +=
            '\n\nThis appears to be a permissions issue. Check Firebase project settings.';
      } else if (errorString.contains('configuration')) {
        detailedError +=
            '\n\nThis appears to be a configuration issue. Check Firebase setup.';
      }

      setState(() {
        _status = detailedError;
        _isLoading = false;
      });
    }
  }

  // Test 2: Create Firestore document only
  Future<void> _testCreateFirestoreOnly() async {
    setState(() {
      _isLoading = true;
      _status = 'Testing Firestore document creation...';
    });

    try {
      final docId = 'test_${DateTime.now().millisecondsSinceEpoch}';
      final displayName = _nameController.text.trim();

      print('DEBUG: Creating Firestore document only...');
      print('DEBUG: Document ID: $docId');

      final now = DateTime.now();
      final userData = {
        'userId': docId,
        'displayName': displayName,
        'email': _emailController.text.trim(),
        'createdAt': now,
        'updatedAt': now,
        'testField': 'This is a test document',
      };

      await _firestore
          .collection('test_users')
          .doc(docId)
          .set(userData)
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw Exception('Firestore operation timed out');
            },
          );

      print('DEBUG: Firestore document created successfully');

      setState(() {
        _status = 'SUCCESS: Firestore document created!\nID: $docId';
        _isLoading = false;
      });
    } on FirebaseException catch (e) {
      print('DEBUG ERROR: FirebaseException');
      print('DEBUG ERROR: Code: ${e.code}');
      print('DEBUG ERROR: Message: ${e.message}');

      setState(() {
        _status = 'FIRESTORE ERROR: ${e.code}\nMessage: ${e.message}';
        _isLoading = false;
      });
    } catch (e) {
      print('DEBUG ERROR: Unknown error type: ${e.runtimeType}');
      print('DEBUG ERROR: Message: $e');

      setState(() {
        _status = 'UNKNOWN ERROR: ${e.runtimeType}\nMessage: $e';
        _isLoading = false;
      });
    }
  }

  // Test 3: Full sign-up process
  Future<void> _testFullSignUp() async {
    setState(() {
      _isLoading = true;
      _status = 'Testing full sign-up process...';
    });

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();
      final displayName = _nameController.text.trim();

      print('DEBUG: Starting full sign-up process...');
      print('DEBUG: Email: $email');

      // Step 1: Create Auth account
      print('DEBUG STEP 1: Creating Firebase Auth account...');
      final UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);

      print('DEBUG: Auth account created successfully');
      print('DEBUG: User ID: ${userCredential.user?.uid}');

      // Step 2: Update display name
      if (userCredential.user != null) {
        print('DEBUG STEP 2: Updating display name...');
        await userCredential.user!.updateDisplayName(displayName);
        print('DEBUG: Display name updated successfully');
      }

      // Step 3: Create Firestore document
      if (userCredential.user != null) {
        print('DEBUG STEP 3: Creating Firestore document...');
        final userId = userCredential.user!.uid;
        final now = DateTime.now();

        final userData = {
          'userId': userId,
          'displayName': displayName,
          'email': email,
          'createdAt': now,
          'updatedAt': now,
          'testField': 'This is a test document',
        };

        await _firestore
            .collection('test_users')
            .doc(userId)
            .set(userData)
            .timeout(
              const Duration(seconds: 10),
              onTimeout: () {
                throw Exception('Firestore operation timed out');
              },
            );

        print('DEBUG: Firestore document created successfully');
      }

      setState(() {
        _status =
            'SUCCESS: Full sign-up completed!\nUID: ${userCredential.user?.uid}';
        _isLoading = false;
      });
    } on FirebaseAuthException catch (e) {
      print('DEBUG ERROR: FirebaseAuthException');
      print('DEBUG ERROR: Code: ${e.code}');
      print('DEBUG ERROR: Message: ${e.message}');

      setState(() {
        _status = 'AUTH ERROR: ${e.code}\nMessage: ${e.message}';
        _isLoading = false;
      });
    } on FirebaseException catch (e) {
      print('DEBUG ERROR: FirebaseException');
      print('DEBUG ERROR: Code: ${e.code}');
      print('DEBUG ERROR: Message: ${e.message}');

      setState(() {
        _status = 'FIRESTORE ERROR: ${e.code}\nMessage: ${e.message}';
        _isLoading = false;
      });
    } catch (e) {
      print('DEBUG ERROR: Unknown error type: ${e.runtimeType}');
      print('DEBUG ERROR: Message: $e');

      setState(() {
        _status = 'UNKNOWN ERROR: ${e.runtimeType}\nMessage: $e';
        _isLoading = false;
      });
    }
  }

  // Test 4: Check Firebase Auth status
  Future<void> _checkAuthStatus() async {
    setState(() {
      _isLoading = true;
      _status = 'Checking Firebase Auth status...';
    });

    try {
      final User? user = _auth.currentUser;

      if (user != null) {
        print('DEBUG: User is signed in');
        print('DEBUG: User ID: ${user.uid}');
        print('DEBUG: Email: ${user.email}');
        print('DEBUG: Display name: ${user.displayName}');

        setState(() {
          _status =
              'SIGNED IN\nUID: ${user.uid}\nEmail: ${user.email}\nName: ${user.displayName}';
          _isLoading = false;
        });
      } else {
        print('DEBUG: No user is signed in');

        setState(() {
          _status = 'NOT SIGNED IN';
          _isLoading = false;
        });
      }
    } catch (e) {
      print('DEBUG ERROR: Unknown error type: ${e.runtimeType}');
      print('DEBUG ERROR: Message: $e');

      setState(() {
        _status = 'ERROR: ${e.runtimeType}\nMessage: $e';
        _isLoading = false;
      });
    }
  }

  // Test 5: Sign out
  Future<void> _signOut() async {
    setState(() {
      _isLoading = true;
      _status = 'Signing out...';
    });

    try {
      await _auth.signOut();

      print('DEBUG: User signed out successfully');

      setState(() {
        _status = 'SIGNED OUT SUCCESSFULLY';
        _isLoading = false;
      });
    } catch (e) {
      print('DEBUG ERROR: Unknown error type: ${e.runtimeType}');
      print('DEBUG ERROR: Message: $e');

      setState(() {
        _status = 'ERROR: ${e.runtimeType}\nMessage: $e';
        _isLoading = false;
      });
    }
  }

  // Test 6: Check Firebase Configuration
  Future<void> _checkFirebaseConfig() async {
    setState(() {
      _isLoading = true;
      _status = 'Checking Firebase configuration...';
    });

    try {
      print('DEBUG: Checking Firebase configuration...');

      // Check Firebase app
      print('DEBUG: Firebase app name: ${_auth.app.name}');
      print('DEBUG: Firebase app options: ${_auth.app.options.projectId}');
      print('DEBUG: Firebase app options apiKey: ${_auth.app.options.apiKey}');

      // Check if email/password auth is enabled
      print('DEBUG: Attempting to fetch sign-in methods...');

      // Try to fetch sign-in methods for a test email
      final testEmail = 'test_probe@example.com';
      final signInMethods = await _auth.fetchSignInMethodsForEmail(testEmail);

      print('DEBUG: Available sign-in methods: $signInMethods');
      print('DEBUG: Sign-in methods count: ${signInMethods.length}');

      // Check if anonymous auth works (as a fallback test)
      print('DEBUG: Testing anonymous sign-in...');
      final anonymousResult = await _auth.signInAnonymously();
      print('DEBUG: Anonymous sign-in result: ${anonymousResult.user?.uid}');

      // Sign out after anonymous sign-in
      await _auth.signOut();

      setState(() {
        _status = '''FIREBASE CONFIG CHECK:
        
App name: ${_auth.app.name}
Project ID: ${_auth.app.options.projectId}
API Key: ${_auth.app.options.apiKey}

Sign-in methods available: ${signInMethods.isEmpty ? 'None detected' : signInMethods.join(', ')}
Anonymous auth: Working

DIAGNOSIS:
${signInMethods.contains('password') ? '✅ Email/Password authentication is enabled' : '❌ Email/Password authentication appears to be DISABLED in Firebase Console'}

${anonymousResult.user != null ? '✅ Firebase Authentication is working (anonymous auth succeeded)' : '❌ Firebase Authentication may be misconfigured (anonymous auth failed)'}

RECOMMENDATION:
${signInMethods.contains('password') ? 'The issue may be with your app code or network connectivity.' : 'Enable Email/Password authentication in the Firebase Console:\n1. Go to Firebase Console\n2. Select your project\n3. Go to Authentication > Sign-in method\n4. Enable Email/Password provider'}
''';
        _isLoading = false;
      });
    } on FirebaseAuthException catch (e) {
      print('DEBUG ERROR: FirebaseAuthException during config check');
      print('DEBUG ERROR: Code: ${e.code}');
      print('DEBUG ERROR: Message: ${e.message}');

      setState(() {
        _status = '''FIREBASE CONFIG ERROR:
        
Error code: ${e.code}
Error message: ${e.message}

DIAGNOSIS:
${e.code == 'operation-not-allowed' ? '❌ The requested authentication provider is not enabled in Firebase Console' : '❌ Firebase Authentication configuration error'}

RECOMMENDATION:
1. Check Firebase Console > Authentication > Sign-in method
2. Ensure Email/Password provider is enabled
3. Verify your Firebase project settings
4. Check your network connectivity
''';
        _isLoading = false;
      });
    } catch (e) {
      print('DEBUG ERROR: Unknown error during config check: ${e.runtimeType}');
      print('DEBUG ERROR: Message: $e');

      setState(() {
        _status = '''FIREBASE CONFIG ERROR:
        
Error type: ${e.runtimeType}
Error message: $e

DIAGNOSIS:
❌ Unable to verify Firebase configuration

RECOMMENDATION:
1. Check your internet connection
2. Verify Firebase project settings
3. Ensure Firebase initialization is correct
4. Check Firebase Console for any project issues
''';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Firebase Auth Debug'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Firebase Auth & Firestore Debug',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),

            // Input fields
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Display Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),

            // Status display
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Status:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : Text(_status),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Test buttons
            ElevatedButton(
              onPressed: _isLoading ? null : _testCreateAuthOnly,
              child: const Text('Test 1: Create Auth Account Only'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _isLoading ? null : _testCreateFirestoreOnly,
              child: const Text('Test 2: Create Firestore Document Only'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _isLoading ? null : _testFullSignUp,
              child: const Text('Test 3: Full Sign-Up Process'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _isLoading ? null : _checkAuthStatus,
              child: const Text('Test 4: Check Auth Status'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _isLoading ? null : _signOut,
              child: const Text('Test 5: Sign Out'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _isLoading ? null : _checkFirebaseConfig,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Test 6: Check Firebase Config'),
            ),
          ],
        ),
      ),
    );
  }
}
