import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/logic/auth_controller.dart';
import '../../features/game/models/room.dart';
import 'notification_service.dart';

/// Game notification handler
class GameNotifications {
  static String? _lastNotifiedTurnUid;

  static void setupGameNotifications(
    WidgetRef ref,
    Room room,
    String? currentUid,
  ) {
    final notificationService = ref.read(notificationServiceProvider);
    final authState = ref.read(authControllerProvider);
    final userUid = authState.value?.uid;

    if (userUid == null) return;

    // Check if it's the user's turn
    final isPlayerTurn = room.currentTurnUid == userUid;

    // Notify when it's the user's turn (only once per turn)
    if (isPlayerTurn && _lastNotifiedTurnUid != room.currentTurnUid) {
      _lastNotifiedTurnUid = room.currentTurnUid;
      notificationService.showSuccess(
        title: 'Sıra sende',
        message: null,
        duration: const Duration(seconds: 2),
      );
    }

    // Notify when game starts (only once) - removed to avoid notification spam
    // Game page will handle the UI transition automatically

    // Notify when game ends (only once) - removed to avoid notification spam
    // Game page will show a dialog instead
  }

  /// Reset notification state (call when leaving game)
  static void reset() {
    _lastNotifiedTurnUid = null;
  }
}
