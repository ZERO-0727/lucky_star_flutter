import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'home_screen.dart';
import 'plaza_feed_screen.dart';
import 'wish_wall_screen.dart';
import 'edit_profile_screen.dart';
import 'plaza_post_detail_screen.dart';
import 'my_page.dart';
import 'post_experience_screen.dart';
import 'post_wish_screen.dart';
import 'request_experience_screen.dart';
import 'user_plaza_screen.dart';
import 'firebase_test.dart';
import 'firebase_auth_debug.dart';
import 'auth_flow_test.dart';
import 'email_verification_debug.dart';
import 'firebase_email_diagnostics.dart';
import 'email_verification_test.dart';
import 'firebase_email_verification_check.dart';
import 'firebase_email_verification_debug.dart';
import 'screens/auth/auth_wrapper.dart';
import 'screens/auth/profile_screen.dart';
import 'welcome_page.dart';
import 'app_wrapper.dart';
import 'screens/image_upload_test_screen.dart';
import 'experience_detail_screen.dart';
import 'chat_list_screen.dart';
import 'chat_detail_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    print('Starting app initialization...');

    // Load environment variables
    print('Loading environment variables...');
    try {
      await dotenv.load(fileName: ".env");
      print('Environment variables loaded successfully');
    } catch (envError) {
      print('WARNING: Error loading environment variables: $envError');
      print('Continuing without environment variables');
      // Continue without env variables - they might not be critical
    }

    // Initialize Firebase with detailed error handling
    print('Initializing Firebase...');
    try {
      final FirebaseApp app = await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      print('Firebase initialized successfully');
      print('Firebase App name: ${app.name}');
      print('Firebase options: ${app.options.projectId}');

      // Verify Firebase Auth is working
      print('Verifying Firebase Auth...');
      final auth = FirebaseAuth.instance;
      print('Firebase Auth instance created: ${auth.app.name}');

      // Verify Firestore is working
      print('Verifying Firestore...');
      final firestore = FirebaseFirestore.instance;
      print('Firestore instance created: ${firestore.app.name}');
    } catch (firebaseError) {
      print('CRITICAL ERROR: Firebase initialization failed: $firebaseError');
      throw Exception('Firebase initialization failed: $firebaseError');
    }

    print('App initialization completed successfully');
    runApp(const LuckyStarApp());
  } catch (e, stack) {
    print('FATAL ERROR initializing app: $e');
    print('Stack trace: $stack');
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 60),
                  const SizedBox(height: 20),
                  const Text(
                    'App Initialization Error',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Error details: $e',
                    style: const TextStyle(fontSize: 16),
                    textAlign: TextAlign.center,
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
      home: const AppWrapper(),
      routes: {
        '/home': (context) => const MainNavigation(),
        '/wish-wall': (context) => const WishWallScreen(),
        '/post-experience': (context) => const PostExperienceScreen(),
        '/post-wish': (context) => const PostWishScreen(),
        '/request-experience': (context) => const RequestExperienceScreen(),
        '/edit-profile': (context) => const EditProfileScreen(),
        '/my-page': (context) => const MyPage(),
        '/user-plaza': (context) => const UserPlazaScreen(),
        '/firebase-test': (context) => const FirebaseTestScreen(),
        '/firebase-auth-debug': (context) => const FirebaseAuthDebugScreen(),
        '/auth-flow-test': (context) => const AuthFlowTestScreen(),
        '/email-verification-debug':
            (context) => const EmailVerificationDebugScreen(),
        '/firebase-email-diagnostics':
            (context) => const FirebaseEmailDiagnosticsScreen(),
        '/email-verification-test': (context) => const EmailVerificationTest(),
        '/firebase-email-verification-check':
            (context) => const FirebaseEmailVerificationCheck(),
        '/firebase-email-verification-debug':
            (context) => const FirebaseEmailVerificationDebug(),
        '/welcome': (context) => const WelcomePage(),
        '/login': (context) => const AuthWrapper(),
        '/profile': (context) => const ProfileScreen(),
        '/image-upload-test': (context) => const ImageUploadTestScreen(),
        '/experience-detail':
            (context) => const ExperienceDetailScreen(experienceId: ''),
        '/chat-list': (context) => const ChatListScreen(),
      },
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/plaza-post-detail':
            final args = settings.arguments as Map<String, dynamic>? ?? {};
            return MaterialPageRoute(
              builder:
                  (context) => PlazaPostDetailScreen(
                    title: args['title'] ?? 'Post Details',
                    displayName: args['displayName'] ?? 'Anonymous',
                    timestamp: args['timestamp'] ?? 'Just now',
                    description:
                        args['description'] ?? 'No description provided',
                  ),
            );
          case '/share-experiences':
            return MaterialPageRoute(
              builder: (context) => const WishWallScreen(initialTabIndex: 1),
            );
          case '/chat-detail':
            final args = settings.arguments as Map<String, dynamic>? ?? {};
            return MaterialPageRoute(
              builder:
                  (context) => ChatDetailScreen(
                    chatId: args['chatId'] ?? '',
                    userName: args['userName'] ?? 'User',
                    userAvatar: args['userAvatar'],
                    experience: args['experience'],
                    wish: args['wish'],
                    initialMessage: args['initialMessage'],
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

  final List<String> _tabLabels = ['Plaza', 'Wish Wall', 'User Plaza', 'Home'];

  final List<IconData> _tabIcons = [
    Icons.explore,
    Icons.star,
    Icons.person,
    Icons.home,
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
