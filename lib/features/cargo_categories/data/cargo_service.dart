import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart' hide Category;
import 'package:flutter/services.dart';

import '../models/cargo_word.dart';
import '../models/category.dart';

class CargoService {
  CargoService._();
  static final CargoService instance = CargoService._();

  List<Category>? _categories;
  Map<String, List<CargoWord>>? _wordsByCategory;

  // Default colors for categories if not provided in JSON
  static const Map<String, String> _defaultColors = {
    'food': '#F4A261',
    'travel': '#2A9D8F',
    'feelings': '#E76F51',
    'house': '#264653',
    'school': '#E9C46A',
    'nature': '#7FB069',
    'clothes': '#8B5CF6',
  };

  Future<void> loadData() async {
    if (_categories != null && _wordsByCategory != null) {
      return; // Already loaded
    }

    try {
      final jsonString = await rootBundle.loadString(
        'assets/cargo_categories.json',
      );
      final jsonMap = json.decode(jsonString) as Map<String, dynamic>;

      _categories = <Category>[];
      _wordsByCategory = <String, List<CargoWord>>{};

      // Load categories and their words
      if (jsonMap['categories'] != null) {
        final categoriesList = jsonMap['categories'] as List<dynamic>;

        for (final categoryItem in categoriesList) {
          final categoryMap = categoryItem as Map<String, dynamic>;

          // Add default color if not present
          if (categoryMap['color'] == null) {
            final id = categoryMap['id'] as String;
            categoryMap['color'] = _defaultColors[id] ?? '#9CA3AF';
          }

          final category = Category.fromJson(categoryMap);
          _categories!.add(category);

          // Load words from this category
          if (categoryMap['words'] != null) {
            final wordsList =
                (categoryMap['words'] as List<dynamic>).map((wordItem) {
                  final wordMap = wordItem as Map<String, dynamic>;
                  return CargoWord.fromJson({
                    'word': wordMap['english'],
                    'translate': wordMap['turkish'],
                    'category': category.id,
                  });
                }).toList();
            _wordsByCategory![category.id] = wordsList;
          }
        }
      }

      if (kDebugMode) {
        debugPrint('Loaded cargo data: ${_categories?.length} categories');
        debugPrint(
          'Total words: ${_wordsByCategory?.values.fold<int>(0, (sum, list) => sum + list.length)}',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error loading cargo_categories.json: $e');
      }
      rethrow;
    }
  }

  List<Category> getCategories() {
    if (_categories == null) {
      throw StateError('Data not loaded. Call loadData() first.');
    }
    return _categories!;
  }

  List<CargoWord> getWordsByCategories(List<String> categoryIds) {
    if (_wordsByCategory == null) {
      throw StateError('Data not loaded. Call loadData() first.');
    }

    final result = <CargoWord>[];
    for (final categoryId in categoryIds) {
      final words = _wordsByCategory![categoryId] ?? [];
      result.addAll(words);
    }

    // Shuffle words
    result.shuffle(Random());

    return result;
  }

  Category? getCategoryById(String categoryId) {
    if (_categories == null) {
      return null;
    }
    try {
      return _categories!.firstWhere((cat) => cat.id == categoryId);
    } catch (e) {
      return null;
    }
  }

  /// Get 3 random distinct categories from all available categories
  List<Category> getRandomCategories(int count, Random random) {
    if (_categories == null) {
      throw StateError('Data not loaded. Call loadData() first.');
    }
    final allCategories = List<Category>.from(_categories!);
    allCategories.shuffle(random);
    return allCategories.take(count).toList();
  }

  /// Get categories by difficulty level
  List<Category> getCategoriesByDifficulty(String difficulty) {
    if (_categories == null) {
      throw StateError('Data not loaded. Call loadData() first.');
    }
    return _categories!.where((cat) => cat.difficulty == difficulty).toList();
  }

  /// Get 3 random categories based on game level
  /// Beginner: 2 easy + 1 medium
  /// Normal: 2 medium + 1 easy
  /// Advanced: 2 medium + 1 hard
  /// Expert: 2 hard + 1 medium
  List<Category> getRandomCategoriesByLevel(String level, Random random) {
    if (_categories == null) {
      throw StateError('Data not loaded. Call loadData() first.');
    }

    // Get categories by difficulty and create fresh shuffled copies
    final easyCategories = List<Category>.from(
      getCategoriesByDifficulty('easy'),
    );
    final mediumCategories = List<Category>.from(
      getCategoriesByDifficulty('medium'),
    );
    final hardCategories = List<Category>.from(
      getCategoriesByDifficulty('hard'),
    );

    // Shuffle each difficulty list multiple times for better randomization
    for (int i = 0; i < 3; i++) {
      easyCategories.shuffle(random);
      mediumCategories.shuffle(random);
      hardCategories.shuffle(random);
    }

    final selected = <Category>[];

    switch (level) {
      case 'beginner':
        // 2 easy + 1 medium
        if (easyCategories.length < 2 || mediumCategories.isEmpty) {
          throw StateError('Not enough categories for beginner level');
        }
        // Use random indices instead of just taking first ones
        final easyIndices = List<int>.generate(easyCategories.length, (i) => i)
          ..shuffle(random);
        final mediumIndices = List<int>.generate(
          mediumCategories.length,
          (i) => i,
        )..shuffle(random);
        selected.add(easyCategories[easyIndices[0]]);
        selected.add(easyCategories[easyIndices[1]]);
        selected.add(mediumCategories[mediumIndices[0]]);
        break;
      case 'normal':
        // 2 medium + 1 easy
        if (mediumCategories.length < 2 || easyCategories.isEmpty) {
          throw StateError('Not enough categories for normal level');
        }
        final mediumIndices = List<int>.generate(
          mediumCategories.length,
          (i) => i,
        )..shuffle(random);
        final easyIndices = List<int>.generate(easyCategories.length, (i) => i)
          ..shuffle(random);
        selected.add(mediumCategories[mediumIndices[0]]);
        selected.add(mediumCategories[mediumIndices[1]]);
        selected.add(easyCategories[easyIndices[0]]);
        break;
      case 'advanced':
        // 2 medium + 1 hard
        if (mediumCategories.length < 2 || hardCategories.isEmpty) {
          throw StateError('Not enough categories for advanced level');
        }
        final mediumIndices = List<int>.generate(
          mediumCategories.length,
          (i) => i,
        )..shuffle(random);
        final hardIndices = List<int>.generate(hardCategories.length, (i) => i)
          ..shuffle(random);
        selected.add(mediumCategories[mediumIndices[0]]);
        selected.add(mediumCategories[mediumIndices[1]]);
        selected.add(hardCategories[hardIndices[0]]);
        break;
      case 'expert':
        // 2 hard + 1 medium
        if (hardCategories.length < 2 || mediumCategories.isEmpty) {
          throw StateError('Not enough categories for expert level');
        }
        final hardIndices = List<int>.generate(hardCategories.length, (i) => i)
          ..shuffle(random);
        final mediumIndices = List<int>.generate(
          mediumCategories.length,
          (i) => i,
        )..shuffle(random);
        selected.add(hardCategories[hardIndices[0]]);
        selected.add(hardCategories[hardIndices[1]]);
        selected.add(mediumCategories[mediumIndices[0]]);
        break;
      default:
        throw StateError('Invalid game level: $level');
    }

    // Shuffle final selection multiple times for better randomization
    for (int i = 0; i < 3; i++) {
      selected.shuffle(random);
    }
    return selected;
  }

  /// Get 4 random words from a specific category
  List<CargoWord> getRandomWordsFromCategory(
    String categoryId,
    int count,
    Random random,
  ) {
    if (_wordsByCategory == null) {
      throw StateError('Data not loaded. Call loadData() first.');
    }
    final words = List<CargoWord>.from(_wordsByCategory![categoryId] ?? []);
    if (words.length < count) {
      throw StateError('Category $categoryId has fewer than $count words');
    }
    words.shuffle(random);
    return words.take(count).toList();
  }
}
