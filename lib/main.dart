import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import 'settings_screen.dart';
import 'home_screen.dart';
import 'plaza_feed_screen.dart';
import 'wish_wall_screen.dart';
import 'user_plaza_screen.dart';

void main() async {
  await dotenv.load(fileName: ".env");
  runApp(const LuckyStarApp());
}

class LuckyStarApp extends StatelessWidget {
  const LuckyStarApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lucky Star',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF7153DF), // Cosmic Purple
          secondary: const Color(0xFFF8F5F0), // Soft Gray
        ),
      ),
      home: const MainNavigation(),
      routes: {'/settings': (context) => const SettingsScreen()},
    );
  }
}

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  // Define the 5 core navigation tabs
  final List<Widget> _tabs = [
    const PlazaFeedScreen(), // 🌍 Plaza Feed
    const WishWallScreen(), // 💫 Wish Wall & Explore
    const UserPlazaScreen(), // 👥 User Plaza
    const HomeScreen(), // 🏠 Home Page
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _tabs[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.explore), label: 'Plaza'),
          BottomNavigationBarItem(icon: Icon(Icons.star), label: 'Wish Wall'),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'User Plaza',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        ],
      ),
    );
  }
}
