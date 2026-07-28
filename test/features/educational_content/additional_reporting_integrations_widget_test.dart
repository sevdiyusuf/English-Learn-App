import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:yunoo/core/content/educational_content_id_resolver.dart';
import 'package:yunoo/features/educational_content/content_report_service.dart';
import 'package:yunoo/features/grammar/logic/grammar_providers.dart';
import 'package:yunoo/features/grammar/models/grammar_models.dart';
import 'package:yunoo/features/grammar/ui/pages/lesson_viewer_page.dart';
import 'package:yunoo/features/grammar/ui/pages/story_viewer_page.dart';
import 'package:yunoo/features/training/logic/training_session_controller.dart';
import 'package:yunoo/features/training/models/training_models.dart';
import 'package:yunoo/features/training/models/training_state.dart';
import 'package:yunoo/features/training/ui/worksheet_page.dart';
import 'package:yunoo/l10n/app_localizations.dart';

// ── Mock Service ──────────────────────────────────────────────────────────────

class FakeContentReportService implements ContentReportService {
  ContentReportResult resultToReturn = ContentReportResult.success;
  int submitCallCount = 0;
  String? lastContentId;
  String? lastContentType;

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
    lastContentType = contentType;
    return resultToReturn;
  }
}

class FakeTrainingSessionController extends StateNotifier<TrainingSessionState>
    with Fake
    implements TrainingSessionController {
  FakeTrainingSessionController(super.state);

  @override
  Future<void> loadWorksheet(String path) async {}
}

