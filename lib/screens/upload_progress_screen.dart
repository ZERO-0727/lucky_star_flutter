import 'package:flutter/material.dart';
import '../services/notification_service.dart';

class UploadProgressScreen extends StatefulWidget {
  final String experienceId;
  final String experienceTitle;
  final int totalImages;

  const UploadProgressScreen({
    super.key,
    required this.experienceId,
    required this.experienceTitle,
    required this.totalImages,
  });

  @override
  State<UploadProgressScreen> createState() => _UploadProgressScreenState();
}

class _UploadProgressScreenState extends State<UploadProgressScreen>
    with TickerProviderStateMixin {
  late AnimationController _progressAnimationController;
  late AnimationController _pulseAnimationController;
  late Animation<double> _progressAnimation;
  late Animation<double> _pulseAnimation;

  String _statusMessage = 'Preparing upload...';
  double _progress = 0.0;
  bool _isComplete = false;
  bool _hasError = false;
  String? _errorMessage;
  int _uploadedImages = 0;

  @override
  void initState() {
    super.initState();

    _progressAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _pulseAnimationController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat(reverse: true);

    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _progressAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(
        parent: _pulseAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    _listenToUploadProgress();
    _startUploadingMessage();
  }

  void _startUploadingMessage() {
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted && !_isComplete && !_hasError) {
        setState(() {
          _statusMessage = 'Uploading images...';
        });
      }
    });
  }

  void _listenToUploadProgress() {
    NotificationService().currentNotification.addListener(
      _onNotificationUpdate,
    );
  }

  void _onNotificationUpdate() {
    final notification = NotificationService().currentNotification.value;
    if (notification == null) return;

    if (mounted) {
      setState(() {
        switch (notification['type']) {
          case 'experience_uploading':
            _statusMessage = notification['message'] ?? 'Uploading images...';
            _uploadedImages = notification['progress'] ?? 0;
            final total = notification['total'] ?? widget.totalImages;

            // Use overall progress if available, otherwise calculate from completed images
            if (notification['overallProgress'] != null) {
              _progress = notification['overallProgress'];
            } else {
              _progress = total > 0 ? _uploadedImages / total : 0.0;
            }

            _progressAnimationController.animateTo(_progress);
            break;

          case 'experience_success':
            _isComplete = true;
            _hasError = false;
            _progress = 1.0;
            _statusMessage = notification['message'] ?? 'Upload complete!';
            _progressAnimationController.animateTo(1.0);
            _pulseAnimationController.stop();
            _showCompletionAndNavigate();
            break;

          case 'experience_error':
            _hasError = true;
            _isComplete = false;
            _errorMessage = notification['message'] ?? 'Upload failed';
            _statusMessage = 'Upload failed';
            _pulseAnimationController.stop();
            break;
        }
      });
    }
  }

  void _showCompletionAndNavigate() {
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    });
  }

  @override
  void dispose() {
    NotificationService().currentNotification.removeListener(
      _onNotificationUpdate,
    );
    _progressAnimationController.dispose();
    _pulseAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Publishing Experience'),
        backgroundColor: const Color(0xFF7153DF),
        foregroundColor: Colors.white,
        elevation: 0,
        leading:
            _isComplete
                ? null
                : IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                ),
        automaticallyImplyLeading: !_isComplete,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const SizedBox(height: 40),

            // Experience Info
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: const Color(0xFF7153DF).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.auto_awesome,
                      color: Color(0xFF7153DF),
                      size: 30,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.experienceTitle,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.totalImages > 0
                              ? '${widget.totalImages} photos to upload'
                              : 'No photos to upload',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),

            // Progress Section
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Status Icon
                  AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale:
                            _isComplete || _hasError
                                ? 1.0
                                : _pulseAnimation.value,
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color:
                                _hasError
                                    ? Colors.red.withOpacity(0.1)
                                    : _isComplete
                                    ? Colors.green.withOpacity(0.1)
                                    : const Color(0xFF7153DF).withOpacity(0.1),
                          ),
                          child: Icon(
                            _hasError
                                ? Icons.error_outline
                                : _isComplete
                                ? Icons.check_circle_outline
                                : Icons.cloud_upload_outlined,
                            size: 60,
                            color:
                                _hasError
                                    ? Colors.red
                                    : _isComplete
                                    ? Colors.green
                                    : const Color(0xFF7153DF),
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 32),

                  // Status Message
                  Text(
                    _statusMessage,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: _hasError ? Colors.red : Colors.grey[800],
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 16),

                  // Progress Details
                  if (widget.totalImages > 0 && !_hasError) ...[
                    Text(
                      _isComplete
                          ? 'All images uploaded successfully!'
                          : '$_uploadedImages of ${widget.totalImages} images uploaded',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),

                    const SizedBox(height: 24),

                    // Progress Bar
                    Container(
                      width: double.infinity,
                      height: 8,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        color: Colors.grey[200],
                      ),
                      child: AnimatedBuilder(
                        animation: _progressAnimation,
                        builder: (context, child) {
                          return Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: LinearProgressIndicator(
                              value: _progressAnimation.value,
                              backgroundColor: Colors.transparent,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                _isComplete
                                    ? Colors.green
                                    : const Color(0xFF7153DF),
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Percentage
                    AnimatedBuilder(
                      animation: _progressAnimation,
                      builder: (context, child) {
                        return Text(
                          '${(_progressAnimation.value * 100).toStringAsFixed(0)}%',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color:
                                _isComplete
                                    ? Colors.green
                                    : const Color(0xFF7153DF),
                          ),
                        );
                      },
                    ),
                  ],

                  // Error Message
                  if (_hasError && _errorMessage != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red.withOpacity(0.3)),
                      ),
                      child: Column(
                        children: [
                          Text(
                            _errorMessage!,
                            style: const TextStyle(
                              color: Colors.red,
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Your experience has been published, but images couldn\'t be uploaded. You can try uploading them again later.',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Action Buttons
            if (_hasError || _isComplete) ...[
              const SizedBox(height: 24),
              if (_hasError) ...[
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.of(
                            context,
                          ).popUntil((route) => route.isFirst);
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: const BorderSide(color: Color(0xFF7153DF)),
                        ),
                        child: const Text(
                          'Go to Home',
                          style: TextStyle(color: Color(0xFF7153DF)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          // TODO: Implement retry logic
                          Navigator.of(
                            context,
                          ).popUntil((route) => route.isFirst);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF7153DF),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text(
                          'Retry Upload',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ] else if (_isComplete) ...[
                const Text(
                  'Redirecting to home...',
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                ),
              ],
            ],

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
