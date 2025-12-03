import 'dart:async';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/word_match_providers.dart';
import '../data/word_match_repo_interface.dart';
import '../models/word_pair.dart';
import '../models/word_set.dart';

enum MatchAttemptState { none, correct, wrong }

class WordMatchSetSnapshot {
  const WordMatchSetSnapshot({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
    required this.lastPracticedAt,
  });

  factory WordMatchSetSnapshot.fromSet(WordSet set) {
    return WordMatchSetSnapshot(
      id: set.id,
      name: set.name,
      createdAt: set.createdAt,
      updatedAt: set.updatedAt,
      lastPracticedAt: set.lastPracticedAt,
    );
  }

  final int id;
  final String name;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastPracticedAt;

  WordMatchSetSnapshot copyWith({
    String? name,
    DateTime? updatedAt,
    DateTime? lastPracticedAt,
  }) {
    return WordMatchSetSnapshot(
      id: id,
      name: name ?? this.name,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastPracticedAt: lastPracticedAt ?? this.lastPracticedAt,
    );
  }
}

class WordMatchSessionState {
  static const Object _sentinel = Object();

  const WordMatchSessionState({
    required this.set,
    required this.currentRoundPairs,
    required this.remainingPairs,
    required this.leftOrder,
    required this.rightOrder,
    required this.solvedPairIds,
    required this.correctAttempts,
    required this.wrongAttempts,
    required this.selectedLeftId,
    required this.selectedRightId,
    required this.attemptState,
    required this.attemptLeftId,
    required this.attemptRightId,
    required this.totalPairs,
    required this.isComplete,
  });

  factory WordMatchSessionState.initial({
    required WordMatchSetSnapshot set,
    required List<WordPair> roundPairs,
    required List<WordPair> remainingPairs,
    required int totalPairs,
    required Random random,
  }) {
    final ids = roundPairs.map((pair) => pair.id).toList();
    final leftOrder = List<int>.from(ids)..shuffle(random);
    final rightOrder = List<int>.from(ids)..shuffle(random);
    return WordMatchSessionState(
      set: set,
      currentRoundPairs: roundPairs,
      remainingPairs: remainingPairs,
      leftOrder: leftOrder,
      rightOrder: rightOrder,
      solvedPairIds: <int>{},
      correctAttempts: 0,
      wrongAttempts: 0,
      selectedLeftId: null,
      selectedRightId: null,
      attemptState: MatchAttemptState.none,
      attemptLeftId: null,
      attemptRightId: null,
      totalPairs: totalPairs,
      isComplete: false,
    );
  }

  final WordMatchSetSnapshot set;
  final List<WordPair> currentRoundPairs;
  final List<WordPair> remainingPairs;
  final List<int> leftOrder;
  final List<int> rightOrder;
  final Set<int> solvedPairIds;
  final int correctAttempts;
  final int wrongAttempts;
  final int? selectedLeftId;
  final int? selectedRightId;
  final MatchAttemptState attemptState;
  final int? attemptLeftId;
  final int? attemptRightId;
  final int totalPairs;
  final bool isComplete;

  int get attempts => correctAttempts + wrongAttempts;

  bool get roundSolved =>
      solvedPairIds.length == currentRoundPairs.length &&
      currentRoundPairs.isNotEmpty;

