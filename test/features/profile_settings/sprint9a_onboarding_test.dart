import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yunoo/features/profile_settings/models/user_settings.dart';
import 'package:yunoo/features/profile_settings/ui/onboarding_gate.dart';
import 'package:yunoo/l10n/app_localizations.dart';

Widget _localizedApp(Widget child) => ProviderScope(
  child: MaterialApp(
    locale: const Locale('en'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: child,
  ),
);

void main() {
  group('onboarding gate and resume', () {
    test('fresh and older versions require onboarding; current skips it', () {
      expect(requiresCurrentOnboarding(const UserSettings()), isTrue);
      expect(
        requiresCurrentOnboarding(
          const UserSettings(onboardingCompletedVersion: 0),
        ),
        isTrue,
      );
      expect(
        requiresCurrentOnboarding(
          const UserSettings(
            onboardingCompletedVersion:
                LearningProfileValues.currentOnboardingVersion,
          ),
        ),
        isFalse,
      );
    });

    testWidgets(
      'valid partial progress resumes and invalid review falls back',
      (tester) async {
        await tester.pumpWidget(
          _localizedApp(
            OnboardingPage(
              initialSettings: const UserSettings(
                onboardingStep: LearningProfileValues.onboardingGoal,
                cefrLevel: 'B1',
              ),
              updateLearningProfile: _successfulUpdate,
            ),
          ),
        );
        expect(find.text('Choose a learning goal'), findsOneWidget);

        await tester.pumpWidget(
          _localizedApp(
            OnboardingPage(
              key: const ValueKey('invalid-review'),
              initialSettings: const UserSettings(
                onboardingStep: LearningProfileValues.onboardingReview,
              ),
              updateLearningProfile: _successfulUpdate,
            ),
          ),
        );
        await tester.pump();
        expect(find.text('Choose your level'), findsOneWidget);
      },
    );
  });

  testWidgets(
    'intro to review persists each stage, validates, and completes before home',
    (tester) async {
      final writes = <UserSettings>[];
      var homeVisible = false;

      Future<void> update({
        required String? cefrLevel,
        required String? learningGoal,
        required String onboardingStep,
        required int onboardingCompletedVersion,
      }) async {
        expect(homeVisible, isFalse);
        writes.add(
          UserSettings(
            cefrLevel: cefrLevel,
            learningGoal: learningGoal,
            onboardingStep: onboardingStep,
            onboardingCompletedVersion: onboardingCompletedVersion,
          ),
        );
        if (onboardingCompletedVersion ==
            LearningProfileValues.currentOnboardingVersion) {
          homeVisible = true;
        }
      }

      await tester.pumpWidget(
        _localizedApp(
          OnboardingPage(
            initialSettings: const UserSettings(),
            updateLearningProfile: update,
          ),
        ),
      );
      expect(find.text('Welcome'), findsOneWidget);

      await tester.tap(find.text('Continue'));
      await tester.pump();
      expect(writes.last.onboardingStep, LearningProfileValues.onboardingLevel);
      expect(find.text('Choose your level'), findsOneWidget);

      await tester.tap(find.text('Continue'));
      await tester.pump();
      expect(find.text('Choose an option to continue.'), findsOneWidget);

      await tester.tap(find.text('A1 — Beginner'));
      await tester.tap(find.text('Continue'));
      await tester.pump();
      expect(writes.last.cefrLevel, 'A1');
      expect(writes.last.onboardingStep, LearningProfileValues.onboardingGoal);

      await tester.tap(find.text('Build vocabulary'));
      await tester.tap(find.text('Continue'));
      await tester.pump();
      expect(writes.last.learningGoal, 'word_practice');
      expect(
        writes.last.onboardingStep,
        LearningProfileValues.onboardingReview,
      );

      await tester.binding.handlePopRoute();
      await tester.pump();
      expect(find.text('Choose a learning goal'), findsOneWidget);
      expect(find.text('Build vocabulary'), findsOneWidget);

      await tester.tap(find.text('Continue'));
      await tester.pump();
      await tester.tap(find.text('Start learning'));
      await tester.pump();

      expect(writes, hasLength(5));
      expect(
        writes.last.onboardingCompletedVersion,
        LearningProfileValues.currentOnboardingVersion,
      );
      expect(homeVisible, isTrue);
    },
  );

  testWidgets('save failure preserves selection and retry succeeds', (
    tester,
  ) async {
    var attempts = 0;
    final successfulWrites = <String>[];

    await tester.pumpWidget(
      _localizedApp(
        OnboardingPage(
          initialSettings: const UserSettings(
            onboardingStep: LearningProfileValues.onboardingLevel,
          ),
          updateLearningProfile: ({
            required String? cefrLevel,
            required String? learningGoal,
            required String onboardingStep,
            required int onboardingCompletedVersion,
          }) async {
            attempts++;
            if (attempts == 1) throw StateError('write failed');
            successfulWrites.add(cefrLevel!);
          },
        ),
      ),
    );

    await tester.tap(find.text('B2 — Upper intermediate'));
    await tester.tap(find.text('Continue'));
    await tester.pump();
    expect(
      find.text('We could not save your choices. Please try again.'),
      findsOneWidget,
    );
    expect(find.text('B2 — Upper intermediate'), findsOneWidget);

    await tester.tap(find.text('Continue'));
    await tester.pump();
    expect(successfulWrites, ['B2']);
    expect(find.text('Choose a learning goal'), findsOneWidget);
  });

  testWidgets('first-stage back is safe and disposed page never advances', (
    tester,
  ) async {
    final pending = Completer<void>();
    await tester.pumpWidget(
      _localizedApp(
        OnboardingPage(
          initialSettings: const UserSettings(),
          updateLearningProfile:
              ({
                required String? cefrLevel,
                required String? learningGoal,
                required String onboardingStep,
                required int onboardingCompletedVersion,
              }) => pending.future,
        ),
      ),
    );

    await tester.binding.handlePopRoute();
    await tester.pump();
    expect(find.text('Welcome'), findsOneWidget);

    await tester.tap(find.text('Continue'));
    await tester.pump();
    await tester.pumpWidget(_localizedApp(const SizedBox()));
    pending.complete();
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.text('Choose your level'), findsNothing);
  });
}

Future<void> _successfulUpdate({
  required String? cefrLevel,
  required String? learningGoal,
  required String onboardingStep,
  required int onboardingCompletedVersion,
}) async {}
