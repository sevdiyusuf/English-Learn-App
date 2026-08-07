import 'dart:convert';
import 'package:isar/isar.dart';

import 'outbox_item_web.dart';

export 'outbox_item_web.dart' show OutboxOperationType, OutboxSyncStatus;

part 'outbox_item_io.g.dart';

@collection
@Name("OutboxItem1")
class OutboxItem {
  Id id = Isar.autoIncrement;

  /// Unique operation identifier for idempotency
  @Index(unique: true, replace: false)
  late String operationId;

  /// Type of entity being synced (e.g. 'word_set', 'word_pair')
  late String entityType;

  /// Identifier of entity (e.g. '101')
  late String entityId;

  /// Deterministic scope/coalescing key for identifying active operations
  /// on the same entity within owner scope. Format: "${ownerUid ?? 'guest'}_${entityType}_${entityId}"
  @Index()
  late String coalescingKey;

  /// Owner user ID for local multi-user isolation.
  /// - null: Guest record
  /// - String: Signed-in user's Firebase Auth UID
  @Index()
  String? ownerUid;

  /// Operation type (create, update, delete)
  @enumerated
  late OutboxOperationType operation;

  /// Current synchronization status
  @enumerated
  @Index()
  OutboxSyncStatus syncStatus = OutboxSyncStatus.pending;

  /// Local entity version
  int localVersion = 1;

  /// Remote version from cloud service if known
  int? remoteVersion;

  /// Record creation timestamp
  late DateTime createdAt;

  /// Record last update timestamp
  late DateTime updatedAt;

  /// Timestamp of the last sync attempt
  DateTime? lastAttemptAt;

  /// Number of sync attempts made so far
  int attemptCount = 0;

  /// Soft deletion timestamp for tombstone records
  DateTime? deletedAt;

  /// Whether this entry serves as a tombstone
  bool isTombstone = false;

  /// Error message summary from the last attempt
  String? lastErrorMessage;

  /// Error code from the last attempt
  String? lastErrorCode;

  /// Details of conflict resolution if syncStatus == OutboxSyncStatus.conflict
  String? conflictDetails;

  /// Serialized JSON payload for create/update snapshots
  String? payloadJson;

  /// Helper getter to decode payload JSON as a Map
  @ignore
  Map<String, dynamic>? get payload {
    if (payloadJson == null || payloadJson!.isEmpty) return null;
    try {
      return jsonDecode(payloadJson!) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  /// Helper setter to encode Map payload into JSON
  set payload(Map<String, dynamic>? value) {
    if (value == null) {
      payloadJson = null;
    } else {
      payloadJson = jsonEncode(value);
    }
  }
}
