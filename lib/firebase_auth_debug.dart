import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseAuthDebugScreen extends StatefulWidget {
  const FirebaseAuthDebugScreen({Key? key}) : super(key: key);

  @override
  State<FirebaseAuthDebugScreen> createState() =>
      _FirebaseAuthDebugScreenState();
}

class _FirebaseAuthDebugScreenState extends State<FirebaseAuthDebugScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  String _userInfo = 'No user logged in';
  String _eventLog = '';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _updateUserInfo();

    // Listen to auth state changes
    _auth.authStateChanges().listen((User? user) {
      _log('Auth state changed: ${user?.email ?? 'No user'}');
      _updateUserInfo();
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _updateUserInfo() {
    setState(() {
      if (_auth.currentUser != null) {
        final user = _auth.currentUser!;
        _userInfo = '''
Current User:
  UID: ${user.uid}
  Email: ${user.email}
  Display Name: ${user.displayName ?? 'Not set'}
  Email Verified: ${user.emailVerified}
  Provider IDs: ${user.providerData.map((e) => e.providerId).join(', ')}
  Created: ${user.metadata.creationTime}
  Last Sign In: ${user.metadata.lastSignInTime}
''';
      } else {
        _userInfo = 'No user logged in';
      }
    });
  }

  void _log(String message) {
    final timestamp = DateTime.now().toString().substring(0, 19);
    setState(() {
      _eventLog = '[$timestamp] $message\n$_eventLog';
    });
    print('AUTH DEBUG: $message');
  }

  Future<void> _createAccount() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      _log('Error: Email and password must not be empty');
      return;
    }

    setState(() => _isLoading = true);

    try {
      _log('Creating account: ${_emailController.text}');
      final credentials = await _auth.createUserWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );
      _log('Account creation successful: ${credentials.user?.uid}');
      _updateUserInfo();
    } on FirebaseAuthException catch (e) {
      _log('Error creating account: [${e.code}] ${e.message}');
    } catch (e) {
      _log('Error creating account: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _signIn() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      _log('Error: Email and password must not be empty');
      return;
    }

    setState(() => _isLoading = true);

    try {
      _log('Signing in: ${_emailController.text}');
      final credentials = await _auth.signInWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );
      _log('Sign in successful: ${credentials.user?.uid}');
      _updateUserInfo();
    } on FirebaseAuthException catch (e) {
      _log('Error signing in: [${e.code}] ${e.message}');
    } catch (e) {
      _log('Error signing in: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _signOut() async {
    setState(() => _isLoading = true);

    try {
      _log('Signing out...');
      await _auth.signOut();
      _log('Sign out successful');
      _updateUserInfo();
    } catch (e) {
      _log('Error signing out: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _sendEmailVerification() async {
    setState(() => _isLoading = true);

    try {
      if (_auth.currentUser == null) {
        _log('No user signed in to verify');
        return;
      }

      _log('Sending verification email to: ${_auth.currentUser?.email}');

      // Make sure we have fresh user data
      await _auth.currentUser!.reload();

      // Check if already verified
      if (_auth.currentUser!.emailVerified) {
        _log('Email is already verified!');
        _updateUserInfo();
        setState(() => _isLoading = false);
        return;
      }

      await _auth.currentUser!.sendEmailVerification();
      _log('Verification email sent successfully');
    } on FirebaseAuthException catch (e) {
      _log('Error sending verification email: [${e.code}] ${e.message}');
    } catch (e) {
      _log('Error sending verification email: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _checkEmailVerified() async {
    setState(() => _isLoading = true);

    try {
      if (_auth.currentUser == null) {
        _log('No user signed in to check');
        return;
      }

      _log('Checking if email is verified for: ${_auth.currentUser?.email}');

      // Force a reload to get the latest status
      await _auth.currentUser!.reload();

      if (_auth.currentUser!.emailVerified) {
        _log('Email IS verified ✓');
      } else {
        _log('Email is NOT verified ✗');
      }

      _updateUserInfo();
    } catch (e) {
      _log('Error checking email verification: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteAccount() async {
    setState(() => _isLoading = true);

    try {
      if (_auth.currentUser == null) {
        _log('No user signed in to delete');
        return;
      }

      _log('Deleting account: ${_auth.currentUser?.email}');
      await _auth.currentUser!.delete();
      _log('Account deleted successfully');
      _updateUserInfo();
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        _log('You need to re-authenticate before deleting your account');

        try {
          // Try to re-authenticate if we have credentials available
          if (_emailController.text.isNotEmpty &&
              _passwordController.text.isNotEmpty) {
            _log('Re-authenticating...');
            final credential = EmailAuthProvider.credential(
              email: _emailController.text,
              password: _passwordController.text,
            );
            await _auth.currentUser!.reauthenticateWithCredential(credential);
            _log('Re-authentication successful, trying to delete again');

            // Try to delete again
            await _auth.currentUser!.delete();
            _log('Account deleted successfully after re-authentication');
            _updateUserInfo();
          } else {
            _log('Please enter email and password to re-authenticate');
          }
        } catch (reAuthErr) {
          _log('Re-authentication error: $reAuthErr');
        }
      } else {
        _log('Error deleting account: [${e.code}] ${e.message}');
      }
    } catch (e) {
      _log('Error deleting account: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Firebase Auth Debug'),
        backgroundColor: Colors.orange,
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Padding(
                padding: const EdgeInsets.all(16.0),
                child: ListView(
                  children: [
                    const Text(
                      'User Status',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(_userInfo),
                    ),
                    const SizedBox(height: 16),

                    const Text(
                      'Auth Operations',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
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
                      decoration: const InputDecoration(
                        labelText: 'Password',
                        border: OutlineInputBorder(),
                      ),
                      obscureText: true,
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _createAccount,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Create Account'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _signIn,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Sign In'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _signOut,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Sign Out'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _sendEmailVerification,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Send Verification'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _checkEmailVerified,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.purple,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Check Verification'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _deleteAccount,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Delete Account'),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),
                    const Text(
                      'Event Log',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 200,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: SingleChildScrollView(
                        child: Text(
                          _eventLog,
                          style: const TextStyle(color: Colors.green),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
    );
  }
}
