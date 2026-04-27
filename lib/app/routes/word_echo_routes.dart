import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/word_echo/models/word_echo_state.dart';
import '../../features/word_echo/ui/word_echo_grid_page.dart';
import '../../features/word_echo/ui/word_echo_grid_setup_page.dart';
import '../../features/word_echo/ui/word_echo_mode_selection_page.dart';
import '../../features/word_echo/ui/word_echo_page.dart';
import '../../features/word_echo/ui/word_echo_setup_page.dart';

List<RouteBase> get wordEchoRoutes => [
  // Mode selection page
  GoRoute(
    path: '/word-echo',
    name: WordEchoModeSelectionPage.routeName,
    pageBuilder:
        (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const WordEchoModeSelectionPage(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
  ),
  // Classical Word Echo setup
  GoRoute(
    path: '/word-echo/classic',
    name: WordEchoSetupPage.routeName,
    pageBuilder:
        (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const WordEchoSetupPage(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
  ),
  // Classical Word Echo game
  GoRoute(
    path: '/word-echo/classic/game',
    name: WordEchoPage.routeName,
    pageBuilder: (context, state) {
      final extra = state.extra as Map<String, dynamic>?;
      final speed = extra?['speed'] as WordEchoSpeed?;
      final setName = extra?['setName'] as String?;

      if (speed == null || setName == null) {
        return CustomTransitionPage(
          key: state.pageKey,
          child: const Scaffold(
            body: Center(child: Text('Geçersiz parametreler')),
          ),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        );
      }

      return CustomTransitionPage(
        key: state.pageKey,
        child: WordEchoPage(speed: speed, setName: setName),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      );
    },
  ),
  // Word Echo Grid setup
  GoRoute(
    path: '/word-echo/grid',
    name: WordEchoGridSetupPage.routeName,
    pageBuilder:
        (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const WordEchoGridSetupPage(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
  ),
  // Word Echo Grid game
  GoRoute(
    path: '/word-echo/grid/game',
    name: WordEchoGridPage.routeName,
    pageBuilder: (context, state) {
      final extra = state.extra as Map<String, dynamic>?;
      final speed = extra?['speed'] as WordEchoSpeed?;
      final setName = extra?['setName'] as String?;

      if (speed == null || setName == null) {
        return CustomTransitionPage(
          key: state.pageKey,
          child: const Scaffold(
            body: Center(child: Text('Geçersiz parametreler')),
          ),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        );
      }

      return CustomTransitionPage(
        key: state.pageKey,
        child: WordEchoGridPage(speed: speed, setName: setName),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      );
    },
  ),
];
