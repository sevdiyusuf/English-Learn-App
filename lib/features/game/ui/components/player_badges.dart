import 'package:flutter/material.dart';
import 'package:yunoo/l10n/app_localizations.dart';

import '../../models/room.dart';

class PlayerBadges extends StatelessWidget {
  const PlayerBadges({
    super.key,
    required this.room,
    this.currentUid,
    this.scores = const {},
  });

  final Room room;
  final String? currentUid;
  final Map<String, int> scores;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.playersCount(room.players.length),
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children:
                  room.players.map((uid) {
                    final isCurrentTurn = uid == room.currentTurnUid;
                    final isActive = room.activePlayerIds.contains(uid);
                    final isSelf = uid == currentUid;
                    final isHost = uid == room.hostUid;

                    // Get player name from playerNames map, fallback to UID if not found
                    final playerName = room.playerNames[uid] ?? l10n.user;
                    final score = scores[uid] ?? 0;

                    final labels = <String>[];
                    if (isHost) labels.add(l10n.hostLabel);
                    if (isSelf) labels.add(l10n.you);
                    if (!isActive) labels.add(l10n.eliminatedLabel);
                    if (isCurrentTurn && isActive) {
                      labels.add(l10n.currentTurnLabel);
                    }

                    Color textColor;
                    if (!isActive) {
                      textColor = Colors.grey;
                    } else if (isCurrentTurn) {
                      textColor = Colors.green.shade700;
                    } else {
                      textColor = Colors.black87;
                    }

                    return Semantics(
                      label: [
                        l10n.playerScore(playerName, score),
                        ...labels,
                      ].join('. '),
                      excludeSemantics: true,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color:
                              isCurrentTurn && isActive
                                  ? Colors.green.shade50
                                  : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          border:
                              isCurrentTurn && isActive
                                  ? Border.all(
                                    color: Colors.green.shade300,
                                    width: 1,
                                  )
                                  : null,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              l10n.playerScore(playerName, score),
                              style: Theme.of(
                                context,
                              ).textTheme.bodySmall?.copyWith(
                                color: textColor,
                                fontWeight:
                                    isCurrentTurn
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                              ),
                            ),
                            if (labels.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                labels.join(', '),
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(color: Colors.grey.shade600),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
