import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/cargo_service.dart';
import '../models/cargo_categories_state.dart';
import '../models/cargo_word.dart';

class CargoCategoriesController extends StateNotifier<CargoCategoriesState> {
  CargoCategoriesController() : super(const CargoCategoriesState()) {
    _initialize();
  }

  Timer? _gameTimer;
  DateTime? _gameStartTime;

  Future<void> _initialize() async {
    await CargoService.instance.loadData();
  }

  void selectGameLevel(GameLevel level) {
    state = state.copyWith(selectedGameLevel: level);
  }

  void selectDifficulty(Difficulty difficulty) {
    state = state.copyWith(selectedDifficulty: difficulty);
  }

  /// Start a new game: randomly select 3 categories based on game level and 4 words per category
  void startGame() {
    if (!state.canStartGame) return;

    try {
      // Create a new Random instance with current time as seed for better randomization
      final gameRandom = Random(DateTime.now().millisecondsSinceEpoch);

      // 1. Select 3 categories based on game level
      final levelString = state.selectedGameLevel.name;
      final chosenCategories = CargoService.instance.getRandomCategoriesByLevel(
        levelString,
        gameRandom,
      );

      // 2. For each category, get 4 random words
      final allWords = <CargoWord>[];
      for (final category in chosenCategories) {
        final words = CargoService.instance.getRandomWordsFromCategory(
          category.id,
          4,
          gameRandom,
        );
        allWords.addAll(words);
      }

      // 3. Shuffle all 12 words multiple times for better randomization
      for (int i = 0; i < 3; i++) {
        allWords.shuffle(gameRandom);
      }

      // 4. Initialize 3 empty columns
      final columns = List.generate(3, (_) => const CargoColumn());

      _gameStartTime = DateTime.now();

      state = state.copyWith(
        chosenCategories: chosenCategories,
        remainingOnBelt: allWords,
        columns: columns,
        isRunning: true,
        isFinished: false,
        showSolution: false,
        isRegrouping: false,
        hasWon: false,
        elapsedTime: Duration.zero,
      );

      // Start timer
      _gameTimer?.cancel();
      _gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted || !state.isRunning || state.isFinished) {
          timer.cancel();
          return;
        }
        if (_gameStartTime != null) {
          final elapsed = DateTime.now().difference(_gameStartTime!);
          state = state.copyWith(elapsedTime: elapsed);
        }
      });

      // 5. Load first word onto conveyor
      // Use Future.microtask with a small delay to ensure state is fully updated
      // This is especially important on web where state updates might be async
      // Pass allWords directly to avoid reading stale state
      Future.microtask(() {
        // Small delay to ensure state update is processed on web
        Future.delayed(const Duration(milliseconds: 50), () {
          if (mounted && state.isRunning && !state.isFinished) {
            debugPrint(
              'startGame: Loading first word. allWords.length: ${allWords.length}, state.remainingOnBelt.length: ${state.remainingOnBelt.length}',
            );
            // Always use allWords to ensure we have all 12 words
            // This avoids reading stale state on web, especially on first load
            loadNextWord(remainingBelt: allWords, totalPlacedOverride: 0);
          }
        });
      });
    } catch (e) {
      debugPrint('Error starting game: $e');
    }
  }

  /// Load next word from belt onto conveyor
  void loadNextWord({
    List<CargoWord>? remainingBelt,
    int? totalPlacedOverride,
  }) {
    // Use override if provided, otherwise read from state
    // This ensures we use the correct totalPlaced value even if state hasn't updated yet
    final totalPlaced = totalPlacedOverride ?? state.totalWordsPlaced;
    final belt = remainingBelt ?? state.remainingOnBelt;

    debugPrint(
      'loadNextWord: Called with totalPlaced: $totalPlaced, belt.length: ${belt.length}, currentWord: ${state.currentWord?.word}',
    );

    // Check if all 12 words are placed in columns AND belt is empty
    // Only stop loading if both conditions are met
    if (totalPlaced >= 12 && belt.isEmpty) {
      // All words are placed in columns and belt is empty, no need to load more
      state = state.copyWith(currentWord: null);
      debugPrint(
        'loadNextWord: All 12 words placed in columns and belt is empty. Current word cleared.',
      );
      return;
    }

    // If belt is empty but not all words are placed, wait for timeout words
    // BUT: Don't clear currentWord if it exists - it might be the last word that needs to be shown
    // IMPORTANT: Only return early if currentWord is NOT null (meaning a word is already on the belt)
    // If currentWord is null and belt is empty, we should wait for timeout words
    if (belt.isEmpty) {
      // No more words in belt, but not all are placed yet
      // This means all words are either placed or timed out
      // Timeout words will be added back by handleTimeout()
      if (state.currentWord == null) {
        // Current word is null and belt is empty - wait for timeout words
        // Don't clear currentWord again, just wait
        debugPrint(
          'loadNextWord: Belt is empty but $totalPlaced/12 words placed. Current word is null, waiting for timeout words.',
        );
      } else {
        // Current word exists, keep it - it will timeout or be placed
        // Don't return here - let the word be shown
        debugPrint(
          'loadNextWord: Belt is empty but $totalPlaced/12 words placed. Current word ${state.currentWord?.word} is still on belt, waiting for timeout words.',
        );
        // Don't return - the current word should be shown
        return;
      }
      return;
    }

    final word = belt.first;
    final newRemaining = List<CargoWord>.from(belt)..removeAt(0);

    state = state.copyWith(currentWord: word, remainingOnBelt: newRemaining);

    debugPrint(
      'loadNextWord: Loaded ${word.word}, remaining: ${newRemaining.length}, placed: $totalPlaced/12',
    );

    // CRITICAL: After loading a word, if remaining is 0 and not all words are placed,
    // we should NOT stop - timeout words will be added back by handleTimeout()
    // The word is now loaded and will be shown, timeout will handle adding it back if needed

    // IMPORTANT: If this is the last word (remaining: 0, totalPlaced: 11),
    // and it times out, handleTimeout will add it back and call loadNextWord again
    // But we need to ensure that if the word is placed, we don't try to load again
    // The word is now in currentWord and will be shown on the conveyor
  }

  /// Handle timeout - put the timed-out word back to the end of the belt
  void handleTimeout(CargoWord timedOutWord) {
    if (!state.isRunning || state.isFinished || state.isRegrouping) return;

    // Check if the word is already in a column (shouldn't happen, but safety check)
    bool wordAlreadyPlaced = false;
    for (final column in state.columns) {
      if (column.words.any((w) => w.word == timedOutWord.word)) {
        wordAlreadyPlaced = true;
        break;
      }
    }

    if (wordAlreadyPlaced) {
      debugPrint(
        'handleTimeout: ${timedOutWord.word} is already placed, ignoring timeout',
      );
      // Just try to load next word
      final totalPlaced = state.totalWordsPlaced;
      if (state.remainingOnBelt.isNotEmpty && totalPlaced < 12) {
        loadNextWord(totalPlacedOverride: totalPlaced);
      }
      return;
    }

    // Get current total placed count
    final totalPlaced = state.totalWordsPlaced;

    // Even if all 12 words are placed, if this word timed out, it means it wasn't actually placed
    // So we should add it back to the belt and try to load it again
    // Only skip if the word is already in a column (checked above)

    // Put the timed-out word back to the end of remainingOnBelt
    // Check if it's already in remainingOnBelt (shouldn't be, but check anyway)
    final newRemaining = List<CargoWord>.from(state.remainingOnBelt);
    if (!newRemaining.any((w) => w.word == timedOutWord.word)) {
      newRemaining.add(timedOutWord);
    }

    debugPrint(
      'handleTimeout: ${timedOutWord.word} timed out, added back to belt. Remaining: ${newRemaining.length}, placed: $totalPlaced/12',
    );

    // CRITICAL: Even if this is the last word (totalPlaced: 11), we need to ensure it gets reloaded
    // The word is now in newRemaining and will be loaded by loadNextWord

    // Clear current word if it matches the timed-out word
    // IMPORTANT: Always clear currentWord when a word times out, so it can be reloaded
    // This ensures ConveyorArea detects the change and restarts animation
    final newCurrentWord =
        state.currentWord?.word == timedOutWord.word ? null : state.currentWord;

    // Update state first to clear currentWord
    state = state.copyWith(
      currentWord: newCurrentWord,
      remainingOnBelt: newRemaining,
    );

    // Always try to load next word if there are words remaining
    // This ensures that even if currentWord is not null, we still load the next word from the belt
    // This is especially important when the last word times out
    // Use a longer delay to ensure state is fully updated and ConveyorArea detects the change
    Future.delayed(const Duration(milliseconds: 50), () {
      if (mounted &&
          state.isRunning &&
          !state.isFinished &&
          !state.isRegrouping) {
        // Double check total placed hasn't changed
        final currentTotalPlaced = state.totalWordsPlaced;
        final currentRemaining = state.remainingOnBelt;
        final currentCurrentWord = state.currentWord;

        // Always try to load next word if there are words remaining
        // Even if totalPlaced >= 12, the timed-out word might need to be shown again
        // CRITICAL: Always load if currentWord is null, regardless of totalPlaced
        // This ensures the last word that times out will be reloaded
        if (currentRemaining.isNotEmpty && currentCurrentWord == null) {
          debugPrint(
            'handleTimeout: Loading next word after timeout (currentWord is null). Remaining: ${currentRemaining.length}, placed: $currentTotalPlaced/12',
          );
          loadNextWord(
            remainingBelt: currentRemaining,
            totalPlacedOverride: currentTotalPlaced,
          );
        } else if (currentRemaining.isNotEmpty && currentCurrentWord != null) {
          // Current word is not null, but we have words in the belt
          // This can happen if a word times out while another word is on the belt
          // We should wait for the current word to be placed or timeout first
          debugPrint(
            'handleTimeout: Current word ${currentCurrentWord.word} is still on belt, but ${currentRemaining.length} words in remaining belt. Will load after current word is handled.',
          );
        } else if (currentRemaining.isEmpty &&
            currentCurrentWord == null &&
            currentTotalPlaced < 12) {
          // Belt is empty, currentWord is null, but not all words placed
          // This should not happen if all words are either placed or timed out
          // But if it does, we should wait for timeout words
          debugPrint(
            'handleTimeout: Remaining belt is empty but $currentTotalPlaced/12 placed. Current word is null. Waiting for more timeout words.',
          );
        } else {
          debugPrint(
            'handleTimeout: Remaining belt is empty but $currentTotalPlaced/12 placed. Current word ${currentCurrentWord?.word} exists. Waiting for more timeout words.',
          );
        }
      }
    });
  }

  /// Handle word dropped from conveyor belt to a column
  void dropWordToColumn(CargoWord word, int columnIndex) {
    debugPrint(
      'dropWordToColumn: Called for ${word.word} to column $columnIndex. isRunning: ${state.isRunning}, isFinished: ${state.isFinished}, isRegrouping: ${state.isRegrouping}',
    );

    if (!state.isRunning || state.isFinished || state.isRegrouping) {
      debugPrint(
        'dropWordToColumn: Early return - game not running/finished/regrouping',
      );
      return;
    }
    if (columnIndex < 0 || columnIndex >= 3) {
      debugPrint('dropWordToColumn: Early return - invalid column index');
      return;
    }

    final columns = List<CargoColumn>.from(state.columns);
    final targetColumn = columns[columnIndex];

    // Check if word is already in a column (being moved between columns)
    bool isMovingBetweenColumns = false;
    int? fromColumnIndex;
    for (int i = 0; i < columns.length; i++) {
      if (columns[i].words.any((w) => w.word == word.word)) {
        isMovingBetweenColumns = true;
        fromColumnIndex = i;
        break;
      }
    }

    if (isMovingBetweenColumns && fromColumnIndex != null) {
      // This is handled by moveWordBetweenColumns
      moveWordBetweenColumns(word, fromColumnIndex, columnIndex);
      return;
    }

    // Add word to column
    final newWords = List<CargoWord>.from(targetColumn.words)..add(word);
    columns[columnIndex] = targetColumn.copyWith(words: newWords);

    // Remove word from belt (either current word or remaining)
    final newRemaining = List<CargoWord>.from(state.remainingOnBelt);
    CargoWord? newCurrentWord = state.currentWord;
    bool shouldLoadNext = false;

    if (state.currentWord?.word == word.word) {
      // Current word was dropped, clear it and load next
      newCurrentWord = null;
      shouldLoadNext = true;
      debugPrint(
        'dropWordToColumn: Current word ${word.word} dropped, will load next. Remaining: ${newRemaining.length}',
      );
    } else {
      // Remove from remaining belt
      newRemaining.removeWhere((w) => w.word == word.word);
      debugPrint(
        'dropWordToColumn: Word ${word.word} from belt dropped. Remaining: ${newRemaining.length}, currentWord: ${newCurrentWord?.word}',
      );

      // If currentWord exists and is not in any column, add it back to belt and load next
      // This ensures continuous flow - if user drops a word from remainingOnBelt,
      // we should also clear the currentWord and load next
      if (newCurrentWord != null) {
        final currentWordRef =
            newCurrentWord; // Save reference before potentially nulling
        // Check if currentWord is already in a column
        bool currentWordInColumn = false;
        for (final column in columns) {
          if (column.words.any((w) => w.word == currentWordRef.word)) {
            currentWordInColumn = true;
            break;
          }
        }

        if (!currentWordInColumn &&
            !newRemaining.any((w) => w.word == currentWordRef.word)) {
          // CurrentWord is not in any column and not in remainingOnBelt, add it back
          newRemaining.add(currentWordRef);
          newCurrentWord = null;
          shouldLoadNext = true;
          debugPrint(
            'dropWordToColumn: Current word ${currentWordRef.word} was not placed, added back to belt. Will load next.',
          );
        }
      }

      // Always try to load next word if there are words remaining and not all placed
      final totalPlaced = columns.fold<int>(
        0,
        (sum, col) => sum + col.words.length,
      );
      if (totalPlaced < 12 && newRemaining.isNotEmpty && !shouldLoadNext) {
        // If currentWord is null now, we can load next immediately
        if (newCurrentWord == null) {
          shouldLoadNext = true;
          debugPrint(
            'dropWordToColumn: Current word is null, will load next from remaining belt',
          );
        }
      }
    }

    // Additional check: if currentWord is in a column, clear it
    if (newCurrentWord != null) {
      bool currentWordAlreadyPlaced = false;
      for (final column in columns) {
        if (column.words.any((w) => w.word == newCurrentWord!.word)) {
          currentWordAlreadyPlaced = true;
          break;
        }
      }

      if (currentWordAlreadyPlaced) {
        debugPrint(
          'dropWordToColumn: Current word ${newCurrentWord.word} is already placed, clearing it',
        );
        newCurrentWord = null;
        shouldLoadNext = true;
      }
    }

    state = state.copyWith(
      currentWord: newCurrentWord,
      remainingOnBelt: newRemaining,
      columns: columns,
    );

    // Load next word if current was dropped
    // Continue loading even if remainingOnBelt is empty, as timeout words will be added back
    if (shouldLoadNext) {
      // Calculate total placed with updated columns
      final totalPlaced = columns.fold<int>(
        0,
        (sum, col) => sum + col.words.length,
      );

      // Use a microtask to ensure state is updated before loading next word
      // Pass the updated remaining list directly to avoid reading stale state
      Future.microtask(() {
        debugPrint(
          'dropWordToColumn: Future.microtask executing. mounted: $mounted, isRunning: ${state.isRunning}, isFinished: ${state.isFinished}, isRegrouping: ${state.isRegrouping}, totalPlaced: $totalPlaced, newRemaining: ${newRemaining.length}',
        );

        if (!mounted) {
          debugPrint('dropWordToColumn: Not mounted, skipping loadNextWord');
          return;
        }

        if (!state.isRunning || state.isFinished || state.isRegrouping) {
          debugPrint(
            'dropWordToColumn: Game not running/finished/regrouping, skipping loadNextWord',
          );
          return;
        }

        // Check if all words are placed (use the calculated value, not state)
        // Always try to load next word if there are words remaining, even if totalPlaced >= 12
        // This handles the case where the last word times out and needs to be reloaded
        if (newRemaining.isNotEmpty) {
          debugPrint(
            'dropWordToColumn: Loading next word, remaining: ${newRemaining.length}, placed: $totalPlaced/12',
          );
          // Pass totalPlaced to ensure correct value is used
          loadNextWord(
            remainingBelt: newRemaining,
            totalPlacedOverride: totalPlaced,
          );
        } else if (totalPlaced < 12) {
          // Belt is empty but not all words placed
          // This means all remaining words are either placed or timed out
          // Clear current word - timeout words will trigger handleTimeout() which will reload them
          debugPrint(
            'dropWordToColumn: Belt empty but $totalPlaced/12 placed. Waiting for timeout words.',
          );
          // Current word is already null from state update above
        } else {
          debugPrint(
            'dropWordToColumn: All words placed ($totalPlaced/12) and belt is empty. Not loading next word.',
          );
        }
      });
    }
  }

  /// Move word from one column to another
  void moveWordBetweenColumns(
    CargoWord word,
    int fromColumnIndex,
    int toColumnIndex,
  ) {
    if (!state.isRunning || state.isFinished || state.isRegrouping) return;
    if (fromColumnIndex < 0 || fromColumnIndex >= 3) return;
    if (toColumnIndex < 0 || toColumnIndex >= 3) return;
    if (fromColumnIndex == toColumnIndex) return;

    final columns = List<CargoColumn>.from(state.columns);
    final fromColumn = columns[fromColumnIndex];
    final toColumn = columns[toColumnIndex];

    // Remove from source column
    final fromWords = List<CargoWord>.from(fromColumn.words)
      ..removeWhere((w) => w.word == word.word);
    columns[fromColumnIndex] = fromColumn.copyWith(words: fromWords);

    // Add to target column
    final toWords = List<CargoWord>.from(toColumn.words)..add(word);
    columns[toColumnIndex] = toColumn.copyWith(words: toWords);

    // Update state but preserve currentWord and remainingOnBelt
    // This ensures the conveyor belt continues working
    // Don't pass currentWord or remainingOnBelt to copyWith - they will be preserved automatically
    state = state.copyWith(columns: columns);

    debugPrint(
      'moveWordBetweenColumns: Moved ${word.word} from column $fromColumnIndex to $toColumnIndex. Current word: ${state.currentWord?.word}',
    );
  }

  /// Check if the player's grouping is correct
  void checkSolution() {
    if (!state.canCheck) {
      debugPrint('Cannot check: not all words placed');
      return;
    }

    // Calculate score BEFORE regrouping (using original user placement)
    // Check each column: if all words in the column have the same category, it's correct
    int correctCount = 0;
    int wrongCount = 0;

    for (int i = 0; i < 3; i++) {
      final column = state.columns[i];
      if (column.words.isNotEmpty) {
        final firstCategory = column.words.first.category;
        final allSameCategory = column.words.every(
          (w) => w.category == firstCategory,
        );

        if (allSameCategory) {
          correctCount++;
        } else {
          wrongCount++;
        }
      }
    }

    // Calculate score based on correct count:
    // 3 correct = 100 points
    // 2 correct = 66 points
    // 1 correct = 50 points
    // 0 correct = 0 points
    int calculatedScore;
    switch (correctCount) {
      case 3:
        calculatedScore = 100;
        break;
      case 2:
        calculatedScore = 66;
        break;
      case 1:
        calculatedScore = 50;
        break;
      default:
        calculatedScore = 0;
    }

    // Save score and counts to state BEFORE regrouping
    state = state.copyWith(
      finalScore: calculatedScore,
      finalCorrectCount: correctCount,
      finalWrongCount: wrongCount,
    );

    // For each column, check if all words belong to the same category
    final columnCategories = <String?>[];
    bool allCorrect = true;

    for (int i = 0; i < 3; i++) {
      final column = state.columns[i];
      if (column.words.isEmpty) {
        allCorrect = false;
        columnCategories.add(null);
        continue;
      }

      // Get the category of the first word
      final firstCategory = column.words.first.category;

      // Check if all words have the same category
      final allSameCategory = column.words.every(
        (w) => w.category == firstCategory,
      );

      if (allSameCategory) {
        columnCategories.add(firstCategory);
      } else {
        allCorrect = false;
        columnCategories.add(null);
      }
    }

    if (allCorrect) {
      // Player wins!
      state = state.copyWith(
        isFinished: true,
        isRunning: false,
        hasWon: true,
        showSolution: true,
      );
    } else {
      // Player loses - regroup words into correct columns
      _regroupWords();
    }
  }

  /// Regroup words into correct columns based on their actual categories
  void _regroupWords() {
    state = state.copyWith(isRegrouping: true);

    // Collect all words from all columns
    final allWords = <CargoWord>[];
    for (final column in state.columns) {
      allWords.addAll(column.words);
    }

    // Group words by their actual category
    final wordsByCategory = <String, List<CargoWord>>{};
    for (final word in allWords) {
      wordsByCategory.putIfAbsent(word.category, () => []).add(word);
    }

    // Create new columns with correct grouping
    final newColumns = <CargoColumn>[];
    for (int i = 0; i < 3; i++) {
      final category = state.chosenCategories[i];
      final words = wordsByCategory[category.id] ?? [];
      newColumns.add(CargoColumn(words: words));
    }

    // After animation delay, update state
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        state = state.copyWith(
          columns: newColumns,
          isRegrouping: false,
          isFinished: true,
          isRunning: false,
          showSolution: true,
          hasWon: false,
        );
      }
    });
  }

  void reset() {
    _gameTimer?.cancel();
    _gameTimer = null;
    _gameStartTime = null;
    state = const CargoCategoriesState(
      selectedGameLevel: GameLevel.beginner,
      selectedDifficulty: Difficulty.normal,
      finalScore: null,
      finalCorrectCount: null,
      finalWrongCount: null,
    );
  }

  @override
  void dispose() {
    _gameTimer?.cancel();
    super.dispose();
  }
}

final cargoCategoriesControllerProvider =
    StateNotifierProvider<CargoCategoriesController, CargoCategoriesState>(
      (ref) => CargoCategoriesController(),
    );
