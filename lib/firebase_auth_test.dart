import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseAuthTest extends StatefulWidget {
  const FirebaseAuthTest({Key? key}) : super(key: key);

  @override
  State<FirebaseAuthTest> createState() => _FirebaseAuthTestState();
}

class _FirebaseAuthTestState extends State<FirebaseAuthTest> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String _status = 'Not authenticated';

  @override
  void initState() {
    super.initState();
    _checkCurrentUser();
  }

  void _checkCurrentUser() {
    final User? user = _auth.currentUser;
    setState(() {
      _status =
          user != null
              ? 'Authenticated as: ${user.email}'
              : 'Not authenticated';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Firebase Auth Test')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_status),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _checkCurrentUser,
              child: const Text('Check Auth Status'),
            ),
          ],
        ),
      ),
    );
  }
}
