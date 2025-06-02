import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'home_screen.dart';
import 'plaza_feed_screen.dart';
import 'wish_wall_screen.dart';
import 'edit_profile_screen.dart';
import 'plaza_post_detail_screen.dart';
import 'my_page.dart';
import 'post_experience_screen.dart';
import 'request_experience_screen.dart';
import 'user_plaza_screen.dart';

void main() {
  initializeApp();
}

Future<void> initializeApp() async {
  try {
    await dotenv.load(fileName: ".env");
    runApp(const LuckyStarApp());
  } catch (e) {
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(child: Text('Error loading environment: $e')),
        ),
      ),
    );
  }
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
      routes: {
        '/home': (context) => const HomeScreen(),
        '/wish-wall': (context) => const WishWallScreen(),
        '/post-experience': (context) => const PostExperienceScreen(),
        '/request-experience': (context) => const RequestExperienceScreen(),
        '/edit-profile': (context) => const EditProfileScreen(),
        '/plaza-post-detail': (context) => const PlazaPostDetailScreen(),
        '/my-page': (context) => const MyPage(),
        '/user-plaza': (context) => const UserPlazaScreen(),
      },
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/plaza-post-detail':
            final args = settings.arguments as Map<String, dynamic>? ?? {};
            return MaterialPageRoute(
              builder: (context) => PlazaPostDetailScreen(
                title: args['title'] ?? 'Post Details',
                displayName: args['displayName'] ?? 'Anonymous',
                timestamp: args['timestamp'] ?? 'Just now',
                description: args['description'] ?? 'No description provided',
              ),
            );
          default:
            return MaterialPageRoute(
              builder: (context) => const MainNavigation(),
            );
        }
      },
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

  // Define the 4 core navigation tabs
  final List<Widget> _tabs = [
    const PlazaFeedScreen(), // 🌍 Plaza Feed
    const WishWallScreen(), // 💫 Wish Wall & Explore
    const UserPlazaScreen(), // 👥 User Plaza
    const HomeScreen(), // 🏠 Home Page
  ];

  final List<String> _tabLabels = [
    'Plaza',
    'Wish Wall',
    'User Plaza',
    'Home'
  ];

  final List<IconData> _tabIcons = [
    Icons.explore,
    Icons.star,
    Icons.person,
    Icons.home
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _tabs[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        items: List.generate(
          _tabs.length,
          (index) => BottomNavigationBarItem(
            icon: Icon(_tabIcons[index]),
            label: _tabLabels[index],
          ),
        ),
      ),
    );
  }
}

// Placeholder ChatPage widget
class ChatPage extends StatelessWidget {
  const ChatPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chat (Placeholder)')),
      body: const Center(
        child: Text(
          'ChatPage Placeholder\nReplace with actual chat screen.',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
