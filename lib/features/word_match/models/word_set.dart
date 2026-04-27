import 'package:isar/isar.dart';

part 'word_set.g.dart';

enum SetVisibility { private, friendsOnly, public }

@collection
@Name("WordSet319")
class WordSet {
  Id id = Isar.autoIncrement;

  late String name;
  late DateTime createdAt;
  late DateTime updatedAt;

  /// Updated when a practice session is completed.
  DateTime? lastPracticedAt;

  /// Whether this is a built-in set that cannot be deleted.
  bool isBuiltin = false;

  /// Firestore ID for synchronization
  String? cloudId;

  /// Visibility of the set (Phase 2)
  @enumerated
  SetVisibility visibility = SetVisibility.private;

  /// Metadata for imported sets
  String? sourceSetId;
  String? sourceOwnerUid;
  DateTime? importedAt;
}
