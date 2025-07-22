import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/auth_service.dart';
import 'login_screen.dart';
import 'forgot_password_screen.dart';

class AccountManagementScreen extends StatefulWidget {
  const AccountManagementScreen({Key? key}) : super(key: key);

  @override
  State<AccountManagementScreen> createState() =>
      _AccountManagementScreenState();
}

class _AccountManagementScreenState extends State<AccountManagementScreen> {
  final AuthService _authService = AuthService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isLoading = false;

  User? get currentUser => _auth.currentUser;

  // Change password
  Future<void> _changePassword(BuildContext context) async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => ForgotPasswordScreen(
              onBackToLogin: () => Navigator.pop(context),
            ),
      ),
    );
  }

  // Delete account
  Future<void> _showDeleteAccountConfirmation() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Account'),
          content: SingleChildScrollView(
            child: ListBody(
              children: const [
                Text('Are you sure you want to delete your account?'),
                SizedBox(height: 10),
                Text(
                  'This action cannot be undone. All your data will be permanently deleted.',
                  style: TextStyle(color: Colors.red),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deleteAccount();
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  // Perform account deletion
  Future<void> _deleteAccount() async {
    setState(() {
      _isLoading = true;
    });

    try {
      print('ACCOUNT: Attempting to delete user account');
      await _authService.deleteAccount();
      print('ACCOUNT: Account deleted successfully');

      // Navigate to login screen after successful deletion
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder:
                (context) => LoginScreen(
                  onSignUpPressed:
                      () {}, // This won't be used as we're removing all routes
                ),
          ),
          (Route<dynamic> route) => false,
        );

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Your account has been deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('ACCOUNT ERROR: Failed to delete account: $e');
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Account Settings'),
        backgroundColor: const Color(0xFF7153DF),
        foregroundColor: Colors.white,
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Account info section
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Account Information',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            ListTile(
                              leading: const Icon(Icons.email),
                              title: const Text('Email'),
                              subtitle: Text(
                                currentUser?.email ?? 'Not available',
                              ),
                              contentPadding: EdgeInsets.zero,
                            ),
                            ListTile(
                              leading: const Icon(Icons.verified_user),
                              title: const Text('Email Verification'),
                              subtitle: Text(
                                currentUser?.emailVerified ?? false
                                    ? 'Verified'
                                    : 'Not verified',
                              ),
                              trailing:
                                  currentUser?.emailVerified ?? false
                                      ? const Icon(
                                        Icons.check_circle,
                                        color: Colors.green,
                                      )
                                      : TextButton(
                                        onPressed: () async {
                                          setState(() => _isLoading = true);
                                          try {
                                            if (currentUser != null) {
                                              // Use our improved rate-limited method
                                              await _authService
                                                  .sendVerificationEmailWithRateLimiting(
                                                    currentUser!,
                                                  );

                                              if (mounted) {
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  const SnackBar(
                                                    content: Text(
                                                      'Verification email sent! Please check your inbox and spam folder.',
                                                    ),
                                                    backgroundColor:
                                                        Colors.green,
                                                    duration: Duration(
                                                      seconds: 5,
                                                    ),
                                                  ),
                                                );
                                              }
                                            } else {
                                              throw Exception(
                                                'User is not logged in',
                                              );
                                            }
                                          } catch (e) {
                                            print(
                                              'Error sending verification email: $e',
                                            );
                                            if (mounted) {
                                              // Get a clean error message
                                              String errorMsg = e.toString();
                                              if (errorMsg.contains(
                                                'Exception:',
                                              )) {
                                                errorMsg =
                                                    errorMsg
                                                        .replaceAll(
                                                          'Exception:',
                                                          '',
                                                        )
                                                        .trim();
                                              }

                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                SnackBar(
                                                  content: Text(errorMsg),
                                                  backgroundColor:
                                                      Colors.orange,
                                                  duration: const Duration(
                                                    seconds: 5,
                                                  ),
                                                ),
                                              );
                                            }
                                          } finally {
                                            if (mounted) {
                                              setState(
                                                () => _isLoading = false,
                                              );
                                            }
                                          }
                                        },
                                        child: const Text('Verify'),
                                      ),
                              contentPadding: EdgeInsets.zero,
                            ),
                            ListTile(
                              leading: const Icon(Icons.person),
                              title: const Text('Display Name'),
                              subtitle: Text(
                                currentUser?.displayName ?? 'Not set',
                              ),
                              contentPadding: EdgeInsets.zero,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // App information
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'App Information',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 16),
                            ListTile(
                              leading: Icon(Icons.info),
                              title: Text('Version'),
                              subtitle: Text('1.0.0'),
                              contentPadding: EdgeInsets.zero,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Delete Account Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _showDeleteAccountConfirmation,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Delete Account',
                          style: TextStyle(fontSize: 18),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
    );
  }
}
