import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'services/auth_service.dart';

/// This screen provides a dedicated interface for testing and verifying
/// all critical authentication flows in one place.
class AuthFlowTestScreen extends StatefulWidget {
  const AuthFlowTestScreen({Key? key}) : super(key: key);

  @override
  State<AuthFlowTestScreen> createState() => _AuthFlowTestScreenState();
}

class _AuthFlowTestScreenState extends State<AuthFlowTestScreen> {
  final _authService = AuthService();
  final _auth = FirebaseAuth.instance;

  // Controllers
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();

  // Test state
  String _statusMessage = 'Ready for testing';
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  // Update status with timestamp
  void _updateStatus(String message) {
    final timestamp = DateTime.now().toString().substring(11, 19);
    setState(() {
      _statusMessage = '[$timestamp] $message';
    });
    print('AUTH TEST: $message');
  }

  // Check current auth state
  void _checkAuthState() {
    final user = _auth.currentUser;
    if (user == null) {
      _updateStatus('Not authenticated');
    } else {
      _updateStatus(
        'Authenticated as: ${user.email}\n'
        'Email verified: ${user.emailVerified}\n'
        'User ID: ${user.uid}\n'
        'Display name: ${user.displayName ?? "Not set"}',
      );
    }
  }

  // Create a new test account
  Future<void> _createTestAccount() async {
    if (_emailController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _nameController.text.isEmpty) {
      _updateStatus('Error: All fields are required');
      return;
    }

    setState(() => _isLoading = true);

    try {
      _updateStatus('Creating account...');

      final result = await _authService.signUpWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        displayName: _nameController.text.trim(),
        sendVerificationEmail: true,
      );

      _updateStatus(
        'Account created successfully!\n'
        'User ID: ${result.user?.uid}\n'
        'Verification email sent. Please check inbox and spam folder.',
      );
    } catch (e) {
      String errorMsg = e.toString();
      if (errorMsg.contains('Exception:')) {
        errorMsg = errorMsg.replaceAll('Exception:', '').trim();
      }
      _updateStatus('Error: $errorMsg');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Sign in with existing account
  Future<void> _signIn() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      _updateStatus('Error: Email and password are required');
      return;
    }

    setState(() => _isLoading = true);