  WordMatchSessionState copyWith({
    WordMatchSetSnapshot? set,
    List<WordPair>? currentRoundPairs,
    List<WordPair>? remainingPairs,
    List<int>? leftOrder,
    List<int>? rightOrder,
    Set<int>? solvedPairIds,
    int? correctAttempts,
    int? wrongAttempts,
    Object? selectedLeftId = _sentinel,
    Object? selectedRightId = _sentinel,
    MatchAttemptState? attemptState,
    Object? attemptLeftId = _sentinel,
    Object? attemptRightId = _sentinel,
    int? totalPairs,
    bool? isComplete,
  }) {
    return WordMatchSessionState(
      set: set ?? this.set,
      currentRoundPairs: currentRoundPairs ?? this.currentRoundPairs,
      remainingPairs: remainingPairs ?? this.remainingPairs,
      leftOrder: leftOrder ?? this.leftOrder,
      rightOrder: rightOrder ?? this.rightOrder,
      solvedPairIds: solvedPairIds ?? this.solvedPairIds,
      correctAttempts: correctAttempts ?? this.correctAttempts,
      wrongAttempts: wrongAttempts ?? this.wrongAttempts,
      selectedLeftId:
          identical(selectedLeftId, _sentinel)
              ? this.selectedLeftId
              : selectedLeftId as int?,
      selectedRightId:
          identical(selectedRightId, _sentinel)
              ? this.selectedRightId
              : selectedRightId as int?,
      attemptState: attemptState ?? this.attemptState,
      attemptLeftId:
          identical(attemptLeftId, _sentinel)
              ? this.attemptLeftId
              : attemptLeftId as int?,
      attemptRightId:
          identical(attemptRightId, _sentinel)
              ? this.attemptRightId
              : attemptRightId as int?,
      totalPairs: totalPairs ?? this.totalPairs,
      isComplete: isComplete ?? this.isComplete,
    );
  }

  WordPair pairById(int id) {
    return currentRoundPairs.firstWhere((element) => element.id == id);
  }
}

