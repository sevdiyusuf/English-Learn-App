import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yunoo/core/notifications/notification_service.dart';
import 'package:yunoo/core/widgets/notification_banner.dart';

import '../support/sprint9c_test_harness.dart';

void main() {
  testWidgets(
    'foreground invitation exposes independent 48px labeled actions at 2x text',
    (tester) async {
      await configureTestView(tester, logicalSize: const Size(320, 520));
      final service = NotificationService();
      addTearDown(service.dispose);
      var opened = 0;
      var dismissed = 0;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [notificationServiceProvider.overrideWithValue(service)],
          child: sprint9cTestApp(
            textScale: 2,
            child: const Scaffold(body: Stack(children: [NotificationToast()])),
          ),
        ),
      );
      service.showNotification(
        AppNotification(
          id: 'invite-safe-test-key',
          title: 'Game invitation',
          message: 'A friend invited you to play.',
          type: NotificationType.info,
          duration: const Duration(minutes: 1),
          actions: [
            NotificationAction(label: 'Not now', onPressed: () => dismissed++),
            NotificationAction(label: 'Open', onPressed: () => opened++),
          ],
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      expect(find.text('Game invitation'), findsOneWidget);
      expect(find.text('A friend invited you to play.'), findsOneWidget);
      expect(find.byTooltip('Close'), findsOneWidget);
      expectNoFlutterException(tester);
      expect(tester, meetsGuideline(androidTapTargetGuideline));
      expect(tester, meetsGuideline(labeledTapTargetGuideline));

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(opened, 1);
      expect(dismissed, 0);
      expect(find.text('Game invitation'), findsNothing);
    },
  );

  test('duplicate notification IDs replace instead of stacking', () {
    final service = NotificationService();
    addTearDown(service.dispose);
    service.showNotification(
      AppNotification(id: 'same', title: 'First', type: NotificationType.info),
    );
    service.showNotification(
      AppNotification(id: 'same', title: 'Second', type: NotificationType.info),
    );
    expect(service.currentNotifications, hasLength(1));
    expect(service.currentNotifications.single.title, 'Second');
  });
}