    try {
      _updateStatus('Signing in...');

      final result = await _authService.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // Reload to get latest verification status
      await result.user?.reload();
      final freshUser = _auth.currentUser;

      _updateStatus(
        'Sign in successful!\n'
        'User ID: ${freshUser?.uid}\n'
        'Email verified: ${freshUser?.emailVerified}\n'
        'Display name: ${freshUser?.displayName ?? "Not set"}',
      );
    } catch (e) {
      String errorMsg = e.toString();
      if (errorMsg.contains('Exception:')) {
        errorMsg = errorMsg.replaceAll('Exception:', '').trim();
      }
      _updateStatus('Error: $errorMsg');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Send verification email
  Future<void> _sendVerificationEmail() async {
    setState(() => _isLoading = true);

    try {
      final user = _auth.currentUser;

      if (user == null) {
        _updateStatus('Error: You must be signed in to verify email');
        return;
      }

      _updateStatus('Sending verification email...');

      await _authService.sendVerificationEmailWithRateLimiting(user);

      _updateStatus(
        'Verification email sent successfully to ${user.email}.\n'
        'Please check your inbox and spam folder.',
      );
    } catch (e) {
      String errorMsg = e.toString();
      if (errorMsg.contains('Exception:')) {
        errorMsg = errorMsg.replaceAll('Exception:', '').trim();
      }
      _updateStatus('Error: $errorMsg');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Check email verification status
  Future<void> _checkVerificationStatus() async {
    setState(() => _isLoading = true);

    try {
      final user = _auth.currentUser;

      if (user == null) {
        _updateStatus('Error: You must be signed in to check verification');
        return;
      }

      _updateStatus('Checking verification status...');

      // Force reload to get latest status
      await user.reload();
      final freshUser = _auth.currentUser;

      if (freshUser?.emailVerified ?? false) {
        _updateStatus('Email IS verified ✓');
      } else {
        _updateStatus('Email is NOT verified ✗');
      }
    } catch (e) {
      _updateStatus('Error: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Sign out
  Future<void> _signOut() async {
    setState(() => _isLoading = true);

    try {
      _updateStatus('Signing out...');

      await _authService.signOut();

      _updateStatus('Signed out successfully');
    } catch (e) {
      _updateStatus('Error: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Auth Flow Test'),
        backgroundColor: const Color(0xFF7153DF),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _checkAuthState,
            tooltip: 'Check Auth State',
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Padding(
                padding: const EdgeInsets.all(16.0),
                child: ListView(
                  children: [
                    // Status section
                    Card(
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Status',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              width: double.infinity,
                              child: Text(_statusMessage),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Input fields
                    Card(
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Test Credentials',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextField(
                              controller: _nameController,
                              decoration: const InputDecoration(
                                labelText: 'Display Name',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.person),
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              decoration: const InputDecoration(
                                labelText: 'Email',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.email),
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _passwordController,
                              obscureText: true,
                              decoration: const InputDecoration(
                                labelText: 'Password',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.lock),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Account creation and sign in
                    Card(
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Registration & Login',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: _createTestAccount,
                                    icon: const Icon(Icons.person_add),
                                    label: const Text('Create Account'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.all(12),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: _signIn,
                                    icon: const Icon(Icons.login),
                                    label: const Text('Sign In'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blue,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.all(12),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Email verification
                    Card(
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Email Verification',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: _sendVerificationEmail,
                                    icon: const Icon(Icons.mark_email_read),
                                    label: const Text('Send Verification'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.orange,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.all(12),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: _checkVerificationStatus,
                                    icon: const Icon(Icons.verified_user),
                                    label: const Text('Check Status'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.purple,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.all(12),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Account management
                    Card(
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Account Management',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: _signOut,
                                    icon: const Icon(Icons.logout),
                                    label: const Text('Sign Out'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.grey.shade700,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.all(12),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () {
                                      Navigator.pushNamed(
                                        context,
                                        '/account-management',
                                      );
                                    },
                                    icon: const Icon(Icons.settings),
                                    label: const Text('Account Settings'),
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.all(12),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Column(
                              children: [
                                ElevatedButton.icon(
                                  onPressed: () {
                                    Navigator.pushNamed(
                                      context,
                                      '/firebase-auth-debug',
                                    );
                                  },
                                  icon: const Icon(Icons.bug_report),
                                  label: const Text('Advanced Debug'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.all(12),
                                    minimumSize: const Size(
                                      double.infinity,
                                      48,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                ElevatedButton.icon(
                                  onPressed: () {
                                    Navigator.pushNamed(
                                      context,
                                      '/email-verification-debug',
                                    );
                                  },
                                  icon: const Icon(Icons.email),
                                  label: const Text('Email Verification Debug'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.deepOrange,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.all(12),
                                    minimumSize: const Size(
                                      double.infinity,
                                      48,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                ElevatedButton.icon(
                                  onPressed: () {
                                    Navigator.pushNamed(
                                      context,
                                      '/firebase-email-diagnostics',
                                    );
                                  },
                                  icon: const Icon(Icons.bug_report),
                                  label: const Text(
                                    'Firebase Email Diagnostics',
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.all(12),
                                    minimumSize: const Size(
                                      double.infinity,
                                      48,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                ElevatedButton.icon(
                                  onPressed: () {
                                    Navigator.pushNamed(
                                      context,
                                      '/email-verification-test',
                                    );
                                  },
                                  icon: const Icon(Icons.email_outlined),
                                  label: const Text(
                                    'Simple Email Verification Test',
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.purple,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.all(12),
                                    minimumSize: const Size(
                                      double.infinity,
                                      48,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
    );
  }
}
