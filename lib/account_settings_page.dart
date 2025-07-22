import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'feedback_page.dart';
import 'donation_page.dart';
import 'user_verification_page.dart';
import 'privacy_policy_screen.dart';
import 'screens/auth/account_management_screen.dart';
import 'screens/auth/change_password_screen.dart';
import 'services/auth_service.dart';
import 'welcome_page.dart';

class AccountSettingsPage extends StatefulWidget {
  const AccountSettingsPage({super.key});

  @override
  State<AccountSettingsPage> createState() => _AccountSettingsPageState();
}

class _AccountSettingsPageState extends State<AccountSettingsPage> {
  // Settings state variables
  bool _darkModeEnabled = false;
  bool _notificationsEnabled = true;
  String _selectedLanguage = 'English';
  final List<String> _availableLanguages = [
    'English',
    'Japanese',
    'Spanish',
    'French',
    'German',
    'Chinese',
  ];

  @override
  void initState() {
    super.initState();
    _loadDarkModePreference();
  }

  // Load dark mode preference from SharedPreferences
  Future<void> _loadDarkModePreference() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _darkModeEnabled = prefs.getBool('darkModeEnabled') ?? false;
    });
  }

  // Save dark mode preference to SharedPreferences
  Future<void> _saveDarkModePreference(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('darkModeEnabled', value);
  }

  // Toggle dark mode
  Future<void> _toggleDarkMode(bool value) async {
    setState(() {
      _darkModeEnabled = value;
    });
    await _saveDarkModePreference(value);
  }

  // Get theme colors based on dark mode status
  Color get _backgroundColor =>
      _darkModeEnabled ? const Color(0xFF121212) : Colors.white;
  Color get _cardColor =>
      _darkModeEnabled ? const Color(0xFF1E1E1E) : Colors.white;
  Color get _textColor => _darkModeEnabled ? Colors.white : Colors.black;
  Color get _subtitleColor =>
      _darkModeEnabled ? const Color(0xFFB3B3B3) : const Color(0xFF666666);
  Color get _dividerColor =>
      _darkModeEnabled ? const Color(0xFF333333) : const Color(0xFFE0E0E0);
  Color get _primaryColor =>
      _darkModeEnabled ? const Color(0xFF9C27B0) : const Color(0xFF7153DF);
  Color get _accentColor =>
      _darkModeEnabled ? const Color(0xFF9C27B0) : const Color(0xFFDCCEF9);
  Color get _iconColor =>
      _darkModeEnabled ? const Color(0xFF9C27B0) : const Color(0xFF7153DF);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        title: Text('Settings', style: TextStyle(color: _textColor)),
        centerTitle: true,
        backgroundColor: _backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: _textColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Settings Section
              _buildSectionHeader('Profile Settings'),
              const SizedBox(height: 16),
              _buildProfileSettingsSection(),
              const SizedBox(height: 24),

              // Preferences Section
              _buildSectionHeader('Preferences'),
              const SizedBox(height: 16),
              _buildPreferencesSection(),
              const SizedBox(height: 24),

              // About & Support Section
              _buildSectionHeader('About & Support'),
              const SizedBox(height: 16),
              _buildAboutAndSupportSection(),
              const SizedBox(height: 32),

              // Logout Button
              _buildLogoutButton(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Row(
      children: [
        Expanded(child: Divider(color: _dividerColor, thickness: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: _primaryColor,
            ),
          ),
        ),
        Expanded(child: Divider(color: _dividerColor, thickness: 1)),
      ],
    );
  }

  Widget _buildProfileSettingsSection() {
    return Card(
      elevation: 2,
      color: _cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSettingsItem(
              icon: Icons.account_circle,
              title: 'Account Security',
              onTap: () {
                // Navigate to AccountManagementScreen
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AccountManagementScreen(),
                  ),
                );
              },
            ),
            Divider(color: _dividerColor),
            _buildSettingsItem(
              icon: Icons.phone,
              title: 'Phone Number',
              subtitle: '+81 90-1234-5678',
              onTap: () {
                // Navigate to phone settings
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Phone settings coming soon')),
                );
              },
            ),
            Divider(color: _dividerColor),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: OutlinedButton(
                onPressed: () {
                  // Navigate to change password screen
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ChangePasswordScreen(),
                    ),
                  );
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: _primaryColor,
                  side: BorderSide(color: _primaryColor),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.lock_outline, color: _iconColor),
                    const SizedBox(width: 8),
                    Text(
                      'Change Password',
                      style: TextStyle(color: _textColor),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreferencesSection() {
    return Card(
      elevation: 2,
      color: _cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Language Dropdown
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                children: [
                  Icon(Icons.language, color: _iconColor),
                  const SizedBox(width: 16),
                  Text(
                    'Language',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: _textColor,
                    ),
                  ),
                  const Spacer(),
                  Theme(
                    data: Theme.of(context).copyWith(canvasColor: _cardColor),
                    child: DropdownButton<String>(
                      value: _selectedLanguage,
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setState(() {
                            _selectedLanguage = newValue;
                          });
                        }
                      },
                      items:
                          _availableLanguages.map<DropdownMenuItem<String>>((
                            String value,
                          ) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(
                                value,
                                style: TextStyle(color: _textColor),
                              ),
                            );
                          }).toList(),
                      underline: Container(),
                      dropdownColor: _cardColor,
                      style: TextStyle(color: _textColor),
                      iconEnabledColor: _iconColor,
                    ),
                  ),
                ],
              ),
            ),
            Divider(color: _dividerColor),
            // Dark Mode Toggle
            SwitchListTile(
              title: Text(
                'Dark Mode',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: _textColor,
                ),
              ),
              secondary: Icon(Icons.dark_mode, color: _iconColor),
              value: _darkModeEnabled,
              onChanged: _toggleDarkMode,
              activeColor: _primaryColor,
            ),
            Divider(color: _dividerColor),
            // Notifications Toggle
            SwitchListTile(
              title: Text(
                'Notifications',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: _textColor,
                ),
              ),
              secondary: Icon(Icons.notifications, color: _iconColor),
              value: _notificationsEnabled,
              onChanged: (bool value) {
                setState(() {
                  _notificationsEnabled = value;
                });
              },
              activeColor: _primaryColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAboutAndSupportSection() {
    return Card(
      elevation: 2,
      color: _cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSettingsItem(
              icon: Icons.info,
              title: 'About CosmoSoul',
              onTap: () {
                Navigator.pushNamed(context, '/about-cosmosoul');
              },
            ),
            Divider(color: _dividerColor),
            _buildSettingsItem(
              icon: Icons.verified_user,
              title: 'Verify Identity',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const UserVerificationPage(),
                  ),
                );
              },
            ),
            Divider(color: _dividerColor),
            _buildSettingsItem(
              icon: Icons.feedback,
              title: 'Feedback',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const FeedbackPage()),
                );
              },
            ),
            Divider(color: _dividerColor),
            _buildSettingsItem(
              icon: Icons.privacy_tip,
              title: 'Privacy Policy',
              onTap: () {
                // Navigate to privacy policy screen
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PrivacyPolicyScreen(),
                  ),
                );
              },
            ),
            Divider(color: _dividerColor),
            _buildSettingsItem(
              icon: Icons.description,
              title: 'Terms of Service',
              onTap: () {
                // Navigate to terms of service
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Terms of Service coming soon')),
                );
              },
            ),
            Divider(color: _dividerColor),
            _buildSettingsItem(
              icon: Icons.favorite,
              title: 'Support Lucky Star',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const DonationPage()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsItem({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: _iconColor),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: _textColor,
        ),
      ),
      subtitle:
          subtitle != null
              ? Text(subtitle, style: TextStyle(color: _subtitleColor))
              : null,
      trailing: Icon(Icons.chevron_right, color: _subtitleColor),
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildLogoutButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          // Logout logic
          showDialog(
            context: context,
            builder:
                (context) => AlertDialog(
                  title: const Text('Logout'),
                  content: const Text('Are you sure you want to logout?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () async {
                        Navigator.pop(context); // Close dialog

                        try {
                          // Show loading indicator
                          showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder:
                                (context) => const Center(
                                  child: CircularProgressIndicator(),
                                ),
                          );

                          // Sign out using Firebase Auth
                          final authService = AuthService();
                          await authService.signOut();

                          // Close loading indicator
                          if (mounted) Navigator.pop(context);

                          // Navigate to Welcome Page and clear navigation stack
                          if (mounted) {
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const WelcomePage(),
                              ),
                              (route) => false, // Remove all previous routes
                            );
                          }
                        } catch (e) {
                          // Close loading indicator if it's still showing
                          if (mounted) Navigator.pop(context);

                          // Show error message
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Logout failed: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      },
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                      child: const Text('Logout'),
                    ),
                  ],
                ),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text('Log Out', style: TextStyle(fontSize: 18)),
      ),
    );
  }
}
