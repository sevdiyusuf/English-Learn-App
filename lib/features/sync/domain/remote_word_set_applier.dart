import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/errors/app_failure.dart';
import '../../word_match/data/word_match_repo_interface.dart';
import '../../word_match/models/word_pair.dart';
import '../../word_match/models/word_set.dart';
import '../data/outbox_repository.dart';
import '../domain/word_set_sync_codec.dart';
import '../models/outbox_item.dart';

/// Result of applying a single remote document locally.
enum ApplyOutcome {
  /// Document was applied (create or update).
  applied,

  /// Document was skipped because it was stale or idempotent.
  skipped,

  /// A pending local operation was put into conflict state.
  conflict,

  /// Apply failed with an error; other documents should still be processed.
  failed,
}

class DocumentApplyResult {
  const DocumentApplyResult({
    required this.document,
    required this.outcome,
    this.error,
  });

  final RemoteDocumentData document;
  final ApplyOutcome outcome;
  final Object? error;

  bool get success =>
      outcome == ApplyOutcome.applied || outcome == ApplyOutcome.skipped;
}

/// Applies pages of remote [RemoteDocumentData] to the local [WordMatchRepoInterface].
///
/// This is the ONLY path that writes remote changes to local storage.
/// It does NOT produce Outbox operations — remote apply is always internal-origin.
///
/// Owner/session validation is checked before each document.
/// A single document failure does NOT abort the rest of the page.
class RemoteWordSetApplier {
  RemoteWordSetApplier({
    required WordMatchRepoInterface localRepo,
    required OutboxRepository outboxRepo,
    required String? Function() activeUidFetcher,
  }) : _localRepo = localRepo,
       _outboxRepo = outboxRepo,
       _activeUidFetcher = activeUidFetcher;

  final WordMatchRepoInterface _localRepo;
  final OutboxRepository _outboxRepo;
  final String? Function() _activeUidFetcher;

  static const String _entityType = 'word_set';

  /// Applies a page of remote documents to local storage.
  ///
  /// Returns the last *successfully processed* document (applied or skipped),
  /// which the caller should use as the checkpoint anchor.
  ///
  /// If the session becomes stale mid-page, throws [AppFailure.auth].
  /// Individual document errors are logged and skipped; the last successfully
  /// processed document is still returned.
  Future<RemoteDocumentData?> applyPage({
    required String ownerUid,
    required List<RemoteDocumentData> changes,
  }) async {
    if (ownerUid.isEmpty) {
      throw AppFailure.auth(
        message: 'Guest scope için RemoteWordSetApplier çalıştırılamaz.',
      );
    }

    RemoteDocumentData? lastSuccessful;

    for (final doc in changes) {
      // Session guard before each document
      final currentAuth = _activeUidFetcher();
      if (currentAuth != ownerUid) {
        throw AppFailure.auth(
          message:
              'Session değişti — apply durduruldu. '
              'Beklenen: $ownerUid, Aktif: $currentAuth',
        );
      }

      // Owner guard: only process documents belonging to this owner
      if (doc.ownerUid != ownerUid) {
        debugPrint(
          'RemoteWordSetApplier: Skipping doc ${doc.entityId} — '
          'ownerUid mismatch (doc=${doc.ownerUid}, session=$ownerUid)',
        );
        lastSuccessful =
            doc; // Advance cursor even if skipped (wrong-owner docs are stable)
        continue;
      }

      try {
        final outcome = await _applyDocument(ownerUid: ownerUid, doc: doc);
        if (outcome == ApplyOutcome.applied ||
            outcome == ApplyOutcome.skipped ||
            outcome == ApplyOutcome.conflict) {
          lastSuccessful = doc;
        }
        // ApplyOutcome.failed → do not advance cursor beyond this doc.
      } catch (e, stack) {
        debugPrint(
          'RemoteWordSetApplier: Error applying doc ${doc.entityId}: $e\n$stack',
        );
        // Do NOT set lastSuccessful — checkpoint should not advance past failed doc.
      }
    }

    return lastSuccessful;
  }

  Future<ApplyOutcome> _applyDocument({
    required String ownerUid,
    required RemoteDocumentData doc,
  }) async {
    final entityId = doc.entityId;

    // Find local entity by cloudId (entityId == Firestore document ID)
    final existingSet = await _localRepo.getSetByCloudId(entityId);

    // Check for pending local operations on this entity
    final pendingOps = await _outboxRepo.getPendingOperations(
      ownerUid: ownerUid,
    );
    final pendingForEntity =
        pendingOps
            .where(
              (op) => op.entityId == entityId && op.entityType == _entityType,
            )
            .toList();

    // Echo detection: remote lastOperationId matches a locally-known operationId
    // This means we pushed this operation and it bounced back — idempotent skip.
    final localSyncedOp =
        pendingForEntity
            .where(
              (op) =>
                  op.syncStatus == OutboxSyncStatus.synced &&
                  op.operationId == doc.lastOperationId,
            )
            .firstOrNull;
    if (localSyncedOp != null) {
      debugPrint(
        'RemoteWordSetApplier: Echo detected for ${doc.entityId} '
        '(lastOperationId=${doc.lastOperationId}) — skip.',
      );
      return ApplyOutcome.skipped;
    }

    if (doc.isTombstone) {
      return _applyTombstone(
        ownerUid: ownerUid,
        doc: doc,
        existingSet: existingSet,
        pendingForEntity: pendingForEntity,
      );
    } else {
      return _applyLiveDocument(
        ownerUid: ownerUid,
        doc: doc,
        existingSet: existingSet,
        pendingForEntity: pendingForEntity,
      );
    }
  }

