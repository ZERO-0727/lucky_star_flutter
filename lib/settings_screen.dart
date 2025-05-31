import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _apiKeyController = TextEditingController();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadApiKey();
  }

  Future<void> _loadApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _apiKeyController.text = prefs.getString('api_key') ?? '';
    });
  }

  Future<void> _saveApiKey() async {
    setState(() => _isSaving = true);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('api_key', _apiKeyController.text);
    setState(() => _isSaving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('API Key saved successfully!')),
    );
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
              'OpenAI API Key',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _apiKeyController,
              decoration: const InputDecoration(
                hintText: 'Enter your OpenAI API key',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveApiKey,
                child:
                    _isSaving
                        ? const CircularProgressIndicator()
                        : const Text('Save API Key'),
              ),
            ),
            const SizedBox(height: 16),
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
              'Note: Your API key is stored securely on your device and never sent anywhere else.',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
