import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/flash_opposites/ui/flash_opposites_level_select_page.dart';
import '../../features/flash_opposites/ui/flash_opposites_page.dart';
import '../../features/flash_opposites/ui/mini_games_page.dart';

List<RouteBase> get flashOppositesRoutes => [
  GoRoute(
    path: '/mini-games',
    name: MiniGamesPage.routeName,
    pageBuilder:
        (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const MiniGamesPage(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
  ),
  GoRoute(
    path: '/flash-opposites',
    name: FlashOppositesLevelSelectPage.routeName,
    pageBuilder:
        (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const FlashOppositesLevelSelectPage(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
  ),
  GoRoute(
    path: '/flash-opposites/:level',
    name: FlashOppositesPage.routeName,
    pageBuilder: (context, state) {
      final level = state.pathParameters['level'];
      if (level == null ||
          !['easy', 'medium', 'upper', 'expert'].contains(level)) {
        return CustomTransitionPage(
          key: state.pageKey,
          child: const Scaffold(body: Center(child: Text('Geçersiz seviye'))),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        );
      }
      return CustomTransitionPage(
        key: state.pageKey,
        child: FlashOppositesPage(level: level),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      );
    },
  ),
];
