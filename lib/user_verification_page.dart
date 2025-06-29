import 'package:flutter/material.dart';
import 'services/world_id_service.dart';

class UserVerificationPage extends StatefulWidget {
  const UserVerificationPage({super.key});

  @override
  State<UserVerificationPage> createState() => _UserVerificationPageState();
}

class _UserVerificationPageState extends State<UserVerificationPage> {
  int _selectedMethod = 0; // 0: Web2, 1: World ID
  bool _verified = false;
  WorldIDVerificationState _worldIDState = WorldIDVerificationState.idle;
  String? _verificationUrl;
  String? _signal;
  String? _errorMessage;

  final List<Map<String, dynamic>> _methods = [
    {
      'title': 'Web2 Verification',
      'subtitle':
          'Use official ID (passport/driver\'s license) and store securely in our encrypted database.',
      'steps': [
        {'icon': Icons.upload_file, 'text': 'Upload ID'},
        {'icon': Icons.face, 'text': 'Facial Scan'},
        {'icon': Icons.verified, 'text': 'Verified'},
      ],
    },
    {
      'title': 'World ID Verification (Web3)',
      'subtitle':
          'Use Worldcoin World ID. Blockchain-secured, privacy-first identity verification.',
      'steps': [
        {'icon': Icons.account_balance_wallet, 'text': 'Connect World ID'},
        {'icon': Icons.face_retouching_natural, 'text': 'Biometric Proof'},
        {'icon': Icons.verified, 'text': 'Verified'},
      ],
    },
  ];

  @override
  void initState() {
    super.initState();
    _checkVerificationStatus();
  }

  Future<void> _checkVerificationStatus() async {
    final status = await WorldIDService.getVerificationStatus();
    if (status.success && status.isVerified) {
      setState(() {
        _verified = true;
        _worldIDState = WorldIDVerificationState.verified;
      });
    }
  }

