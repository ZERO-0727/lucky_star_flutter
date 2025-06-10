import 'package:flutter/material.dart';
import '../services/notification_service.dart';

class UploadNotificationBar extends StatelessWidget {
  const UploadNotificationBar({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Map<String, dynamic>?>(
      valueListenable: NotificationService().currentNotification,
      builder: (context, notification, child) {
        if (notification == null || notification['isVisible'] != true) {
          return const SizedBox.shrink();
        }

        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: _getBackgroundColor(notification['type']),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: SafeArea(
            bottom: false,
            child: Row(
              children: [
                _getIcon(notification['type']),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        notification['message'] ?? '',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (notification['type'] == 'experience_uploading') ...[
                        const SizedBox(height: 8),
                        LinearProgressIndicator(
                          value:
                              notification['total'] > 0
                                  ? (notification['progress'] ?? 0) /
                                      notification['total']
                                  : null,
                          backgroundColor: Colors.white.withOpacity(0.3),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (notification['type'] != 'experience_uploading')
                  IconButton(
                    icon: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 20,
                    ),
                    onPressed: () {
                      NotificationService().hideNotification();
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Color _getBackgroundColor(String? type) {
    switch (type) {
      case 'experience_uploading':
        return const Color(0xFF7153DF);
      case 'experience_success':
        return Colors.green;
      case 'experience_error':
        return Colors.orange;
      default:
        return const Color(0xFF7153DF);
    }
  }

  Widget _getIcon(String? type) {
    switch (type) {
      case 'experience_uploading':
        return const SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
        );
      case 'experience_success':
        return const Icon(Icons.check_circle, color: Colors.white, size: 20);
      case 'experience_error':
        return const Icon(Icons.warning, color: Colors.white, size: 20);
      default:
        return const Icon(Icons.info, color: Colors.white, size: 20);
    }
  }
}
