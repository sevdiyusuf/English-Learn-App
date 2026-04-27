import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../training/data/training_repo.dart';
import '../../../training/models/training_models.dart';

final worksheetCatalogRepoProvider = Provider((ref) {
  return WorksheetCatalogRepo(ref.read(trainingRepoProvider));
});

class WorksheetCatalogRepo {
  final TrainingRepository _trainingRepo;

  WorksheetCatalogRepo(this._trainingRepo);

  Future<Map<String, List<WorksheetMetadata>>> getCatalog() {
    return _trainingRepo.loadIndex();
  }

  Future<Worksheet> loadWorksheet(String path) {
    return _trainingRepo.loadWorksheet(path);
  }

  Future<WorksheetMetadata?> getRandomWorksheetForLevel(String level) async {
    final index = await getCatalog();
    final list = index[level];
    if (list == null || list.isEmpty) return null;
    return list[Random().nextInt(list.length)];
  }
}
