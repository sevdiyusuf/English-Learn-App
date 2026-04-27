import 'package:go_router/go_router.dart';

import '../../features/user_stats/ui/user_stats_page.dart';

final statsRoutes = [
  GoRoute(
    path: '/stats',
    name: 'stats',
    builder: (context, state) => const UserStatsPage(),
  ),
];
