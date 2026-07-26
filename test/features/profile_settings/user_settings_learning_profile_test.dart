import 'package:flutter_test/flutter_test.dart';
import 'package:yunoo/core/repositories/user_settings_repo.dart';
import 'package:yunoo/features/profile_settings/logic/user_settings_controller.dart';
import 'package:yunoo/features/profile_settings/models/user_settings.dart';

void main() {
  group('UserSettings learning profile compatibility', () {
    test('old JSON uses incomplete onboarding defaults', () {
      final settings = UserSettings.fromJson(<String, dynamic>{});

      expect(settings.onboardingCompletedVersion, 0);
      expect(settings.onboardingStep, LearningProfileValues.onboardingIntro);
      expect(settings.cefrLevel, isNull);
      expect(settings.learningGoal, isNull);
    });

    test('stable learning profile values round-trip through JSON', () {
      const settings = UserSettings(
        onboardingCompletedVersion:
            LearningProfileValues.currentOnboardingVersion,
        onboardingStep: LearningProfileValues.onboardingReview,
        cefrLevel: 'B1',
        learningGoal: 'grammar_practice',
      );

      final restored = UserSettings.fromJson(settings.toJson());
      expect(restored, settings);
    });

    test('stable identifier inventories contain only supported values', () {
      expect(
        LearningProfileValues.cefrLevels,
        containsAll(<String>['A1', 'A2', 'B1', 'B2', 'C1', 'C2']),
      );
      expect(
        LearningProfileValues.learningGoals,
        containsAll(<String>[
          'word_practice',
          'grammar_practice',
          'mini_games',
          'multiplayer',
        ]),
      );
    });

    test('invalid values and negative versions normalize safely', () {
      final normalized = UserSettingsRepo.normalizeLearningProfile(
        const UserSettings(
          onboardingCompletedVersion: -1,
          onboardingStep: 'unknown',
          cefrLevel: 'Z9',
          learningGoal: 'unsupported',
        ),
      );

      expect(normalized.onboardingCompletedVersion, 0);
      expect(normalized.onboardingStep, LearningProfileValues.onboardingIntro);
      expect(normalized.cefrLevel, isNull);
      expect(normalized.learningGoal, isNull);
    });

    test(
      'learning profile update preserves unrelated settings and progress',
      () {
        const current = UserSettings(
          themeMode: 'light',
          languageCode: 'en',
          soundEnabled: false,
          onboardingCompletedVersion: 3,
          onboardingStep: LearningProfileValues.onboardingReview,
          cefrLevel: 'A1',
          learningGoal: 'word_practice',
        );

        final updated = UserSettingsController.learningProfileUpdate(
          current,
          cefrLevel: 'C1',
          learningGoal: 'multiplayer',
          onboardingStep: current.onboardingStep,
          onboardingCompletedVersion: current.onboardingCompletedVersion,
        );

        expect(updated.cefrLevel, 'C1');
        expect(updated.learningGoal, 'multiplayer');
        expect(updated.onboardingCompletedVersion, 3);
        expect(updated.onboardingStep, LearningProfileValues.onboardingReview);
        expect(updated.themeMode, 'light');
        expect(updated.languageCode, 'en');
        expect(updated.soundEnabled, isFalse);
      },
    );
  });
}
