import 'package:flutter/material.dart';
import 'feedback_page.dart';
import 'donation_page.dart';
import 'user_verification_page.dart';

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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
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
        Expanded(child: Divider(color: Colors.grey[400], thickness: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF7153DF),
            ),
          ),
        ),
        Expanded(child: Divider(color: Colors.grey[400], thickness: 1)),
      ],
    );
  }

  Widget _buildProfileSettingsSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSettingsItem(
              icon: Icons.account_circle,
              title: 'Profile Picture & Account Security',
              onTap: () {
                // Navigate to profile picture & security settings
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Profile Picture & Security settings coming soon')),
                );
              },
            ),
            const Divider(),
            _buildSettingsItem(
              icon: Icons.person,
              title: 'Username',
              subtitle: 'sarahjohnson',
              onTap: () {
                // Navigate to username settings
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Username settings coming soon')),
                );
              },
            ),
            const Divider(),
            _buildSettingsItem(
              icon: Icons.email,
              title: 'Email',
              subtitle: 'sarah.johnson@example.com',
              onTap: () {
                // Navigate to email settings
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Email settings coming soon')),
                );
              },
            ),
            const Divider(),
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
            const Divider(),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: OutlinedButton(
                onPressed: () {
                  // Navigate to change password
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Change Password coming soon')),
                  );
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF7153DF),
                  side: const BorderSide(color: Color(0xFF7153DF)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.lock_outline),
                    SizedBox(width: 8),
                    Text('Change Password'),
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
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
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
                  const Icon(Icons.language, color: Color(0xFF7153DF)),
                  const SizedBox(width: 16),
                  const Text(
                    'Language',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  DropdownButton<String>(
                    value: _selectedLanguage,
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() {
                          _selectedLanguage = newValue;
                        });
                      }
                    },
                    items: _availableLanguages
                        .map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    underline: Container(),
                  ),
                ],
              ),
            ),
            const Divider(),
            // Dark Mode Toggle
            SwitchListTile(
              title: const Text(
                'Dark Mode',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              secondary: const Icon(Icons.dark_mode, color: Color(0xFF7153DF)),
              value: _darkModeEnabled,
              onChanged: (bool value) {
                setState(() {
                  _darkModeEnabled = value;
                });
              },
              activeColor: const Color(0xFF7153DF),
            ),
            const Divider(),
            // Notifications Toggle
            SwitchListTile(
              title: const Text(
                'Notifications',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              secondary: const Icon(Icons.notifications, color: Color(0xFF7153DF)),
              value: _notificationsEnabled,
              onChanged: (bool value) {
                setState(() {
                  _notificationsEnabled = value;
                });
              },
              activeColor: const Color(0xFF7153DF),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAboutAndSupportSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSettingsItem(
              icon: Icons.info,
              title: 'About Lucky Star',
              onTap: () {
                // Navigate to about page
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('About page coming soon')),
                );
              },
            ),
            const Divider(),
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
            _buildSettingsItem(
              icon: Icons.feedback,
              title: 'Feedback',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const FeedbackPage(),
                  ),
                );
              },
            ),
            const Divider(),
            _buildSettingsItem(
              icon: Icons.privacy_tip,
              title: 'Privacy Policy',
              onTap: () {
                // Navigate to privacy policy
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Privacy Policy coming soon')),
                );
              },
            ),
            const Divider(),
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
            const Divider(),
            _buildSettingsItem(
              icon: Icons.favorite,
              title: 'Support Lucky Star',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const DonationPage(),
                  ),
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
      leading: Icon(icon, color: const Color(0xFF7153DF)),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: subtitle != null ? Text(subtitle) : null,
      trailing: const Icon(Icons.chevron_right),
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
            builder: (context) => AlertDialog(
              title: const Text('Logout'),
              content: const Text('Are you sure you want to logout?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context); // Close dialog
                    Navigator.pop(context); // Go back to profile
                    // In a real app, you would implement actual logout logic here
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Logged out successfully')),
                    );
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red,
                  ),
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
        child: const Text(
          'Log Out',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