void main() {
  group('Additional Educational Content Reporting Integrations', () {
    late FakeContentReportService fakeService;

    setUp(() {
      fakeService = FakeContentReportService();
    });

    testWidgets(
      'WorksheetPage displays report icon and opens dialog for exercise item',
      (tester) async {
        tester.view.physicalSize = const Size(800, 800);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);

        final dummyItem = WorksheetItem(
          id: 'adv_mcq1',
          engine: EngineType.mcq,
          prompt: 'Choose the correct adverb.',
          answer: 0,
          bank: const [],
          options: const ['quickly', 'quick'],
          steps: const [],
          raw: const {},
        );

        final dummyWorksheet = Worksheet(
          schemaVersion: '1.0',
          level: 'A1',
          worksheetId: 'A1-ADV-01',
          title: 'Adverbs Worksheet',
          topicTags: const ['adverbs'],
          subskills: const [],
          difficulty: 1,
          items: [dummyItem],
        );

        final initialSessionState = TrainingSessionState(
          worksheet: dummyWorksheet,
          currentIndex: 0,
          isLoading: false,
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              educationalContentRegistryProvider.overrideWith(
                (ref) async => {
                  const EducationalItemKey(
                        'assets/worksheets/A1/A1-ADV-01.json',
                        'id:adv_mcq1',
                      ):
                      'edu.item.006139',
                },
              ),
              contentReportServiceProvider.overrideWithValue(fakeService),
              trainingSessionProvider.overrideWith(
                (ref) => FakeTrainingSessionController(initialSessionState),
              ),
            ],
            child: const MaterialApp(
              localizationsDelegates: [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: AppLocalizations.supportedLocales,
              home: WorksheetPage(path: 'A1/A1-ADV-01.json'),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final reportBtn = find.byKey(
          const ValueKey('report_worksheet_adv_mcq1'),
        );
        expect(reportBtn, findsOneWidget);

        await tester.tap(reportBtn);
        await tester.pumpAndSettle();

        expect(find.text('Report Content Issue'), findsOneWidget);
        expect(find.text('Incorrect answer key'), findsOneWidget);
      },
    );

    testWidgets(
      'LessonViewerPage displays report icon and opens dialog for lesson card',
      (tester) async {
        tester.view.physicalSize = const Size(800, 800);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);

        final dummyCard = LessonCard(
          id: 'c1',
          type: LessonCardType.rule,
          title: 'Adverbs Explanation',
        );

        final dummyLesson = LessonDoc(
          schemaVersion: '1.0',
          level: 'A1',
          lessonId: 'A1-ADV-01-lesson',
          title: 'Adverbs Lesson',
          topicTags: const ['adverbs'],
          microLesson: MicroLesson(cards: [dummyCard]),
          storyMode: StoryMode(
            enabled: false,
            title: 'Story',
            introBullets: const [],
            items: const [],
            recapBullets: const [],
          ),
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              educationalContentRegistryProvider.overrideWith(
                (ref) async => {
                  const EducationalItemKey(
                        'assets/lessons/A1/A1-ADV-01-lesson.json',
                        'id:c1',
                      ):
                      'edu.item.000182',
                },
              ),
              contentReportServiceProvider.overrideWithValue(fakeService),
              lessonIndexProvider.overrideWith(
                (ref) async => LessonIndex(
                  levels: ['A1'],
                  lessonsByLevel: {
                    'A1': [
                      LessonEntry(
                        lessonId: 'A1-ADV-01-lesson',
                        title: 'Adverbs Lesson',
                        path: 'A1/A1-ADV-01-lesson.json',
                        topicTags: ['adverbs'],
                      ),
                    ],
                  },
                ),
              ),
              lessonDocProvider(
                'A1-ADV-01-lesson',
              ).overrideWith((ref) async => dummyLesson),
              currentCardIndexProvider(
                'A1-ADV-01-lesson',
              ).overrideWith((ref) => 0),
            ],
            child: const MaterialApp(
              localizationsDelegates: [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: AppLocalizations.supportedLocales,
              home: LessonViewerPage(lessonId: 'A1-ADV-01-lesson'),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final reportBtn = find.byKey(const ValueKey('report_lesson_card_c1'));
        expect(reportBtn, findsOneWidget);

        await tester.tap(reportBtn);
        await tester.pumpAndSettle();

        expect(find.text('Report Content Issue'), findsOneWidget);
        expect(find.text('Unclear or confusing explanation'), findsOneWidget);
      },
    );

    testWidgets(
      'StoryViewerPage displays report icon and opens dialog for story exercise item',
      (tester) async {
        tester.view.physicalSize = const Size(800, 800);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);

        final dummyItem = WorksheetItem(
          id: 's1',
          engine: EngineType.fill,
          prompt: 'Tom is healthy. He ____ eats fast food.',
          answer: 'never',
          bank: const [],
          options: const [],
          steps: const [],
          raw: const {},
        );

        final dummyLesson = LessonDoc(
          schemaVersion: '1.0',
          level: 'A1',
          lessonId: 'A1-ADV-01-lesson',
          title: 'Adverbs Lesson',
          topicTags: const ['adverbs'],
          microLesson: MicroLesson(cards: const []),
          storyMode: StoryMode(
            enabled: true,
            title: 'Tom\'s Healthy Day',
            introBullets: const ['Follow Tom\'s routine'],
            items: [dummyItem],
            recapBullets: const ['Tom lives healthily.'],
          ),
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              educationalContentRegistryProvider.overrideWith(
                (ref) async => {
                  const EducationalItemKey(
                        'assets/lessons/A1/A1-ADV-01-lesson.json',
                        'prompt:Tom is healthy. He ____ eats fast food.',
                      ):
                      'edu.item.000187',
                },
              ),
              contentReportServiceProvider.overrideWithValue(fakeService),
              lessonIndexProvider.overrideWith(
                (ref) async => LessonIndex(
                  levels: ['A1'],
                  lessonsByLevel: {
                    'A1': [
                      LessonEntry(
                        lessonId: 'A1-ADV-01-lesson',
                        title: 'Adverbs Lesson',
                        path: 'A1/A1-ADV-01-lesson.json',
                        topicTags: ['adverbs'],
                      ),
                    ],
                  },
                ),
              ),
              lessonDocProvider(
                'A1-ADV-01-lesson',
              ).overrideWith((ref) async => dummyLesson),
            ],
            child: const MaterialApp(
              localizationsDelegates: [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: AppLocalizations.supportedLocales,
              home: StoryViewerPage(lessonId: 'A1-ADV-01-lesson'),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final reportBtn = find.byKey(const ValueKey('report_story_item_0'));
        expect(reportBtn, findsOneWidget);

        await tester.tap(reportBtn);
        await tester.pumpAndSettle();

        expect(find.text('Report Content Issue'), findsOneWidget);
        expect(find.text('Incorrect answer key'), findsOneWidget);
      },
    );
  });
}
