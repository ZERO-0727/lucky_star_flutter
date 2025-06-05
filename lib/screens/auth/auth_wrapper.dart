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

          // If user is logged in, navigate to home screen
          if (user != null) {
            return Navigator(
              onGenerateRoute: (settings) {
                return MaterialPageRoute(
                  builder:
                      (context) => const Scaffold(
                        body: Center(child: CircularProgressIndicator()),
                      ),
                );
              },
              onPopPage: (route, result) {
                // Navigate to home screen
                Navigator.of(context).pushReplacementNamed('/home');
                return route.didPop(result);
              },
            );
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
