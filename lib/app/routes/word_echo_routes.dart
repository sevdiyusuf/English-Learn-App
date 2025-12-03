import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/word_echo/models/word_echo_state.dart';
import '../../features/word_echo/ui/word_echo_page.dart';
import '../../features/word_echo/ui/word_echo_setup_page.dart';

List<RouteBase> get wordEchoRoutes => [
      GoRoute(
        path: '/word-echo',
        name: WordEchoSetupPage.routeName,
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const WordEchoSetupPage(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
        ),
      ),
      GoRoute(
        path: '/word-echo/game',
        name: WordEchoPage.routeName,
        pageBuilder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final speed = extra?['speed'] as WordEchoSpeed?;
          final setName = extra?['setName'] as String?;

          if (speed == null || setName == null) {
            return CustomTransitionPage(
              key: state.pageKey,
              child: const Scaffold(
                body: Center(
                  child: Text('Geçersiz parametreler'),
                ),
              ),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                return FadeTransition(
                  opacity: animation,
                  child: child,
                );
              },
            );
          }

          return CustomTransitionPage(
            key: state.pageKey,
            child: WordEchoPage(
              speed: speed,
              setName: setName,
            ),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(
                opacity: animation,
                child: child,
              );
            },
          );
        },
      ),
    ];
