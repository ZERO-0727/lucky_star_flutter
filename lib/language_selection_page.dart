import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class LanguageSelectionPage extends StatefulWidget {
  final List<String> selectedLanguages;
  
  const LanguageSelectionPage({
    super.key,
    this.selectedLanguages = const [],
  });

  @override
  State<LanguageSelectionPage> createState() => _LanguageSelectionPageState();
}

class _LanguageSelectionPageState extends State<LanguageSelectionPage> {
  late List<String> _selectedLanguages;
  
  // Predefined list of languages
  final List<String> _availableLanguages = [
    'English',
    'Japanese',
    'Chinese',
    'Korean',
    'Spanish',
    'French',
    'German',
    'Italian',
    'Portuguese',
    'Russian',
    'Arabic',
    'Hindi',
    'Thai',
    'Vietnamese',
    'Indonesian',
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
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
          ),
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
                final isSelected = _selectedLanguages.contains(language);
                
                return CheckboxListTile(
                  title: Text(
                    language,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                    ),
                  ),
                  value: isSelected,
                  activeColor: const Color(0xFF7153DF),
                  onChanged: (bool? value) {
                    setState(() {
                      if (value == true) {
                        if (!_selectedLanguages.contains(language)) {
                          _selectedLanguages.add(language);
                        }
                      } else {
                        _selectedLanguages.remove(language);
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
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () {
                setState(() {
                  _selectedLanguages.clear();
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
              onPressed: () {
                // Return the selected languages to the previous screen
                Navigator.pop(context, _selectedLanguages);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7153DF),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Save and Return',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