  Future<ApplyOutcome> _applyLiveDocument({
    required String ownerUid,
    required RemoteDocumentData doc,
    required WordSet? existingSet,
    required List<OutboxItem> pendingForEntity,
  }) async {
    final activePending =
        pendingForEntity
            .where(
              (op) =>
                  op.syncStatus == OutboxSyncStatus.pending ||
                  op.syncStatus == OutboxSyncStatus.failedRetryable,
            )
            .firstOrNull;

    if (existingSet != null) {
      // Stale/equal version check: never roll back local state
      final localRemoteVersion = _getLocalRemoteVersion(existingSet);
      if (localRemoteVersion != null &&
          doc.remoteVersion <= localRemoteVersion) {
        debugPrint(
          'RemoteWordSetApplier: Stale remote (remote=${doc.remoteVersion}, '
          'local=$localRemoteVersion) for ${doc.entityId} — skip.',
        );
        return ApplyOutcome.skipped;
      }

      // Conflict detection: newer remote with pending local operation
      if (activePending != null) {
        final conflictReason =
            'Remote version ${doc.remoteVersion} conflicts with '
            'pending ${activePending.operation.name} '
            '(operationId=${activePending.operationId}).';
        await _outboxRepo.markConflict(
          operationId: activePending.operationId,
          conflictDetails: conflictReason,
        );
        debugPrint(
          'RemoteWordSetApplier: Conflict for ${doc.entityId} — $conflictReason',
        );
        // Do NOT overwrite local state when there is a pending user mutation.
        return ApplyOutcome.conflict;
      }
    }

    // Apply: create or update local set from remote data
    await _writeLocalSet(
      ownerUid: ownerUid,
      doc: doc,
      existingSet: existingSet,
    );
    return ApplyOutcome.applied;
  }

  Future<ApplyOutcome> _applyTombstone({
    required String ownerUid,
    required RemoteDocumentData doc,
    required WordSet? existingSet,
    required List<OutboxItem> pendingForEntity,
  }) async {
    if (existingSet == null) {
      // Already removed locally — idempotent
      return ApplyOutcome.skipped;
    }

    final activePending =
        pendingForEntity
            .where(
              (op) =>
                  op.syncStatus == OutboxSyncStatus.pending ||
                  op.syncStatus == OutboxSyncStatus.failedRetryable,
            )
            .firstOrNull;

    if (activePending != null) {
      // Remote tombstone vs pending local update/create → conflict.
      // Do NOT silently delete local user content.
      final conflictReason =
          'Remote tombstone conflicts with pending '
          '${activePending.operation.name} '
          '(operationId=${activePending.operationId}).';
      await _outboxRepo.markConflict(
        operationId: activePending.operationId,
        conflictDetails: conflictReason,
      );
      debugPrint(
        'RemoteWordSetApplier: Tombstone conflict for ${doc.entityId} — $conflictReason',
      );
      return ApplyOutcome.conflict;
    }

    // Safe to remove local cache entry (local cache cleanup only;
    // Firestore tombstone document is NOT physically deleted).
    debugPrint(
      'RemoteWordSetApplier: Applying tombstone for ${doc.entityId} — removing local set.',
    );
    await _localRepo.deleteSet(existingSet.id);
    return ApplyOutcome.applied;
  }

  Future<void> _writeLocalSet({
    required String ownerUid,
    required RemoteDocumentData doc,
    required WordSet? existingSet,
  }) async {
    final payload = doc.payload;
    final name = (payload?['name'] as String?) ?? '';
    final createdAtStr = payload?['createdAt'] as String?;
    final updatedAtStr = payload?['updatedAt'] as String?;
    final visibilityStr = payload?['visibility'] as String? ?? 'private';
    final pairsList = (payload?['pairs'] as List<dynamic>?) ?? [];
    final sourceSetId = payload?['sourceSetId'] as String?;
    final sourceOwnerUid = payload?['sourceOwnerUid'] as String?;
    final importedAtStr = payload?['importedAt'] as String?;

    final visibility = SetVisibility.values.firstWhere(
      (e) => e.name == visibilityStr,
      orElse: () => SetVisibility.private,
    );

    final pairs =
        pairsList.map((p) {
          final m = p as Map<String, dynamic>;
          return WordPair()
            ..setId = 0
            ..english = (m['english'] as String?) ?? ''
            ..turkish = (m['turkish'] as String?) ?? ''
            ..learned = (m['learned'] as bool?) ?? false;
        }).toList();

    int setId;
    if (existingSet != null) {
      setId = existingSet.id;
      if (name.isNotEmpty && existingSet.name != name) {
        await _localRepo.renameSetInternal(id: setId, name: name);
      }
    } else {
      // New local set from remote
      setId = await _localRepo.createSetInternal(
        name: name.isNotEmpty ? name : doc.entityId,
        ownerUid: ownerUid,
        cloudId: doc.entityId,
      );
    }

    // Sync metadata fields
    await _localRepo.updateSetRemoteMetadata(
      setId,
      cloudId: doc.entityId,
      ownerUid: ownerUid,
      remoteVersion: doc.remoteVersion,
      lastOperationId: doc.lastOperationId,
      visibility: visibility,
      sourceSetId: sourceSetId,
      sourceOwnerUid: sourceOwnerUid,
      importedAt:
          importedAtStr != null ? DateTime.tryParse(importedAtStr) : null,
      updatedAt: updatedAtStr != null ? DateTime.tryParse(updatedAtStr) : null,
      createdAt: createdAtStr != null ? DateTime.tryParse(createdAtStr) : null,
    );

    // Replace pairs (remote is source of truth for pairs)
    await _localRepo.savePairsInternal(setId: setId, pairs: pairs);
  }

  int? _getLocalRemoteVersion(WordSet set) {
    // WordSet stores remoteVersion in a dedicated field added by Sprint 4E
    return set.remoteVersion;
  }
}
