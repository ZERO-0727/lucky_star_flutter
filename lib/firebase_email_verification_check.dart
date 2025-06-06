import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

/// Quick diagnostic check for Firebase email verification
class FirebaseEmailVerificationCheck extends StatefulWidget {
  const FirebaseEmailVerificationCheck({Key? key}) : super(key: key);

  @override
  State<FirebaseEmailVerificationCheck> createState() =>
      _FirebaseEmailVerificationCheckState();
}

class _FirebaseEmailVerificationCheckState
    extends State<FirebaseEmailVerificationCheck> {
  final List<String> _diagnosticResults = [];
  bool _isChecking = false;

  @override
  void initState() {
    super.initState();
    _runDiagnostics();
  }

  void _addResult(String result, {bool isError = false}) {
    setState(() {
      _diagnosticResults.add('${isError ? '❌' : '✅'} $result');
    });
    print('FIREBASE CHECK: $result');
  }

  Future<void> _runDiagnostics() async {
    setState(() {
      _isChecking = true;
      _diagnosticResults.clear();
    });

    try {
      // 1. Check Firebase initialization
      _addResult('Checking Firebase initialization...');
      final app = Firebase.app();
      _addResult('Firebase initialized: ${app.name}');
      _addResult('Project ID: ${app.options.projectId}');
      _addResult('Auth Domain: ${app.options.authDomain ?? "Not set"}');

      // 2. Check Firebase Auth instance
      _addResult('Checking Firebase Auth...');
      final auth = FirebaseAuth.instance;
      _addResult('Auth instance created');

      // 3. Check current user
      final currentUser = auth.currentUser;
      if (currentUser != null) {
        _addResult('Current user: ${currentUser.email}');
        _addResult('Email verified: ${currentUser.emailVerified}');

        // 4. Try to send verification email
        _addResult('Attempting to send verification email...');
        try {
          await currentUser.reload();
          if (!currentUser.emailVerified) {
            await currentUser.sendEmailVerification();
            _addResult('Verification email sent successfully!');
            _addResult('Check inbox and spam folder');
          } else {
            _addResult('Email already verified');
          }
        } catch (e) {
          _addResult('Failed to send email: $e', isError: true);

          // Check specific error types
          if (e.toString().contains('too-many-requests')) {
            _addResult(
              'RATE LIMIT: Too many requests. Wait before trying again.',
              isError: true,
            );
          } else if (e.toString().contains('network')) {
            _addResult(
              'NETWORK ERROR: Check internet connection',
              isError: true,
            );
          }
        }
      } else {
        _addResult('No user signed in', isError: true);
      }

      // 5. Check Firebase project configuration
      _addResult('\nCHECKLIST FOR FIREBASE CONSOLE:');
      _addResult('1. Go to Firebase Console > Authentication > Settings');
      _addResult(
        '2. Check "Authorized domains" - ensure your domain is listed',
      );
      _addResult(
        '3. Check "Email providers" - ensure Email/Password is enabled',
      );
      _addResult(
        '4. Check "Templates" - verify email templates are configured',
      );
      _addResult('5. Check "Usage" tab for any quota limits');
    } catch (e) {
      _addResult('Diagnostic error: $e', isError: true);
    } finally {
      setState(() {
        _isChecking = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Email Verification Diagnostic'),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Firebase Email Verification Check',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (_isChecking)
              const Center(child: CircularProgressIndicator())
            else
              Expanded(
                child: ListView.builder(
                  itemCount: _diagnosticResults.length,
                  itemBuilder: (context, index) {
                    final result = _diagnosticResults[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text(
                        result,
                        style: TextStyle(
                          color:
                              result.contains('❌') ? Colors.red : Colors.black,
                          fontWeight:
                              result.contains('CHECKLIST')
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                        ),
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isChecking ? null : _runDiagnostics,
              child: const Text('Run Diagnostics Again'),
            ),
          ],
        ),
      ),
    );
  }
}
