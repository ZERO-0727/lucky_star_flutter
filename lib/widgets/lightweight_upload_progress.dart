import 'package:flutter/material.dart';
import '../services/notification_service.dart';

class LightweightUploadProgress extends StatefulWidget {
  const LightweightUploadProgress({super.key});

  @override
  State<LightweightUploadProgress> createState() =>
      _LightweightUploadProgressState();
}

class _LightweightUploadProgressState extends State<LightweightUploadProgress>
    with TickerProviderStateMixin {
  late AnimationController _progressController;
  late AnimationController _slideController;
  late Animation<double> _progressAnimation;
  late Animation<Offset> _slideAnimation;

  String _statusMessage = 'Uploading images...';
  double _progress = 0.0;
  bool _isVisible = false;
  bool _isComplete = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();

    _progressController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));

    _listenToUploadProgress();
  }

  void _listenToUploadProgress() {
    NotificationService().currentNotification.addListener(
      _onNotificationUpdate,
    );
  }

  void _onNotificationUpdate() {
    final notification = NotificationService().currentNotification.value;

    if (notification == null) {
      if (_isVisible) {
        _hideProgress();
      }
      return;
    }

    if (mounted) {
      setState(() {
        switch (notification['type']) {
          case 'experience_uploading':
            if (!_isVisible) {
              _showProgress();
            }
            _statusMessage = notification['message'] ?? 'Uploading images...';

            // Use overall progress if available
            if (notification['overallProgress'] != null) {
              _progress = notification['overallProgress'];
            } else {
              final uploaded = notification['progress'] ?? 0;
              final total = notification['total'] ?? 1;
              _progress = total > 0 ? uploaded / total : 0.0;
            }

            _progressController.animateTo(_progress);
            break;

          case 'experience_success':
            _isComplete = true;
            _hasError = false;
            _progress = 1.0;
            _statusMessage = notification['message'] ?? 'Upload complete!';
            _progressController.animateTo(1.0);

            // Auto-hide after success
            Future.delayed(const Duration(seconds: 3), () {
              if (mounted) _hideProgress();
            });
            break;

          case 'experience_error':
            _hasError = true;
            _isComplete = false;
            _statusMessage = 'Upload failed, but experience is published';

            // Auto-hide after error
            Future.delayed(const Duration(seconds: 5), () {
              if (mounted) _hideProgress();
            });
            break;
        }
      });
    }
  }

  void _showProgress() {
    if (!_isVisible) {
      setState(() {
        _isVisible = true;
      });
      _slideController.forward();
    }
  }

  void _hideProgress() {
    if (_isVisible) {
      _slideController.reverse().then((_) {
        if (mounted) {
          setState(() {
            _isVisible = false;
            _isComplete = false;
            _hasError = false;
            _progress = 0.0;
          });
        }
      });
    }
  }

  @override
  void dispose() {
    NotificationService().currentNotification.removeListener(
      _onNotificationUpdate,
    );
    _progressController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isVisible) return const SizedBox.shrink();

    return SlideTransition(
      position: _slideAnimation,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color:
              _hasError
                  ? Colors.orange
                  : _isComplete
                  ? Colors.green
                  : const Color(0xFF7153DF),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Status row
                Row(
                  children: [
                    // Status icon
                    SizedBox(
                      width: 20,
                      height: 20,
                      child:
                          _hasError
                              ? const Icon(
                                Icons.warning,
                                color: Colors.white,
                                size: 18,
                              )
                              : _isComplete
                              ? const Icon(
                                Icons.check_circle,
                                color: Colors.white,
                                size: 18,
                              )
                              : const CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                    ),
                    const SizedBox(width: 12),

                    // Status message
                    Expanded(
                      child: Text(
                        _statusMessage,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),

                    // Progress percentage
                    if (!_hasError && !_isComplete)
                      AnimatedBuilder(
                        animation: _progressAnimation,
                        builder: (context, child) {
                          return Text(
                            '${(_progressAnimation.value * 100).toInt()}%',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          );
                        },
                      ),

                    // Close button (only for errors or completion)
                    if (_hasError || _isComplete) ...[
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: _hideProgress,
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ],
                  ],
                ),

                // Progress bar
                if (!_hasError) ...[
                  const SizedBox(height: 8),
                  Container(
                    height: 3,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(1.5),
                      color: Colors.white.withOpacity(0.3),
                    ),
                    child: AnimatedBuilder(
                      animation: _progressAnimation,
                      builder: (context, child) {
                        return Container(
                          height: 3,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(1.5),
                          ),
                          child: LinearProgressIndicator(
                            value: _progressAnimation.value,
                            backgroundColor: Colors.transparent,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
