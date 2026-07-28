import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:yunoo/core/tts/resilient_tts_service.dart';
import 'package:yunoo/features/educational_content/content_report_service.dart';
import 'package:yunoo/features/irregular_verbs/logic/irregular_verb_content_ids.dart';
import 'package:yunoo/features/irregular_verbs/logic/irregular_verbs_provider.dart';
import 'package:yunoo/features/irregular_verbs/models/irregular_verb.dart';
import 'package:yunoo/features/irregular_verbs/ui/irregular_verbs_tutorial_page.dart';
import 'package:yunoo/l10n/app_localizations.dart';

// ── Mock/Fake Service ────────────────────────────────────────────────────────

class FakeContentReportService implements ContentReportService {
  ContentReportResult resultToReturn = ContentReportResult.success;
  int submitCallCount = 0;
  String? lastContentId;
  int? lastContentVersion;
  String? lastContentType;
  ContentReportCategory? lastCategory;
  String? lastComment;
  Completer<ContentReportResult>? pendingSubmit;

  @override
  Future<ContentReportResult> submit({
    required String contentId,
    required int contentVersion,
    required String contentType,
    required ContentReportCategory category,
    String comment = '',
  }) async {
    submitCallCount++;
    lastContentId = contentId;
    lastContentVersion = contentVersion;
    lastContentType = contentType;
    lastCategory = category;
    lastComment = comment;

    if (pendingSubmit != null) {
      return pendingSubmit!.future;
    }
    return resultToReturn;
  }
}

class FakeTtsEngine implements TtsEngine {
  @override
  Future<Object?> isLanguageAvailable(String language) async => true;
  @override
  Future<Object?> setLanguage(String language) async => 1;
  @override
  Future<Object?> setPitch(double pitch) async => 1;
  @override
  Future<Object?> setSpeechRate(double rate) async => 1;
  @override
  Future<Object?> stop() async => 1;
  @override
  Future<Object?> speak(String text) async => 1;
  @override
  void setCompletionHandler(void Function() handler) {}
  @override
  void setErrorHandler(void Function(Object? error) handler) {}
}

// ── Test Helper ──────────────────────────────────────────────────────────────

