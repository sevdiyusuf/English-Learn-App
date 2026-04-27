
import 'package:go_router/go_router.dart';
import '../../features/training/ui/training_home_page.dart';
import '../../features/training/ui/worksheet_page.dart';
import '../../features/training/ui/result_page.dart';

List<RouteBase> get trainingRoutes => [
      GoRoute(
        path: '/training',
        name: TrainingHomePage.routeName,
        builder: (context, state) => const TrainingHomePage(),
        routes: [
          GoRoute(
            path: 'worksheet',
            name: WorksheetPage.routeName,
            builder: (context, state) {
              final path = state.uri.queryParameters['path'] ?? '';
              return WorksheetPage(path: path);
            },
          ),
          GoRoute(
            path: 'result',
            name: ResultPage.routeName,
            builder: (context, state) {
              final correct = int.tryParse(state.uri.queryParameters['correct'] ?? '0') ?? 0;
              final total = int.tryParse(state.uri.queryParameters['total'] ?? '0') ?? 0;
              final id = state.uri.queryParameters['id'] ?? '';
              return ResultPage(correct: correct, total: total, worksheetId: id);
            },
          ),
        ],
      ),
    ];
