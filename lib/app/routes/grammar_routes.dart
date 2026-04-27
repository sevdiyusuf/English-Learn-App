import 'package:go_router/go_router.dart';
import '../../features/grammar/ui/pages/grammar_home_page.dart';
import '../../features/grammar/ui/pages/lesson_viewer_page.dart';
import '../../features/grammar/ui/pages/story_viewer_page.dart';

final List<RouteBase> grammarRoutes = [
  GoRoute(
    path: '/grammar',
    name: GrammarHomePage.routeName,
    builder: (context, state) => const GrammarHomePage(),
    routes: [
      GoRoute(
        path: 'learn/:lessonId',
        builder: (context, state) {
          final lessonId = state.pathParameters['lessonId']!;
          return LessonViewerPage(lessonId: lessonId);
        },
        routes: [
          GoRoute(
            path: 'story',
            builder: (context, state) {
              final lessonId = state.pathParameters['lessonId']!;
              return StoryViewerPage(lessonId: lessonId);
            },
          ),
        ],
      ),
    ],
  ),
];
