import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/flash_synonym/ui/flash_synonym_level_select_page.dart';
import '../../features/flash_synonym/ui/flash_synonym_page.dart';

List<RouteBase> get flashSynonymRoutes => [
  GoRoute(
    path: '/flash-synonym',
    name: FlashSynonymLevelSelectPage.routeName,
    pageBuilder:
        (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const FlashSynonymLevelSelectPage(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
  ),
  GoRoute(
    path: '/flash-synonym/:level',
    name: FlashSynonymPage.routeName,
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
        child: FlashSynonymPage(level: level),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      );
    },
  ),
];
