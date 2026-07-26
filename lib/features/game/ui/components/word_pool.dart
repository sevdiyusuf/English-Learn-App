import 'package:flutter/material.dart';
import 'package:yunoo/l10n/app_localizations.dart';

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
  List<PlayedWord> _sortedWords = [];

  @override
  void initState() {
    super.initState();
    _updateSortedWords();
    // Scroll to bottom when new words are added
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }

  @override
  void didUpdateWidget(WordPool oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.playedWords != oldWidget.playedWords) {
      _updateSortedWords();
    }
    // Scroll to bottom when new words are added
    if (widget.playedWords.length > oldWidget.playedWords.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
    }
  }

  void _updateSortedWords() {
    _sortedWords = List<PlayedWord>.from(widget.playedWords)
      ..sort((a, b) => a.at.compareTo(b.at));
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
    final l10n = AppLocalizations.of(context)!;
    if (widget.room.players.length < 2) {
      return Center(child: Text(l10n.noWordsYet));
    }

    // Get player UIDs
    final player1Uid = widget.room.players[0];
    final player2Uid =
        widget.room.players.length > 1 ? widget.room.players[1] : null;

    if (player2Uid == null) {
      return Center(child: Text(l10n.noWordsYet));
    }

    // Determine which player is "me" (current user)
    final myUid = widget.currentUid ?? player1Uid;

    if (_sortedWords.isEmpty) {
      return Center(
        child: Text(
          l10n.noWordsYet,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade400),
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemCount: _sortedWords.length,
      itemBuilder: (context, index) {
        final word = _sortedWords[index];
        final isMyWord = word.byUid == myUid;

        return _PlayedWordItem(word: word, isMyWord: isMyWord);
      },
    );
  }
}

class _PlayedWordItem extends StatelessWidget {
  const _PlayedWordItem({required this.word, required this.isMyWord});

  final PlayedWord word;
  final bool isMyWord;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            isMyWord ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isMyWord) ...[
            // Opponent's word - left side
            _WordBubble(word: word.word, isMyWord: false),
          ] else ...[
            // My word - right side
            _WordBubble(word: word.word, isMyWord: true),
          ],
        ],
      ),
    );
  }
}

class _WordBubble extends StatelessWidget {
  const _WordBubble({required this.word, required this.isMyWord});

  final String word;
  final bool isMyWord;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Semantics(
      label: isMyWord ? l10n.myPlayedWord(word) : l10n.opponentPlayedWord(word),
      excludeSemantics: true,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.7,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                word,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.black87,
                  fontSize: 15,
                ),
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
              child: const Icon(Icons.check, color: Colors.black, size: 14),
            ),
          ],
        ),
      ),
    );
  }
}
