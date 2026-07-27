import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:yunoo/features/profile_settings/ui/content_licenses_page.dart';
import 'package:yunoo/l10n/app_localizations.dart';

import '../support/sprint9c_test_harness.dart';

void main() {
  testWidgets('Settings destination opens and back navigation is safe', (
    tester,
  ) async {
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder:
              (context, state) => Scaffold(
                body: ContentLicensesSettingsTile(
                  onTap: () => context.push('/content-licenses'),
                ),
              ),
        ),
        GoRoute(
          path: '/content-licenses',
          builder: (context, state) => const ContentLicensesPage(),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(_routerApp(router));
    expect(find.text('Content & Licenses'), findsOneWidget);

    await tester.tap(find.byKey(const Key('content-licenses-settings-tile')));
    await tester.pumpAndSettle();
    expect(find.byType(ContentLicensesPage), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('content-licenses-settings-tile')),
      findsOneWidget,
    );
    expectNoFlutterException(tester);
  });

  testWidgets('Flutter software license page is reachable', (tester) async {
    await tester.pumpWidget(
      sprint9cTestApp(child: const ContentLicensesPage()),
    );

    await tester.scrollUntilVisible(
      find.text('Software Licenses'),
      240,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Software Licenses'));
    await tester.pumpAndSettle();

    expect(find.byType(LicensePage), findsOneWidget);
    expect(find.text('Yunoo'), findsWidgets);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byType(ContentLicensesPage), findsOneWidget);
  });

  testWidgets('EN/TR, light/dark and 320px 2x text remain usable', (
    tester,
  ) async {
    await configureTestView(tester, logicalSize: const Size(320, 640));

    for (final locale in const [Locale('en'), Locale('tr')]) {
      for (final theme in ThemeMode.values) {
        await tester.pumpWidget(
          sprint9cTestApp(
            child: const ContentLicensesPage(),
            locale: locale,
            themeMode: theme,
            textScale: 2,
          ),
        );
        await tester.pump();
        expect(find.byType(ContentLicensesPage), findsOneWidget);
        expect(find.byType(Scrollable), findsWidgets);
        expectNoFlutterException(tester);
      }
    }
  });

  testWidgets(
    'attribution links are meaningful and failures are non-blocking',
    (tester) async {
      final opened = <Uri>[];
      await tester.pumpWidget(
        sprint9cTestApp(
          child: ContentLicensesPage(
            openExternalLink: (uri) async {
              opened.add(uri);
              return false;
            },
          ),
        ),
      );

      await tester.scrollUntilVisible(
        find.textContaining('Material Icons by Google'),
        240,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.textContaining('Material Icons by Google'), findsOneWidget);
      await tester.ensureVisible(find.text('Source'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Source'));
      await tester.pump();
      expect(opened.single.host, 'developers.google.com');
      expect(
        find.text('Link unavailable'),
        findsOneWidget,
      );

      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    },
  );
}

Widget _routerApp(GoRouter router) => MaterialApp.router(
  routerConfig: router,
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
);
