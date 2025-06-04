import 'package:flutter/material.dart';


class UserVerificationPage extends StatefulWidget {
  const UserVerificationPage({Key? key}) : super(key: key);

  @override
  State<UserVerificationPage> createState() => _UserVerificationPageState();
}

class _UserVerificationPageState extends State<UserVerificationPage> {
  int _selectedMethod = 0; // 0: Web2, 1: World ID
  bool _verified = false;

  final List<Map<String, dynamic>> _methods = [
    {
      'title': 'Web2 Verification',
      'subtitle': 'Use official ID (passport/driver’s license) and store securely in our encrypted database.',
      'steps': [
        {'icon': Icons.upload_file, 'text': 'Upload ID'},
        {'icon': Icons.face, 'text': 'Facial Scan'},
        {'icon': Icons.verified, 'text': 'Verified'},
      ],
    },
    {
      'title': 'World ID Verification (Web3)',
      'subtitle': 'Use Worldcoin World ID. Blockchain-secured, privacy-first identity verification.',
      'steps': [
        {'icon': Icons.account_balance_wallet, 'text': 'Connect World ID'},
        {'icon': Icons.face_retouching_natural, 'text': 'Biometric Proof'},
        {'icon': Icons.verified, 'text': 'Verified'},
      ],
    },
  ];

  void _startVerification() {
    setState(() {
      _verified = true;
    });
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) Navigator.of(context).pop();
    });
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
        child: _verified
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.verified, color: Colors.green, size: 64),
                    SizedBox(height: 24),
                    Text('Verification Complete!', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
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
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
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
                            color: _selectedMethod == idx ? const Color(0xFF7153DF) : Colors.grey[300]!,
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
                                      onChanged: (v) => setState(() => _selectedMethod = v!),
                                    ),
                                    Text(
                                      method['title'],
                                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(method['subtitle'], style: theme.textTheme.bodyMedium),
                                const SizedBox(height: 16),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children: List.generate(method['steps'].length, (stepIdx) {
                                    final step = method['steps'][stepIdx];
                                    return Column(
                                      children: [
                                        CircleAvatar(
                                          backgroundColor: const Color(0xFF7153DF).withOpacity(0.1),
                                          child: Icon(step['icon'], color: const Color(0xFF7153DF)),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(step['text'], style: theme.textTheme.bodySmall),
                                      ],
                                    );
                                  }),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _startVerification,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7153DF),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      child: const Text('Start Verification'),
                    ),
                    const SizedBox(height: 28),
                    Column(
                      children: [
                        const Text(
                          'Your identity will be used only for trust scoring and never shared publicly.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 13, color: Colors.black54),
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
}
