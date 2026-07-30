import '../models/idempotency_receipt.dart';
import '../models/outbox_item.dart';
import 'word_set_sync_codec.dart';

enum ConflictDecisionType { applyMutation, alreadyApplied, conflict }

class ConflictDecision {
  const ConflictDecision({
    required this.type,
    this.nextRemoteVersion,
    this.conflictReason,
    this.expectedRemoteVersion,
    this.actualRemoteVersion,
  });

  final ConflictDecisionType type;
  final int? nextRemoteVersion;
  final String? conflictReason;
  final int? expectedRemoteVersion;
  final int? actualRemoteVersion;
}

class SyncConflictResolver {
  static ConflictDecision resolve({
    required OutboxItem localOp,
    required RemoteDocumentData? remoteDoc,
    required IdempotencyReceipt? existingReceipt,
  }) {
    // 1. Idempotency Receipt Check: If this operationId has already been applied, return alreadyApplied
    if (existingReceipt != null) {
      return ConflictDecision(
        type: ConflictDecisionType.alreadyApplied,
        nextRemoteVersion: existingReceipt.appliedRemoteVersion,
      );
    }

    // 2. Also check lastOperationId on remote doc
    if (remoteDoc != null && remoteDoc.lastOperationId == localOp.operationId) {
      return ConflictDecision(
        type: ConflictDecisionType.alreadyApplied,
        nextRemoteVersion: remoteDoc.remoteVersion,
      );
    }

    final localOperation = localOp.operation;

    // 3. CREATE operation
    if (localOperation == OutboxOperationType.create) {
      if (remoteDoc == null) {
        return const ConflictDecision(
          type: ConflictDecisionType.applyMutation,
          nextRemoteVersion: 1,
        );
      } else {
        // Live document or tombstone already exists under this entity ID -> Conflict
        return ConflictDecision(
          type: ConflictDecisionType.conflict,
          conflictReason:
              remoteDoc.isTombstone
                  ? 'Remote tombstone exists for pending create.'
                  : 'Remote live document already exists for pending create.',
          expectedRemoteVersion: 0,
          actualRemoteVersion: remoteDoc.remoteVersion,
        );
      }
    }

    // 4. UPDATE operation
    if (localOperation == OutboxOperationType.update) {
      if (remoteDoc == null) {
        return ConflictDecision(
          type: ConflictDecisionType.conflict,
          conflictReason:
              'Remote document does not exist for update operation.',
          expectedRemoteVersion: localOp.remoteVersion ?? 1,
          actualRemoteVersion: 0,
        );
      }

      if (remoteDoc.isTombstone) {
        return ConflictDecision(
          type: ConflictDecisionType.conflict,
          conflictReason: 'Remote document was deleted (tombstone exists).',
          expectedRemoteVersion: localOp.remoteVersion ?? 1,
          actualRemoteVersion: remoteDoc.remoteVersion,
        );
      }

      final expectedVer = localOp.remoteVersion ?? (remoteDoc.remoteVersion);
      if (remoteDoc.remoteVersion != expectedVer) {
        return ConflictDecision(
          type: ConflictDecisionType.conflict,
          conflictReason:
              'Remote version mismatch. Expected $expectedVer, found ${remoteDoc.remoteVersion}.',
          expectedRemoteVersion: expectedVer,
          actualRemoteVersion: remoteDoc.remoteVersion,
        );
      }

      return ConflictDecision(
        type: ConflictDecisionType.applyMutation,
        nextRemoteVersion: remoteDoc.remoteVersion + 1,
      );
    }

    // 5. DELETE operation
    if (localOperation == OutboxOperationType.delete) {
      if (remoteDoc == null) {
        // Safe tombstone creation
        return const ConflictDecision(
          type: ConflictDecisionType.applyMutation,
          nextRemoteVersion: 1,
        );
      }

      if (remoteDoc.isTombstone) {
        // Already tombstone -> Idempotent success
        return ConflictDecision(
          type: ConflictDecisionType.alreadyApplied,
          nextRemoteVersion: remoteDoc.remoteVersion,
        );
      }

      final expectedVer = localOp.remoteVersion ?? (remoteDoc.remoteVersion);
      if (remoteDoc.remoteVersion > expectedVer) {
        return ConflictDecision(
          type: ConflictDecisionType.conflict,
          conflictReason:
              'Remote document has a newer version (${remoteDoc.remoteVersion} > $expectedVer).',
          expectedRemoteVersion: expectedVer,
          actualRemoteVersion: remoteDoc.remoteVersion,
        );
      }

      return ConflictDecision(
        type: ConflictDecisionType.applyMutation,
        nextRemoteVersion: remoteDoc.remoteVersion + 1,
      );
    }

    return const ConflictDecision(
      type: ConflictDecisionType.conflict,
      conflictReason: 'Unsupported operation type.',
    );
  }
}
