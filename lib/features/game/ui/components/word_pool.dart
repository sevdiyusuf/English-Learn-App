import 'package:flutter/material.dart';

import '../../models/played_word.dart';
import '../../models/room.dart';

class WordPool extends StatefulWidget {
  const WordPool({
    super.key,
    required this.playedWords,
    required this.room,
    this.currentUid,
  });

  final List<PlayedWord> playedWords;
  final Room room;
  final String? currentUid;

  @override
  State<WordPool> createState() => _WordPoolState();
}

class _WordPoolState extends State<WordPool> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Scroll to bottom when new words are added
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }

  @override
  void didUpdateWidget(WordPool oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Scroll to bottom when new words are added
    if (widget.playedWords.length > oldWidget.playedWords.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.room.players.length < 2) {
      return const Center(
        child: Text('Henüz kelime yok'),
      );
    }

    // Get player UIDs
    final player1Uid = widget.room.players[0];
    final player2Uid = widget.room.players.length > 1 ? widget.room.players[1] : null;

    if (player2Uid == null) {
      return const Center(
        child: Text('Henüz kelime yok'),
      );
    }

    // Determine which player is "me" (current user)
    final myUid = widget.currentUid ?? player1Uid;

    // Sort all words chronologically
    final sortedWords = List<PlayedWord>.from(widget.playedWords)
      ..sort((a, b) => a.at.compareTo(b.at));

    if (sortedWords.isEmpty) {
      return Center(
        child: Text(
          'Henüz kelime yok',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Colors.grey.shade400,
          ),
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemCount: sortedWords.length,
      itemBuilder: (context, index) {
        final word = sortedWords[index];
        final isMyWord = word.byUid == myUid;
        
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            mainAxisAlignment: isMyWord 
                ? MainAxisAlignment.end 
                : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isMyWord) ...[
                // Opponent's word - left side
                Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.7,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        word.word,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.black87,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: Colors.green.shade300,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                // My word - right side (same style as opponent's word)
                Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.7,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        word.word,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.black87,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: Colors.green.shade300,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