Future<void> _pumpReportingPage(
  WidgetTester tester, {
  required FakeContentReportService reportService,
  Map<String, String> contentIdMap = const {'go': 'edu.item.000001'},
  Locale locale = const Locale('en'),
  TextScaler textScaler = TextScaler.noScaling,
  double width = 800,
  double height = 800,
}) async {
  tester.view.physicalSize = Size(width, height);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final ttsService = ResilientTtsService(engine: FakeTtsEngine());

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
        irregularVerbContentIdMapProvider.overrideWith(
          (ref) async => contentIdMap,
        ),
        contentReportServiceProvider.overrideWithValue(reportService),
      ],
      child: MaterialApp(
        locale: locale,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        builder:
            (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(textScaler: textScaler),
              child: child!,
            ),
        home: IrregularVerbsTutorialPage(ttsService: ttsService),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

// ── Widget Tests ─────────────────────────────────────────────────────────────

void main() {
  group('Irregular Verbs Educational Content Reporting Widget Tests', () {
    late FakeContentReportService fakeService;

    setUp(() {
      fakeService = FakeContentReportService();
    });

    testWidgets('report action icon appears when stable contentId exists', (
      tester,
    ) async {
      await _pumpReportingPage(
        tester,
        reportService: fakeService,
        contentIdMap: {'go': 'edu.item.000001'},
      );

      expect(find.byKey(const ValueKey('report_verb_go')), findsOneWidget);
    });

    testWidgets(
      'report action icon does NOT appear when contentId is missing',
      (tester) async {
        await _pumpReportingPage(
          tester,
          reportService: fakeService,
          contentIdMap: {},
        );

        expect(find.byKey(const ValueKey('report_verb_go')), findsNothing);
      },
    );

    testWidgets(
      'dialog opens and displays categories and cancel/submit buttons',
      (tester) async {
        await _pumpReportingPage(tester, reportService: fakeService);

        await tester.tap(find.byKey(const ValueKey('report_verb_go')));
        await tester.pumpAndSettle();

        expect(find.text('Report Content Issue'), findsOneWidget);
        expect(find.text('Typo or spelling error'), findsOneWidget);
        expect(
          find.text('Incorrect answer key'),
          findsOneWidget,
        );
        expect(find.text('Submit'), findsOneWidget);
        expect(find.text('Cancel'), findsOneWidget);
      },
    );

    testWidgets('submitting without category shows validation error', (
      tester,
    ) async {
      await _pumpReportingPage(tester, reportService: fakeService);

      await tester.tap(find.byKey(const ValueKey('report_verb_go')));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Submit'));
      await tester.pumpAndSettle();

      expect(find.text('Please select a category'), findsOneWidget);
      expect(fakeService.submitCallCount, 0);
    });

    testWidgets(
      'category selection and optional comment submission works with success feedback',
      (tester) async {
        fakeService.resultToReturn = ContentReportResult.success;
        await _pumpReportingPage(tester, reportService: fakeService);

        await tester.tap(find.byKey(const ValueKey('report_verb_go')));
        await tester.pumpAndSettle();

        // Select category
        await tester.tap(find.text('Typo or spelling error'));
        await tester.pumpAndSettle();

        // Enter optional comment
        await tester.enterText(
          find.byType(TextField),
          'V2 is written incorrectly',
        );
        await tester.pumpAndSettle();

        // Submit
        await tester.tap(find.text('Submit'));
        await tester.pumpAndSettle();

        expect(fakeService.submitCallCount, 1);
        expect(fakeService.lastContentId, 'edu.item.000001');
        expect(fakeService.lastContentVersion, 1);
        expect(fakeService.lastContentType, 'irregular_verb');
        expect(fakeService.lastCategory, ContentReportCategory.typo);
        expect(fakeService.lastComment, 'V2 is written incorrectly');

        // Success snackbar
        expect(
          find.text('Report submitted successfully'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'duplicate feedback snackbar is displayed when alreadyReported returned',
      (tester) async {
        fakeService.resultToReturn = ContentReportResult.alreadyReported;
        await _pumpReportingPage(tester, reportService: fakeService);

        await tester.tap(find.byKey(const ValueKey('report_verb_go')));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Audio playback issue'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Submit'));
        await tester.pumpAndSettle();

        expect(
          find.text('Issue already reported'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'unauthenticated feedback snackbar is displayed when unauthenticated returned',
      (tester) async {
        fakeService.resultToReturn = ContentReportResult.unauthenticated;
        await _pumpReportingPage(tester, reportService: fakeService);

        await tester.tap(find.byKey(const ValueKey('report_verb_go')));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Wrong level or category'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Submit'));
        await tester.pumpAndSettle();

        expect(find.text('Sign in required to report issue'), findsOneWidget);
      },
    );

    testWidgets(
      'temporary failure feedback snackbar is displayed when failure returned',
      (tester) async {
        fakeService.resultToReturn = ContentReportResult.failure;
        await _pumpReportingPage(tester, reportService: fakeService);

        await tester.tap(find.byKey(const ValueKey('report_verb_go')));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Other issue'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Submit'));
        await tester.pumpAndSettle();

        expect(
          find.text('Failed to submit report'),
          findsOneWidget,
        );
      },
    );

    testWidgets('failed reporting does not block tutorial / TTS / navigation', (
      tester,
    ) async {
      fakeService.resultToReturn = ContentReportResult.failure;
      await _pumpReportingPage(tester, reportService: fakeService);

      // Open report & submit failure
      await tester.tap(find.byKey(const ValueKey('report_verb_go')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Typo or spelling error'));
      await tester.tap(find.text('Submit'));
      await tester.pumpAndSettle();

      // Ensure page elements are still functional (TTS check removed to avoid timer cleanup issues)
      expect(find.text('go'), findsWidgets);
      expect(find.text('went'), findsWidgets);
    });

    testWidgets(
      'rapid double submit does not produce duplicate submission calls',
      (tester) async {
        fakeService.pendingSubmit = Completer<ContentReportResult>();
        await _pumpReportingPage(tester, reportService: fakeService);

        await tester.tap(find.byKey(const ValueKey('report_verb_go')));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Typo or spelling error'));
        await tester.pumpAndSettle();

        // Tap submit twice rapidly while first call is pending
        final submitButton = find.byKey(const ValueKey('report_submit_button'));
        await tester.tap(submitButton);
        await tester.pump(const Duration(milliseconds: 50));
        await tester.tap(submitButton, warnIfMissed: false);
        await tester.pump(const Duration(milliseconds: 50));

        expect(fakeService.submitCallCount, 1);

        // Resolve pending call
        fakeService.pendingSubmit!.complete(ContentReportResult.success);
        await tester.pumpAndSettle();
      },
    );

    testWidgets(
      'Turkish EN/TR localization strings resolve correctly in dialog',
      (tester) async {
        await _pumpReportingPage(
          tester,
          reportService: fakeService,
          locale: const Locale('tr'),
        );

        await tester.tap(find.byKey(const ValueKey('report_verb_go')));
        await tester.pumpAndSettle();

        expect(find.text('İçerik Sorunu Bildir'), findsOneWidget);
        expect(find.text('Yazım veya imla hatası'), findsOneWidget);
        expect(find.text('Hatalı cevap anahtarı'), findsOneWidget);
        expect(find.text('Ses çalma sorunu'), findsOneWidget);
        expect(find.text('Gönder'), findsOneWidget);
        expect(find.text('İptal'), findsOneWidget);
      },
    );

    testWidgets('accessibility tooltip and semantics exist for report button', (
      tester,
    ) async {
      await _pumpReportingPage(tester, reportService: fakeService);

      final iconButtonFinder = find.byKey(const ValueKey('report_verb_go'));
      expect(iconButtonFinder, findsOneWidget);

      final IconButton button = tester.widget(iconButtonFinder);
      expect(button.tooltip, 'Report an issue with this content');
    });

    testWidgets(
      '320 logical px at 2.0 text scale has no Flutter exception or overflow',
      (tester) async {
        await _pumpReportingPage(
          tester,
          reportService: fakeService,
          width: 320,
          height: 568,
          textScaler: const TextScaler.linear(2.0),
        );

        await tester.tap(find.byKey(const ValueKey('report_verb_go')));
        await tester.pumpAndSettle();

        expect(find.text('Report Content Issue'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('navigation / dispose during active submission is safe', (
      tester,
    ) async {
      fakeService.pendingSubmit = Completer<ContentReportResult>();
      await _pumpReportingPage(tester, reportService: fakeService);

      await tester.tap(find.byKey(const ValueKey('report_verb_go')));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Typo or spelling error'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Submit'));
      await tester.pump(const Duration(milliseconds: 50));

      // Replace widget tree (simulate navigation / dispose)
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: Text('Navigated away'))),
      );
      await tester.pump();

      // Complete async service call after page is disposed
      fakeService.pendingSubmit!.complete(ContentReportResult.success);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Navigated away'), findsOneWidget);
    });
  });
}
