import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yunoo/features/profile_settings/models/user_settings.dart';
import 'package:yunoo/features/profile_settings/ui/learning_profile_editor.dart';
import 'package:yunoo/l10n/app_localizations.dart';

Widget _app(Widget child) => MaterialApp(
  locale: const Locale('en'),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(body: child),
);

void main() {
  testWidgets('saved stable values are selected and new IDs are persisted', (
    tester,
  ) async {
    String? savedLevel;
    String? savedGoal;

    await tester.pumpWidget(
      _app(
        LearningProfileEditorDialog(
          initialSettings: const UserSettings(
            onboardingCompletedVersion: 1,
            onboardingStep: LearningProfileValues.onboardingReview,
            cefrLevel: 'B1',
            learningGoal: 'grammar_practice',
            themeMode: 'dark',
          ),
          onSave: ({
            required String cefrLevel,
            required String learningGoal,
          }) async {
            savedLevel = cefrLevel;
            savedGoal = learningGoal;
          },
        ),
      ),
    );

    expect(find.text('B1 — Intermediate'), findsOneWidget);
    expect(find.text('Practice grammar'), findsOneWidget);

    await tester.tap(find.byType(DropdownButtonFormField<String>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('C1 — Advanced').last);
    await tester.pumpAndSettle();

    await tester.tap(find.byType(DropdownButtonFormField<String>).last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Learn with games').last);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(savedLevel, 'C1');
    expect(savedGoal, 'mini_games');
  });

  testWidgets('failed save keeps pending choices visible and retry succeeds', (
    tester,
  ) async {
    var attempts = 0;
    final saved = <String>[];

    await tester.pumpWidget(
      _app(
        LearningProfileEditorDialog(
          initialSettings: const UserSettings(
            onboardingCompletedVersion: 1,
            onboardingStep: LearningProfileValues.onboardingReview,
            cefrLevel: 'A1',
            learningGoal: 'word_practice',
          ),
          onSave: ({
            required String cefrLevel,
            required String learningGoal,
          }) async {
            attempts++;
            if (attempts == 1) throw StateError('write failed');
            saved.add('$cefrLevel/$learningGoal');
          },
        ),
      ),
    );

    await tester.tap(find.byType(DropdownButtonFormField<String>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('A2 — Elementary').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButtonFormField<String>).last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Play with others').last);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Save'));
    await tester.pump();
    expect(
      find.text('Could not save your changes. Try again.'),
      findsOneWidget,
    );
    expect(find.text('A2 — Elementary'), findsOneWidget);
    expect(find.text('Play with others'), findsOneWidget);

    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(saved, ['A2/multiplayer']);
    expect(find.byType(LearningProfileEditorDialog), findsNothing);
  });

  testWidgets('missing choices are validated without invoking persistence', (
    tester,
  ) async {
    var saveCount = 0;
    await tester.pumpWidget(
      _app(
        LearningProfileEditorDialog(
          initialSettings: const UserSettings(),
          onSave: ({
            required String cefrLevel,
            required String learningGoal,
          }) async {
            saveCount++;
          },
        ),
      ),
    );

    await tester.tap(find.text('Save'));
    await tester.pump();

    expect(find.text('Choose an option to continue.'), findsOneWidget);
    expect(saveCount, 0);
  });
}
