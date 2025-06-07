import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'services/auth_service.dart';

class FirebaseEmailVerificationDebug extends StatefulWidget {
  const FirebaseEmailVerificationDebug({Key? key}) : super(key: key);

  @override
  State<FirebaseEmailVerificationDebug> createState() =>
      _FirebaseEmailVerificationDebugState();
}

class _FirebaseEmailVerificationDebugState
    extends State<FirebaseEmailVerificationDebug> {
  final AuthService _authService = AuthService();
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _auth = FirebaseAuth.instance;

  String _statusMessage = '';
  bool _isLoading = false;
  bool _showPassword = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _createAccountAndVerify() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _statusMessage = 'Creating account...';
      });

      try {
        // Step 1: Create a new user account
        final userCredential = await _auth.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        setState(() {
          _statusMessage =
              'Account created successfully! User ID: ${userCredential.user?.uid}';
        });

        // Step 2: Send verification email - try the standard Firebase method first
        if (userCredential.user != null) {
          setState(() {
            _statusMessage +=
                '\nSending verification email via standard Firebase method...';
          });

          try {
            await userCredential.user!.sendEmailVerification();
            setState(() {
              _statusMessage +=
                  '\nStandard verification email sent successfully!';
            });
          } catch (e) {
            setState(() {
              _statusMessage += '\nStandard method failed: $e';
            });

            // Try our custom method with rate limiting
            setState(() {
              _statusMessage += '\nTrying custom verification method...';
            });

            try {
              await _authService.sendVerificationEmailWithRateLimiting(
                userCredential.user!,
              );
              setState(() {
                _statusMessage +=
                    '\nCustom verification email sent successfully!';
              });
            } catch (e) {
              setState(() {
                _statusMessage += '\nCustom method also failed: $e';
              });
            }
          }

          // Try our SendGrid implementation if Firebase methods fail
          if (_statusMessage.contains('failed')) {
            setState(() {
              _statusMessage += '\nTrying SendGrid implementation...';
            });

            try {
              await _authService.sendCustomVerificationEmail(
                userCredential.user!,
              );
              setState(() {
                _statusMessage +=
                    '\nSendGrid verification email sent successfully!';
              });
            } catch (e) {
              setState(() {
                _statusMessage += '\nSendGrid method also failed: $e';
              });
            }
          }
        }
      } catch (e) {
        setState(() {
          _statusMessage = 'Error: $e';
        });
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _checkVerificationStatus() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Checking verification status...';
    });

    try {
      // Force reload user to get current verification status
      await _auth.currentUser?.reload();
      final user = _auth.currentUser;

      if (user != null) {
        setState(() {
          _statusMessage =
              'Email: ${user.email}\nVerified: ${user.emailVerified}';
        });
      } else {
        setState(() {
          _statusMessage = 'No user is currently signed in';
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Error checking status: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _resendVerificationEmail() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Resending verification email...';
    });

    try {
      final user = _auth.currentUser;

      if (user != null) {
        // Try all three methods in sequence until one succeeds
        try {
          // Method 1: Standard Firebase
          await user.sendEmailVerification();
          setState(() {
            _statusMessage = 'Standard verification email resent successfully!';
          });
        } catch (e) {
          setState(() {
            _statusMessage =
                'Standard method failed: $e\nTrying custom method...';
          });

          try {
            // Method 2: Custom rate-limited method
            await _authService.sendVerificationEmailWithRateLimiting(user);
            setState(() {
              _statusMessage +=
                  '\nCustom verification email sent successfully!';
            });
          } catch (e) {
            setState(() {
              _statusMessage +=
                  '\nCustom method also failed: $e\nTrying SendGrid...';
            });

            try {
              // Method 3: SendGrid implementation
              await _authService.sendCustomVerificationEmail(user);
              setState(() {
                _statusMessage +=
                    '\nSendGrid verification email sent successfully!';
              });
            } catch (e) {
              setState(() {
                _statusMessage +=
                    '\nAll methods failed to send verification email: $e';
              });
            }
          }
        }
      } else {
        setState(() {
          _statusMessage = 'No user is currently signed in';
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Firebase Email Verification Debug'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Account creation form
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Create Test Account & Verify Email',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _emailController,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter an email';
                            }
                            if (!value.contains('@') || !value.contains('.')) {
                              return 'Please enter a valid email';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _passwordController,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            border: const OutlineInputBorder(),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _showPassword
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                              ),
                              onPressed: () {
                                setState(() {
                                  _showPassword = !_showPassword;
                                });
                              },
                            ),
                          ),
                          obscureText: !_showPassword,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter a password';
                            }
                            if (value.length < 6) {
                              return 'Password must be at least 6 characters';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed:
                              _isLoading ? null : _createAccountAndVerify,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepPurple,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text(
                            'Create Account & Send Verification',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Status and actions
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Verification Actions',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed:
                                  _isLoading ? null : _checkVerificationStatus,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Check Status'),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton(
                              onPressed:
                                  _isLoading ? null : _resendVerificationEmail,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Resend Verification'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Status message
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Status Messages',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (_statusMessage.isNotEmpty)
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _statusMessage = '';
                                });
                              },
                              child: const Text('Clear'),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (_isLoading)
                        const Center(child: CircularProgressIndicator())
                      else if (_statusMessage.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(_statusMessage),
                        )
                      else
                        const Center(child: Text('No status messages yet')),
                    ],
                  ),
                ),
              ),

              // Instructions
              const SizedBox(height: 24),
              const Text(
                'Debugging Notes:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                '• Check if the email verification is getting sent by Firebase\n'
                '• Verify if the email is reaching your inbox (check spam folder)\n'
                '• Make sure your Firebase project has email verification enabled\n'
                '• Check if there are any rate limiting issues\n'
                '• Try our custom methods if the standard Firebase method fails',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
