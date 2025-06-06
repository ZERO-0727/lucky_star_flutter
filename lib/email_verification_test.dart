import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// A focused test to diagnose Firebase email verification issues
class EmailVerificationTest extends StatefulWidget {
  const EmailVerificationTest({Key? key}) : super(key: key);

  @override
  State<EmailVerificationTest> createState() => _EmailVerificationTestState();
}

class _EmailVerificationTestState extends State<EmailVerificationTest> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  List<String> _logs = [];
  bool _isLoading = false;
  User? _currentUser;
  bool _isSuccess = false;

  @override
  void initState() {
    super.initState();
    _checkCurrentUser();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _log(String message, {bool isError = false}) {
    final timestamp = DateTime.now().toString().substring(0, 19);
    setState(() {
      _logs.add('[$timestamp] ${isError ? '❌ ' : ''}$message');
    });
    print('EMAIL TEST: $message');
  }

  void _checkCurrentUser() {
    setState(() {
      _currentUser = _auth.currentUser;
    });

    if (_currentUser != null) {
      _log('Currently signed in as: ${_currentUser!.email}');
      _log('Email verified: ${_currentUser!.emailVerified}');
    } else {
      _log('Not signed in');
    }
  }

  Future<void> _signIn() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      _log('Error: Email and password required', isError: true);
      return;
    }

    setState(() {
      _isLoading = true;
      _isSuccess = false;
    });

    try {
      _log('Signing in with email: ${_emailController.text}');

      final credential = await _auth.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      _log('Sign in successful: ${credential.user!.uid}');
      _checkCurrentUser();
    } catch (e) {
      _log('Error signing in: $e', isError: true);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _createAccount() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      _log('Error: Email and password required', isError: true);
      return;
    }

    setState(() {
      _isLoading = true;
      _isSuccess = false;
    });

    try {
      _log('Creating account with email: ${_emailController.text}');

      final credential = await _auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      _log('Account created successfully: ${credential.user!.uid}');
      _checkCurrentUser();
    } catch (e) {
      _log('Error creating account: $e', isError: true);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _sendVerificationEmail() async {
    setState(() {
      _isLoading = true;
      _isSuccess = false;
    });

    try {
      if (_auth.currentUser == null) {
        _log('Error: Not signed in', isError: true);
        return;
      }

      _log('Current time: ${DateTime.now().toString()}');
      _log('Sending verification email to: ${_auth.currentUser!.email}');
      _log('Firebase project ID: ${_auth.app.options.projectId}');
      _log('Firebase auth domain: ${_auth.app.options.authDomain}');

      // 1. Make sure we have the latest user data
      _log('Reloading user to ensure latest data...');
      await _auth.currentUser!.reload();

      if (_auth.currentUser!.emailVerified) {
        _log('Email is already verified!');
        return;
      }

      // 2. Attempt to send verification email with timing
      _log('Sending verification email...');
      final startTime = DateTime.now();
      await _auth.currentUser!.sendEmailVerification();
      final endTime = DateTime.now();
      final duration = endTime.difference(startTime);

      _log('✅ Verification email sent successfully!');
      _log('Request completed in ${duration.inMilliseconds}ms');

      setState(() {
        _isSuccess = true;
      });

      // 3. Display additional instructions
      _log('Note: Check both inbox and spam folders');
      _log(
        'Firebase sender address is typically noreply@[your-project-id].firebaseapp.com',
      );
    } catch (e) {
      _log('Error sending verification email: $e', isError: true);

      // 4. Special handling for specific errors
      if (e is FirebaseAuthException) {
        _log('Firebase Auth Error Code: ${e.code}');

        if (e.code == 'too-many-requests') {
          _log(
            'RATE LIMIT DETECTED: Firebase is blocking email sending due to quota',
          );
          _log(
            'This suggests you\'ve hit Firebase\'s daily/hourly quota limit',
          );
        }
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _checkVerificationStatus() async {
    setState(() {
      _isLoading = true;
    });

    try {
      if (_auth.currentUser == null) {
        _log('Error: Not signed in', isError: true);
        return;
      }

      _log('Checking verification status for: ${_auth.currentUser!.email}');

      // Force reload to get the latest status
      await _auth.currentUser!.reload();

      if (_auth.currentUser!.emailVerified) {
        _log('✅ Email IS verified!');
      } else {
        _log('❌ Email is NOT verified');
      }
    } catch (e) {
      _log('Error checking verification status: $e', isError: true);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _signOut() async {
    setState(() {
      _isLoading = true;
      _isSuccess = false;
    });

    try {
      _log('Signing out...');
      await _auth.signOut();
      _log('Signed out successfully');
      _checkCurrentUser();
    } catch (e) {
      _log('Error signing out: $e', isError: true);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _clearLogs() {
    setState(() {
      _logs.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Email Verification Test'),
        backgroundColor: Colors.purple,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _checkCurrentUser,
            tooltip: 'Refresh Auth State',
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _clearLogs,
            tooltip: 'Clear Logs',
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

                    // Success message if email was sent
                    if (_isSuccess)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green.shade100,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green),
                        ),
                        child: const Column(
                          children: [
                            Text(
                              'Verification Email Sent!',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Please check your inbox AND spam folder. It may take a few minutes to arrive.',
                            ),
                          ],
                        ),
                      ),
                    if (_isSuccess) const SizedBox(height: 16),

                    // Sign in form if not signed in
                    if (_currentUser == null) ...[
                      TextField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.email),
                        ),
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _passwordController,
                        decoration: const InputDecoration(
                          labelText: 'Password',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.lock),
                        ),
                        obscureText: true,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _signIn,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.all(12),
                              ),
                              child: const Text('Sign In'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _createAccount,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.all(12),
                              ),
                              child: const Text('Create Account'),
                            ),
                          ),
                        ],
                      ),
                    ],

                    // Actions if signed in
                    if (_currentUser != null) ...[
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _sendVerificationEmail,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.all(12),
                              ),
                              child: const Text('Send Verification Email'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _checkVerificationStatus,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.purple,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.all(12),
                              ),
                              child: const Text('Check Status'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: _signOut,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.all(12),
                        ),
                        child: const Text('Sign Out'),
                      ),
                    ],

                    const SizedBox(height: 16),
                    const Text(
                      'Logs:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),

                    // Logs section
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
                            final log = _logs[_logs.length - 1 - index];
                            Color color = Colors.green;

                            if (log.contains('Error') || log.contains('❌')) {
                              color = Colors.red;
                            } else if (log.contains('RATE LIMIT')) {
                              color = Colors.orange;
                            } else if (log.contains('✅')) {
                              color = Colors.green.shade300;
                            }

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Text(
                                log,
                                style: TextStyle(
                                  color: color,
                                  fontFamily: 'monospace',
                                  fontSize: 12,
                                ),
                              ),
                            );
                          },
                          reverse: true,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
    );
  }
}
