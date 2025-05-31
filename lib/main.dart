import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import 'settings_screen.dart';

void main() {
  runApp(const ChatApp());
}

class ChatApp extends StatelessWidget {
  const ChatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI Chat',
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      home: const ChatScreen(),
      routes: {'/settings': (context) => const SettingsScreen()},
    );
  }
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final List<ChatMessage> _messages = [];
  final TextEditingController _textController = TextEditingController();
  bool _isLoading = false;

  // AI Agent prompt
  String get aiPrompt =>
      "You are a helpful AI assistant. Respond to the user's messages in a friendly and informative way. Keep responses concise and relevant to the conversation.";

  void _handleSubmitted(String text) async {
    if (text.isEmpty) return;

    // Add user message
    _textController.clear();
    setState(() {
      _messages.add(ChatMessage(text: text, isUser: true));
      _isLoading = true;
    });

    try {
      // Get API key from shared preferences
      final prefs = await SharedPreferences.getInstance();
      final apiKey = prefs.getString('api_key');

      if (apiKey == null || apiKey.isEmpty) {
        setState(() {
          _messages.add(
            ChatMessage(
              text: 'Please set your OpenAI API key in Settings',
              isUser: false,
            ),
          );
          _isLoading = false;
        });
        return;
      }

      // Call OpenAI API
      final response = await _callOpenAIApi(apiKey, text);

      setState(() {
        _messages.add(ChatMessage(text: response, isUser: false));
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _messages.add(
          ChatMessage(text: 'Error: ${e.toString()}', isUser: false),
        );
        _isLoading = false;
      });
    }
  }

  Future<String> _callOpenAIApi(String apiKey, String userMessage) async {
    const url = 'https://api.openai.com/v1/chat/completions';

    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $apiKey',
    };

    // Get model from shared preferences or use default
    final prefs = await SharedPreferences.getInstance();
    final model = prefs.getString('model') ?? 'gpt-3.5-turbo-0125';

    final body = jsonEncode({
      'model': model,
      'messages': [
        {'role': 'system', 'content': aiPrompt},
        {'role': 'user', 'content': userMessage},
      ],
      'temperature': 0.7,
    });

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: body,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'].trim();
      } else {
        // Log detailed error information
        final errorBody = jsonDecode(response.body);
        final errorCode = errorBody['error']['code'];
        final errorMessage = errorBody['error']['message'];

        throw Exception('API Error ($errorCode): $errorMessage');
      }
    } catch (e) {
      // Handle network errors
      throw Exception('Network error: ${e.toString()}');
    }
  }

  void _openSettings(BuildContext context) {
    Navigator.pushNamed(context, '/settings');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Chat'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => _openSettings(context),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(8.0),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                return _messages[index];
              },
            ),
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: CircularProgressIndicator(),
            ),
          const Divider(height: 1.0),
          Container(
            decoration: BoxDecoration(color: Theme.of(context).cardColor),
            child: _buildTextComposer(),
          ),
        ],
      ),
    );
  }

  Widget _buildTextComposer() {
    return IconTheme(
      data: IconThemeData(color: Theme.of(context).colorScheme.secondary),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Row(
          children: [
            Flexible(
              child: TextField(
                controller: _textController,
                onSubmitted: _handleSubmitted,
                decoration: const InputDecoration.collapsed(
                  hintText: 'Send a message...',
                ),
                enabled: !_isLoading,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.send),
              onPressed:
                  _isLoading
                      ? null
                      : () => _handleSubmitted(_textController.text),
            ),
          ],
        ),
      ),
    );
  }
}

class ChatMessage extends StatelessWidget {
  const ChatMessage({super.key, required this.text, required this.isUser});

  final String text;
  final bool isUser;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(right: 16.0),
            child: CircleAvatar(
              backgroundColor: isUser ? Colors.blue : Colors.green,
              child: Text(isUser ? 'U' : 'AI'),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Text(isUser ? 'You' : 'AI Assistant'),
                Container(
                  margin: const EdgeInsets.only(top: 5.0),
                  child: Text(text),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
