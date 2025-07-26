import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:package_info_plus/package_info_plus.dart';

class AboutCosmosoulPage extends StatefulWidget {
  const AboutCosmosoulPage({super.key});

  @override
  State<AboutCosmosoulPage> createState() => _AboutCosmosoulPageState();
}

class _AboutCosmosoulPageState extends State<AboutCosmosoulPage> {
  String _version = '';
  String _buildNumber = '';
  String _appName = '';

  @override
  void initState() {
    super.initState();
    _getPackageInfo();
  }

  Future<void> _getPackageInfo() async {
    final packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      _version = packageInfo.version;
      _buildNumber = packageInfo.buildNumber;
      _appName = packageInfo.appName;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'About CosmoSoul',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF7153DF),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      backgroundColor: Colors.grey[50],
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Planet emoji and title
            Center(
              child: Column(
                children: [
                  const Text('🪐', style: TextStyle(fontSize: 64)),
                  const SizedBox(height: 16),
                  Text(
                    'About CosmoSoul',
                    style: GoogleFonts.poppins(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF7153DF),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 60,
                    height: 2,
                    color: const Color(0xFF7153DF).withOpacity(0.3),
                  ),
                  // Version information
                  if (_version.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      'Version $_version${_buildNumber.isNotEmpty ? ' ($_buildNumber)' : ''}',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: const Color(0xFF7153DF).withOpacity(0.7),
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Tagline
            Center(
              child: Text(
                'A Universe of Experiences, A Network of Trust.',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1A1A1A),
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
            ),

            const SizedBox(height: 32),

            // Main content
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    spreadRadius: 0,
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'CosmoSoul is more than just an app — it\'s a movement.',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1A1A1A),
                      height: 1.6,
                    ),
                  ),

                  const SizedBox(height: 16),

                  Text(
                    'We believe that deep human connections can be built not through algorithms alone, but through shared real-life experiences, mutual trust, and open global collaboration.',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: const Color(0xFF4A5568),
                      height: 1.6,
                    ),
                  ),

                  const SizedBox(height: 24),

                  Text(
                    'Built with an AI-native and privacy-conscious architecture, CosmoSoul empowers users to:',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1A1A1A),
                      height: 1.6,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Feature list
                  ..._buildFeatureList(),

                  const SizedBox(height: 24),

                  Text(
                    'Whether you\'re looking to share your skills, explore a new lifestyle, or just make one honest connection, CosmoSoul is your companion in this cosmic journey of humanity.',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: const Color(0xFF4A5568),
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Closing message
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF7153DF).withOpacity(0.1),
                    const Color(0xFF9C7EFF).withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFF7153DF).withOpacity(0.15),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  Text(
                    'Let\'s redefine how strangers become friends.',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF7153DF),
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 8),

                  Text(
                    'Let\'s rebuild trust, one soul at a time.',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF7153DF),
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildFeatureList() {
    final features = [
      'Exchange meaningful experiences with people from all over the world',
      'Verify trustworthiness through transparent reputation systems and World ID authentication',
      'Build global identity through footprints, ratings, and contributions',
      'Transcend cultural boundaries using multilingual support and decentralized profiles',
    ];

    return features.map((feature) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 6,
              height: 6,
              margin: const EdgeInsets.only(top: 8, right: 12),
              decoration: const BoxDecoration(
                color: Color(0xFF7153DF),
                shape: BoxShape.circle,
              ),
            ),
            Expanded(
              child: Text(
                feature,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: const Color(0xFF4A5568),
                  height: 1.6,
                ),
              ),
            ),
          ],
        ),
      );
    }).toList();
  }
}
