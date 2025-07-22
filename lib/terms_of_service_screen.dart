import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

class TermsOfServiceScreen extends StatefulWidget {
  const TermsOfServiceScreen({super.key});

  @override
  State<TermsOfServiceScreen> createState() => _TermsOfServiceScreenState();
}

class _TermsOfServiceScreenState extends State<TermsOfServiceScreen> {
  bool _darkModeEnabled = false;
  bool _isLoading = true;
  WebViewController? _controller;
  String? _errorMessage;
  bool _hasTimedOut = false;

  static const String termsOfServiceUrl =
      'https://ittend.notion.site/CosmoSoul-Terms-of-Service-238e1800c49480078a77fa858f2aa38c';

  @override
  void initState() {
    super.initState();
    _loadDarkModePreference();
    _initializeTermsOfService();
    _startLoadingTimeout();
  }

  // Add timeout to prevent infinite loading
  void _startLoadingTimeout() {
    Future.delayed(const Duration(seconds: 15), () {
      if (mounted && _isLoading && _errorMessage == null) {
        setState(() {
          _isLoading = false;
          _hasTimedOut = true;
          _errorMessage =
              'Loading timed out. Please check your internet connection and try again.';
        });
      }
    });
  }

  // Load dark mode preference from SharedPreferences
  Future<void> _loadDarkModePreference() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _darkModeEnabled = prefs.getBool('darkModeEnabled') ?? false;
    });
  }

  // Initialize terms of service based on platform
  Future<void> _initializeTermsOfService() async {
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
                  print('WebView loading progress: $progress%');
                },
                onPageStarted: (String url) {
                  print('WebView started loading: $url');
                  if (mounted) {
                    setState(() {
                      _isLoading = true;
                      _errorMessage = null;
                      _hasTimedOut = false;
                    });
                  }
                },
                onPageFinished: (String url) {
                  print('WebView finished loading: $url');
                  if (mounted) {
                    setState(() {
                      _isLoading = false;
                    });
                  }
                },
                onWebResourceError: (WebResourceError error) {
                  print(
                    'WebView error: ${error.description} (${error.errorCode})',
                  );
                  if (mounted) {
                    setState(() {
                      _isLoading = false;
                      _errorMessage =
                          'Failed to load page: ${error.description}';
                    });
                  }
                },
                onNavigationRequest: (NavigationRequest request) {
                  print('WebView navigation request: ${request.url}');
                  // Allow all navigation for Notion pages and related domains
                  if (request.url.contains('notion.site') ||
                      request.url.contains('notion.so') ||
                      request.url.startsWith('https://')) {
                    return NavigationDecision.navigate;
                  }
                  return NavigationDecision.prevent;
                },
              ),
            );

      // Load the URL after controller is fully configured
      _controller!
          .loadRequest(Uri.parse(termsOfServiceUrl))
          .then((_) {
            print('WebView load request initiated');
          })
          .catchError((error) {
            print('WebView load request failed: $error');
            if (mounted) {
              setState(() {
                _isLoading = false;
                _errorMessage = 'Failed to load Terms of Service: $error';
              });
            }
          });
    } catch (e) {
      print('WebView initialization failed: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to initialize WebView: $e';
        });
      }
    }
  }

  // Open in external browser for web platform
  Future<void> _openInBrowser() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final Uri url = Uri.parse(termsOfServiceUrl);
      bool launched = false;

      try {
        // Try to open in new tab first
        launched = await launchUrl(url, mode: LaunchMode.externalApplication);
      } catch (e) {
        // Fallback to platform default
        launched = await launchUrl(url);
      }

      if (!launched) {
        throw Exception('Could not open terms of service');
      }

      // For web, we can immediately go back since the link opens in a new tab
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Unable to open Terms of Service: $e';
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
        title: Text('Terms of Service', style: TextStyle(color: _textColor)),
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
                final Uri url = Uri.parse(termsOfServiceUrl);
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
                    'Loading Terms of Service...',
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
              'Unable to Load Terms of Service',
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
                  final Uri url = Uri.parse(termsOfServiceUrl);
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
            Icon(Icons.description_outlined, size: 64, color: _primaryColor),
            const SizedBox(height: 24),
            Text(
              'Terms of Service',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: _textColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'The Terms of Service will open in a new browser tab.',
              style: TextStyle(fontSize: 16, color: _subtitleColor),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () async {
                try {
                  final Uri url = Uri.parse(termsOfServiceUrl);
                  await launchUrl(url, mode: LaunchMode.externalApplication);
                  Navigator.pop(context);
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Could not open Terms of Service: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              icon: const Icon(Icons.open_in_browser),
              label: const Text('Open Terms of Service'),
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
