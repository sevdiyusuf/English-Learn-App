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
      final jsonString =
          await rootBundle.loadString('assets/cargo_categories.json');
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
            final wordsList = (categoryMap['words'] as List<dynamic>)
                .map((wordItem) {
                  final wordMap = wordItem as Map<String, dynamic>;
                  return CargoWord.fromJson({
                    'word': wordMap['english'],
                    'translate': wordMap['turkish'],
                    'category': category.id,
                  });
                })
                .toList();
            _wordsByCategory![category.id] = wordsList;
          }
        }
      }

      if (kDebugMode) {
        debugPrint('Loaded cargo data: ${_categories?.length} categories');
        debugPrint('Total words: ${_wordsByCategory?.values.fold<int>(0, (sum, list) => sum + list.length)}');
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
}
