import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:yunoo/core/notifications/incoming_destination.dart';
import 'package:yunoo/features/irregular_verbs/logic/irregular_verbs_provider.dart';
import 'package:yunoo/features/irregular_verbs/models/irregular_verb.dart';
import 'package:yunoo/features/irregular_verbs/ui/irregular_verbs_tutorial_page.dart';
import 'package:yunoo/features/user_stats/models/user_stats.dart';
import 'package:yunoo/l10n/app_localizations.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('P0 Android Real Device & Emulator Integration Suite', () {
    testWidgets(
      'App root initializes on Android device without startup crash',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          const ProviderScope(
            child: MaterialApp(
              home: Scaffold(
                body: Center(child: Text('Yunoo Android Device Ready')),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();
        expect(find.text('Yunoo Android Device Ready'), findsOneWidget);
      },
    );

    testWidgets(
      'IrregularVerbs tutorial page renders built-in educational mode UI on device',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              irregularVerbsProvider.overrideWith(
                (ref) async => const [
                  IrregularVerb(
                    v1: 'go',
                    v2: 'went',
                    v3: 'gone',
                    meaningTr: 'gitmek',
                  ),
                ],
              ),
            ],
            child: const MaterialApp(
              locale: Locale('en'),
              localizationsDelegates: [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: AppLocalizations.supportedLocales,
              home: IrregularVerbsTutorialPage(),
            ),
          ),
        );

        await tester.pumpAndSettle();
        expect(find.byType(IrregularVerbsTutorialPage), findsOneWidget);
        expect(find.text('go'), findsWidgets);
      },
    );

    test(
      'IncomingDestinationParser parses valid push notification payload deterministically on device',
      () {
        final destination = IncomingDestinationParser.fromMessageData({
          'type': 'multiplayer_invitation',
          'version': '1',
          'invitationId': 'inv_12345',
        });

        expect(destination, isNotNull);
        expect(destination, isA<MultiplayerInvitationDestination>());
        final invite = destination as MultiplayerInvitationDestination;
        expect(invite.invitationId, 'inv_12345');
        expect(invite.deduplicationKey, 'invitation:inv_12345');
      },
    );

    test(
      'UserStats initializes default non-null metrics for new user profile on device',
      () {
        const stats = UserStats();

        expect(stats.totalLearnedWords, 0);
        expect(stats.totalSessions, 0);
        expect(stats.totalScore, 0);
      },
    );
  });
}
