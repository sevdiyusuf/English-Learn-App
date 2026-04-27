import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Notification types
enum NotificationType {
  info,
  success,
  warning,
  error,
}

/// Notification data model
class AppNotification {
  AppNotification({
    required this.id,
    required this.title,
    this.message,
    required this.type,
    this.duration = const Duration(seconds: 3),
    this.actions,
  });

  final String id;
  final String title;
  final String? message;
  final NotificationType type;
  final Duration duration;
  final List<NotificationAction>? actions;

  IconData get icon {
    switch (type) {
      case NotificationType.success:
        return Icons.check_circle;
      case NotificationType.error:
        return Icons.error;
      case NotificationType.warning:
        return Icons.warning;
      case NotificationType.info:
        return Icons.info;
    }
  }

  Color get color {
    switch (type) {
      case NotificationType.success:
        return Colors.green;
      case NotificationType.error:
        return Colors.red;
      case NotificationType.warning:
        return Colors.orange;
      case NotificationType.info:
        return Colors.blue;
    }
  }
}

/// Notification action
class NotificationAction {
  NotificationAction({
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback onPressed;
}

/// Notification service
class NotificationService {
  NotificationService();

  final List<AppNotification> _notifications = [];
  final StreamController<List<AppNotification>> _controller =
      StreamController<List<AppNotification>>.broadcast();

  Stream<List<AppNotification>> get notifications => _controller.stream;
  List<AppNotification> get currentNotifications => List.unmodifiable(_notifications);

  /// Show a notification
  void showNotification(AppNotification notification) {
    _notifications.add(notification);
    _controller.add(currentNotifications);

    // Request browser notification permission (web only)
    if (kIsWeb) {
      _requestBrowserNotificationPermission(notification);
    }

    // Auto-dismiss after duration
    Timer(notification.duration, () {
      dismissNotification(notification.id);
    });
  }

  /// Show success notification
  void showSuccess({
    required String title,
    String? message,
    Duration? duration,
  }) {
    showNotification(
      AppNotification(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: title,
        message: message,
        type: NotificationType.success,
        duration: duration ?? const Duration(seconds: 3),
      ),
    );
  }

  /// Show error notification
  void showError({
    required String title,
    String? message,
    Duration? duration,
  }) {
    showNotification(
      AppNotification(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: title,
        message: message,
        type: NotificationType.error,
        duration: duration ?? const Duration(seconds: 4),
      ),
    );
  }

  /// Show warning notification
  void showWarning({
    required String title,
    String? message,
    Duration? duration,
  }) {
    showNotification(
      AppNotification(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: title,
        message: message,
        type: NotificationType.warning,
        duration: duration ?? const Duration(seconds: 4),
      ),
    );
  }

  /// Show info notification
  void showInfo({
    required String title,
    String? message,
    Duration? duration,
  }) {
    showNotification(
      AppNotification(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: title,
        message: message,
        type: NotificationType.info,
        duration: duration ?? const Duration(seconds: 3),
      ),
    );
  }

  /// Dismiss a notification
  void dismissNotification(String id) {
    _notifications.removeWhere((n) => n.id == id);
    _controller.add(currentNotifications);
  }

  /// Dismiss all notifications
  void dismissAll() {
    _notifications.clear();
    _controller.add(currentNotifications);
  }

  /// Request browser notification permission (web only)
  Future<void> _requestBrowserNotificationPermission(AppNotification notification) async {
    if (!kIsWeb) return;

    try {
      // Request permission
      final permission = await _getBrowserNotificationPermission();
      
      if (permission == 'granted') {
        // Show browser notification
        _showBrowserNotification(notification);
      }
    } catch (e) {
      // Browser notifications not supported or permission denied
      if (kDebugMode) {
        debugPrint('Browser notification error: $e');
      }
    }
  }

  /// Get browser notification permission
  Future<String?> _getBrowserNotificationPermission() async {
    if (!kIsWeb) return null;

    try {
      // Use dart:html for web notifications
      // This is a simplified version - in real implementation,
      // you'd use package:universal_html or similar
      return 'default'; // Simplified for now
    } catch (e) {
      return null;
    }
  }

  /// Show browser notification
  void _showBrowserNotification(AppNotification notification) {
    if (!kIsWeb) return;

    // Browser notification implementation
    // In a real app, you'd use the Web Notifications API
    // For now, we'll just show in-app notifications
  }

  void dispose() {
    _controller.close();
  }
}

/// Notification service provider
final notificationServiceProvider = Provider<NotificationService>((ref) {
  final service = NotificationService();
  ref.onDispose(() => service.dispose());
  return service;
});

