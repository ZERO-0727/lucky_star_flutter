import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseTestScreen extends StatefulWidget {
  const FirebaseTestScreen({super.key});

  @override
  State<FirebaseTestScreen> createState() => _FirebaseTestScreenState();
}

class _FirebaseTestScreenState extends State<FirebaseTestScreen> {
  bool _isLoading = true;
  String _resultMessage = '';
  List<String> _userIds = [];

  @override
  void initState() {
    super.initState();
    _testFirestore();
  }

  Future<void> _testFirestore() async {
    try {
      setState(() {
        _isLoading = true;
        _resultMessage = 'Testing Firestore connection...';
      });

      // Create a test user document if it doesn't exist
      await _ensureTestUserExists();

      // Fetch users from Firestore
      final QuerySnapshot usersSnapshot =
          await FirebaseFirestore.instance.collection('users').limit(5).get();

      final List<String> userIds =
          usersSnapshot.docs.map((doc) => doc.id).toList();

      setState(() {
        _isLoading = false;
        _userIds = userIds;
        _resultMessage = 'Successfully connected to Firestore!';
      });

      print('Firebase connection test successful');
      print('Found ${userIds.length} users: $userIds');
    } catch (e) {
      setState(() {
        _isLoading = false;
        _resultMessage = 'Error connecting to Firestore: $e';
      });
      print('Firebase connection test failed: $e');
    }
  }

  Future<void> _ensureTestUserExists() async {
    try {
      // Check if test user exists
      final testUserDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc('test_user_1')
              .get();

      // If not, create it
      if (!testUserDoc.exists) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc('test_user_1')
            .set({
              'userId': 'test_user_1',
              'displayName': 'Test User',
              'bio': 'This is a test user for Firebase integration',
              'avatarUrl': '',
              'interests': ['Testing', 'Firebase', 'Flutter'],
              'visitedCountries': ['Japan', 'United States'],
              'verificationBadges': ['Test Badge'],
              'referenceCount': 0,
              'statistics': {
                'experiencesCount': 0,
                'wishesCount': 0,
                'wishesFullfilledCount': 0,
                'responseRate': 100,
              },
              'createdAt': FieldValue.serverTimestamp(),
              'updatedAt': FieldValue.serverTimestamp(),
            });
        print('Created test user document');
      } else {
        print('Test user document already exists');
      }
    } catch (e) {
      print('Error ensuring test user exists: $e');
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Firebase Test'),
        backgroundColor: const Color(0xFF7153DF),
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_isLoading)
                const CircularProgressIndicator()
              else
                const Icon(Icons.check_circle, color: Colors.green, size: 60),
              const SizedBox(height: 20),
              Text(
                _resultMessage,
                style: const TextStyle(fontSize: 18),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              if (_userIds.isNotEmpty) ...[
                const Text(
                  'Users in Firestore:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                ...List.generate(
                  _userIds.length,
                  (index) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Text(
                      'User ID: ${_userIds[index]}',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: _testFirestore,
                child: const Text('Test Again'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
