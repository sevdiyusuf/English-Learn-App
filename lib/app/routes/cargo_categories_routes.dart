import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/cargo_categories/ui/cargo_categories_game_page.dart';
import '../../features/cargo_categories/ui/cargo_categories_setup_page.dart';

List<RouteBase> get cargoCategoriesRoutes => [
  GoRoute(
    path: '/cargo-categories/setup',
    name: CargoCategoriesSetupPage.routeName,
    pageBuilder:
        (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const CargoCategoriesSetupPage(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
  ),
  GoRoute(
    path: '/cargo-categories/game',
    name: CargoCategoriesGamePage.routeName,
    pageBuilder:
        (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const CargoCategoriesGamePage(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
  ),
];
