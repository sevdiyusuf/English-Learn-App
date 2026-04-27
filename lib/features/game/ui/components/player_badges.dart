import 'package:flutter/material.dart';

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
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Oyuncular (${room.players.length})',
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
                    final playerName = room.playerNames[uid] ?? uid;
                    final score = scores[uid] ?? 0;

                    final labels = <String>[];
                    if (isHost) labels.add('Host');
                    if (isSelf) labels.add('Sen');
                    if (!isActive) labels.add('Elendi');

                    Color textColor;
                    if (!isActive) {
                      textColor = Colors.grey;
                    } else if (isCurrentTurn) {
                      textColor = Colors.green.shade700;
                    } else {
                      textColor = Colors.black87;
                    }

                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
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
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '$playerName ($score)',
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
                            const SizedBox(width: 4),
                            Text(
                              '(${labels.join(', ')})',
                              style: Theme.of(
                                context,
                              ).textTheme.bodySmall?.copyWith(
                                color: Colors.grey.shade600,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ],
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
