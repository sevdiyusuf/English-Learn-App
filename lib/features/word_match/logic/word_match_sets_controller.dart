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
  Timer? _streamStartTimer;

  @override
  Future<WordMatchSetsState> build() async {
    try {
      // Timeout ile sınırlandırılmış repo initialization - APK için daha kısa
      final repo = await _ensureRepo().timeout(
        const Duration(seconds: 12), // APK için daha kısa timeout
        onTimeout: () {
          debugPrint(
            'ERROR: Repository initialization timeout after 12 seconds',
          );
          throw TimeoutException(
            'Repository initialization timeout after 12 seconds. '
            'Setler yüklenemedi - lütfen uygulamayı yeniden başlatın.',
            const Duration(seconds: 12),
          );
        },
      );

      // Ensure built-in sets exist on first access - timeout ile
      await repo.ensureBuiltinSet().timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          throw TimeoutException('ensureBuiltinSet timeout');
        },
      );

      // Ensure A1, A2, B1, B2 level sets
      await repo.ensureLevelSets().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          debugPrint('Warning: ensureLevelSets timeout');
        },
      );

      try {
        await repo.ensureWordsFromGamesSet().timeout(
          const Duration(seconds: 5),
          onTimeout: () {
            throw TimeoutException('ensureWordsFromGamesSet timeout');
          },
        );
      } catch (e) {
        debugPrint('Warning: Failed to ensure Words from Games set: $e');
        // Continue - bu kritik değil
      }

      // Fix any incorrect built-in sets (user request: only 2 specific sets should be built-in)
      await repo.fixBuiltinSets();

      // Ensure initial user set exists
      await repo.ensureInitialUserSet();

      final setsStream = repo.watchSets();

      // Use Completer to get initial value from single stream subscription
      final completer = Completer<List<WordSet>>();
      bool initialValueReceived = false;
      Timer? timeoutTimer;

      // Stream'in başlaması için timeout - eğer 3 saniye içinde ilk değer gelmezse hata ver
      _streamStartTimer = Timer(const Duration(seconds: 3), () {
        if (!initialValueReceived && !completer.isCompleted) {
          debugPrint('ERROR: Stream did not emit any value within 3 seconds');
          _subscription?.cancel();
          completer.completeError(
            TimeoutException(
              'Sets stream did not emit any value within 3 seconds. '
              'Veritabanından setler okunamadı.',
            ),
          );
        }
      });

      _subscription = setsStream.listen(
        (sets) {
          _streamStartTimer?.cancel();
          timeoutTimer?.cancel();
          // First value completes the completer, subsequent values update state
          if (!initialValueReceived) {
            initialValueReceived = true;
            debugPrint('First sets value received: ${sets.length} sets');
            if (!completer.isCompleted) {
              completer.complete(sets);
            }
          } else {
            // Update state for subsequent values
            unawaited(_syncSets(sets));
          }
        },
        onError: (error, stackTrace) {
          _streamStartTimer?.cancel();
          timeoutTimer?.cancel();
          debugPrint('ERROR: Sets stream error: $error');
          if (!completer.isCompleted) {
            completer.completeError(error, stackTrace);
          }
          state = AsyncValue.error(error, stackTrace);
        },
        cancelOnError: false,
      );

      ref.onDispose(() {
        _streamStartTimer?.cancel();
        timeoutTimer?.cancel();
        _subscription?.cancel();
      });

      // Timeout timer - 8 saniye sonra hata ver (APK için daha kısa)
      timeoutTimer = Timer(const Duration(seconds: 8), () {
        if (!completer.isCompleted) {
          debugPrint('ERROR: Sets stream timeout after 8 seconds');
          _subscription?.cancel();
          completer.completeError(
            TimeoutException(
              'Sets stream timeout after 8 seconds. '
              'Veritabanından setler okunamadı.',
            ),
          );
        }
      });

      // Wait for initial value with timeout (APK için daha kısa)
      final initialSets = await completer.future.timeout(
        const Duration(seconds: 8),
        onTimeout: () {
          debugPrint('ERROR: Sets stream timeout waiting for initial value');
          _subscription?.cancel();
          throw TimeoutException(
            'Sets stream timeout after 8 seconds. '
            'Veritabanından setler okunamadı. Lütfen uygulamayı yeniden başlatın.',
          );
        },
      );

      return _mapToState(initialSets);
    } catch (e, stackTrace) {
      debugPrint('WordMatchSetsController build failed: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<WordMatchSetsState> _mapToState(List<WordSet> sets) async {
    final repo = await _ensureRepo();
    final counts = await repo.countPairsForSets(sets.map((s) => s.id).toList());

    // Create overview list
    final overview =
        sets.map((set) {
          return WordSetOverview(set: set, pairCount: counts[set.id] ?? 0);
        }).toList();

    // Sort: "Words from Games" always at the top, then by updatedAt
    overview.sort((a, b) {
      if (a.set.name == WordMatchRepoInterface.wordsFromGamesSetName) return -1;
      if (b.set.name == WordMatchRepoInterface.wordsFromGamesSetName) return 1;
      return b.set.updatedAt.compareTo(a.set.updatedAt);
    });

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
    final id = await repo.createSet(name);
    return id;
  }

  Future<void> deleteSet(int id) async {
    final repo = await _ensureRepo();
    await repo.deleteSet(id);
  }

  Future<void> renameSet({required int id, required String name}) async {
    final repo = await _ensureRepo();
    await repo.renameSet(id: id, name: name);
  }

  /// Merge two sets into a new set with [newName].
  ///
  /// Keeps the original sets as they are and creates a third combined set.
  /// Delegates to repo.mergeSetsIntoNewSet so Isar can do everything in one transaction.
  Future<int> mergeSets({
    required int baseSetId,
    required int otherSetId,
    required String newName,
  }) async {
    final repo = await _ensureRepo();
    final baseSet = await repo.getSet(baseSetId);
    final otherSet = await repo.getSet(otherSetId);
    if (baseSet == null || otherSet == null) {
      throw StateError('Birleştirilecek setlerden biri bulunamadı');
    }
    final newId = await repo.mergeSetsIntoNewSet(
      baseSetId: baseSetId,
      otherSetId: otherSetId,
      newName: newName,
    );
    return newId;
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
