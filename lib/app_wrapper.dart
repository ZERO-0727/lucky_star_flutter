import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'services/auth_service.dart';
import 'welcome_page.dart';
import 'main.dart';

class AppWrapper extends StatelessWidget {
  const AppWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: AuthService().authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.active) {
          final User? user = snapshot.data;

          // If user is logged in and email is verified, go to home
          if (user != null && user.emailVerified) {
            print(
              'AppWrapper: User is authenticated and verified, going to home',
            );
            return const MainNavigation();
          }

          // For all other cases (no user, unverified user), show Welcome Page
          print('AppWrapper: No authenticated user, showing Welcome Page');
          return const WelcomePage();
        }

        // Show loading while checking auth state
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      },
    );
  }
}