  Future<void> _startVerification() async {
    if (_selectedMethod == 0) {
      // Web2 verification (placeholder)
      setState(() {
        _verified = true;
      });
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) Navigator.of(context).pop();
      });
    } else {
      // World ID verification
      await _startWorldIDVerification();
    }
  }

  Future<void> _startWorldIDVerification() async {
    setState(() {
      _worldIDState = WorldIDVerificationState.initializing;
      _errorMessage = null;
    });

    try {
      final response = await WorldIDService.initVerification();

      if (response.success && response.verificationUrl != null) {
        setState(() {
          _verificationUrl = response.verificationUrl;
          _signal = response.signal;
          _worldIDState = WorldIDVerificationState.awaitingUserAction;
        });

        // Launch World ID verification
        final launched = await WorldIDService.launchVerification(
          response.verificationUrl!,
        );

        if (launched) {
          _showVerificationDialog();
        } else {
          setState(() {
            _errorMessage = 'Failed to launch World ID verification';
            _worldIDState = WorldIDVerificationState.failed;
          });
        }
      } else {
        setState(() {
          _errorMessage = response.error ?? 'Failed to initialize verification';
          _worldIDState = WorldIDVerificationState.failed;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _worldIDState = WorldIDVerificationState.failed;
      });
    }
  }

  void _showVerificationDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Complete World ID Verification'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.smartphone, size: 64, color: Color(0xFF7153DF)),
              const SizedBox(height: 16),
              const Text(
                'Please complete the verification in the World ID app, then return to this screen.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              if (_worldIDState == WorldIDVerificationState.verifying)
                const CircularProgressIndicator(),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  _worldIDState = WorldIDVerificationState.idle;
                });
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed:
                  _worldIDState == WorldIDVerificationState.verifying
                      ? null
                      : _checkVerificationComplete,
              child:
                  _worldIDState == WorldIDVerificationState.verifying
                      ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                      : const Text('I\'ve Completed Verification'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _checkVerificationComplete() async {
    setState(() {
      _worldIDState = WorldIDVerificationState.verifying;
    });

    // Check if user has completed verification
    final status = await WorldIDService.getVerificationStatus();

    if (status.success && status.isVerified) {
      setState(() {
        _verified = true;
        _worldIDState = WorldIDVerificationState.verified;
      });

      if (mounted) {
        Navigator.of(context).pop(); // Close dialog

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.verified, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'World ID verification successful! Trust score increased by ${status.trustScore}',
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );

        // Navigate back after showing success
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) Navigator.of(context).pop();
        });
      }
    } else {
      setState(() {
        _worldIDState = WorldIDVerificationState.awaitingUserAction;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Verification not yet complete. Please try again.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  void _showPrivacyPolicyMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Privacy Policy link tapped (placeholder)')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify Your Identity'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        elevation: 0,
      ),
      body: SafeArea(
        child:
            _verified
                ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.verified, color: Colors.green, size: 64),
                      SizedBox(height: 24),
                      Text(
                        'Verification Complete!',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 12),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 32.0),
                        child: Text(
                          'Thank you for verifying your identity. You now have more trust and visibility in the community.',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                )
                : SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 24,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 8),
                      Text(
                        'Verified users get more trust and are prioritized in the community.',
                        style: theme.textTheme.bodyLarge,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 28),
                      // Verification Method Options
                      ...List.generate(_methods.length, (idx) {
                        final method = _methods[idx];
                        return Card(
                          elevation: _selectedMethod == idx ? 4 : 1,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(
                              color:
                                  _selectedMethod == idx
                                      ? const Color(0xFF7153DF)
                                      : Colors.grey[300]!,
                              width: 2,
                            ),
                          ),
                          margin: const EdgeInsets.only(bottom: 20),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () => setState(() => _selectedMethod = idx),
                            child: Padding(
                              padding: const EdgeInsets.all(18.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Radio<int>(
                                        value: idx,
                                        groupValue: _selectedMethod,
                                        activeColor: const Color(0xFF7153DF),
                                        onChanged:
                                            (v) => setState(
                                              () => _selectedMethod = v!,
                                            ),
                                      ),
                                      Expanded(
                                        child: Text(
                                          method['title'],
                                          style: theme.textTheme.titleMedium
                                              ?.copyWith(
                                                fontWeight: FontWeight.bold,
                                              ),
                                        ),
                                      ),
                                      if (idx == 1 &&
                                          _worldIDState !=
                                              WorldIDVerificationState.idle)
                                        _buildWorldIDStatusIcon(),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    method['subtitle'],
                                    style: theme.textTheme.bodyMedium,
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: List.generate(
                                      method['steps'].length,
                                      (stepIdx) {
                                        final step = method['steps'][stepIdx];
                                        return Column(
                                          children: [
                                            CircleAvatar(
                                              backgroundColor: const Color(
                                                0xFF7153DF,
                                              ).withOpacity(0.1),
                                              child: Icon(
                                                step['icon'],
                                                color: const Color(0xFF7153DF),
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              step['text'],
                                              style: theme.textTheme.bodySmall,
                                            ),
                                          ],
                                        );
                                      },
                                    ),
                                  ),
                                  if (idx == 1 && _errorMessage != null) ...[
                                    const SizedBox(height: 12),
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.red.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        _errorMessage!,
                                        style: const TextStyle(
                                          color: Colors.red,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed:
                            _worldIDState ==
                                        WorldIDVerificationState.initializing ||
                                    _worldIDState ==
                                        WorldIDVerificationState.verifying
                                ? null
                                : _startVerification,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF7153DF),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        child:
                            _worldIDState ==
                                        WorldIDVerificationState.initializing ||
                                    _worldIDState ==
                                        WorldIDVerificationState.verifying
                                ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                                : const Text('Start Verification'),
                      ),
                      const SizedBox(height: 28),
                      Column(
                        children: [
                          const Text(
                            'Your identity will be used only for trust scoring and never shared publicly.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.black54,
                            ),
                          ),
                          GestureDetector(
                            onTap: _showPrivacyPolicyMessage,
                            child: const Text(
                              'View Privacy Policy',
                              style: TextStyle(
                                color: Color(0xFF7153DF),
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
      ),
    );
  }

  Widget _buildWorldIDStatusIcon() {
    switch (_worldIDState) {
      case WorldIDVerificationState.initializing:
      case WorldIDVerificationState.verifying:
        return const SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(strokeWidth: 2),
        );
      case WorldIDVerificationState.awaitingUserAction:
        return const Icon(Icons.pending, color: Colors.orange);
      case WorldIDVerificationState.verified:
        return const Icon(Icons.verified, color: Colors.green);
      case WorldIDVerificationState.failed:
        return const Icon(Icons.error, color: Colors.red);
      default:
        return const SizedBox.shrink();
    }
  }
}
