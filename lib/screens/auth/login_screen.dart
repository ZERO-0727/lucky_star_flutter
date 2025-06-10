import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/auth_service.dart';
import 'forgot_password_screen.dart';
import '../../auth/phone_auth_screen.dart';

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

    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

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
          print('LOGIN: Email is NOT verified, blocking access');

          // Sign out the user since they're not verified
          await _authService.signOut();
          print('LOGIN: Signed out unverified user');

          // Email is not verified, show SnackBar and reset loading state
          if (mounted) {
            setState(() {
              _isLoading = false;
              _errorMessage = null;
            });

            // Show SnackBar with verification message
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text(
                  'Your email is not verified. Please check your inbox.',
                ),
                backgroundColor: Colors.orange,
                duration: const Duration(seconds: 5),
                behavior: SnackBarBehavior.floating,
                margin: const EdgeInsets.all(16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                action: SnackBarAction(
                  label: 'Resend',
                  textColor: Colors.white,
                  onPressed: () async {
                    setState(() {
                      _isLoading = true;
                    });

                    try {
                      // Since we signed out the user, we need to sign in again to send verification
                      final tempCredential = await _authService
                          .signInWithEmailAndPassword(
                            email: email,
                            password: password,
                          );

                      // Use our improved verification method
                      await _authService.sendVerificationEmailWithRateLimiting(
                        tempCredential.user!,
                      );

                      // Sign out again after sending verification
                      await _authService.signOut();

                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text(
                              'Verification email sent! Please check your inbox and spam folder.',
                            ),
                            backgroundColor: Colors.green,
                            duration: const Duration(seconds: 5),
                            behavior: SnackBarBehavior.floating,
                            margin: const EdgeInsets.all(16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        );
                      }
                    } catch (e) {
                      print('Error resending verification email: $e');
                      if (mounted) {
                        String errorMsg = e.toString();
                        if (errorMsg.contains('Exception:')) {
                          errorMsg =
                              errorMsg.replaceAll('Exception:', '').trim();
                        }

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(errorMsg),
                            backgroundColor: Colors.orange,
                            duration: const Duration(seconds: 5),
                            behavior: SnackBarBehavior.floating,
                            margin: const EdgeInsets.all(16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        );
                      }
                    } finally {
                      if (mounted) {
                        setState(() {
                          _isLoading = false;
                        });
                      }
                    }
                  },
                ),
              ),
            );
          }
          return;
        }

        // Make sure to set loading to false before navigating
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }

        // Let AuthWrapper handle navigation based on verification status
        print(
          'LOGIN: Authentication successful - letting AuthWrapper handle verification and navigation',
        );

        // The AuthWrapper will automatically detect this auth state change
        // and check for email verification status before navigating
      } else {
        // User is null after sign-in (shouldn't happen, but handle it)
        print('LOGIN ERROR: User is null after successful sign-in');
        if (mounted) {
          setState(() {
            _isLoading = false;
            _errorMessage = 'Authentication error: User is null after sign-in';
          });
        }
      }
    } on FirebaseAuthException catch (e) {
      print('LOGIN ERROR: FirebaseAuthException: ${e.code}');
      print('LOGIN ERROR: Message: ${e.message}');

      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = null;
        });
      }

      // Show user-friendly error messages via SnackBar
      String errorMessage;
      Color backgroundColor;

      switch (e.code) {
        case 'user-not-found':
        case 'wrong-password':
        case 'invalid-credential':
          errorMessage = 'Incorrect email or password. Please try again.';
          backgroundColor = Colors.red;
          break;
        case 'user-disabled':
          errorMessage =
              'This account has been disabled. Please contact support.';
          backgroundColor = Colors.red;
          break;
        case 'too-many-requests':
          errorMessage = 'Too many failed attempts. Please try again later.';
          backgroundColor = Colors.orange;
          break;
        case 'network-request-failed':
          errorMessage =
              'Network error. Please check your connection and try again.';
          backgroundColor = Colors.orange;
          break;
        case 'invalid-email':
          errorMessage = 'Please enter a valid email address.';
          backgroundColor = Colors.red;
          break;
        default:
          errorMessage = e.message ?? 'Login failed. Please try again.';
          backgroundColor = Colors.red;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: backgroundColor,
            duration: const Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    } catch (e) {
      print('LOGIN ERROR: Unexpected exception: ${e.runtimeType}');
      print('LOGIN ERROR: Message: $e');

      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = null;
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'An unexpected error occurred. Please try again.',
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
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
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) => ForgotPasswordScreen(
                                  onBackToLogin: () => Navigator.pop(context),
                                ),
                          ),
                        );
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
                  const SizedBox(height: 20),

                  // Phone Login Button
                  OutlinedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const PhoneAuthScreen(isLogin: true),
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
                          'Continue with Phone',
                          style: TextStyle(color: Color(0xFF7153DF)),
                        ),
                      ],
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
