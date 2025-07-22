import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

class PrivacyPolicyScreen extends StatefulWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  State<PrivacyPolicyScreen> createState() => _PrivacyPolicyScreenState();
}

class _PrivacyPolicyScreenState extends State<PrivacyPolicyScreen> {
  bool _darkModeEnabled = false;
  bool _isLoading = true;
  WebViewController? _controller;
  String? _errorMessage;

  static const String privacyPolicyUrl =
      'https://ittend.notion.site/CosmoSoul-Privacy-Policy-238e1800c49480239003cc91853c8779';

  @override
  void initState() {
    super.initState();
    _loadDarkModePreference();
    _initializePrivacyPolicy();
  }

  // Load dark mode preference from SharedPreferences
  Future<void> _loadDarkModePreference() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _darkModeEnabled = prefs.getBool('darkModeEnabled') ?? false;
    });
  }

  // Initialize privacy policy based on platform
  Future<void> _initializePrivacyPolicy() async {
    if (kIsWeb) {
      // On web, open in new tab
      _openInBrowser();
    } else {
      // On mobile, use WebView
      _initializeWebView();
    }
  }

  // Initialize WebView for mobile platforms
  void _initializeWebView() {
    try {
      _controller =
          WebViewController()
            ..setJavaScriptMode(JavaScriptMode.unrestricted)
            ..setBackgroundColor(
              _darkModeEnabled ? const Color(0xFF121212) : Colors.white,
            )
            ..setNavigationDelegate(
              NavigationDelegate(
                onProgress: (int progress) {
                  // Update loading progress if needed
                },
                onPageStarted: (String url) {
                  setState(() {
                    _isLoading = true;
                    _errorMessage = null;
                  });
                },
                onPageFinished: (String url) {
                  setState(() {
                    _isLoading = false;
                  });
                },
                onWebResourceError: (WebResourceError error) {
                  setState(() {
                    _isLoading = false;
                    _errorMessage = 'Failed to load page: ${error.description}';
                  });
                },
                onNavigationRequest: (NavigationRequest request) {
                  // Allow all navigation for Notion pages
                  return NavigationDecision.navigate;
                },
              ),
            )
            ..loadRequest(Uri.parse(privacyPolicyUrl));
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to initialize WebView: $e';
      });
    }
  }

  // Open in external browser for web platform
  Future<void> _openInBrowser() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final Uri url = Uri.parse(privacyPolicyUrl);
      bool launched = false;

      try {
        // Try to open in new tab first
        launched = await launchUrl(url, mode: LaunchMode.externalApplication);
      } catch (e) {
        // Fallback to platform default
        launched = await launchUrl(url);
      }

      if (!launched) {
        throw Exception('Could not open privacy policy');
      }

      // For web, we can immediately go back since the link opens in a new tab
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Unable to open Privacy Policy: $e';
        });
      }
    }
  }

  void _retryLoad() {
    setState(() {
      _errorMessage = null;
    });

    if (kIsWeb) {
      _openInBrowser();
    } else {
      _initializeWebView();
    }
  }

  // Get theme colors based on dark mode status
  Color get _backgroundColor =>
      _darkModeEnabled ? const Color(0xFF121212) : Colors.white;
  Color get _cardColor =>
      _darkModeEnabled ? const Color(0xFF1E1E1E) : Colors.white;
  Color get _textColor => _darkModeEnabled ? Colors.white : Colors.black;
  Color get _subtitleColor =>
      _darkModeEnabled ? const Color(0xFFB3B3B3) : const Color(0xFF666666);
  Color get _primaryColor =>
      _darkModeEnabled ? const Color(0xFF9C27B0) : const Color(0xFF7153DF);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        title: Text('Privacy Policy', style: TextStyle(color: _textColor)),
        centerTitle: true,
        backgroundColor: _backgroundColor,
        elevation: 1,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: _textColor),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          // Refresh button for WebView
          if (!kIsWeb && _controller != null)
            IconButton(
              icon: Icon(Icons.refresh, color: _textColor),
              onPressed: () {
                _controller?.reload();
              },
            ),
          // Open in browser button
          IconButton(
            icon: Icon(Icons.open_in_browser, color: _textColor),
            onPressed: () async {
              try {
                final Uri url = Uri.parse(privacyPolicyUrl);
                await launchUrl(url, mode: LaunchMode.externalApplication);
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Could not open browser: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_errorMessage != null) {
      return _buildErrorView();
    }

    if (kIsWeb) {
      return _buildWebFallback();
    }

    return Stack(
      children: [
        if (_controller != null)
          WebViewWidget(controller: _controller!)
        else
          _buildErrorView(),

        // Loading indicator
        if (_isLoading)
          Container(
            color: _backgroundColor.withOpacity(0.8),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(_primaryColor),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Loading Privacy Policy...',
                    style: TextStyle(color: _textColor, fontSize: 16),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: _subtitleColor),
            const SizedBox(height: 16),
            Text(
              'Unable to Load Privacy Policy',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: _textColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'An unexpected error occurred',
              style: TextStyle(fontSize: 16, color: _subtitleColor),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _retryLoad,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () async {
                try {
                  final Uri url = Uri.parse(privacyPolicyUrl);
                  await launchUrl(url, mode: LaunchMode.externalApplication);
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Could not open browser: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              icon: const Icon(Icons.open_in_browser),
              label: const Text('Open in Browser'),
              style: OutlinedButton.styleFrom(
                foregroundColor: _primaryColor,
                side: BorderSide(color: _primaryColor),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWebFallback() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.privacy_tip_outlined, size: 64, color: _primaryColor),
            const SizedBox(height: 24),
            Text(
              'Privacy Policy',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: _textColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'The Privacy Policy will open in a new browser tab.',
              style: TextStyle(fontSize: 16, color: _subtitleColor),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () async {
                try {
                  final Uri url = Uri.parse(privacyPolicyUrl);
                  await launchUrl(url, mode: LaunchMode.externalApplication);
                  Navigator.pop(context);
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Could not open Privacy Policy: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              icon: const Icon(Icons.open_in_browser),
              label: const Text('Open Privacy Policy'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
