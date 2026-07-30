import 'dart:async';
import 'package:flutter/material.dart';
import 'package:yunoo/l10n/app_localizations.dart';

class GameTimer extends StatefulWidget {
  const GameTimer({
    super.key,
    required this.startTime,
    required this.serverOffset,
    this.isSmall = false,
  });

  final DateTime startTime;
  final Duration serverOffset;
  final bool isSmall;

  @override
  State<GameTimer> createState() => _GameTimerState();
}

class _GameTimerState extends State<GameTimer> {
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
    final l10n = AppLocalizations.of(context)!;
    final minutes = _elapsed.inMinutes;
    final seconds = _elapsed.inSeconds % 60;
    final formattedTime =
        '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

    return Semantics(
      label: l10n.elapsedTime(minutes, seconds),
      excludeSemantics: true,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: widget.isSmall ? 8 : 12,
          vertical: widget.isSmall ? 4 : 8,
        ),
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
      ),
    );
  }
}
