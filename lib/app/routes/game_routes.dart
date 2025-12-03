import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/game/ui/game_page.dart';

/// Game-related routes
List<RouteBase> get gameRoutes => [
      GoRoute(
        path: '/game/:roomId',
        name: GamePage.routeName,
        pageBuilder: (context, state) {
          final roomId = state.pathParameters['roomId'];
          if (roomId == null || roomId.isEmpty) {
            // Redirect to home if roomId is missing
            return CustomTransitionPage(
              key: state.pageKey,
              child: const Scaffold(
                body: Center(
                  child: Text('Oda ID bulunamadı'),
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
            child: GamePage(roomId: roomId),
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

