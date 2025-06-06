import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';

class PhoneAuthScreen extends StatefulWidget {
  final bool isLogin;
  
  const PhoneAuthScreen({super.key, required this.isLogin});

  @override
  State<PhoneAuthScreen> createState() => _PhoneAuthScreenState();
}

class _PhoneAuthScreenState extends State<PhoneAuthScreen> {
  final _phoneController = TextEditingController();
  final _codeController = TextEditingController();
  final _authService = AuthService();
  String? _verificationId;
  bool _isLoading = false;
  bool _codeSent = false;
  String? _errorMessage;

  Future<void> _verifyPhone() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final phoneNumber = _phoneController.text.trim();
    if (phoneNumber.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter a phone number';
        _isLoading = false;
      });
      return;
    }
    
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    
    print('Initiating phone verification for: $phoneNumber');
    print('Timestamp: ${DateTime.now().toIso8601String()}');
    
    try {
      await _authService.verifyPhoneNumber(
        '+${_phoneController.text.trim()}',
        (verificationId) {
          print('Code sent successfully to $phoneNumber');
          print('Verification ID: $verificationId');
          setState(() {
            _verificationId = verificationId;
            _codeSent = true;
            _isLoading = false;
          });
        },
        (FirebaseAuthException e) {
          print('Phone verification failed');
          print('Error Code: ${e.code}');
          print('Error Message: ${e.message}');
          print('Error Stack: ${e.stackTrace}');
          String errorMessage;
          if (e.code == 'billing-not-enabled') {
            errorMessage = 'Phone authentication requires billing to be enabled on the Firebase project. Please set up billing in the Firebase console.';
          } else {
            errorMessage = 'Error: ${e.message ?? "Unknown error"}';
          }
          setState(() {
            _errorMessage = errorMessage;
            _isLoading = false;
          });
        },
        (PhoneAuthCredential credential) {
          print('Auto-verification completed');
          _completeAuth(credential);
        },
      );
    } catch (e) {
      print('Unexpected error during phone verification: $e');
      setState(() {
        _errorMessage = 'Unexpected error: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _verifyCode() async {
    if (_verificationId == null) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: _codeController.text.trim(),
      );
      await _completeAuth(credential);
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  Future<void> _completeAuth(PhoneAuthCredential credential) async {
    try {
      await _authService.signInWithPhoneNumber(
        credential.verificationId!, 
        credential.smsCode!
      );
      // Success - Navigator will handle the rest
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isLogin ? 'Phone Login' : 'Phone Sign Up'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (!_codeSent) ...[
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  hintText: '+1 234 567 8900',
                  prefixIcon: Icon(Icons.phone),
                ),
              ),
              const SizedBox(height: 20),
            ] else ...[
              TextField(
                controller: _codeController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Verification Code',
                  hintText: '123456',
                  prefixIcon: Icon(Icons.sms),
                ),
              ),
              const SizedBox(height: 20),
            ],
            if (_errorMessage != null)
              Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red),
              ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isLoading 
                  ? null 
                  : _codeSent ? _verifyCode : _verifyPhone,
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : Text(_codeSent ? 'Verify Code' : 'Send Code'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _codeController.dispose();
    super.dispose();
  }
}
