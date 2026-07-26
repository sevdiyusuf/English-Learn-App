import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/errors/app_failure.dart';
import '../data/firestore_sync_gateway.dart';
import '../data/outbox_repository.dart';
import '../domain/sync_conflict_resolver.dart';
import '../domain/sync_retry_policy.dart';
import '../models/outbox_item.dart';

enum PushOperationStatus {
  synced,
  alreadyApplied,
  conflict,
  retryScheduled,
  permanentFailure,
  cancelled,
}

class PushOperationResult {
  const PushOperationResult({
    required this.operationId,
    required this.status,
    this.remoteVersion,
    this.errorMessage,
    this.conflictDetails,
  });

  final String operationId;
  final PushOperationStatus status;
  final int? remoteVersion;
  final String? errorMessage;
  final String? conflictDetails;
}

class PushSyncResult {
  const PushSyncResult({
    required this.ownerUid,
    required this.results,
    required this.hasMorePending,
  });

  final String ownerUid;
  final List<PushOperationResult> results;
  final bool hasMorePending;
}

class PushSyncService {
  PushSyncService({
    required OutboxRepository outboxRepository,
    required FirestoreSyncGateway gateway,
    SyncRetryPolicy? retryPolicy,
    String? Function()? activeAuthenticatedUidFetcher,
  }) : _outboxRepo = outboxRepository,
       _gateway = gateway,
       _retryPolicy = retryPolicy ?? SyncRetryPolicy(),
       _activeAuthenticatedUidFetcher = activeAuthenticatedUidFetcher;

  final OutboxRepository _outboxRepo;
  final FirestoreSyncGateway _gateway;
  final SyncRetryPolicy _retryPolicy;
  final String? Function()? _activeAuthenticatedUidFetcher;

  static final Map<String, bool> _activeDrains = {};

  Future<PushSyncResult> pushOnce({
    required String? ownerUid,
    int batchLimit = 10,
  }) async {
    if (ownerUid == null || ownerUid.isEmpty) {
      throw AppFailure.auth(
        message:
            'Guest / unauthenticated scope için push işlemi çalıştırılamaz.',
      );
    }

    if (_activeAuthenticatedUidFetcher != null) {
      final currentAuth = _activeAuthenticatedUidFetcher();
      if (currentAuth == null || currentAuth != ownerUid) {
        throw AppFailure.auth(
          message:
              'Aktif oturum UID ($currentAuth) ile ownerUid ($ownerUid) eşleşmiyor.',
        );
      }
    }

    if (_activeDrains[ownerUid] == true) {
      debugPrint(
        'PushSyncService: Drain already in progress for $ownerUid, skipping duplicate concurrent push.',
      );
      return PushSyncResult(
        ownerUid: ownerUid,
        results: const [],
        hasMorePending: true,
      );
    }

    _activeDrains[ownerUid] = true;
    final results = <PushOperationResult>[];
    bool hasMore = false;

    try {
      final pendingOps = await _outboxRepo.getPendingOperations(
        ownerUid: ownerUid,
      );

      final opsToProcess = pendingOps.take(batchLimit).toList();
      hasMore = pendingOps.length > batchLimit;

      for (final op in opsToProcess) {
        // Verify session before each operation
        if (_activeAuthenticatedUidFetcher != null) {
          final currentAuth = _activeAuthenticatedUidFetcher();
          if (currentAuth != ownerUid) {
            results.add(
              PushOperationResult(
                operationId: op.operationId,
                status: PushOperationStatus.cancelled,
                errorMessage: 'Session changed during push.',
              ),
            );
            break;
          }
        }

        final itemResult = await _processSingleOperation(ownerUid, op);
        results.add(itemResult);
      }
    } finally {
      _activeDrains.remove(ownerUid);
    }

    return PushSyncResult(
      ownerUid: ownerUid,
      results: results,
      hasMorePending: hasMore,
    );
  }

  Future<PushOperationResult> _processSingleOperation(
    String ownerUid,
    OutboxItem op,
  ) async {
    // Unsupported entity check
    if (op.entityType != 'word_set') {
      await _outboxRepo.markFailedPermanent(
        operationId: op.operationId,
        errorMessage: 'Desteklenmeyen entity type: ${op.entityType}',
      );
      return PushOperationResult(
        operationId: op.operationId,
        status: PushOperationStatus.permanentFailure,
        errorMessage: 'Desteklenmeyen entity type',
      );
    }

    try {
      final decision = await _gateway.executeIdempotentTransaction(
        ownerUid: ownerUid,
        localOp: op,
      );

      switch (decision.type) {
        case ConflictDecisionType.applyMutation:
        case ConflictDecisionType.alreadyApplied:
          final ver = decision.nextRemoteVersion ?? 1;
          await _outboxRepo.markSynced(
            operationId: op.operationId,
            remoteVersion: ver,
          );
          return PushOperationResult(
            operationId: op.operationId,
            status:
                decision.type == ConflictDecisionType.alreadyApplied
                    ? PushOperationStatus.alreadyApplied
                    : PushOperationStatus.synced,
            remoteVersion: ver,
          );

        case ConflictDecisionType.conflict:
          final reason =
              decision.conflictReason ?? 'Veri çatışması tespit edildi.';
          await _outboxRepo.markConflict(
            operationId: op.operationId,
            conflictDetails: reason,
          );
          return PushOperationResult(
            operationId: op.operationId,
            status: PushOperationStatus.conflict,
            conflictDetails: reason,
          );
      }
    } catch (e) {
      final isRetryable = FirebaseFailureClassifier.isRetryable(e);
      final newAttempt = op.attemptCount + 1;

      await _outboxRepo.updateAttempt(
        operationId: op.operationId,
        errorMessage: e.toString(),
      );

      if (isRetryable && newAttempt < _retryPolicy.maxAttempts) {
        await _outboxRepo.markFailedRetryable(
          operationId: op.operationId,
          errorMessage: e.toString(),
        );
        return PushOperationResult(
          operationId: op.operationId,
          status: PushOperationStatus.retryScheduled,
          errorMessage: e.toString(),
        );
      } else {
        await _outboxRepo.markFailedPermanent(
          operationId: op.operationId,
          errorMessage: e.toString(),
        );
        return PushOperationResult(
          operationId: op.operationId,
          status: PushOperationStatus.permanentFailure,
          errorMessage: e.toString(),
        );
      }
    }
  }
}
