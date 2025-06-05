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
              // Email is NOT verified, sign out and show login screen
              print('AuthWrapper: Email is NOT verified, signing out user');

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
