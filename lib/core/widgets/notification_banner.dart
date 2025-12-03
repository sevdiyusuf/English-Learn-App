import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../notifications/notification_service.dart';

/// Notification banner widget that displays notifications at the top
class NotificationBanner extends ConsumerWidget {
  const NotificationBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationService = ref.watch(notificationServiceProvider);
    final notifications = notificationService.currentNotifications;

    if (notifications.isEmpty) {
      return const SizedBox.shrink();
    }

    // Show only the first notification
    final notification = notifications.first;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(8),
      child: Material(
        elevation: 4,
        borderRadius: BorderRadius.circular(8),
        color: notification.color,
        child: InkWell(
          onTap: () {
            notificationService.dismissNotification(notification.id);
          },
          borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  Icon(
                    notification.icon,
                    color: Colors.white,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          notification.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        if (notification.message != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            notification.message!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                if (notification.action != null) ...[
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () {
                      notification.action!.onPressed();
                      notificationService.dismissNotification(notification.id);
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white,
                    ),
                    child: Text(notification.action!.label),
                  ),
                ],
                const SizedBox(width: 4),
                IconButton(
                  onPressed: () {
                    notificationService.dismissNotification(notification.id);
                  },
                  icon: const Icon(Icons.close, color: Colors.white, size: 16),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Toast-style notification widget
class NotificationToast extends ConsumerWidget {
  const NotificationToast({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationService = ref.watch(notificationServiceProvider);
    
    return StreamBuilder<List<AppNotification>>(
      stream: notificationService.notifications,
      builder: (context, snapshot) {
        final notifications = snapshot.data ?? [];
        if (notifications.isEmpty) {
          return const SizedBox.shrink();
        }

        return Positioned(
          top: MediaQuery.of(context).padding.top + 4,
          left: 12,
          right: 12,
          child: Column(
            children: notifications.map((notification) {
              return _NotificationToastItem(
                key: ValueKey(notification.id),
                notification: notification,
                onDismiss: () {
                  notificationService.dismissNotification(notification.id);
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }
}

class _NotificationToastItem extends StatefulWidget {
  const _NotificationToastItem({
    required this.notification,
    required this.onDismiss,
    super.key,
  });

  final AppNotification notification;
  final VoidCallback onDismiss;

  @override
  State<_NotificationToastItem> createState() => _NotificationToastItemState();
}

class _NotificationToastItemState extends State<_NotificationToastItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _controller.forward();

    // Auto-dismiss
    Future.delayed(widget.notification.duration, () {
      if (mounted) {
        _dismiss();
      }
    });
  }

  void _dismiss() {
    _controller.reverse().then((_) {
      if (mounted) {
        widget.onDismiss();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
          child: Container(
            margin: const EdgeInsets.only(bottom: 6),
            decoration: BoxDecoration(
              color: widget.notification.color,
              borderRadius: BorderRadius.circular(6),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _dismiss,
              borderRadius: BorderRadius.circular(6),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Icon(
                  widget.notification.icon,
                  color: Colors.white,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.notification.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      if (widget.notification.message != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          widget.notification.message!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                    if (widget.notification.action != null) ...[
                      const SizedBox(width: 8),
                      TextButton(
                        onPressed: () {
                          widget.notification.action!.onPressed();
                          _dismiss();
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white,
                        ),
                        child: Text(widget.notification.action!.label),
                      ),
                    ],
                    const SizedBox(width: 4),
                    IconButton(
                      onPressed: _dismiss,
                      icon: const Icon(Icons.close, color: Colors.white, size: 16),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

