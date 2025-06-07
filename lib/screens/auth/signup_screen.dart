import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth_service.dart';
import '../../auth/phone_auth_screen.dart';

class SignUpScreen extends StatefulWidget {
  final VoidCallback onLoginPressed;

  const SignUpScreen({Key? key, required this.onLoginPressed})
    : super(key: key);

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _authService = AuthService();

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    // Validate form first
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final displayName = _nameController.text.trim();

    print('SignUpScreen: Starting sign-up process for email: $email');
    print('SignUpScreen: Display name: $displayName');

    try {
      // Use the regular sign-up function with email verification
      print('SignUpScreen: Calling AuthService.signUpWithEmailAndPassword...');

      // Clear error message if any
      setState(() {
        _errorMessage = null;
      });

      final result = await _authService.signUpWithEmailAndPassword(
        email: email,
        password: password,
        displayName: displayName,
        // Let our improved method handle the verification email
        sendVerificationEmail: true,
      );

      print('SignUpScreen: Sign-up successful with UID: ${result.user?.uid}');

      // Show success message and auto-navigate
      if (mounted) {
        print('SignUpScreen: Showing success message');

        // Reset loading state and show success message
        setState(() {
          _isLoading = false;
          _errorMessage = null; // Clear any previous errors
        });

        // Check if user record was successfully created in Firestore
        bool firestoreSuccess = true; // Assume success unless we know otherwise
        try {
          // Try to get the user's document
          final userDoc =
              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(result.user?.uid)
                  .get();

          // If document doesn't exist, Firestore creation failed
          if (!userDoc.exists) {
            firestoreSuccess = false;
            print('SignUpScreen: User document not found in Firestore');
          } else {
            print('SignUpScreen: User document exists in Firestore');
          }
        } catch (e) {
          // If there's an error checking Firestore, assume creation failed
          firestoreSuccess = false;
          print('SignUpScreen: Error checking Firestore document: $e');
        }

        // Show appropriate success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              firestoreSuccess
                  ? 'Account created successfully. Please verify your email.'
                  : 'Sorry, please check your email link.',
            ),
            backgroundColor: firestoreSuccess ? Colors.green : Colors.orange,
            duration: const Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );

        print(
          'SignUpScreen: Success message shown, navigating to login screen',
        );

        // Make sure the user is signed out
        try {
          await _authService.signOut();
          print('SignUpScreen: User signed out successfully before navigation');
        } catch (e) {
          print('SignUpScreen: Error signing out user: $e');
          // Continue anyway as this is not critical
        }

        // Show success dialog with clear information
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green),
                  SizedBox(width: 10),
                  Text('Registration Successful'),
                ],
              ),
              content: SingleChildScrollView(
                child: ListBody(
                  children: [
                    Text(
                      'A verification email has been sent to ${_emailController.text.trim()}.',
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Please check your inbox and verify your email before logging in.',
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('Go to Login'),
                  onPressed: () {
                    Navigator.of(context).pop(); // Close dialog
                    print(
                      'SignUpScreen: User clicked "Go to Login", navigating to login screen',
                    );

                    // Navigate to login screen
                    widget.onLoginPressed();
                    print('SignUpScreen: Navigation to login screen triggered');
                  },
                ),
              ],
            );
          },
        );
      }
    } on FirebaseAuthException catch (e) {
      // Handle specific Firebase Auth errors
      print('SignUpScreen ERROR: FirebaseAuthException');
      print('Code: ${e.code}');
      print('Message: ${e.message}');

      String userMessage;
      switch (e.code) {
        case 'email-already-in-use':
          userMessage =
              'This email is already registered. Please use a different email or try logging in.';
          break;
        case 'invalid-email':
          userMessage = 'Please enter a valid email address.';
          break;
        case 'operation-not-allowed':
          userMessage =
              'Email/password sign up is not enabled. Please contact support.';
          break;
        case 'weak-password':
          userMessage =
              'Your password is too weak. Please choose a stronger password.';
          break;
        case 'network-request-failed':
          userMessage =
              'Network error. Please check your internet connection and try again.';
          break;
        default:
          userMessage =
              e.message ??
              'An authentication error occurred. Please try again.';
      }

      setState(() {
        _errorMessage = userMessage;
        _isLoading = false;
      });
    } on FirebaseException catch (e) {
      // Handle Firestore or other Firebase errors
      print('SignUpScreen ERROR: FirebaseException');
      print('Code: ${e.code}');
      print('Message: ${e.message}');

      setState(() {
        _errorMessage =
            'Database error: ${e.message ?? 'Unknown database error'}';
        _isLoading = false;
      });
    } catch (e) {
      // Handle any other unexpected errors
      print('SignUpScreen ERROR: Unexpected error');
      print('Error type: ${e.runtimeType}');
      print('Error message: $e');

      // Detailed error logging for debugging
      print('Sign-Up Error Type: [31m${e.runtimeType}[0m');
      print('Sign-Up Error Message: [31m$e[0m');

      // Format the error message for better user experience
      String errorMsg = e.toString();
      if (errorMsg.contains('Exception:')) {
        errorMsg = errorMsg.replaceAll('Exception:', '').trim();
      }

      // If the error message is empty or just "Error", provide a more helpful message
      if (errorMsg.isEmpty || errorMsg == 'Error') {
        errorMsg =
            'An unknown error occurred during sign-up. Please try again later.';
      }

      setState(() {
        _errorMessage = errorMsg;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo or App Name
                  const Icon(Icons.star, size: 80, color: Color(0xFF7153DF)),
                  const SizedBox(height: 16),
                  const Text(
                    'Create Account',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF7153DF),
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Name Field
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Full Name',
                      prefixIcon: const Icon(Icons.person),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Email Field
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      prefixIcon: const Icon(Icons.email),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your email';
                      }
                      if (!RegExp(
                        r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                      ).hasMatch(value)) {
                        return 'Please enter a valid email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Password Field
                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a password';
                      }
                      if (value.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Confirm Password Field
                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Confirm Password',
                      prefixIcon: const Icon(Icons.lock_outline),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please confirm your password';
                      }
                      if (value != _passwordController.text) {
                        return 'Passwords do not match';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  // Error Message
                  if (_errorMessage != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(color: Colors.red.shade800),
                      ),
                    ),
                  if (_errorMessage != null) const SizedBox(height: 16),

                  // Sign Up Button
                  ElevatedButton(
                    onPressed: _isLoading ? null : _signUp,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7153DF),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      disabledBackgroundColor: Colors.grey.shade300,
                    ),
                    child:
                        _isLoading
                            ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                            : const Text(
                              'Sign Up',
                              style: TextStyle(fontSize: 16),
                            ),
                  ),
                  const SizedBox(height: 20),

                  // Phone Sign Up Button
                  OutlinedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const PhoneAuthScreen(isLogin: false),
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(color: Color(0xFF7153DF)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.phone, color: Color(0xFF7153DF)),
                        SizedBox(width: 8),
                        Text(
                          'Sign Up with Phone',
                          style: TextStyle(color: Color(0xFF7153DF)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Login Link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Already have an account?'),
                      TextButton(
                        onPressed: widget.onLoginPressed,
                        child: const Text('Login'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
