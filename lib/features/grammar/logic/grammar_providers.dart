import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/grammar_repository.dart';
import '../models/grammar_models.dart';

final grammarRepositoryProvider = Provider<GrammarRepository>((ref) {
  return GrammarRepository();
});

final lessonIndexProvider = FutureProvider<LessonIndex>((ref) async {
  final repository = ref.watch(grammarRepositoryProvider);
  return repository.loadIndex();
});

final lessonDocProvider = FutureProvider.family<LessonDoc, String>((ref, lessonId) async {
  final index = await ref.watch(lessonIndexProvider.future);
  final repository = ref.watch(grammarRepositoryProvider);
  
  // Find lesson path from index
  String? path;
  for (var lessons in index.lessonsByLevel.values) {
    for (var lesson in lessons) {
      if (lesson.lessonId == lessonId) {
        path = lesson.path;
        break;
      }
    }
    if (path != null) break;
  }

  if (path == null) {
    throw Exception('Lesson with ID $lessonId not found in index');
  }

  return repository.loadLesson(path);
});

// State for Lesson Viewer
final currentCardIndexProvider = StateProvider.family<int, String>((ref, lessonId) => 0);

// State for Story Viewer
final currentStoryItemIndexProvider = StateProvider.family<int, String>((ref, lessonId) => 0);
final storyScoreProvider = StateProvider.family<int, String>((ref, lessonId) => 0);
