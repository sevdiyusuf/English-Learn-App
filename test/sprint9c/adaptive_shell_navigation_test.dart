import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:yunoo/features/home/ui/main_shell.dart';
import 'package:yunoo/l10n/app_localizations.dart';

import '../support/sprint9c_test_harness.dart';

void main() {
  testWidgets(
    'compact and expanded shell share destination without duplicate navigation',
    (tester) async {
      await configureTestView(tester, logicalSize: const Size(320, 640));
      final router = GoRouter(
        routes: [
          StatefulShellRoute.indexedStack(
            builder:
                (context, state, shell) => MainShell(navigationShell: shell),
            branches: [
              _branch('/', 'home-page'),
              _branch('/social-test', 'social-page'),
              _branch('/stats-test', 'stats-page'),
              _branch('/profile-test', 'profile-page'),
            ],
          ),
        ],
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: router,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.text('home-page'), findsOneWidget);

      await tester.tap(find.text('Social'));
      await tester.pumpAndSettle();
      expect(find.text('social-page'), findsOneWidget);

      tester.view.physicalSize = const Size(900, 640);
      await tester.pumpAndSettle();
      expect(find.byType(NavigationRail), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);
      expect(find.text('social-page'), findsOneWidget);
      expect(router.routeInformationProvider.value.uri.path, '/social-test');
      expectNoFlutterException(tester);
      expect(tester, meetsGuideline(androidTapTargetGuideline));
      expect(tester, meetsGuideline(labeledTapTargetGuideline));
    },
  );
}

StatefulShellBranch _branch(String path, String label) {
  return StatefulShellBranch(
    routes: [
      GoRoute(
        path: path,
        builder: (_, __) => Scaffold(body: Center(child: Text(label))),
      ),
    ],
  );
}
