import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/signup_screen.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1a1a2e), // Dark blue
              Color(0xFF16213e), // Darker blue
              Color(0xFF0f3460), // Deep blue
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                // Logo and star icon at the top
                const Spacer(flex: 2),
                const Icon(
                  Icons.star,
                  size: 80,
                  color: Color(0xFFFFD700), // Gold color for the star
                ),
                const SizedBox(height: 24),

                // Main title in English
                Text(
                  'Welcome to CosmoSoul',
                  style: GoogleFonts.poppins(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),

                // Japanese title
                Text(
                  'ようこそ、体験でつながり未来へ',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFFB0B0B0), // Light gray
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                // Subheading
                Text(
                  'Find your next connection through experience.',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    color: const Color(0xFFE0E0E0), // Lighter gray
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),

                const Spacer(flex: 3),

                // Login and Sign Up buttons
                Column(
                  children: [
                    // Log In button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pushNamed(context, '/login');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF7153DF),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 8,
                          shadowColor: const Color(0xFF7153DF).withOpacity(0.3),
                        ),
                        child: Text(
                          'Log In',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Sign Up button
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) => SignUpScreen(
                                    onLoginPressed: () {
                                      Navigator.pop(context);
                                      Navigator.pushNamed(context, '/login');
                                    },
                                  ),
                            ),
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white, width: 2),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Sign Up',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // Footer text
                Text(
                  '© 2025 CosmoSoul. All rights reserved.',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: const Color(0xFF808080),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
