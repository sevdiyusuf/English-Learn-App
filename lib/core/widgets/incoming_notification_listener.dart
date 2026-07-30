import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yunoo/l10n/app_localizations.dart';

import '../notifications/incoming_route_coordinator.dart';
import '../notifications/notification_service.dart';

class IncomingNotificationListener extends ConsumerWidget {
  const IncomingNotificationListener({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(incomingRouteCoordinatorProvider);
    ref.listen(incomingRouteCoordinatorProvider, (previous, next) {
      final l10n = AppLocalizations.of(context);
      if (l10n == null) return;
      final invitation = next.foregroundInvitation;
      if (invitation != null && invitation != previous?.foregroundInvitation) {
        ref
            .read(notificationServiceProvider)
            .showNotification(
              AppNotification(
                id: invitation.deduplicationKey,
                title: l10n.invitationNotificationTitle,
                message: l10n.invitationNotificationBody,
                type: NotificationType.info,
                duration: const Duration(seconds: 12),
                actions: [
                  NotificationAction(
                    label: l10n.invitationDismiss,
                    onPressed:
                        () =>
                            ref
                                .read(incomingRouteCoordinatorProvider.notifier)
                                .dismissForegroundInvitation(),
                  ),
                  NotificationAction(
                    label: l10n.invitationOpen,
                    onPressed:
                        () =>
                            ref
                                .read(incomingRouteCoordinatorProvider.notifier)
                                .openForegroundInvitation(),
                  ),
                ],
              ),
            );
      }
      if (next.invitationUnavailable &&
          previous?.invitationUnavailable != true) {
        ref
            .read(notificationServiceProvider)
            .showError(title: l10n.invitationUnavailable);
        ref.read(incomingRouteCoordinatorProvider.notifier).clearUnavailable();
      }
    });
    return child;
  }
}
