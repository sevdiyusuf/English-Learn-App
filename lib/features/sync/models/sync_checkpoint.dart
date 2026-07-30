import 'package:isar/isar.dart';

part 'sync_checkpoint.g.dart';

@collection
@Name("SyncCheckpoint1")
class SyncCheckpoint {
  Id id = Isar.autoIncrement;

  /// Unique checkpoint key per owner and entity type.
  /// Format: "${ownerUid}_${entityType}"
  @Index(unique: true, replace: true)
  late String checkpointKey;

  /// Owner user ID for local multi-user isolation.
  @Index()
  late String ownerUid;

  /// Type of entity synced (e.g. 'word_set')
  late String entityType;

  /// Last server update timestamp received from remote query
  DateTime? lastServerUpdatedAt;

  /// Document ID tie-breaker for deterministic pagination when timestamps match
  String? tieBreakerDocId;

  /// Timestamp when checkpoint was updated locally
  late DateTime updatedAt;
}
