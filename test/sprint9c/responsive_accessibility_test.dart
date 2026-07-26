import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yunoo/core/widgets/error_view.dart';
import 'package:yunoo/core/widgets/responsive_content.dart';
import 'package:yunoo/features/auth/ui/email_auth_dialog.dart';
import 'package:yunoo/features/game/models/room.dart';
import 'package:yunoo/features/game/ui/components/player_badges.dart';
import 'package:yunoo/features/mode_select/ui/mode_select_page.dart';
import 'package:yunoo/features/multiplayer/ui/multiplayer_home_page.dart';
import 'package:yunoo/features/profile_settings/models/user_settings.dart';
import 'package:yunoo/features/profile_settings/ui/onboarding_gate.dart';

import '../support/sprint9c_test_harness.dart';

void main() {
  group('responsive content', () {
    for (final width in [320.0, 360.0, 600.0, 900.0]) {
      testWidgets('uses readable constraints without overflow at $width px', (
        tester,
      ) async {
        await configureTestView(
          tester,
          logicalSize: Size(width, width == 320 ? 480 : 700),
          padding: const EdgeInsets.only(top: 18, bottom: 20),
        );
        await tester.pumpWidget(
          sprint9cTestApp(
            textScale: width == 320 ? 2 : 1.3,
            child: const Scaffold(
              body: SafeArea(
                child: ResponsiveContent(
                  maxWidth: 640,
                  child: ColoredBox(
                    key: ValueKey('content'),
                    color: Colors.blue,
                  ),
                ),
              ),
            ),
          ),
        );

        expect(
          tester.getSize(find.byKey(const ValueKey('content'))).width,
          lessThanOrEqualTo(640),
        );
        expectNoFlutterException(tester);
      });
    }
  });

  testWidgets(
    'onboarding remains operable at 320px, short height, Turkish and 2x text',
    (tester) async {
      await configureTestView(
        tester,
        logicalSize: const Size(320, 430),
        padding: const EdgeInsets.only(top: 20, bottom: 20),
      );
      await tester.pumpWidget(
        ProviderScope(
          child: sprint9cTestApp(
            locale: const Locale('tr'),
            textScale: 2,
            child: OnboardingPage(
              initialSettings: const UserSettings(),
              updateLearningProfile:
                  ({
                    required cefrLevel,
                    required learningGoal,
                    required onboardingStep,
                    required onboardingCompletedVersion,
                  }) async {},
            ),
          ),
        ),
      );

      expect(find.text('Hoş geldiniz'), findsOneWidget);
      expect(find.text('Devam et'), findsOneWidget);
      await tester.tap(find.text('Devam et'));
      await tester.pump();
      expect(find.text('Seviyenizi seçin'), findsOneWidget);
      expect(find.byTooltip('Geri'), findsOneWidget);
      expectNoFlutterException(tester);
      expect(tester, meetsGuideline(androidTapTargetGuideline));
      expect(tester, meetsGuideline(labeledTapTargetGuideline));
    },
  );

  testWidgets(
    'email dialog keeps fields and actions reachable above keyboard',
    (tester) async {
      await configureTestView(
        tester,
        logicalSize: const Size(320, 520),
        viewInsets: const EdgeInsets.only(bottom: 220),
      );
      await tester.pumpWidget(
        ProviderScope(
          child: sprint9cTestApp(
            textScale: 1.3,
            child: const Scaffold(body: EmailAuthDialog()),
          ),
        ),
      );

      expect(find.text('Email address'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Sign in'), findsWidgets);
      expect(find.byTooltip('Show password'), findsOneWidget);
      expectNoFlutterException(tester);
      expect(tester, meetsGuideline(androidTapTargetGuideline));
      expect(tester, meetsGuideline(labeledTapTargetGuideline));
    },
  );

  testWidgets('multiplayer cards wrap text at compact 2x scale', (
    tester,
  ) async {
    await configureTestView(tester, logicalSize: const Size(320, 520));
    await tester.pumpWidget(
      sprint9cTestApp(textScale: 2, child: const MultiplayerHomePage()),
    );

    await tester.scrollUntilVisible(find.text('Word Battle'), 160);
    expect(find.text('Word Battle'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Grammar Battle'), 160);
    expect(find.text('Grammar Battle'), findsOneWidget);
    await tester.drag(find.byType(ListView), const Offset(0, -400));
    await tester.pump();
    expectNoFlutterException(tester);
  });

  testWidgets('home learning actions retain text and useful semantics', (
    tester,
  ) async {
    await configureTestView(tester, logicalSize: const Size(320, 640));
    await tester.pumpWidget(
      ProviderScope(
        child: sprint9cTestApp(
          textScale: 2,
          child: Scaffold(
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  LearningStartCard(
                    accentColor: Colors.blue,
                    settingsOverride: const UserSettings(
                      cefrLevel: 'B2',
                      learningGoal: 'grammar_practice',
                    ),
                    onStart: (_) {},
                  ),
                  const SizedBox(height: 16),
                  LearningModesGrid(
                    accentColor: Colors.blue,
                    onNavigate: (_) {},
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.bySemanticsLabel('Start learning'), findsOneWidget);
    expect(find.text('Start learning'), findsWidgets);
    expect(find.text('Grammar'), findsOneWidget);
    expect(find.text('Mini Games'), findsOneWidget);
    expect(find.text('Grammar Arena'), findsOneWidget);
    expectNoFlutterException(tester);
    expect(tester, meetsGuideline(androidTapTargetGuideline));
    expect(tester, meetsGuideline(labeledTapTargetGuideline));
  });

  testWidgets('multiplayer score and turn state are announced with context', (
    tester,
  ) async {
    await configureTestView(tester, logicalSize: const Size(320, 480));
    final room = Room(
      hostUid: 'host-id',
      createdAt: DateTime(2026),
      status: RoomStatus.active,
      players: const ['host-id', 'guest-id'],
      playerNames: const {'host-id': 'Ada', 'guest-id': 'Mert'},
      activePlayerIds: const ['host-id', 'guest-id'],
      currentTurnUid: 'guest-id',
    );
    await tester.pumpWidget(
      sprint9cTestApp(
        locale: const Locale('tr'),
        textScale: 2,
        child: Scaffold(
          body: PlayerBadges(
            room: room,
            currentUid: 'host-id',
            scores: const {'host-id': 12, 'guest-id': 8},
          ),
        ),
      ),
    );

    expect(find.bySemanticsLabel(RegExp(r'Ada, skor 12')), findsOneWidget);
    expect(
      find.bySemanticsLabel(RegExp(r'Mert, skor 8.*Sıra bu oyuncuda')),
      findsOneWidget,
    );
    expectNoFlutterException(tester);
  });

  testWidgets('loading and error states expose useful live semantics', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      sprint9cTestApp(child: const Scaffold(body: ErrorView.loading())),
    );
    expect(find.text('Loading…'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) => widget is Semantics && widget.properties.liveRegion == true,
      ),
      findsOneWidget,
    );

    await tester.pumpWidget(
      sprint9cTestApp(child: const Scaffold(body: ErrorView())),
    );
    expect(find.text('Something went wrong'), findsOneWidget);
    expectNoFlutterException(tester);
    await expectLater(tester, meetsGuideline(textContrastGuideline));

    await tester.pumpWidget(
      sprint9cTestApp(
        themeMode: ThemeMode.dark,
        child: const Scaffold(body: ErrorView()),
      ),
    );
    await expectLater(tester, meetsGuideline(textContrastGuideline));
    handle.dispose();
  });
}