class WordMatchSessionController
    extends AutoDisposeFamilyAsyncNotifier<WordMatchSessionState, int> {
  WordMatchRepoInterface? _repo;
  final Random _random = Random();
  bool _selectionLocked = false;
  bool _isDisposed = false;

  @override
  Future<WordMatchSessionState> build(int arg) async {
    final repo = await ref.watch(wordMatchRepoProvider.future);
    _repo = repo;
    ref.onDispose(() {
      _isDisposed = true;
    });

    final set = await repo.getSet(arg);
    if (set == null) {
      throw StateError('Set bulunamadı');
    }
    final pairs = await repo.fetchPairs(arg);
    if (pairs.isEmpty) {
      throw StateError('Bu sette henüz kelime yok');
    }
    // Learned kelimeleri filtrele - sadece aktif (öğrenilmemiş) kelimeleri göster
    final learnedStatuses = await repo.getLearnedStatuses(arg);
    final activePairs = pairs.where((pair) => !(learnedStatuses[pair.id] ?? false)).toList();
    if (activePairs.isEmpty) {
      throw StateError('Bu sette aktif kelime kalmadı. Tüm kelimeler öğrenilmiş.');
    }
    // Her yeni session'da kelimeleri karıştır
    final shuffledPairs = List<WordPair>.from(activePairs)..shuffle(_random);
    final totalPairs = shuffledPairs.length;
    final initialRound = shuffledPairs.take(8).toList();
    final remaining = shuffledPairs.skip(initialRound.length).toList();

    return WordMatchSessionState.initial(
      set: WordMatchSetSnapshot.fromSet(set),
      roundPairs: initialRound,
      remainingPairs: remaining,
      totalPairs: totalPairs,
      random: _random,
    );
  }

  void selectLeft(int pairId) {
    final current = state.value;
    if (current == null ||
        current.isComplete ||
        current.solvedPairIds.contains(pairId) ||
        _selectionLocked) {
      return;
    }
    final isSame = current.selectedLeftId == pairId;
    final updated = current.copyWith(
      selectedLeftId: isSame ? null : pairId,
      selectedRightId: current.selectedRightId,
      attemptState: MatchAttemptState.none,
      attemptLeftId: null,
      attemptRightId: null,
    );
    state = AsyncValue.data(updated);
    _tryEvaluate(updated);
  }

  void selectRight(int pairId) {
    final current = state.value;
    if (current == null ||
        current.isComplete ||
        current.solvedPairIds.contains(pairId) ||
        _selectionLocked) {
      return;
    }
    final isSame = current.selectedRightId == pairId;
    final updated = current.copyWith(
      selectedRightId: isSame ? null : pairId,
      selectedLeftId: current.selectedLeftId,
      attemptState: MatchAttemptState.none,
      attemptLeftId: null,
      attemptRightId: null,
    );
    state = AsyncValue.data(updated);
    _tryEvaluate(updated);
  }

  void _tryEvaluate(WordMatchSessionState snapshot) {
    final left = snapshot.selectedLeftId;
    final right = snapshot.selectedRightId;
    if (left == null || right == null || _selectionLocked) {
      return;
    }
    if (left == right) {
      _handleCorrect(snapshot, left);
    } else {
      _handleWrong(snapshot, left, right);
    }
  }

  void _handleCorrect(WordMatchSessionState snapshot, int pairId) {
    final updatedSolved = <int>{...snapshot.solvedPairIds, pairId};
    final updated = snapshot.copyWith(
      solvedPairIds: updatedSolved,
      correctAttempts: snapshot.correctAttempts + 1,
      attemptState: MatchAttemptState.correct,
      attemptLeftId: pairId,
      attemptRightId: pairId,
      selectedLeftId: pairId,
      selectedRightId: pairId,
    );
    state = AsyncValue.data(updated);
    _selectionLocked = true;
    unawaited(_finishCorrectAttempt(updated));
  }

  Future<void> _finishCorrectAttempt(WordMatchSessionState snapshot) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    if (_isDisposed) {
      return;
    }
    var current = state.value;
    if (current == null) {
      return;
    }
    current = current.copyWith(
      attemptState: MatchAttemptState.none,
      attemptLeftId: null,
      attemptRightId: null,
      selectedLeftId: null,
      selectedRightId: null,
    );
    state = AsyncValue.data(current);
    _selectionLocked = false;

    if (current.roundSolved) {
      await _advanceRound();
    }
  }

  void _handleWrong(WordMatchSessionState snapshot, int left, int right) {
    final updated = snapshot.copyWith(
      wrongAttempts: snapshot.wrongAttempts + 1,
      attemptState: MatchAttemptState.wrong,
      attemptLeftId: left,
      attemptRightId: right,
    );
    state = AsyncValue.data(updated);
    _selectionLocked = true;
    unawaited(_resetAfterWrong());
  }

  Future<void> _resetAfterWrong() async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    if (_isDisposed) {
      return;
    }
    final current = state.value;
    if (current == null) {
      return;
    }
    state = AsyncValue.data(
      current.copyWith(
        attemptState: MatchAttemptState.none,
        attemptLeftId: null,
        attemptRightId: null,
        selectedLeftId: null,
        selectedRightId: null,
      ),
    );
    _selectionLocked = false;
  }

  Future<void> _advanceRound() async {
    final current = state.value;
    if (current == null || current.isComplete) {
      return;
    }
    if (current.remainingPairs.isEmpty) {
      await _completeSession(current);
      return;
    }
    // Kalan kelimeleri de karıştır
    final shuffledRemaining = List<WordPair>.from(current.remainingPairs)
      ..shuffle(_random);
    final nextBatchSize =
        shuffledRemaining.length >= 8 ? 8 : shuffledRemaining.length;
    final nextRound = shuffledRemaining.take(nextBatchSize).toList();
    final nextRemaining = shuffledRemaining
        .skip(nextBatchSize)
        .toList(growable: false);

    final ids = nextRound.map((pair) => pair.id).toList();
    final leftOrder = List<int>.from(ids)..shuffle(_random);
    final rightOrder = List<int>.from(ids)..shuffle(_random);

    state = AsyncValue.data(
      current.copyWith(
        currentRoundPairs: nextRound,
        remainingPairs: nextRemaining,
        leftOrder: leftOrder,
        rightOrder: rightOrder,
        solvedPairIds: <int>{},
        selectedLeftId: null,
        selectedRightId: null,
        attemptState: MatchAttemptState.none,
        attemptLeftId: null,
        attemptRightId: null,
      ),
    );
  }

  Future<void> _completeSession(WordMatchSessionState snapshot) async {
    final repo = _repo;
    if (repo != null) {
      await repo.recordPractice(snapshot.set.id);
    }
    final updatedSet = snapshot.set.copyWith(
      updatedAt: DateTime.now(),
      lastPracticedAt: DateTime.now(),
    );
    if (_isDisposed) {
      return;
    }
    state = AsyncValue.data(
      snapshot.copyWith(set: updatedSet, isComplete: true),
    );
  }
}

final wordMatchSessionControllerProvider =
    AutoDisposeAsyncNotifierProviderFamily<
      WordMatchSessionController,
      WordMatchSessionState,
      int
    >(WordMatchSessionController.new);
