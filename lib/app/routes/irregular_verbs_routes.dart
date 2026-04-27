import 'package:go_router/go_router.dart';
import '../../features/irregular_verbs/ui/irregular_verbs_home_page.dart';
import '../../features/irregular_verbs/ui/irregular_verbs_tutorial_page.dart';
import '../../features/irregular_verbs/ui/irregular_verbs_practice_page.dart';

final irregularVerbsRoutes = [
  GoRoute(
    path: '/irregular-verbs',
    name: 'irregularVerbsHome',
    builder: (context, state) => const IrregularVerbsHomePage(),
    routes: [
      GoRoute(
        path: 'tutorial',
        name: 'irregularVerbsTutorial',
        builder: (context, state) => const IrregularVerbsTutorialPage(),
      ),
      GoRoute(
        path: 'practice',
        name: 'irregularVerbsPractice',
        builder: (context, state) => const IrregularVerbsPracticePage(),
      ),
    ],
  ),
];
