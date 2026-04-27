import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/training_repo.dart';
import '../models/training_models.dart';

final trainingUpdateTriggerProvider = StateProvider<int>((ref) => 0);

final trainingIndexProvider =
    FutureProvider.autoDispose<Map<String, List<WorksheetMetadata>>>((
      ref,
    ) async {
      ref.watch(trainingUpdateTriggerProvider);
      final repo = ref.watch(trainingRepoProvider);
      return repo.loadIndex();
    });
