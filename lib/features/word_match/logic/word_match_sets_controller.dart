import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/word_match_providers.dart';
import '../data/word_match_repo_interface.dart';
import '../models/word_set.dart';

class WordSetOverview {
  const WordSetOverview({required this.set, required this.pairCount});

  final WordSet set;
  final int pairCount;
}

class WordMatchSetsState {
  const WordMatchSetsState({required this.sets, required this.canCreateMore});

  final List<WordSetOverview> sets;
  final bool canCreateMore;
}

class WordMatchSetsController
    extends AutoDisposeAsyncNotifier<WordMatchSetsState> {
  WordMatchRepoInterface? _repo;
  StreamSubscription<List<WordSet>>? _subscription;

  @override
  Future<WordMatchSetsState> build() async {
    // Retry mechanism for repository initialization
    for (var attempt = 0; attempt < 3; attempt++) {
      try {
        final repo = await _ensureRepo();

        // Ensure built-in sets exist on first access
        await repo.ensureBuiltinSet();
        try {
          await repo.ensureWordsFromGamesSet();
        } catch (e) {
          // Log error but don't fail initialization
          debugPrint('Warning: Failed to ensure Words from Games set: $e');
        }

        // Wait a bit more to ensure Isar is fully ready
        await Future.delayed(const Duration(milliseconds: 300));

        final setsStream = repo.watchSets();
        
        // Use Completer to get initial value from single stream subscription
        final completer = Completer<List<WordSet>>();
        bool initialValueReceived = false;
        
        _subscription = setsStream.listen(
          (sets) {
            // First value completes the completer, subsequent values update state
            if (!initialValueReceived) {
              initialValueReceived = true;
              if (!completer.isCompleted) {
                completer.complete(sets);
              }
            } else {
              // Update state for subsequent values
              unawaited(_syncSets(sets));
            }
          },
          onError: (error, stackTrace) {
            if (!completer.isCompleted) {
              completer.completeError(error, stackTrace);
            }
            state = AsyncValue.error(error, stackTrace);
          },
          cancelOnError: false,
        );

        ref.onDispose(() {
          _subscription?.cancel();
        });

        // Wait for initial value with timeout
        final initialSets = await completer.future.timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            throw TimeoutException('Sets stream timeout');
          },
        );

        return _mapToState(initialSets);
      } catch (e) {
        if (attempt < 2) {
          // Reset repo to force re-initialization
          _repo = null;
          _subscription?.cancel();
          _subscription = null;
          await Future.delayed(Duration(milliseconds: 500 * (attempt + 1)));
          continue;
        }
        rethrow;
      }
    }
    throw StateError('Failed to initialize sets controller');
  }

  Future<WordMatchSetsState> _mapToState(List<WordSet> sets) async {
    final repo = await _ensureRepo();
    final counts = await repo.countPairsForSets(sets.map((s) => s.id).toList());
    final overview = sets
        .map((set) => WordSetOverview(set: set, pairCount: counts[set.id] ?? 0))
        .toList(growable: false);

    return WordMatchSetsState(
      sets: overview,
      canCreateMore: sets.length < WordMatchRepoInterface.maxSets,
    );
  }

  Future<void> _syncSets(List<WordSet> sets) async {
    final nextState = await _mapToState(sets);
    state = AsyncValue.data(nextState);
  }

  Future<int> createSet(String name) async {
    final repo = await _ensureRepo();
    return repo.createSet(name);
  }

  Future<void> deleteSet(int id) async {
    final repo = await _ensureRepo();
    await repo.deleteSet(id);
  }

  Future<void> renameSet({required int id, required String name}) async {
    final repo = await _ensureRepo();
    await repo.renameSet(id: id, name: name);
  }

  Future<WordMatchRepoInterface> _ensureRepo() async {
    final existing = _repo;
    if (existing != null) {
      return existing;
    }
    final repo = await ref.watch(wordMatchRepoProvider.future);
    _repo = repo;
    return repo;
  }
}

final wordMatchSetsControllerProvider = AutoDisposeAsyncNotifierProvider<
  WordMatchSetsController,
  WordMatchSetsState
>(WordMatchSetsController.new);
