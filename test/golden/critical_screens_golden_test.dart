import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yunoo/features/auth/logic/auth_controller.dart';
import 'package:yunoo/features/auth/ui/email_auth_dialog.dart';
import 'package:yunoo/features/educational_content/content_report_dialog.dart';
import 'package:yunoo/features/educational_content/content_report_service.dart';
import 'package:yunoo/features/profile_settings/logic/user_settings_controller.dart';
import 'package:yunoo/features/profile_settings/models/user_settings.dart';
import 'package:yunoo/features/profile_settings/ui/content_licenses_page.dart';
import 'package:yunoo/features/profile_settings/ui/learning_profile_editor.dart';
import 'package:yunoo/features/profile_settings/ui/onboarding_gate.dart';
import 'package:yunoo/l10n/app_localizations.dart';

class FakeContentReportService implements ContentReportService {
  @override
  Future<ContentReportResult> submit({
    required String contentId,
    required int contentVersion,
    required String contentType,
    required ContentReportCategory category,
    String? comment,
  }) async {
    return ContentReportResult.success;
  }
}

class FakeAuthController extends AuthController {
  FakeAuthController(super.ref) {
    state = const AsyncValue.data(null);
  }
}

class FakeUserSettingsNotifier extends UserSettingsController {
  @override
  Future<UserSettings> build() async {
    return const UserSettings(
      onboardingCompletedVersion: 1,
      cefrLevel: 'B1',
      learningGoal: 'grammar_practice',
    );
  }
}

class TestHttpOverrides extends HttpOverrides {}

Widget buildTestApp(Widget child, {List<Override> overrides = const []}) {
  return ProviderScope(
    overrides: [
      authControllerProvider.overrideWith((ref) => FakeAuthController(ref)),
      userSettingsControllerProvider.overrideWith(
        () => FakeUserSettingsNotifier(),
      ),
      ...overrides,
    ],
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(useMaterial3: true),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    ),
  );
}

void main() {
  setUpAll(() {
    HttpOverrides.global = TestHttpOverrides();
  });

  group('Critical Screens Golden Baseline Tests', () {
    testWidgets('Golden 1 - Onboarding Page static baseline', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestApp(const OnboardingPage()));
      await tester.pump();

      await expectLater(
        find.byType(OnboardingPage),
        matchesGoldenFile('goldens/onboarding_page.png'),
      );
    });

    testWidgets('Golden 2 - Content Licenses Page static baseline', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestApp(const ContentLicensesPage()));
      await tester.pump();

      await expectLater(
        find.byType(ContentLicensesPage),
        matchesGoldenFile('goldens/content_licenses_page.png'),
      );
    });

    testWidgets('Golden 3 - Learning Profile Editor static baseline', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        buildTestApp(
          LearningProfileEditorDialog(
            initialSettings: const UserSettings(
              onboardingCompletedVersion: 1,
              cefrLevel: 'B1',
              learningGoal: 'grammar_practice',
            ),
            onSave:
                ({
                  required String cefrLevel,
                  required String learningGoal,
                }) async {},
          ),
        ),
      );
      await tester.pump();

      await expectLater(
        find.byType(LearningProfileEditorDialog),
        matchesGoldenFile('goldens/learning_profile_editor_dialog.png'),
      );
    });

    testWidgets('Golden 4 - Content Report Dialog static baseline', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        buildTestApp(
          Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  showContentReportSheet(
                    context,
                    contentId: 'edu.verb.cut',
                    contentVersion: 1,
                    contentType: 'irregular_verb',
                  );
                },
                child: const Text('Open Report'),
              );
            },
          ),
          overrides: [
            contentReportServiceProvider.overrideWithValue(
              FakeContentReportService(),
            ),
          ],
        ),
      );
      await tester.pump();

      await tester.tap(find.text('Open Report'));
      await tester.pump();

      expect(find.text('Report a content issue'), findsOneWidget);

      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/content_report_dialog.png'),
      );
    });

    testWidgets('Golden 5 - Email Auth Dialog static baseline', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestApp(const EmailAuthDialog()));
      await tester.pump();

      await expectLater(
        find.byType(EmailAuthDialog),
        matchesGoldenFile('goldens/email_auth_dialog.png'),
      );
    });
  });
}
