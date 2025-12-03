import 'dart:async';

import 'package:flutter/material.dart';

class CountdownWidget extends StatefulWidget {
  const CountdownWidget({
    super.key,
    required this.deadline,
    required this.turnDurationSeconds,
    required this.isActiveTurn,
    required this.serverOffset,
    required this.onTimeout,
  });

  final DateTime? deadline;
  final int turnDurationSeconds;
  final bool isActiveTurn;
  final Duration serverOffset;
  final Future<void> Function() onTimeout;

  @override
  State<CountdownWidget> createState() => _CountdownWidgetState();
}

class _CountdownWidgetState extends State<CountdownWidget> {
  Timer? _timer;
  Duration _remaining = Duration.zero;
  bool _timeoutTriggered = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void didUpdateWidget(covariant CountdownWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.deadline != widget.deadline ||
        oldWidget.serverOffset != widget.serverOffset) {
      _timeoutTriggered = false;
      _startTimer();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    _updateRemaining();
    if (widget.deadline == null) {
      return;
    }
    _timer = Timer.periodic(const Duration(milliseconds: 250), (_) {
      _updateRemaining();
    });
  }

  Future<void> _triggerTimeout() async {
    if (_timeoutTriggered) {
      return;
    }
    _timeoutTriggered = true;
    await widget.onTimeout();
  }

  void _updateRemaining() {
    final deadline = widget.deadline;
    if (deadline == null) {
      setState(() => _remaining = Duration.zero);
      return;
    }

    final adjustedNow = DateTime.now().add(widget.serverOffset);
    final diff = deadline.difference(adjustedNow);

    if (diff <= Duration.zero) {
      // Süre bitti: kalan süreyi 0'a sabitle
      setState(() => _remaining = Duration.zero);
      // Küçük bir toleransla ve sadece aktif oyuncu için timeout tetikle
      if (diff <= const Duration(milliseconds: -300) && widget.isActiveTurn) {
        _triggerTimeout();
      }
    } else {
      setState(() => _remaining = diff);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWaiting = widget.deadline == null;
    final secondsRemaining = _remaining.inSeconds.clamp(
      0,
      widget.turnDurationSeconds,
    );
    final progress =
        widget.turnDurationSeconds == 0
            ? 1.0
            : secondsRemaining / widget.turnDurationSeconds;

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Icon(
              widget.isActiveTurn
                  ? Icons.timer_outlined
                  : Icons.schedule_outlined,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.isActiveTurn ? 'Sıra sende!' : 'Sıranı bekle',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  LinearProgressIndicator(
                    value: isWaiting ? null : progress,
                    minHeight: 4,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (isWaiting)
              Text(
                'Bekle',
                style: Theme.of(context).textTheme.bodySmall,
              )
            else
              Text(
                '${secondsRemaining}s',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
