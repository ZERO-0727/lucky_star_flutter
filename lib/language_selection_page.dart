import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'services/user_service.dart';
import 'models/user_model.dart';

class LanguageSelectionPage extends StatefulWidget {
  final List<String> selectedLanguages;
  final UserModel? currentUser;

  const LanguageSelectionPage({
    super.key,
    this.selectedLanguages = const [],
    this.currentUser,
  });

  @override
  State<LanguageSelectionPage> createState() => _LanguageSelectionPageState();
}

class _LanguageSelectionPageState extends State<LanguageSelectionPage> {
  late List<String> _selectedLanguages;
  final UserService _userService = UserService();
  bool _isLoading = false;
  bool _hasChanges = false;

  // Comprehensive list of languages inspired by Airbnb
  final List<Map<String, String>> _availableLanguages = [
    {'code': 'en', 'name': 'English', 'native': 'English'},
    {'code': 'ja', 'name': 'Japanese', 'native': '日本語'},
    {'code': 'zh', 'name': 'Chinese', 'native': '中文'},
    {'code': 'ko', 'name': 'Korean', 'native': '한국어'},
    {'code': 'es', 'name': 'Spanish', 'native': 'Español'},
    {'code': 'fr', 'name': 'French', 'native': 'Français'},
    {'code': 'de', 'name': 'German', 'native': 'Deutsch'},
    {'code': 'it', 'name': 'Italian', 'native': 'Italiano'},
    {'code': 'pt', 'name': 'Portuguese', 'native': 'Português'},
    {'code': 'ru', 'name': 'Russian', 'native': 'Русский'},
    {'code': 'ar', 'name': 'Arabic', 'native': 'العربية'},
    {'code': 'hi', 'name': 'Hindi', 'native': 'हिंदी'},
    {'code': 'th', 'name': 'Thai', 'native': 'ไทย'},
    {'code': 'vi', 'name': 'Vietnamese', 'native': 'Tiếng Việt'},
    {'code': 'id', 'name': 'Indonesian', 'native': 'Bahasa Indonesia'},
    {'code': 'tr', 'name': 'Turkish', 'native': 'Türkçe'},
    {'code': 'nl', 'name': 'Dutch', 'native': 'Nederlands'},
    {'code': 'sv', 'name': 'Swedish', 'native': 'Svenska'},
    {'code': 'da', 'name': 'Danish', 'native': 'Dansk'},
    {'code': 'no', 'name': 'Norwegian', 'native': 'Norsk'},
  ];

  @override
  void initState() {
    super.initState();
    // Initialize with the languages passed from MyPage
    _selectedLanguages = List.from(widget.selectedLanguages);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Host Language',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _availableLanguages.length,
              itemBuilder: (context, index) {
                final language = _availableLanguages[index];
                final languageName = language['name']!;
                final languageNative = language['native']!;
                final isSelected = _selectedLanguages.contains(languageName);

                return CheckboxListTile(
                  title: RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: languageName,
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            color: Colors.black87,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (languageName != languageNative) ...[
                          TextSpan(
                            text: ' • $languageNative',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  value: isSelected,
                  activeColor: const Color(0xFF7153DF),
                  onChanged: (bool? value) {
                    setState(() {
                      if (value == true) {
                        if (!_selectedLanguages.contains(languageName)) {
                          _selectedLanguages.add(languageName);
                          _hasChanges = true;
                        }
                      } else {
                        _selectedLanguages.remove(languageName);
                        _hasChanges = true;
                      }
                    });
                  },
                  controlAffinity: ListTileControlAffinity.leading,
                );
              },
            ),
          ),
          _buildBottomButtons(),
        ],
      ),
    );
  }

  Future<void> _saveLanguagesToDatabase() async {
    if (!_hasChanges || widget.currentUser == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final currentUserId = FirebaseAuth.instance.currentUser?.uid;
      if (currentUserId != null) {
        // Update user languages in Firebase
        await _userService.updateUserFields(currentUserId, {
          'languages': _selectedLanguages,
          'updatedAt': DateTime.now(),
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Languages updated successfully!',
                style: GoogleFonts.poppins(),
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      print('Error saving languages: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error saving languages: $e',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildBottomButtons() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Language count info
          if (_selectedLanguages.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF7153DF).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${_selectedLanguages.length} language${_selectedLanguages.length == 1 ? '' : 's'} selected',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: const Color(0xFF7153DF),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed:
                      _isLoading
                          ? null
                          : () {
                            setState(() {
                              _selectedLanguages.clear();
                              _hasChanges = true;
                            });
                          },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: const BorderSide(color: Color(0xFF7153DF)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Clear All',
                    style: GoogleFonts.poppins(
                      color: const Color(0xFF7153DF),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed:
                      _isLoading
                          ? null
                          : () async {
                            // Save to database and return to previous screen
                            await _saveLanguagesToDatabase();
                            if (mounted) {
                              Navigator.pop(context, _selectedLanguages);
                            }
                          },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7153DF),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child:
                      _isLoading
                          ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                          : Text(
                            'Save & Return',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
