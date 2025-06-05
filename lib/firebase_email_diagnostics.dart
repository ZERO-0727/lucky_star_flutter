import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'services/auth_service.dart';

/// Advanced Firebase Email Diagnostics Tool
/// Created on June 5, 2025 to investigate critical email delivery failure
class FirebaseEmailDiagnosticsScreen extends StatefulWidget {
  const FirebaseEmailDiagnosticsScreen({Key? key}) : super(key: key);

  @override
  State<FirebaseEmailDiagnosticsScreen> createState() =>
      _FirebaseEmailDiagnosticsScreenState();
}

class _FirebaseEmailDiagnosticsScreenState
    extends State<FirebaseEmailDiagnosticsScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final _authService = AuthService();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _logs = <String>[];
  bool _isLoading = false;
  bool _isTestingMode = false;
  User? _currentUser;
  String _firebaseVersion = 'Checking...';
  String _firebaseStatus = 'Checking...';
  String _testResults = '';
  int _failureCounter = 0;

  @override
  void initState() {
    super.initState();
    _checkCurrentUser();
    _getFirebaseStatus();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _addLog(String message, {bool isError = false}) {
    final timestamp = DateTime.now().toString();
    setState(() {
      _logs.add('[$timestamp] ${isError ? '❌ ' : ''}$message');
    });
    if (isError) {
      print('EMAIL DIAG ERROR: $message');
    } else {
      print('EMAIL DIAG: $message');
    }
  }

  void _clearLogs() {
    setState(() {
      _logs.clear();
    });
  }

  void _checkCurrentUser() {
    setState(() {
      _currentUser = _auth.currentUser;
    });
    _addLog(
      'Current auth state: ${_currentUser != null ? "Signed in as ${_currentUser!.email}" : "Not signed in"}',
    );
    if (_currentUser != null) {
      _addLog('Email verified: ${_currentUser!.emailVerified}');
    }
  }

  Future<void> _getFirebaseStatus() async {
    try {
      // Check Firebase version
      final packageInfo = Firebase.app().options;
      setState(() {
        _firebaseVersion = 'Project ID: ${packageInfo.projectId}';
      });
      _addLog('Firebase project: ${packageInfo.projectId}');

      // Check Firebase Auth status via REST API status endpoint if possible
      try {
        final response = await http
            .get(
              Uri.parse('https://firebase.googleapis.com/v1beta1/status'),
              headers: {'Content-Type': 'application/json'},
            )
            .timeout(const Duration(seconds: 5));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          setState(() {
            _firebaseStatus = 'Firebase services operational';
          });
          _addLog('Firebase status check successful: ${data.toString()}');
        } else {
          setState(() {
            _firebaseStatus = 'Status check returned ${response.statusCode}';
          });
          _addLog('Firebase status error: ${response.body}', isError: true);
        }
      } catch (e) {
        setState(() {
          _firebaseStatus = 'Could not check Firebase status';
        });
        _addLog('Could not check Firebase status: $e', isError: true);
      }
    } catch (e) {
      setState(() {
        _firebaseVersion = 'Error getting Firebase info';
        _firebaseStatus = 'Unknown';
      });
      _addLog('Error getting Firebase info: $e', isError: true);
    }
  }

  // Create a test account for diagnostics
  Future<void> _createTestAccount() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      _addLog('Error: Email and password are required', isError: true);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      _addLog('Creating test account...');

      // First check if account exists and try to sign in
      try {
        _addLog('Checking if account already exists...');
        await _authService.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
        _addLog('Account exists, signed in successfully');

        // Force refresh
        await _auth.currentUser?.reload();
        _currentUser = _auth.currentUser;
      } catch (e) {
        _addLog('Account does not exist, creating new one');

        final result = await _authService.signUpWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
          displayName: 'Test User',
          // Important: don't send verification email now, we'll do it manually
          sendVerificationEmail: false,
        );

        _addLog('Account created: ${result.user?.uid}');
      }

      _checkCurrentUser();
    } catch (e) {
      _addLog('Error: ${e.toString()}', isError: true);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Run a comprehensive test of all email verification methods
  Future<void> _runComprehensiveTest() async {
    setState(() {
      _isLoading = true;
      _isTestingMode = true;
      _testResults = '';
      _failureCounter = 0;
    });
    _clearLogs();

    try {
      final user = _auth.currentUser;
      if (user == null) {
        _addLog('Error: Not signed in', isError: true);
        setState(() {
          _testResults = 'Failed: Not signed in';
          _isLoading = false;
          _isTestingMode = false;
        });
        return;
      }

      _addLog('STARTING COMPREHENSIVE EMAIL DIAGNOSTICS');
      _addLog('Current time: ${DateTime.now().toString()}');
      _addLog('User: ${user.email}');

      // Check Firebase Authentication Project Setup
      await _checkFirebaseProject();

      // Method 1: Direct Firebase Email
      final directResult = await _testDirectEmailMethod(user);

      // Method 2: Improved method with rate limiting
      final improvedResult = await _testImprovedEmailMethod(user);

      // Method 3: Retry with backoff
      final retryResult = await _testRetryEmailMethod(user);

      // Final analysis
      setState(() {
        if (_failureCounter == 0) {
          _testResults = 'All tests passed successfully!';
        } else if (_failureCounter == 3) {
          _testResults =
              'CRITICAL: All methods failed to send verification emails.';
        } else {
          _testResults = 'WARNING: $_failureCounter out of 3 methods failed.';
        }
      });

      _addLog('TEST COMPLETE: $_testResults');
    } catch (e) {
      _addLog('Unexpected error during tests: ${e.toString()}', isError: true);
      setState(() {
        _testResults = 'Test error: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
        _isTestingMode = false;
      });
    }
  }

  Future<void> _checkFirebaseProject() async {
    _addLog('Checking Firebase project configuration...');

    try {
      final app = Firebase.app();
      _addLog('Firebase app name: ${app.name}');
      _addLog('Firebase options: ${app.options.projectId}');

      // Get Auth instance details
      _addLog('Auth instance: ${_auth.toString()}');
      _addLog('Auth app name: ${_auth.app.name}');
      _addLog('Auth tenant ID: ${_auth.tenantId ?? "Not set"}');

      // Check if user is currently signed in
      if (_auth.currentUser != null) {
        _addLog('Current user: ${_auth.currentUser!.email}');
        _addLog('User ID: ${_auth.currentUser!.uid}');
        _addLog(
          'Provider data: ${_auth.currentUser!.providerData.map((p) => p.providerId).join(", ")}',
        );
      }

      // Check quota information if available
      _addLog('Note: Firebase does not expose quota information via API');
      _addLog('Check Firebase Console for quota details');
    } catch (e) {
      _addLog('Error checking Firebase project: $e', isError: true);
    }
  }

  Future<bool> _testDirectEmailMethod(User user) async {
    _addLog('TEST 1: Direct Firebase Email Method');
    _addLog('Sending verification email directly via Firebase...');

    try {
      // Reload user to ensure we have latest data
      await user.reload();
      final freshUser = _auth.currentUser;

      if (freshUser == null) {
        _addLog('Error: User is null after reload', isError: true);
        _failureCounter++;
        return false;
      }

      _addLog('Sending email to: ${freshUser.email}');
      final startTime = DateTime.now();
      await freshUser.sendEmailVerification();
      final endTime = DateTime.now();
      final duration = endTime.difference(startTime);

      _addLog('Email send request completed in ${duration.inMilliseconds}ms');
      _addLog('✅ TEST 1: Verification email request accepted by Firebase');
      return true;
    } catch (e) {
      _addLog('❌ TEST 1 FAILED: ${e.toString()}', isError: true);

      if (e is FirebaseAuthException) {
        _addLog('Firebase Auth Error Code: ${e.code}');
        _addLog('Firebase Auth Error Message: ${e.message}');

        if (e.code == 'too-many-requests') {
          _addLog('RATE LIMIT DETECTED: Firebase is blocking email sending');
          _addLog('This suggests quota exhaustion or temporary rate limiting');
        }
      }

      _failureCounter++;
      return false;
    }
  }

  Future<bool> _testImprovedEmailMethod(User user) async {
    _addLog('TEST 2: Improved Method with Rate Limiting');

    try {
      _addLog('Sending email via improved method...');

      await _authService.sendVerificationEmailWithRateLimiting(user);

      _addLog('✅ TEST 2: Verification email sent via improved method');
      return true;
    } catch (e) {
      _addLog('❌ TEST 2 FAILED: ${e.toString()}', isError: true);

      if (e.toString().contains('Too many verification emails')) {
        _addLog('RATE LIMIT DETECTED: App-level rate limiting triggered');
      }

      _failureCounter++;
      return false;
    }
  }

  Future<bool> _testRetryEmailMethod(User user) async {
    _addLog('TEST 3: Retry Method with Backoff');

    try {
      _addLog('Starting retry approach with backoff...');

      bool success = false;
      int attempts = 0;
      final maxAttempts = 2; // Limit retries for diagnostic test

      while (!success && attempts < maxAttempts) {
        attempts++;
        _addLog('Attempt $attempts of $maxAttempts...');

        try {
          // Wait with increasing backoff
          if (attempts > 1) {
            final delay = attempts * 2;
            _addLog('Waiting $delay seconds before retry...');
            await Future.delayed(Duration(seconds: delay));
          }

          // Reload user before each attempt
          await user.reload();
          final freshUser = _auth.currentUser;

          if (freshUser == null) {
            _addLog('Error: User is null after reload', isError: true);
            continue;
          }

          await freshUser.sendEmailVerification();
          _addLog('✅ Email sent successfully on attempt $attempts');
          success = true;
        } catch (attemptError) {
          _addLog('Attempt $attempts failed: $attemptError', isError: true);

          if (attemptError.toString().contains('too-many-requests')) {
            _addLog('RATE LIMIT on attempt $attempts - increasing backoff');
            // No need to continue retrying in diagnostic mode if we hit rate limit
            break;
          }
        }
      }

      if (success) {
        _addLog('✅ TEST 3: Email sent successfully with retry approach');
        return true;
      } else {
        _addLog(
          '❌ TEST 3 FAILED: Maximum retry attempts reached',
          isError: true,
        );
        _failureCounter++;
        return false;
      }
    } catch (e) {
      _addLog(
        '❌ TEST 3 FAILED with unexpected error: ${e.toString()}',
        isError: true,
      );
      _failureCounter++;
      return false;
    }
  }

  // Special diagnostic mode: attempt to identify quota issues
  Future<void> _checkForQuotaIssues() async {
    setState(() {
      _isLoading = true;
    });
    _clearLogs();

    try {
      _addLog('CHECKING FOR QUOTA AND RATE LIMIT ISSUES');
      _addLog('Current time: ${DateTime.now().toString()}');

      final user = _auth.currentUser;
      if (user == null) {
        _addLog('Error: Not signed in', isError: true);
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // 1. Check if we're hitting Firebase's own rate limits
      _addLog('Testing for Firebase rate limits...');

      try {
        await user.reload();
        await user.sendEmailVerification();
        _addLog(
          'Email request accepted by Firebase - not hitting Firebase rate limit',
        );
      } catch (e) {
        if (e is FirebaseAuthException && e.code == 'too-many-requests') {
          _addLog('FIREBASE RATE LIMIT DETECTED', isError: true);
          _addLog('Firebase is actively blocking email sending');
          _addLog('This confirms we have exceeded Firebase quota/rate limits');
          _addLog('Recovery time typically ranges from 1 hour to 24 hours');
        } else {
          _addLog('Error but not rate-limited: ${e.toString()}', isError: true);
        }
      }

      // 2. Check our app's rate limiting logic
      _addLog('Checking app-level rate limiting state...');

      // We can't directly access the static variables, so we'll try to send
      // through our custom method and see if it fails with rate limit message
      try {
        await _authService.sendVerificationEmailWithRateLimiting(user);
        _addLog('App-level rate limiting is not blocking email sends');
      } catch (e) {
        if (e.toString().contains('Too many verification emails') ||
            e.toString().contains('Please wait')) {
          _addLog('APP-LEVEL RATE LIMIT DETECTED', isError: true);
          _addLog('Our app is limiting email sending due to internal limits');
          _addLog('See AuthService class for the specific limits configured');
        } else {
          _addLog(
            'App error but not rate-limited: ${e.toString()}',
            isError: true,
          );
        }
      }

      // 3. Suggest potential solutions
      _addLog('Analyzing results...');
      _addLog('Potential solutions:');
      _addLog('1. Wait for rate limit to reset (typically 1-24 hours)');
      _addLog('2. Check Firebase Console for quota increases if available');
      _addLog(
        '3. Consider temporarily disabling email verification if critical',
      );
      _addLog('4. Check if Firebase Auth service is experiencing an outage');
    } catch (e) {
      _addLog('Error during quota check: ${e.toString()}', isError: true);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Firebase Email Diagnostics'),
        backgroundColor: Colors.red,
      ),
      body:
          _isLoading
              ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Running diagnostics...'),
                  ],
                ),
              )
              : Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Firebase status information
                    Card(
                      color: Colors.blue.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Firebase Status',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text('Version: $_firebaseVersion'),
                            Text('Status: $_firebaseStatus'),
                            if (_currentUser != null) ...[
                              const SizedBox(height: 8),
                              Text('Signed in as: ${_currentUser!.email}'),
                              Text(
                                'Verified: ${_currentUser!.emailVerified ? "Yes" : "No"}',
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Test results if in testing mode
                    if (_testResults.isNotEmpty)
                      Card(
                        color:
                            _failureCounter == 0
                                ? Colors.green.shade50
                                : Colors.orange.shade50,
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Test Results',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _testResults,
                                style: TextStyle(
                                  color:
                                      _failureCounter == 0
                                          ? Colors.green.shade800
                                          : Colors.red.shade800,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    if (_testResults.isNotEmpty) const SizedBox(height: 16),

                    // Controls section
                    if (_currentUser == null) ...[
                      // Sign in form if not logged in
                      TextField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _passwordController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Password',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: _createTestAccount,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Sign In / Create Test Account'),
                      ),
                    ] else ...[
                      // Test controls if logged in
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _runComprehensiveTest,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Run Comprehensive Test'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _checkForQuotaIssues,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Check for Quota Issues'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: () async {
                          await _auth.signOut();
                          _checkCurrentUser();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Sign Out'),
                      ),
                    ],
                    const SizedBox(height: 16),

                    // Logs section
                    const Text(
                      'Diagnostic Logs:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ListView.builder(
                          itemCount: _logs.length,
                          itemBuilder: (context, index) {
                            final log = _logs[index];
                            Color textColor = Colors.green;

                            if (log.contains('❌') ||
                                log.contains('ERROR') ||
                                log.contains('FAILED')) {
                              textColor = Colors.red;
                            } else if (log.contains('WARNING') ||
                                log.contains('RATE LIMIT')) {
                              textColor = Colors.orange;
                            }

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Text(
                                log,
                                style: TextStyle(
                                  color: textColor,
                                  fontFamily: 'monospace',
                                  fontSize: 12,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
    );
  }
}
