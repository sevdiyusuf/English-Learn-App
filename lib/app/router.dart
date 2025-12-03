import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'routes/cargo_categories_routes.dart';
import 'routes/flash_opposites_routes.dart';
import 'routes/flash_synonym_routes.dart';
import 'routes/game_routes.dart';
import 'routes/lobby_routes.dart';
import 'routes/word_echo_routes.dart';
import 'routes/word_match_routes.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

/// Main app router provider with code splitting support
/// Routes are organized in separate files for better code splitting
final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/mode-select',
    routes: [
      ...wordMatchRoutes,
      ...lobbyRoutes,
      ...gameRoutes,
      ...flashOppositesRoutes,
      ...flashSynonymRoutes,
      ...cargoCategoriesRoutes,
      ...wordEchoRoutes,
    ],
    // Enable error handling
    errorBuilder: (context, state) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Sayfa bulunamadı'),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => context.go('/'),
                child: const Text('Ana sayfaya dön'),
              ),
            ],
          ),
        ),
      );
    },
  );
});
