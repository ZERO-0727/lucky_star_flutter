import 'package:flutter/material.dart';

class UploadProgressBar extends StatefulWidget {
  final int totalImages;
  final int uploadedImages;
  final bool isVisible;
  final VoidCallback? onDismiss;

  const UploadProgressBar({
    super.key,
    required this.totalImages,
    required this.uploadedImages,
    this.isVisible = true,
    this.onDismiss,
  });

  @override
  State<UploadProgressBar> createState() => _UploadProgressBarState();
}

class _UploadProgressBarState extends State<UploadProgressBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _slideAnimation = Tween<double>(begin: -1.0, end: 0.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    if (widget.isVisible) {
      _animationController.forward();
    }
  }

  @override
  void didUpdateWidget(UploadProgressBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isVisible && !oldWidget.isVisible) {
      _animationController.forward();
    } else if (!widget.isVisible && oldWidget.isVisible) {
      _animationController.reverse();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isVisible) return const SizedBox.shrink();

    final progress =
        widget.totalImages > 0
            ? widget.uploadedImages / widget.totalImages
            : 0.0;

    final isComplete = widget.uploadedImages >= widget.totalImages;

    return AnimatedBuilder(
      animation: _slideAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _slideAnimation.value * 100),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isComplete ? Colors.green.shade50 : Colors.blue.shade50,
              border: Border(
                bottom: BorderSide(
                  color:
                      isComplete ? Colors.green.shade200 : Colors.blue.shade200,
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                // Icon
                Container(
                  width: 24,
                  height: 24,
                  child:
                      isComplete
                          ? Icon(
                            Icons.check_circle,
                            color: Colors.green.shade600,
                            size: 20,
                          )
                          : SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              value: progress,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.blue.shade600,
                              ),
                            ),
                          ),
                ),
                const SizedBox(width: 12),

                // Text
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        isComplete ? 'Upload complete!' : 'Uploading images...',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color:
                              isComplete
                                  ? Colors.green.shade700
                                  : Colors.blue.shade700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${widget.uploadedImages}/${widget.totalImages} photos',
                        style: TextStyle(
                          fontSize: 12,
                          color:
                              isComplete
                                  ? Colors.green.shade600
                                  : Colors.blue.shade600,
                        ),
                      ),
                    ],
                  ),
                ),

                // Progress percentage
                if (!isComplete) ...[
                  Text(
                    '${(progress * 100).toInt()}%',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.blue.shade600,
                    ),
                  ),
                  const SizedBox(width: 8),
                ],

                // Dismiss button
                if (isComplete && widget.onDismiss != null)
                  GestureDetector(
                    onTap: widget.onDismiss,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      child: Icon(
                        Icons.close,
                        size: 16,
                        color: Colors.green.shade600,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// Global state management for upload progress
class UploadProgressManager {
  static final UploadProgressManager _instance =
      UploadProgressManager._internal();
  factory UploadProgressManager() => _instance;
  UploadProgressManager._internal();

  final ValueNotifier<UploadProgressState> _progressNotifier = ValueNotifier(
    UploadProgressState.idle(),
  );

  ValueNotifier<UploadProgressState> get progressNotifier => _progressNotifier;

  void startUpload(int totalImages) {
    _progressNotifier.value = UploadProgressState(
      isActive: true,
      totalImages: totalImages,
      uploadedImages: 0,
      isComplete: false,
    );
  }

  void updateProgress(int uploadedImages) {
    final current = _progressNotifier.value;
    _progressNotifier.value = current.copyWith(
      uploadedImages: uploadedImages,
      isComplete: uploadedImages >= current.totalImages,
    );
  }

  void completeUpload() {
    final current = _progressNotifier.value;
    _progressNotifier.value = current.copyWith(
      isComplete: true,
      uploadedImages: current.totalImages,
    );
  }

  void dismissUpload() {
    _progressNotifier.value = UploadProgressState.idle();
  }

  void cancelUpload() {
    _progressNotifier.value = UploadProgressState.idle();
  }
}

class UploadProgressState {
  final bool isActive;
  final int totalImages;
  final int uploadedImages;
  final bool isComplete;

  const UploadProgressState({
    required this.isActive,
    required this.totalImages,
    required this.uploadedImages,
    required this.isComplete,
  });

  factory UploadProgressState.idle() {
    return const UploadProgressState(
      isActive: false,
      totalImages: 0,
      uploadedImages: 0,
      isComplete: false,
    );
  }

  UploadProgressState copyWith({
    bool? isActive,
    int? totalImages,
    int? uploadedImages,
    bool? isComplete,
  }) {
    return UploadProgressState(
      isActive: isActive ?? this.isActive,
      totalImages: totalImages ?? this.totalImages,
      uploadedImages: uploadedImages ?? this.uploadedImages,
      isComplete: isComplete ?? this.isComplete,
    );
  }
}
