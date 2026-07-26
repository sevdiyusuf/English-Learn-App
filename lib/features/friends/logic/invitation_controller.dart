import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/logic/auth_controller.dart';
import '../../../core/notifications/notification_service.dart';
import '../../lobby/logic/room_controller.dart';
import '../../multiplayer/grammar_arena/logic/arena_lobby_controller.dart';
import '../../../app/router.dart';
import '../data/invitation_repo.dart';
import '../models/game_invitation.dart';

class InvitationController extends StateNotifier<List<GameInvitation>> {
  InvitationController(this._ref) : super([]) {
    _init();
  }

  final Ref _ref;
  StreamSubscription? _sub;

  void _init() {
    _ref.listen(authControllerProvider, (prev, next) {
      final user = next.value;
      if (user != null) {
        _watchInvitations(user.uid);
      } else {
        _sub?.cancel();
        state = [];
      }
    });

    // Initial check
    final user = _ref.read(authControllerProvider).value;
    if (user != null) {
      _watchInvitations(user.uid);
    }
  }

  void _watchInvitations(String uid) {
    _sub?.cancel();
    _sub = _ref.read(invitationRepositoryProvider).watchInvitations(uid).listen(
      (invitations) {
        _handleNewInvitations(invitations);
        state = invitations;
      },
    );
  }

  void _handleNewInvitations(List<GameInvitation> invitations) {
    // Find new invitations that were not in the previous state
    // and are recent (< 8 seconds old)
    final now = DateTime.now().toUtc();

    for (final invitation in invitations) {
      // Check if already in state
      if (state.any((i) => i.id == invitation.id)) continue;

      // Check timestamp
      if (invitation.createdAt == null) continue;
      if (now.difference(invitation.createdAt!).inSeconds > 8) {
        // Too old, delete it silently
        _deleteInvitation(invitation.id);
        continue;
      }

      // Show notification
      _showInvitationNotification(invitation);
    }
  }

  Future<void> _showInvitationNotification(GameInvitation invitation) async {
    final notificationService = _ref.read(notificationServiceProvider);

    final gameName =
        invitation.gameType == 'word_battle'
            ? 'Kelime Savaşı'
            : 'Gramer Arenası';

    notificationService.showNotification(
      AppNotification(
        id: invitation.id,
        title: 'Oyun Daveti',
        message: '${invitation.fromName} seni $gameName oyununa davet ediyor!',
        type: NotificationType.info,
        duration: const Duration(seconds: 8),
        actions: [
          NotificationAction(
            label: 'Reddet',
            onPressed: () => _rejectInvitation(invitation),
          ),
          NotificationAction(
            label: 'Kabul Et',
            onPressed: () => _acceptInvitation(invitation),
          ),
        ],
      ),
    );
  }

  Future<void> _acceptInvitation(GameInvitation invitation) async {
    await acceptInvitationById(invitation.id);
  }

  Future<bool> acceptInvitationById(String invitationId) async {
    late Map<String, dynamic> resolved;
    try {
      resolved = await _ref
          .read(invitationRepositoryProvider)
          .acceptInvitation(invitationId);
    } catch (_) {
      return false;
    }

    final roomId = resolved['roomId'];
    final gameType = resolved['gameType'];
    if (roomId is! String || roomId.isEmpty || gameType is! String) {
      return false;
    }
    final router = _ref.read(appRouterProvider);

    if (gameType == 'word_battle') {
      final currentUser = _ref.read(authControllerProvider).value;
      if (currentUser == null) return false;
      try {
        await _ref
            .read(roomControllerProvider.notifier)
            .joinRoom(
              roomCode: roomId,
              username: currentUser.displayName ?? 'Oyuncu',
            );
        router.go('/room/$roomId');
        return true;
      } catch (_) {
        return false;
      }
    }
    if (gameType == 'grammar_arena') {
      try {
        await _ref.read(arenaLobbyControllerProvider.notifier).joinRoom(roomId);
        final state = _ref.read(arenaLobbyControllerProvider);
        if (state.hasValue && state.value != null) {
          router.go('/multiplayer/grammar-arena/room/${state.value}');
          return true;
        }
      } catch (_) {
        return false;
      }
    }
    return false;
  }

  Future<void> _rejectInvitation(GameInvitation invitation) async {
    await _deleteInvitation(invitation.id);
  }

  Future<void> _deleteInvitation(String invitationId) async {
    final user = _ref.read(authControllerProvider).value;
    if (user != null) {
      await _ref
          .read(invitationRepositoryProvider)
          .deleteInvitation(user.uid, invitationId);
    }
  }

  // Public method to send invitation
  Future<void> sendInvitation({
    required String toUid,
    required String roomId,
    required String gameType,
  }) async {
    final currentUser = _ref.read(authControllerProvider).value;
    if (currentUser == null) return;

    await _ref
        .read(invitationRepositoryProvider)
        .sendInvitation(
          fromUid: currentUser.uid,
          fromName: currentUser.displayName ?? 'Anonim',
          toUid: toUid,
          roomId: roomId,
          gameType: gameType,
        );
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}

final invitationControllerProvider =
    StateNotifierProvider<InvitationController, List<GameInvitation>>((ref) {
      return InvitationController(ref);
    });
