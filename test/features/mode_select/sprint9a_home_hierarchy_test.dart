import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yunoo/features/mode_select/ui/mode_select_page.dart';
import 'package:yunoo/features/profile_settings/models/user_settings.dart';
import 'package:yunoo/l10n/app_localizations.dart';

Widget _app(Widget child, {Locale locale = const Locale('en')}) =>
    ProviderScope(
      child: MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: child,
          ),
        ),
      ),
    );

void main() {
  test('goal destinations use supported modes and safe word fallback', () {
    expect(learningStartDestination('word_practice'), '/word-match/sets');
    expect(learningStartDestination('grammar_practice'), '/grammar');
    expect(learningStartDestination('mini_games'), '/mini-games');
    expect(learningStartDestination('multiplayer'), '/multiplayer');
    expect(learningStartDestination(null), '/word-match/sets');
    expect(learningStartDestination('invalid'), '/word-match/sets');
  });

  testWidgets(
    'one truthful primary action renders localized profile and routes by goal',
    (tester) async {
      String? destination;
      await tester.pumpWidget(
        _app(
          LearningStartCard(
            accentColor: Colors.blue,
            settingsOverride: const UserSettings(
              cefrLevel: 'B2',
              learningGoal: 'grammar_practice',
            ),
            onStart: (value) => destination = value,
          ),
        ),
      );

      expect(find.bySemanticsLabel('Start learning'), findsOneWidget);
      expect(find.text('Continue learning'), findsNothing);
      expect(find.textContaining('B2 — Upper intermediate'), findsOneWidget);
      expect(find.text('Practice grammar'), findsWidgets);

      await tester.tap(find.bySemanticsLabel('Start learning'));
      expect(destination, '/grammar');
    },
  );

  testWidgets('missing goal keeps start action usable with safe default', (
    tester,
  ) async {
    String? destination;
    await tester.pumpWidget(
      _app(
        LearningStartCard(
          accentColor: Colors.blue,
          settingsOverride: const UserSettings(),
          onStart: (value) => destination = value,
        ),
      ),
    );

    await tester.tap(find.bySemanticsLabel('Start learning'));
    expect(destination, '/word-match/sets');
    expect(find.text('Continue learning'), findsNothing);
  });

  testWidgets('principal learning modes remain visible and reachable', (
    tester,
  ) async {
    final destinations = <String>[];
    await tester.pumpWidget(
      _app(
        LearningModesGrid(
          accentColor: Colors.blue,
          onNavigate: destinations.add,
        ),
      ),
    );

    expect(find.text('Grammar'), findsOneWidget);
    expect(find.text('Mini Games'), findsOneWidget);
    expect(find.text('Grammar Arena'), findsOneWidget);

    await tester.tap(find.text('Grammar'));
    await tester.tap(find.text('Mini Games'));
    await tester.tap(find.text('Grammar Arena'));
    expect(destinations, ['/grammar', '/mini-games', '/multiplayer']);
  });

  testWidgets('stable identifiers render through Turkish localization', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        LearningStartCard(
          accentColor: Colors.blue,
          settingsOverride: const UserSettings(
            cefrLevel: 'A1',
            learningGoal: 'word_practice',
          ),
          onStart: (_) {},
        ),
        locale: const Locale('tr'),
      ),
    );

    expect(find.textContaining('A1'), findsOneWidget);
    expect(find.text('Kelime dağarcığı geliştir'), findsWidgets);
  });
}
