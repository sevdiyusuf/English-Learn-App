import 'package:go_router/go_router.dart';

import '../../features/multiplayer/ui/multiplayer_home_page.dart';
import '../../features/multiplayer/grammar_arena/ui/arena_home_page.dart';
import '../../features/multiplayer/grammar_arena/ui/arena_waiting_page.dart';
import '../../features/multiplayer/grammar_arena/ui/arena_game_page.dart';
import '../../features/multiplayer/grammar_arena/ui/arena_result_page.dart';

List<RouteBase> get arenaRoutes => [
  GoRoute(
    path: '/multiplayer',
    builder: (context, state) => const MultiplayerHomePage(),
    routes: [
      GoRoute(
        path: 'grammar-arena',
        builder: (context, state) => const ArenaHomePage(),
        routes: [
          GoRoute(
            path: 'room/:roomId',
            builder: (context, state) {
              final roomId = state.pathParameters['roomId']!;
              return ArenaWaitingPage(roomId: roomId);
            },
          ),
          GoRoute(
            path: 'game/:roomId',
            builder: (context, state) {
              final roomId = state.pathParameters['roomId']!;
              return ArenaGamePage(roomId: roomId);
            },
          ),
          GoRoute(
            path: 'result/:roomId',
            builder: (context, state) {
              final roomId = state.pathParameters['roomId']!;
              return ArenaResultPage(roomId: roomId);
            },
          ),
        ],
      ),
    ],
  ),
];
