import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/lobby/ui/create_room_page.dart';
import '../../features/lobby/ui/join_room_page.dart';
import '../../features/lobby/ui/lobby_home_page.dart';
import '../../features/lobby/ui/room_lobby_page.dart';

/// Lobby-related routes
List<RouteBase> get lobbyRoutes => [
  GoRoute(
    path: '/lobby',
    name: LobbyHomePage.routeName,
    pageBuilder:
        (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: LobbyHomePage(from: state.uri.queryParameters['from']),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
  ),
  GoRoute(
    path: '/create',
    name: CreateRoomPage.routeName,
    pageBuilder:
        (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const CreateRoomPage(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: animation.drive(
                Tween(
                  begin: const Offset(1.0, 0.0),
                  end: Offset.zero,
                ).chain(CurveTween(curve: Curves.ease)),
              ),
              child: child,
            );
          },
        ),
  ),
  GoRoute(
    path: '/join',
    name: JoinRoomPage.routeName,
    pageBuilder: (context, state) {
      final roomId = state.uri.queryParameters['roomId'];
      final turnDuration = state.uri.queryParameters['t'];
      return CustomTransitionPage(
        key: state.pageKey,
        child: JoinRoomPage(
          initialRoomId: roomId,
          initialTurnDurationSeconds:
              turnDuration != null ? int.tryParse(turnDuration) : null,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: animation.drive(
              Tween(
                begin: const Offset(1.0, 0.0),
                end: Offset.zero,
              ).chain(CurveTween(curve: Curves.ease)),
            ),
            child: child,
          );
        },
      );
    },
  ),
  GoRoute(
    path: '/room/:roomId',
    name: RoomLobbyPage.routeName,
    pageBuilder: (context, state) {
      final roomId = state.pathParameters['roomId'];
      if (roomId == null || roomId.isEmpty) {
        // Redirect to home if roomId is missing
        return CustomTransitionPage(
          key: state.pageKey,
          child: const Scaffold(body: Center(child: Text('Oda ID bulunamadı'))),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        );
      }
      return CustomTransitionPage(
        key: state.pageKey,
        child: RoomLobbyPage(roomId: roomId),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      );
    },
  ),
];
