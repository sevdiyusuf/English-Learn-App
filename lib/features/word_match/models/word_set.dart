import 'package:isar/isar.dart';

part 'word_set.g.dart';

@collection
class WordSet {
  Id id = Isar.autoIncrement;

  late String name;
  late DateTime createdAt;
  late DateTime updatedAt;

  /// Updated when a practice session is completed.
  DateTime? lastPracticedAt;

  /// Whether this is a built-in set that cannot be deleted.
  bool isBuiltin = false;
}
