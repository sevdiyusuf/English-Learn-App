import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/training_models.dart';

final trainingRepoProvider = Provider<TrainingRepository>((ref) {
  return TrainingRepository();
});

class TrainingRepository {
  Map<String, List<WorksheetMetadata>>? _indexCache;
  final Map<String, Worksheet> _worksheetCache = {};

  Future<Map<String, List<WorksheetMetadata>>> loadIndex() async {
    if (_indexCache != null) return _indexCache!;

    try {
      final jsonString = await rootBundle.loadString(
        'assets/worksheets/index.json',
      );
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      final levels = json['levels'] as Map<String, dynamic>;
      final prefs = await SharedPreferences.getInstance();

      final result = <String, List<WorksheetMetadata>>{};
      levels.forEach((level, list) {
        if (list is List) {
          result[level] =
              list.map((e) {
                final id = e['worksheet_id'] as String;
                final score = prefs.getInt('training_score_$id');

                // Parse title and tags for cleaner UI
                String rawTitle = e['title'] as String? ?? '';
                final currentTags =
                    (e['tags'] as List<dynamic>?)
                        ?.map((t) => t.toString())
                        .toList() ??
                    [];

                // Extract text inside ONLY the LAST parentheses group if it exists at the end
                final regex = RegExp(r'\s*\(([^)]*)\)$');
                final match = regex.firstMatch(rawTitle);

                if (match != null) {
                  final content = match.group(1);
                  if (content != null && content.trim().isNotEmpty) {
                    currentTags.add(content.trim());
                  }
                }

                // Remove ONLY the last parentheses group from title
                String cleanTitle = rawTitle.replaceAll(regex, '').trim();

                // Use the cleaned data
                final modifiedJson = Map<String, dynamic>.from(e);
                modifiedJson['title'] = cleanTitle;
                modifiedJson['tags'] = currentTags;

                return WorksheetMetadata.fromJson(
                  modifiedJson,
                  level,
                  bestScore: score,
                );
              }).toList();
        }
      });

      _indexCache = result;
      return result;
    } catch (e) {
      debugPrint('Error loading training index: $e');
      rethrow;
    }
  }

  Future<Worksheet> loadWorksheet(String path) async {
    if (_worksheetCache.containsKey(path)) {
      return _worksheetCache[path]!;
    }

    try {
      final fullPath = 'assets/worksheets/$path';
      final jsonString = await rootBundle.loadString(fullPath);
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      final worksheet = Worksheet.fromJson(json);

      _worksheetCache[path] = worksheet;
      return worksheet;
    } catch (e) {
      debugPrint('Error loading worksheet $path: $e');
      rethrow;
    }
  }

  Future<void> saveScore(String worksheetId, int score) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'training_score_$worksheetId';
    final currentBest = prefs.getInt(key) ?? 0;
    if (score > currentBest) {
      await prefs.setInt(key, score);
      // Invalidate cache so that UI updates on next load
      _indexCache = null;
    }
  }
}
