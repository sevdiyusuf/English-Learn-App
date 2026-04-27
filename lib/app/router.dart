// ignore: avoid_web_libraries_in_flutter
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/home/ui/main_shell.dart';
import '../features/mode_select/ui/mode_select_page.dart';
import '../features/friends/ui/friends_page.dart';
import '../features/user_stats/ui/user_stats_page.dart';
import '../features/profile_settings/ui/profile_settings_page.dart';
import '../core/utils/storage_service.dart';
import '../features/word_match/ui/shared_word_set_page.dart';
import 'routes/word_match_routes.dart';
import 'routes/cargo_categories_routes.dart';
import 'routes/flash_opposites_routes.dart';
import 'routes/flash_synonym_routes.dart';
import 'routes/game_routes.dart';
import 'routes/lobby_routes.dart';
import 'routes/profile_routes.dart';
import 'routes/stats_routes.dart';
import 'routes/word_echo_routes.dart';
import 'routes/training_routes.dart';
import 'routes/arena_routes.dart';
import 'routes/grammar_routes.dart';
import 'routes/irregular_verbs_routes.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorHomeKey = GlobalKey<NavigatorState>(
  debugLabel: 'shellHome',
);
final _shellNavigatorSocialKey = GlobalKey<NavigatorState>(
  debugLabel: 'shellSocial',
);
final _shellNavigatorStatsKey = GlobalKey<NavigatorState>(
  debugLabel: 'shellStats',
);
final _shellNavigatorProfileKey = GlobalKey<NavigatorState>(
  debugLabel: 'shellProfile',
);

final appRouterProvider = Provider<GoRouter>((ref) {
  String startLocation = '/';

  if (kIsWeb) {
    // 1. JavaScript tarafında kaydettiğimiz 'appStartUrl' değişkenini okuyoruz.
    // Bu değişken index.html içinde tanımlandı.
    final String? jsSavedHash = StorageService.getAppStartUrl();

    if (jsSavedHash != null && jsSavedHash.isNotEmpty) {
      // Hash işaretini temizle: "#/s/123" -> "/s/123"
      startLocation = jsSavedHash.replaceFirst('#', '');
      if (kDebugMode) {
        print('Dart: JS den gelen link bulundu: $startLocation');
      }
    }
  }

  return GoRouter(
    navigatorKey: _rootNavigatorKey,

    // 2. Router'a "Buradan başla" diyoruz.
    initialLocation: startLocation.contains('/s/') ? startLocation : '/',

    debugLogDiagnostics: true,

    redirect: (context, state) {
      // Paylaşım linkindeysek karışma
      if (state.uri.toString().contains('/s/')) return null;
      return null;
    },

    routes: [
      GoRoute(
        path: '/s/:shareId',
        name: 'publicShareShortcut',
        builder: (context, state) {
          final shareId = state.pathParameters['shareId'] ?? '';
          return SharedWordSetPage(shareId: shareId);
        },
      ),

      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            navigatorKey: _shellNavigatorHomeKey,
            routes: [
              GoRoute(
                path: '/',
                name: ModeSelectPage.routeName,
                builder: (context, state) => const ModeSelectPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _shellNavigatorSocialKey,
            routes: [
              GoRoute(
                path: '/friends',
                name: FriendsPage.routeName,
                builder: (context, state) => const FriendsPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _shellNavigatorStatsKey,
            routes: [
              GoRoute(
                path: '/stats',
                name: 'stats',
                builder: (context, state) => const UserStatsPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _shellNavigatorProfileKey,
            routes: [
              GoRoute(
                path: '/profile',
                name: 'profile',
                builder: (context, state) => const ProfileSettingsPage(),
              ),
            ],
          ),
        ],
      ),

      ...wordMatchRoutes.whereType<GoRoute>().where((r) => r.path != '/'),
      ...lobbyRoutes,
      ...gameRoutes,
      ...flashOppositesRoutes,
      ...flashSynonymRoutes,
      ...cargoCategoriesRoutes,
      ...wordEchoRoutes,
      ...trainingRoutes,
      ...grammarRoutes,
      ...arenaRoutes,
      ...irregularVerbsRoutes,
      ...profileRoutes.whereType<GoRoute>().where(
        (r) => r.path != '/profile' && r.path != '/friends',
      ),
      ...statsRoutes.whereType<GoRoute>().where((r) => r.path != '/stats'),
    ],

    errorBuilder:
        (context, state) =>
            Scaffold(body: Center(child: Text('Hata: ${state.error}'))),
  );
});
