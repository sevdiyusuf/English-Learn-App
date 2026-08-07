import 'package:isar/isar.dart';

import 'word_set_web.dart';

export 'word_set_web.dart' show SetVisibility;

part 'word_set_io.g.dart';

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

  /// Owner user ID for local multi-user isolation.
  /// - null: Guest set
  /// - String: Signed-in user's Firebase Auth UID
  @Index()
  String? ownerUid;

  /// UID of the user for whom migration was initiated but not yet completed.
  /// Prevents another user account from claiming a guest set whose migration failed previously.
  String? pendingMigrationUid;

  /// Metadata for imported sets
  String? sourceSetId;
  String? sourceOwnerUid;
  DateTime? importedAt;

  // ── Sprint 4E: Sync metadata fields ─────────────────────────────────────

  /// The remote version last applied from Firestore.
  /// Used to detect stale remote updates and avoid rolling back local state.
  /// Null for guest sets and sets never synced.
  int? remoteVersion;

  /// The operationId of the last operation successfully applied from remote.
  /// Used for echo detection: if a remote doc's lastOperationId matches this,
  /// we already applied it and the incoming change is an idempotent echo.
  String? lastRemoteOperationId;
}
