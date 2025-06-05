import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'services/auth_service.dart';

/// Advanced email verification debugging tool
class EmailVerificationDebugScreen extends StatefulWidget {
  const EmailVerificationDebugScreen({Key? key}) : super(key: key);

  @override
  State<EmailVerificationDebugScreen> createState() =>
      _EmailVerificationDebugScreenState();
}

class _EmailVerificationDebugScreenState
    extends State<EmailVerificationDebugScreen> {
  final _authService = AuthService();
  final _auth = FirebaseAuth.instance;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _logs = <String>[];
  bool _isLoading = false;
  User? _currentUser;
  Timer? _reloadTimer;
  int _retryCount = 0;
  int _maxRetries = 3;

  @override
  void initState() {
    super.initState();
    _checkCurrentUser();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _reloadTimer?.cancel();
    super.dispose();
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

  void _addLog(String message) {
    final timestamp = DateTime.now().toString().substring(11, 19);
    setState(() {
      _logs.add('[$timestamp] $message');
    });
    print('EMAIL DEBUG: $message');
  }

  // Create a test account for debugging
  Future<void> _createTestAccount() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      _addLog('Error: Email and password are required');
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
      _addLog('Error: ${e.toString()}');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Try to send verification email directly using Firebase's method
  Future<void> _sendVerificationEmailDirect() async {
    setState(() {
      _isLoading = true;
      _retryCount = 0;
    });

    try {
      final user = _auth.currentUser;
      if (user == null) {
        _addLog('Error: Not signed in');
        return;
      }

      _addLog('Sending verification email directly via Firebase...');

      // Reload user before sending to ensure latest status
      await user.reload();
      final freshUser = _auth.currentUser;

      if (freshUser == null) {
        _addLog('Error: User is null after reload');
        return;
      }

      if (freshUser.emailVerified) {
        _addLog('User is already verified, no need to send email');
        return;
      }

      _addLog('Sending email to: ${freshUser.email}');

      try {
        await freshUser.sendEmailVerification();
        _addLog(
          '✅ Verification email sent successfully (Direct Firebase method)',
        );
      } catch (e) {
        _addLog('❌ Error sending email: $e');

        if (e.toString().contains('too-many-requests')) {
          _addLog('⚠️ RATE LIMIT DETECTED: Firebase is blocking email sending');
        }
      }
    } catch (e) {
      _addLog('❌ Unexpected error: ${e.toString()}');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Try our improved verification email sender
  Future<void> _sendVerificationEmailImproved() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = _auth.currentUser;
      if (user == null) {
        _addLog('Error: Not signed in');
        return;
      }

      _addLog('Sending verification email with our improved method...');

      try {
        await _authService.sendVerificationEmailWithRateLimiting(user);
        _addLog('✅ Verification email sent successfully (Improved method)');
      } catch (e) {
        _addLog('❌ Error in improved method: $e');
      }
    } catch (e) {
      _addLog('❌ Unexpected error: ${e.toString()}');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Try with a different approach - retry with increasing delays
  Future<void> _sendWithRetry() async {
    setState(() {
      _isLoading = true;
      _retryCount = 0;
    });

    try {
      final user = _auth.currentUser;
      if (user == null) {
        _addLog('Error: Not signed in');
        return;
      }

      _addLog('Starting retry approach with backoff...');
      _retryEmailSend(user);
    } catch (e) {
      _addLog('❌ Error in retry initialization: ${e.toString()}');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _retryEmailSend(User user) async {
    if (_retryCount >= _maxRetries) {
      _addLog('⚠️ Maximum retries reached without success');
      setState(() {
        _isLoading = false;
      });
      return;
    }

    _retryCount++;
    final delay = _retryCount * 2; // Increasing delay: 2s, 4s, 6s...

    _addLog('Attempt $_retryCount of $_maxRetries (with ${delay}s delay)...');

    // Wait for the delay
    await Future.delayed(Duration(seconds: delay));

    try {
      // Make sure user is fresh
      await user.reload();
      final freshUser = _auth.currentUser;

      if (freshUser == null) {
        _addLog('Error: User is null after reload in retry');
        setState(() {
          _isLoading = false;
        });
        return;
      }

      _addLog('Sending email to: ${freshUser.email}');
      await freshUser.sendEmailVerification();
      _addLog('✅ Verification email sent on attempt $_retryCount!');
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      _addLog('❌ Attempt $_retryCount failed: $e');

      if (e.toString().contains('too-many-requests')) {
        _addLog('⚠️ RATE LIMIT DETECTED on attempt $_retryCount');
        // Increase the delay more aggressively
        _maxRetries++;
      }

      // Retry
      _retryEmailSend(user);
    }
  }

  // Start or stop checking verification status periodically
  void _toggleVerificationCheck() {
    if (_reloadTimer != null) {
      _reloadTimer!.cancel();
      _reloadTimer = null;
      _addLog('Stopped verification checking');
      return;
    }

    _addLog('Starting verification status checks every 10 seconds...');
    _checkVerificationStatus();

    _reloadTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      _checkVerificationStatus();
    });
  }

  // Check if the user's email has been verified
  Future<void> _checkVerificationStatus() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        _addLog('Cannot check verification: Not signed in');
        return;
      }

      _addLog('Checking verification status...');

      // Force reload to get latest status
      await user.reload();
      final freshUser = _auth.currentUser;

      if (freshUser?.emailVerified ?? false) {
        _addLog('✅ SUCCESS: Email IS verified!');
        // Stop the timer if email is verified
        _reloadTimer?.cancel();
        _reloadTimer = null;
      } else {
        _addLog('❌ Email is still NOT verified');
      }

      setState(() {
        _currentUser = freshUser;
      });
    } catch (e) {
      _addLog('Error checking verification: ${e.toString()}');
    }
  }

  // Sign out
  Future<void> _signOut() async {
    try {
      _addLog('Signing out...');
      await _authService.signOut();
      _addLog('Signed out successfully');
      _checkCurrentUser();
    } catch (e) {
      _addLog('Error signing out: ${e.toString()}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Email Verification Debug'),
        backgroundColor: Colors.red,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _checkCurrentUser,
            tooltip: 'Check Auth State',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _signOut,
            tooltip: 'Sign Out',
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Current user status
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color:
                            _currentUser == null
                                ? Colors.red.shade100
                                : _currentUser!.emailVerified
                                ? Colors.green.shade100
                                : Colors.orange.shade100,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color:
                              _currentUser == null
                                  ? Colors.red
                                  : _currentUser!.emailVerified
                                  ? Colors.green
                                  : Colors.orange,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Status: ${_currentUser == null ? "Not Signed In" : "Signed In"}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          if (_currentUser != null) ...[
                            Text('Email: ${_currentUser!.email}'),
                            Text(
                              'Verified: ${_currentUser!.emailVerified ? "YES ✓" : "NO ✗"}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color:
                                    _currentUser!.emailVerified
                                        ? Colors.green
                                        : Colors.red,
                              ),
                            ),
                            Text('User ID: ${_currentUser!.uid}'),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Only show inputs if not signed in
                    if (_currentUser == null) ...[
                      TextField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.email),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _passwordController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Password',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.lock),
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _createTestAccount,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.all(12),
                        ),
                        child: const Text('Sign In / Create Test Account'),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Verification actions (only if signed in but not verified)
                    if (_currentUser != null &&
                        !_currentUser!.emailVerified) ...[
                      const Text(
                        'Send Verification Email Using:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _sendVerificationEmailDirect,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Firebase Direct'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _sendVerificationEmailImproved,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Improved Method'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: _sendWithRetry,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Send with Retry & Backoff'),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _toggleVerificationCheck,
                        icon: Icon(
                          _reloadTimer != null ? Icons.stop : Icons.play_arrow,
                        ),
                        label: Text(
                          _reloadTimer != null
                              ? 'Stop Checking'
                              : 'Start Verification Checks (every 10s)',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              _reloadTimer != null ? Colors.red : Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],

                    const SizedBox(height: 16),
                    // Logs section
                    const Text(
                      'Debug Logs:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade400),
                        ),
                        child: ListView.builder(
                          itemCount: _logs.length,
                          reverse: true,
                          itemBuilder: (context, index) {
                            final log = _logs[_logs.length - 1 - index];
                            Color color = Colors.black;

                            if (log.contains('Error') || log.contains('❌')) {
                              color = Colors.red;
                            } else if (log.contains('SUCCESS') ||
                                log.contains('✅')) {
                              color = Colors.green;
                            } else if (log.contains('RATE LIMIT') ||
                                log.contains('⚠️')) {
                              color = Colors.orange;
                            }

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Text(
                                log,
                                style: TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 12,
                                  color: color,
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
