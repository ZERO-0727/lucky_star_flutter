import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_screen.dart';
import 'signup_screen.dart';
import '../../services/auth_service.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  final AuthService _authService = AuthService();
  bool _showLogin = true;

  void _toggleView() {
    setState(() {
      _showLogin = !_showLogin;
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: _authService.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.active) {
          final User? user = snapshot.data;

          // If user is logged in, check email verification before proceeding
          if (user != null) {
            print(
              'AuthWrapper: User is logged in, checking email verification',
            );
            print('AuthWrapper: Email verified status: ${user.emailVerified}');

            // Check if email is verified - CRUCIAL SECURITY CHECK
            if (user.emailVerified) {
              print(
                'AuthWrapper: Email is verified, navigating to home screen',
              );

              // Use Future.microtask to avoid build-time navigation
              Future.microtask(() {
                Navigator.of(
                  context,
                ).pushNamedAndRemoveUntil('/home', (route) => false);
              });

              // Show a loading indicator while navigation is in progress
              return const Scaffold(
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Loading your account...'),
                    ],
                  ),
                ),
              );
            } else {
              // Email is NOT verified - check if user is in registration grace period
              print(
                'AuthWrapper: Email is NOT verified, checking registration status',
              );

              // Check if user is in registration grace period
              bool inRegistration = RegistrationManager.isUserInRegistration(
                user.uid,
              );
              print(
                'AuthWrapper: User in registration grace period: $inRegistration',
              );

              if (inRegistration) {
                // User is in registration process, allow them to stay signed in
                // Show a special screen indicating they need to verify their email
                print(
                  'AuthWrapper: User in registration - showing verification pending screen',
                );
                return Scaffold(
                  body: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.mark_email_unread,
                            size: 80,
                            color: Color(0xFF7153DF),
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            'Verify Your Email',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'We sent a verification email to ${user.email}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 16),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Please check your inbox and click the verification link.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 14, color: Colors.grey),
                          ),
                          const SizedBox(height: 32),
                          ElevatedButton(
                            onPressed: () async {
                              await _authService.signOut();
                            },
                            child: const Text('Back to Login'),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              } else {
                // User is not in registration process, sign them out
                print('AuthWrapper: User not in registration - signing out');

                // Use Future.microtask to avoid build-time side effects
                Future.microtask(() async {
                  await _authService.signOut();
                  print('AuthWrapper: Unverified user signed out');

                  // Show a snackbar message if available
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Please verify your email before logging in.',
                        ),
                        backgroundColor: Colors.orange,
                        duration: Duration(seconds: 5),
                      ),
                    );
                  }
                });

                // Return login screen for unverified users
                return LoginScreen(onSignUpPressed: _toggleView);
              }
            }
          }

          // If user is not logged in, show login or signup screen
          return _showLogin
              ? LoginScreen(onSignUpPressed: _toggleView)
              : SignUpScreen(onLoginPressed: _toggleView);
        }

        // Show loading indicator while checking auth state
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      },
    );
  }
}
