import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/animations/animations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../logic/game_controller.dart';
import '../../models/room.dart';
import 'countdown_widget.dart';
import 'player_badges.dart';

class GameHeader extends ConsumerWidget {
  const GameHeader({
    super.key,
    required this.room,
    required this.currentUserUid,
    required this.scores,
    required this.serverOffset,
    required this.gameController,
  });

  final Room room;
  final String? currentUserUid;
  final Map<String, int> scores;
  final Duration serverOffset;
  final GameController gameController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPlayerTurn = room.currentTurnUid == currentUserUid;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceDark.withValues(alpha: 0.9),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 8,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Mode / Theme / Type label
          _GameModeLabel(room: room),
          // Status Banner
          if (room.status == RoomStatus.active)
            _StatusBanner(isMyTurn: isPlayerTurn),
          // Game elapsed time
          if (room.status == RoomStatus.active)
            _GameTimer(
              startTime: room.createdAt,
              serverOffset: serverOffset,
            ),
          FadeInAnimation(
            child: CountdownWidget(
              deadline: room.turnDeadlineAt,
              turnDurationSeconds: room.turnDurationSeconds,
              isActiveTurn: isPlayerTurn,
              serverOffset: serverOffset,
              onTimeout: () async {
                try {
                  await gameController.resolveTimeout();
                } on Object catch (_) {}
              },
            ),
          ),
          const SizedBox(height: 8),
          SlideInAnimation(
            delay: const Duration(milliseconds: 100),
            child: PlayerBadges(
              room: room,
              currentUid: currentUserUid,
              scores: scores,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({required this.isMyTurn});
  final bool isMyTurn;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      decoration: BoxDecoration(
        color:
            isMyTurn
                ? Colors.green.withValues(alpha: 0.2)
                : Colors.orange.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color:
              isMyTurn
                  ? Colors.green.withValues(alpha: 0.5)
                  : Colors.orange.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isMyTurn ? Icons.play_circle_fill : Icons.hourglass_empty,
            size: 16,
            color: Colors.white,
          ),
          const SizedBox(width: 8),
          Text(
            isMyTurn ? 'SIRA SENDE!' : 'RAKİP BEKLENİYOR...',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 13,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _GameModeLabel extends StatelessWidget {
  const _GameModeLabel({required this.room});

  final Room room;

  @override
  Widget build(BuildContext context) {
    final mode = room.gameMode;
    final settings = room.settings;
    String text = 'Word Battle';
    Color chipColor = const Color(0xFF4F46E5);

    if (mode == GameMode.theme && settings?.theme != null) {
      text = 'KONU: ${settings!.theme!.packTitle.toUpperCase()}';
      chipColor = Colors.orange.shade700;
    } else if (mode == GameMode.core && settings?.core != null) {
      final t = settings!.core!.posType;
      final tr =
          t == 'verb'
              ? 'FİİL'
              : t == 'adjective'
              ? 'SIFAT'
              : t == 'noun'
              ? 'İSİM'
              : 'ZARF';
      text = 'GÖREV: $tr GİRİN';
      chipColor = Colors.blue.shade700;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: chipColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        text,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.95),
          fontSize: 14,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _GameTimer extends StatefulWidget {
  const _GameTimer({required this.startTime, required this.serverOffset});

  final DateTime startTime;
  final Duration serverOffset;

  @override
  State<_GameTimer> createState() => _GameTimerState();
}

class _GameTimerState extends State<_GameTimer> {
  Timer? _timer;
  Duration _elapsed = Duration.zero;

  @override
  void initState() {
    super.initState();
    _updateElapsed();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateElapsed();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _updateElapsed() {
    final adjustedNow = DateTime.now().add(widget.serverOffset);
    final elapsed = adjustedNow.difference(widget.startTime);
    if (mounted) {
      setState(() {
        _elapsed = elapsed;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final minutes = _elapsed.inMinutes;
    final seconds = _elapsed.inSeconds % 60;
    final formattedTime =
        '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.timer_outlined, size: 14, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            formattedTime,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
