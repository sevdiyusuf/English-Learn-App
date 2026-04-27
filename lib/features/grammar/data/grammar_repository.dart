import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/grammar_models.dart';

class GrammarRepository {
  static const String _indexPath = 'assets/lessons/index.json';
  static const String _basePath = 'assets/lessons/';

  LessonIndex? _cachedIndex;

  Future<LessonIndex> loadIndex() async {
    if (_cachedIndex != null) return _cachedIndex!;
    
    try {
      final String content = await rootBundle.loadString(_indexPath);
      final Map<String, dynamic> json = jsonDecode(content);
      _cachedIndex = LessonIndex.fromJson(json);
      return _cachedIndex!;
    } catch (e) {
      throw Exception('Failed to load lesson index: $e');
    }
  }

  Future<LessonDoc> loadLesson(String path) async {
    try {
      final String fullPath = '$_basePath$path';
      final String content = await rootBundle.loadString(fullPath);
      final Map<String, dynamic> json = jsonDecode(content);
      return LessonDoc.fromJson(json);
    } catch (e) {
      throw Exception('Failed to load lesson at $path: $e');
    }
  }
}
