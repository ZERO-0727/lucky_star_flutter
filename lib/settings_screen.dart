import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  void initState() {
    super.initState();
  }

  Future<String> _loadProvider() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('ai_provider') ?? 'OpenAI';
  }

  Future<String> _loadModel() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('model') ?? 'gpt-3.5-turbo-0125';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'AI Provider',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            FutureBuilder<String>(
              future: _loadProvider(),
              builder: (context, snapshot) {
                return DropdownButtonFormField<String>(
                  value: snapshot.data ?? 'OpenAI',
                  items: const [
                    DropdownMenuItem(value: 'OpenAI', child: Text('OpenAI')),
                    DropdownMenuItem(
                      value: 'OpenRouter',
                      child: Text('OpenRouter'),
                    ),
                    DropdownMenuItem(
                      value: 'Google Gemini',
                      child: Text('Google Gemini'),
                    ),
                  ],
                  onChanged: (value) async {
                    if (value != null) {
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setString('ai_provider', value);
                    }
                  },
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            const Text(
              'Model',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            FutureBuilder<String>(
              future: _loadModel(),
              builder: (context, snapshot) {
                return DropdownButtonFormField<String>(
                  value: snapshot.data ?? 'gpt-3.5-turbo-0125',
                  items: const [
                    DropdownMenuItem(
                      value: 'gpt-3.5-turbo-0125',
                      child: Text('GPT-3.5 Turbo (gpt-3.5-turbo-0125)'),
                    ),
                    DropdownMenuItem(
                      value: 'gpt-4-turbo',
                      child: Text('GPT-4 Turbo (gpt-4-turbo)'),
                    ),
                    DropdownMenuItem(
                      value: 'gpt-4o',
                      child: Text('GPT-4o (gpt-4o)'),
                    ),
                  ],
                  onChanged: (value) async {
                    if (value != null) {
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setString('model', value);
                    }
                  },
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            const Text(
              'Note: API keys are now stored in .env file',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
