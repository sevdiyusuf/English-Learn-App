import '../models/outbox_item.dart';

enum CoalesceAction {
  createFresh,
  updateExisting,
  duplicateIgnored,
  rejectDeleted,
}

class CoalesceResult {
  const CoalesceResult({
    required this.action,
    this.updatedItem,
    this.rejectionReason,
  });

  final CoalesceAction action;
  final OutboxItem? updatedItem;
  final String? rejectionReason;
}

/// Pure domain helper that computes outbox coalescing logic for sequential operations on the same entity.
class OutboxCoalescer {
  /// Builds a deterministic coalescing key for an entity within owner scope.
  static String buildCoalescingKey(
    String? ownerUid,
    String entityType,
    String entityId,
  ) {
    final scopePrefix =
        ownerUid != null && ownerUid.isNotEmpty ? ownerUid : 'guest';
    return '${scopePrefix}_${entityType}_$entityId';
  }

  /// Computes the coalescing result when an incoming operation is enqueued for an entity.
  static CoalesceResult coalesce({
    required OutboxItem? activeItem,
    required OutboxOperationType incomingOperation,
    required String? incomingPayloadJson,
    required int incomingLocalVersion,
    int? incomingRemoteVersion,
    required DateTime now,
    String? incomingOperationId,
  }) {
    // If no existing active operation exists, create fresh
    if (activeItem == null) {
      return const CoalesceResult(action: CoalesceAction.createFresh);
    }

    // Duplicate operation ID check
    if (incomingOperationId != null &&
        activeItem.operationId == incomingOperationId) {
      return CoalesceResult(
        action: CoalesceAction.duplicateIgnored,
        updatedItem: activeItem,
      );
    }

    // Active item is already synced: new mutation should create fresh item with new operationId
    if (activeItem.syncStatus == OutboxSyncStatus.synced) {
      return const CoalesceResult(action: CoalesceAction.createFresh);
    }

    // Active item is pending delete / tombstone
    if (activeItem.operation == OutboxOperationType.delete ||
        activeItem.isTombstone) {
      if (incomingOperation == OutboxOperationType.delete) {
        // Delete + Delete -> Duplicate delete ignored
        return CoalesceResult(
          action: CoalesceAction.duplicateIgnored,
          updatedItem: activeItem,
        );
      } else {
        // Pending delete + Create/Update -> Rejection (no silent resurrection)
        return const CoalesceResult(
          action: CoalesceAction.rejectDeleted,
          rejectionReason:
              'Silinmiş entity üzerinde izinsiz güncelleme/oluşturma yapılamaz.',
        );
      }
    }

    // Active item is pending create
    if (activeItem.operation == OutboxOperationType.create) {
      if (incomingOperation == OutboxOperationType.update) {
        // pendingCreate + update -> single pendingCreate with updated payload/version
        activeItem.payloadJson = incomingPayloadJson;
        activeItem.localVersion = incomingLocalVersion;
        activeItem.remoteVersion =
            incomingRemoteVersion ?? activeItem.remoteVersion;
        activeItem.updatedAt = now;
        activeItem.syncStatus = OutboxSyncStatus.pending;
        return CoalesceResult(
          action: CoalesceAction.updateExisting,
          updatedItem: activeItem,
        );
      } else if (incomingOperation == OutboxOperationType.delete) {
        // pendingCreate + delete -> single pendingDelete (tombstone)
        activeItem.operation = OutboxOperationType.delete;
        activeItem.payloadJson = null;
        activeItem.isTombstone = true;
        activeItem.deletedAt = now;
        activeItem.localVersion = incomingLocalVersion;
        activeItem.remoteVersion =
            incomingRemoteVersion ?? activeItem.remoteVersion;
        activeItem.updatedAt = now;
        activeItem.syncStatus = OutboxSyncStatus.pending;
        return CoalesceResult(
          action: CoalesceAction.updateExisting,
          updatedItem: activeItem,
        );
      } else if (incomingOperation == OutboxOperationType.create) {
        // pendingCreate + create -> update payload to new create payload
        activeItem.payloadJson = incomingPayloadJson;
        activeItem.localVersion = incomingLocalVersion;
        activeItem.remoteVersion =
            incomingRemoteVersion ?? activeItem.remoteVersion;
        activeItem.updatedAt = now;
        activeItem.syncStatus = OutboxSyncStatus.pending;
        return CoalesceResult(
          action: CoalesceAction.updateExisting,
          updatedItem: activeItem,
        );
      }
    }

    // Active item is pending update
    if (activeItem.operation == OutboxOperationType.update) {
      if (incomingOperation == OutboxOperationType.update ||
          incomingOperation == OutboxOperationType.create) {
        // pendingUpdate + update -> single pendingUpdate with updated payload/version
        activeItem.payloadJson = incomingPayloadJson;
        activeItem.localVersion = incomingLocalVersion;
        activeItem.remoteVersion =
            incomingRemoteVersion ?? activeItem.remoteVersion;
        activeItem.updatedAt = now;
        activeItem.syncStatus = OutboxSyncStatus.pending;
        return CoalesceResult(
          action: CoalesceAction.updateExisting,
          updatedItem: activeItem,
        );
      } else if (incomingOperation == OutboxOperationType.delete) {
        // pendingUpdate + delete -> single pendingDelete (tombstone)
        activeItem.operation = OutboxOperationType.delete;
        activeItem.payloadJson = null;
        activeItem.isTombstone = true;
        activeItem.deletedAt = now;
        activeItem.localVersion = incomingLocalVersion;
        activeItem.remoteVersion =
            incomingRemoteVersion ?? activeItem.remoteVersion;
        activeItem.updatedAt = now;
        activeItem.syncStatus = OutboxSyncStatus.pending;
        return CoalesceResult(
          action: CoalesceAction.updateExisting,
          updatedItem: activeItem,
        );
      }
    }

    return const CoalesceResult(action: CoalesceAction.createFresh);
  }
}
