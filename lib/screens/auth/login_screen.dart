import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  final VoidCallback onSignUpPressed;

  const LoginScreen({Key? key, required this.onSignUpPressed})
    : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    try {
      print('LOGIN: Attempting to sign in with email: $email');

      // Sign in with email and password
      final userCredential = await _authService.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      print('LOGIN: Sign-in successful, user ID: ${userCredential.user?.uid}');

      // Reload the user to get the latest email verification status
      if (userCredential.user != null) {
        print('LOGIN: Reloading user to get latest verification status');
        await userCredential.user!.reload();

        // Get the fresh user object after reload
        final freshUser = _auth.currentUser;
        print('LOGIN: Email verified status: ${freshUser?.emailVerified}');

        // Check if email is verified using the fresh user object
        if (freshUser != null && !freshUser.emailVerified) {
          // Email is not verified, show a message and don't navigate
          if (mounted) {
            setState(() {
              _isLoading = false;
              _errorMessage =
                  'Please verify your email before signing in. Check your inbox for a verification link.';
            });

            // Offer to resend verification email
            showDialog(
              context: context,
              builder:
                  (context) => AlertDialog(
                    title: const Text('Email Not Verified'),
                    content: const Text(
                      'Your email has not been verified yet. Please check your inbox for a verification link.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: const Text('OK'),
                      ),
                      TextButton(
                        onPressed: () async {
                          Navigator.of(context).pop();
                          try {
                            await userCredential.user!.sendEmailVerification();
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Verification email sent!'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error sending email: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        },
                        child: const Text('Resend Email'),
                      ),
                    ],
                  ),
            );
          }
          return;
        }

        // Make sure to set loading to false before navigating
        setState(() {
          _isLoading = false;
        });

        // Email is verified, navigate to home screen
        print('LOGIN: Email is verified, navigating to home screen');
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/home');
        }
      } else {
        // User is null after sign-in (shouldn't happen, but handle it)
        print('LOGIN ERROR: User is null after successful sign-in');
        setState(() {
          _isLoading = false;
          _errorMessage = 'Authentication error: User is null after sign-in';
        });
      }
    } catch (e) {
      print('LOGIN ERROR: Exception during sign-in: ${e.runtimeType}');
      print('LOGIN ERROR: Message: $e');

      setState(() {
        _errorMessage = e.toString();
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
                    'Lucky Star',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF7153DF),
                    ),
                  ),
                  const SizedBox(height: 40),

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
                        return 'Please enter your password';
                      }
                      if (value.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),

                  // Forgot Password
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        // Navigate to forgot password screen
                      },
                      child: const Text('Forgot Password?'),
                    ),
                  ),
                  const SizedBox(height: 16),

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

                  // Sign In Button
                  ElevatedButton(
                    onPressed: _isLoading ? null : _signIn,
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
                              'Sign In',
                              style: TextStyle(fontSize: 16),
                            ),
                  ),
                  const SizedBox(height: 24),

                  // Sign Up Link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Don't have an account?"),
                      TextButton(
                        onPressed: widget.onSignUpPressed,
                        child: const Text('Sign Up'),
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
