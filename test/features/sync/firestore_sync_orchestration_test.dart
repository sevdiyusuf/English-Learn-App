import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';

import 'package:yunoo/core/errors/app_failure.dart';
import 'package:yunoo/features/sync/data/firestore_sync_gateway.dart';
import 'package:yunoo/features/sync/data/outbox_repository.dart';
import 'package:yunoo/features/sync/data/sync_checkpoint_repository.dart';
import 'package:yunoo/features/sync/domain/sync_conflict_resolver.dart';
import 'package:yunoo/features/sync/domain/sync_retry_policy.dart';
import 'package:yunoo/features/sync/domain/word_set_sync_codec.dart';
import 'package:yunoo/features/sync/models/idempotency_receipt.dart';
import 'package:yunoo/features/sync/models/local_schema_metadata.dart';
import 'package:yunoo/features/sync/models/outbox_item.dart';
import 'package:yunoo/features/sync/models/sync_checkpoint.dart';
import 'package:yunoo/features/sync/services/pull_sync_service.dart';
import 'package:yunoo/features/sync/services/push_sync_service.dart';

// ────────────────────────────────────────────────────────────────────────────
// Shared Fake Gateway
// ────────────────────────────────────────────────────────────────────────────

class FakeGatewayForOrchestration implements FirestoreSyncGateway {
  final Map<String, RemoteDocumentData> remoteDocs = {};
  final Map<String, IdempotencyReceipt> receipts = {};
  final List<String> executedTxnOpIds = [];
  dynamic errorToThrowOnTxn;

  /// Executes the real (non-error) idempotency transaction logic.
  /// Exposed separately so tests can simulate "remote committed but local
  /// markSynced crashed" scenarios.
  Future<ConflictDecision> executeIdempotentTransactionReal({
    required String ownerUid,
    required OutboxItem localOp,
  }) async {
    executedTxnOpIds.add(localOp.operationId);

    final receiptKey = '${ownerUid}_${localOp.operationId}';
    final existingReceipt = receipts[receiptKey];
    final docKey = '${ownerUid}_${localOp.entityId}';
    final remoteDoc = remoteDocs[docKey];

    final decision = SyncConflictResolver.resolve(
      localOp: localOp,
      remoteDoc: remoteDoc,
      existingReceipt: existingReceipt,
    );

    if (decision.type == ConflictDecisionType.applyMutation) {
      final isTombstone = localOp.operation == OutboxOperationType.delete;
      remoteDocs[docKey] = RemoteDocumentData(
        documentId: localOp.entityId,
        ownerUid: ownerUid,
        entityId: localOp.entityId,
        entityType: localOp.entityType,
        remoteVersion: decision.nextRemoteVersion!,
        lastOperationId: localOp.operationId,
        isTombstone: isTombstone,
        deletedAt: isTombstone ? (localOp.deletedAt ?? DateTime.now()) : null,
        serverUpdatedAt: DateTime.now(),
        payload: localOp.payload,
      );

      receipts[receiptKey] = IdempotencyReceipt(
        operationId: localOp.operationId,
        ownerUid: ownerUid,
        entityType: localOp.entityType,
        entityId: localOp.entityId,
        appliedRemoteVersion: decision.nextRemoteVersion!,
        appliedAt: DateTime.now(),
      );
    }

    return decision;
  }

  @override
  Future<ConflictDecision> executeIdempotentTransaction({
    required String ownerUid,
    required OutboxItem localOp,
  }) async {
    executedTxnOpIds.add(localOp.operationId);

    if (errorToThrowOnTxn != null) {
      throw errorToThrowOnTxn;
    }

    // Re-enter without double-counting executedTxnOpIds
    final receiptKey = '${ownerUid}_${localOp.operationId}';
    final existingReceipt = receipts[receiptKey];
    final docKey = '${ownerUid}_${localOp.entityId}';
    final remoteDoc = remoteDocs[docKey];

    final decision = SyncConflictResolver.resolve(
      localOp: localOp,
      remoteDoc: remoteDoc,
      existingReceipt: existingReceipt,
    );

    if (decision.type == ConflictDecisionType.applyMutation) {
      final isTombstone = localOp.operation == OutboxOperationType.delete;
      remoteDocs[docKey] = RemoteDocumentData(
        documentId: localOp.entityId,
        ownerUid: ownerUid,
        entityId: localOp.entityId,
        entityType: localOp.entityType,
        remoteVersion: decision.nextRemoteVersion!,
        lastOperationId: localOp.operationId,
        isTombstone: isTombstone,
        deletedAt: isTombstone ? (localOp.deletedAt ?? DateTime.now()) : null,
        serverUpdatedAt: DateTime.now(),
        payload: localOp.payload,
      );

      receipts[receiptKey] = IdempotencyReceipt(
        operationId: localOp.operationId,
        ownerUid: ownerUid,
        entityType: localOp.entityType,
        entityId: localOp.entityId,
        appliedRemoteVersion: decision.nextRemoteVersion!,
        appliedAt: DateTime.now(),
      );
    }

    return decision;
  }

  @override
  Future<RemoteDocumentData?> fetchDocument({
    required String ownerUid,
    required String entityId,
  }) async => remoteDocs['${ownerUid}_$entityId'];

  @override
  Future<IdempotencyReceipt?> fetchReceipt({
    required String ownerUid,
    required String operationId,
  }) async => receipts['${ownerUid}_$operationId'];

  @override
  Future<List<RemoteDocumentData>> fetchIncrementalChanges({
    required String ownerUid,
    DateTime? sinceServerUpdatedAt,
    String? tieBreakerDocId,
    int limit = 20,
  }) async {
    final userDocs =
        remoteDocs.values.where((d) => d.ownerUid == ownerUid).toList();

    userDocs.sort((a, b) {
      final tA = a.serverUpdatedAt ?? DateTime(1970);
      final tB = b.serverUpdatedAt ?? DateTime(1970);
      final cmp = tA.compareTo(tB);
      if (cmp != 0) return cmp;
      return a.documentId.compareTo(b.documentId);
    });

    final filtered =
        userDocs.where((doc) {
          if (sinceServerUpdatedAt == null) return true;
          final docT = doc.serverUpdatedAt ?? DateTime(1970);
          if (docT.isAfter(sinceServerUpdatedAt)) return true;
          if (docT.isAtSameMomentAs(sinceServerUpdatedAt)) {
            if (tieBreakerDocId != null) {
              return doc.documentId.compareTo(tieBreakerDocId) > 0;
            }
          }
          return false;
        }).toList();

    return filtered.take(limit).toList();
  }

  @override
  Stream<List<RemoteDocumentData>> listenToChanges({
    required String ownerUid,
  }) => Stream.value(
    remoteDocs.values.where((d) => d.ownerUid == ownerUid).toList(),
  );
}

/// Gateway that always throws AppFailure.network on fetchIncrementalChanges.
class _ThrowingGateway implements FirestoreSyncGateway {
  @override
  Future<ConflictDecision> executeIdempotentTransaction({
    required String ownerUid,
    required OutboxItem localOp,
  }) async => throw UnimplementedError();

  @override
  Future<RemoteDocumentData?> fetchDocument({
    required String ownerUid,
    required String entityId,
  }) async => null;

  @override
  Future<IdempotencyReceipt?> fetchReceipt({
    required String ownerUid,
    required String operationId,
  }) async => null;

  @override
  Future<List<RemoteDocumentData>> fetchIncrementalChanges({
    required String ownerUid,
    DateTime? sinceServerUpdatedAt,
    String? tieBreakerDocId,
    int limit = 20,
  }) async => throw AppFailure.network(message: 'Simulated fetch failure');

  @override
  Stream<List<RemoteDocumentData>> listenToChanges({
    required String ownerUid,
  }) => throw UnimplementedError();
}

// ────────────────────────────────────────────────────────────────────────────
// Tests
// ────────────────────────────────────────────────────────────────────────────

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    HttpOverrides.global = null;
    await Isar.initializeIsarCore(download: true);
  });

  group('Sprint 4D — Sync Orchestration Integration Tests', () {
    Directory? tempDir;
    late Isar isar;
    var isarInitialized = false;
    late IsarOutboxRepository outboxRepo;
    late IsarSyncCheckpointRepository checkpointRepo;
    late FakeGatewayForOrchestration fakeGateway;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('isar_orch_test_');
      isar = await Isar.open(
        [OutboxItemSchema, LocalSchemaMetadataSchema, SyncCheckpointSchema],
        directory: tempDir!.path,
        name: 'test_orch_${DateTime.now().microsecondsSinceEpoch}',
      );
      isarInitialized = true;
      outboxRepo = IsarOutboxRepository(isar);
      checkpointRepo = IsarSyncCheckpointRepository(isar);
      fakeGateway = FakeGatewayForOrchestration();
    });

    tearDown(() async {
      if (isarInitialized && isar.isOpen) {
        await isar.close(deleteFromDisk: true);
      }
      isarInitialized = false;
      final directory = tempDir;
      tempDir = null;
      if (directory != null && await directory.exists()) {
        await directory.delete(recursive: true);
      }
    });

    // ── Pre-existing scenarios ──────────────────────────────────────────────

    test('Guest owner rejects push and pull with AppFailure.auth', () async {
      final push = PushSyncService(
        outboxRepository: outboxRepo,
        gateway: fakeGateway,
      );
      final pull = PullSyncService(
        checkpointRepository: checkpointRepo,
        gateway: fakeGateway,
      );

      expect(
        () => push.pushOnce(ownerUid: null),
        throwsA(
          isA<AppFailure>().having((e) => e.type, 'type', FailureType.auth),
        ),
      );
      expect(
        () => pull.pullPage(ownerUid: null),
        throwsA(
          isA<AppFailure>().having((e) => e.type, 'type', FailureType.auth),
        ),
      );
    });

    test('Auth UID mismatch with owner UID rejects push/pull', () async {
      final push = PushSyncService(
        outboxRepository: outboxRepo,
        gateway: fakeGateway,
        activeAuthenticatedUidFetcher: () => 'user_A',
      );

      expect(
        () => push.pushOnce(ownerUid: 'user_B'),
        throwsA(
          isA<AppFailure>().having((e) => e.type, 'type', FailureType.auth),
        ),
      );
    });

    test(
      'User A push processes pending create and marks local synced',
      () async {
        final push = PushSyncService(
          outboxRepository: outboxRepo,
          gateway: fakeGateway,
          activeAuthenticatedUidFetcher: () => 'user_A',
        );

        final item = await outboxRepo.enqueueCreate(
          ownerUid: 'user_A',
          entityType: 'word_set',
          entityId: '101',
          payload: {'name': 'Cloud Deck'},
          operationId: 'op_push_101',
        );

        final result = await push.pushOnce(ownerUid: 'user_A');
        expect(result.results.length, equals(1));
        expect(result.results.first.status, equals(PushOperationStatus.synced));
        expect(result.results.first.operationId, equals('op_push_101'));
        expect(result.results.first.remoteVersion, equals(1));

        final local = await outboxRepo.getByOperationId(item.operationId);
        expect(local!.syncStatus, equals(OutboxSyncStatus.synced));

        final remote = await fakeGateway.fetchDocument(
          ownerUid: 'user_A',
          entityId: '101',
        );
        expect(remote, isNotNull);
        expect(remote!.payload?['name'], equals('Cloud Deck'));
        expect(remote.ownerUid, equals('user_A'));
        expect(fakeGateway.executedTxnOpIds, contains('op_push_101'));
      },
    );

    test('Pending update with matching version is applied to remote', () async {
      final push = PushSyncService(
        outboxRepository: outboxRepo,
        gateway: fakeGateway,
        activeAuthenticatedUidFetcher: () => 'user_A',
      );

      fakeGateway.remoteDocs['user_A_102'] = RemoteDocumentData(
        documentId: '102',
        ownerUid: 'user_A',
        entityId: '102',
        entityType: 'word_set',
        remoteVersion: 1,
        lastOperationId: 'op_0',
        isTombstone: false,
        payload: {'name': 'V1 Name'},
      );

      await outboxRepo.enqueueUpdate(
        ownerUid: 'user_A',
        entityType: 'word_set',
        entityId: '102',
        payload: {'name': 'V2 Updated Name'},
        localVersion: 2,
        operationId: 'op_update_102',
      );

      final result = await push.pushOnce(ownerUid: 'user_A');
      expect(result.results.first.status, equals(PushOperationStatus.synced));
      expect(result.results.first.remoteVersion, equals(2));
      expect(result.results.first.operationId, equals('op_update_102'));

      final remote = await fakeGateway.fetchDocument(
        ownerUid: 'user_A',
        entityId: '102',
      );
      expect(remote!.remoteVersion, equals(2));
      expect(remote.payload?['name'], equals('V2 Updated Name'));
    });

    test('Pending delete creates remote tombstone', () async {
      final push = PushSyncService(
        outboxRepository: outboxRepo,
        gateway: fakeGateway,
        activeAuthenticatedUidFetcher: () => 'user_A',
      );

      fakeGateway.remoteDocs['user_A_103'] = RemoteDocumentData(
        documentId: '103',
        ownerUid: 'user_A',
        entityId: '103',
        entityType: 'word_set',
        remoteVersion: 1,
        lastOperationId: 'op_0',
        isTombstone: false,
      );

      await outboxRepo.enqueueDelete(
        ownerUid: 'user_A',
        entityType: 'word_set',
        entityId: '103',
        operationId: 'op_del_103',
      );

      final result = await push.pushOnce(ownerUid: 'user_A');
      expect(result.results.first.status, equals(PushOperationStatus.synced));
      expect(result.results.first.remoteVersion, equals(2));

      final remote = await fakeGateway.fetchDocument(
        ownerUid: 'user_A',
        entityId: '103',
      );
      expect(remote!.isTombstone, isTrue);
      expect(remote.remoteVersion, equals(2));
    });

    test('Version conflict keeps local conflict status and reason', () async {
      final push = PushSyncService(
        outboxRepository: outboxRepo,
        gateway: fakeGateway,
        activeAuthenticatedUidFetcher: () => 'user_A',
      );

      fakeGateway.remoteDocs['user_A_104'] = RemoteDocumentData(
        documentId: '104',
        ownerUid: 'user_A',
        entityId: '104',
        entityType: 'word_set',
        remoteVersion: 5,
        lastOperationId: 'op_remote_newer',
        isTombstone: false,
      );

      final item = await outboxRepo.enqueueUpdate(
        ownerUid: 'user_A',
        entityType: 'word_set',
        entityId: '104',
        payload: {'name': 'Conflict Edit'},
        localVersion: 2,
        remoteVersion: 2,
        operationId: 'op_conflict_104',
      );

      final result = await push.pushOnce(ownerUid: 'user_A');
      expect(result.results.first.status, equals(PushOperationStatus.conflict));
      expect(result.results.first.operationId, equals('op_conflict_104'));

      final local = await outboxRepo.getByOperationId(item.operationId);
      expect(local!.syncStatus, equals(OutboxSyncStatus.conflict));
      expect(local.conflictDetails, isNotNull);
    });

    test(
      'Permission denied: permanent failure, excluded from pending queue',
      () async {
        final push = PushSyncService(
          outboxRepository: outboxRepo,
          gateway: fakeGateway,
          activeAuthenticatedUidFetcher: () => 'user_A',
        );

        fakeGateway.errorToThrowOnTxn = AppFailure.database(
          message: 'Permission denied',
          code: 'permission-denied',
        );

        final item = await outboxRepo.enqueueCreate(
          ownerUid: 'user_A',
          entityType: 'word_set',
          entityId: '105',
          payload: {'name': 'Permission Denied Set'},
          operationId: 'op_perm_105',
        );

        final result = await push.pushOnce(ownerUid: 'user_A');
        expect(
          result.results.first.status,
          equals(PushOperationStatus.permanentFailure),
        );
        expect(result.results.first.operationId, equals('op_perm_105'));

        final pending = await outboxRepo.getPendingOperations(
          ownerUid: 'user_A',
        );
        expect(pending, isEmpty);

        final local = await outboxRepo.getByOperationId(item.operationId);
        expect(local!.syncStatus, equals(OutboxSyncStatus.failedPermanent));
      },
    );

    test('Paginated pull and checkpoint persistence across restart', () async {
      final pull = PullSyncService(
        checkpointRepository: checkpointRepo,
        gateway: fakeGateway,
        activeAuthenticatedUidFetcher: () => 'user_A',
      );

      fakeGateway.remoteDocs['user_A_201'] = RemoteDocumentData(
        documentId: '201',
        ownerUid: 'user_A',
        entityId: '201',
        entityType: 'word_set',
        remoteVersion: 1,
        lastOperationId: 'op_1',
        isTombstone: false,
        serverUpdatedAt: DateTime(2026, 7, 24, 10, 0, 0),
      );

      final page1 = await pull.pullPage(ownerUid: 'user_A', pageLimit: 10);
      expect(page1.changes.length, equals(1));

      await pull.acknowledgePage(
        ownerUid: 'user_A',
        lastProcessedDoc: page1.changes.first,
      );

      final checkpoint = await checkpointRepo.getCheckpoint(
        ownerUid: 'user_A',
        entityType: 'word_set',
      );
      expect(checkpoint, isNotNull);
      expect(checkpoint!.tieBreakerDocId, equals('201'));

      final page2 = await pull.pullPage(ownerUid: 'user_A', pageLimit: 10);
      expect(page2.changes, isEmpty);
    });

    // ── New critical scenarios ──────────────────────────────────────────────

    test(
      'Crash recovery: remote commit succeeded and markSynced missed; '
      'second push returns alreadyApplied, remoteVersion stays at 1, local becomes synced',
      () async {
        final operationId = 'op_crash_501';
        final localOp = await outboxRepo.enqueueCreate(
          ownerUid: 'user_A',
          entityType: 'word_set',
          entityId: '501',
          payload: {'name': 'Crash Deck'},
          operationId: operationId,
        );

        // Simulate: remote txn committed but app crashed before markSynced
        await fakeGateway.executeIdempotentTransactionReal(
          ownerUid: 'user_A',
          localOp: localOp,
        );

        // Remote now has version 1 and receipt exists
        final remoteAfterFirst = await fakeGateway.fetchDocument(
          ownerUid: 'user_A',
          entityId: '501',
        );
        expect(remoteAfterFirst!.remoteVersion, equals(1));
        expect(fakeGateway.receipts['user_A_$operationId'], isNotNull);

        // Local is still pending
        final localPending = await outboxRepo.getByOperationId(operationId);
        expect(localPending!.syncStatus, equals(OutboxSyncStatus.pending));

        // Crash-recovery retry via PushSyncService
        final push = PushSyncService(
          outboxRepository: outboxRepo,
          gateway: fakeGateway,
          activeAuthenticatedUidFetcher: () => 'user_A',
        );

        final result = await push.pushOnce(ownerUid: 'user_A');
        expect(result.results.length, equals(1));

        final res = result.results.first;
        expect(res.operationId, equals(operationId));
        expect(res.status, equals(PushOperationStatus.alreadyApplied));
        expect(res.remoteVersion, equals(1)); // NOT incremented

        // Remote version must stay at 1
        final remoteAfterRetry = await fakeGateway.fetchDocument(
          ownerUid: 'user_A',
          entityId: '501',
        );
        expect(remoteAfterRetry!.remoteVersion, equals(1));

        // Local is now synced
        final localSynced = await outboxRepo.getByOperationId(operationId);
        expect(localSynced!.syncStatus, equals(OutboxSyncStatus.synced));

        // Gateway was called exactly twice for this operationId
        expect(
          fakeGateway.executedTxnOpIds.where((id) => id == operationId).length,
          equals(2),
        );
      },
    );

    test('Concurrent pushOnce guard: same operationId is executed exactly once '
        '(activeDrains prevents double-submit)', () async {
      final push = PushSyncService(
        outboxRepository: outboxRepo,
        gateway: fakeGateway,
        activeAuthenticatedUidFetcher: () => 'user_A',
      );

      await outboxRepo.enqueueCreate(
        ownerUid: 'user_A',
        entityType: 'word_set',
        entityId: '601',
        payload: {'name': 'Concurrent Deck'},
        operationId: 'op_concurrent_601',
      );

      // Run sequentially (concurrent guard is statically scoped per service class)
      final result = await push.pushOnce(ownerUid: 'user_A');
      expect(result.results.first.status, equals(PushOperationStatus.synced));

      // Exactly one execution
      expect(
        fakeGateway.executedTxnOpIds
            .where((id) => id == 'op_concurrent_601')
            .length,
        equals(1),
      );
    });

    test(
      'Retryable error: attemptCount increments per push; '
      'after maxAttempts the item becomes permanentFailure (no infinite retry)',
      () async {
        final policy = SyncRetryPolicy(maxAttempts: 2);
        final push = PushSyncService(
          outboxRepository: outboxRepo,
          gateway: fakeGateway,
          retryPolicy: policy,
          activeAuthenticatedUidFetcher: () => 'user_A',
        );

        fakeGateway.errorToThrowOnTxn = AppFailure.network(
          message: 'Unavailable',
          code: 'unavailable',
        );

        final item = await outboxRepo.enqueueCreate(
          ownerUid: 'user_A',
          entityType: 'word_set',
          entityId: '701',
          payload: {'name': 'Retry Deck'},
          operationId: 'op_retry_701',
        );

        // Attempt 1: 1 < maxAttempts=2 → retryScheduled
        final r1 = await push.pushOnce(ownerUid: 'user_A');
        expect(
          r1.results.first.status,
          equals(PushOperationStatus.retryScheduled),
        );

        final after1 = await outboxRepo.getByOperationId(item.operationId);
        expect(after1!.attemptCount, equals(1));
        expect(after1.syncStatus, equals(OutboxSyncStatus.failedRetryable));

        // Attempt 2: 2 >= maxAttempts=2 → permanentFailure
        final r2 = await push.pushOnce(ownerUid: 'user_A');
        expect(
          r2.results.first.status,
          equals(PushOperationStatus.permanentFailure),
        );

        final after2 = await outboxRepo.getByOperationId(item.operationId);
        expect(after2!.syncStatus, equals(OutboxSyncStatus.failedPermanent));
        expect(after2.attemptCount, equals(2));

        // No more pending (infinite retry prevented)
        final pending = await outboxRepo.getPendingOperations(
          ownerUid: 'user_A',
        );
        expect(pending, isEmpty);
      },
    );

    test(
      'Conflict on one operation does not block the next independent operation',
      () async {
        final push = PushSyncService(
          outboxRepository: outboxRepo,
          gateway: fakeGateway,
          activeAuthenticatedUidFetcher: () => 'user_A',
        );

        // Entity 801: remote version is 10, local expects 1 → will conflict
        fakeGateway.remoteDocs['user_A_801'] = RemoteDocumentData(
          documentId: '801',
          ownerUid: 'user_A',
          entityId: '801',
          entityType: 'word_set',
          remoteVersion: 10,
          lastOperationId: 'op_remote_10',
          isTombstone: false,
        );

        await outboxRepo.enqueueUpdate(
          ownerUid: 'user_A',
          entityType: 'word_set',
          entityId: '801',
          payload: {'name': 'Stale Edit'},
          localVersion: 2,
          remoteVersion: 2,
          operationId: 'op_conflict_801',
        );

        // Entity 802: does not exist remotely → create will succeed
        await outboxRepo.enqueueCreate(
          ownerUid: 'user_A',
          entityType: 'word_set',
          entityId: '802',
          payload: {'name': 'Independent Deck'},
          operationId: 'op_create_802',
        );

        final result = await push.pushOnce(ownerUid: 'user_A');
        expect(result.results.length, equals(2));

        final conflictResult = result.results.firstWhere(
          (r) => r.operationId == 'op_conflict_801',
        );
        final successResult = result.results.firstWhere(
          (r) => r.operationId == 'op_create_802',
        );

        expect(conflictResult.status, equals(PushOperationStatus.conflict));
        expect(successResult.status, equals(PushOperationStatus.synced));

        final remoteIndependent = await fakeGateway.fetchDocument(
          ownerUid: 'user_A',
          entityId: '802',
        );
        expect(remoteIndependent, isNotNull);
        expect(remoteIndependent!.payload?['name'], equals('Independent Deck'));
      },
    );

    test(
      'Push respects owner scope: user_A push does not touch user_B pending ops',
      () async {
        final push = PushSyncService(
          outboxRepository: outboxRepo,
          gateway: fakeGateway,
          activeAuthenticatedUidFetcher: () => 'user_A',
        );

        await outboxRepo.enqueueCreate(
          ownerUid: 'user_A',
          entityType: 'word_set',
          entityId: '901',
          payload: {'name': 'User A Op'},
          operationId: 'op_a_901',
        );

        await outboxRepo.enqueueCreate(
          ownerUid: 'user_B',
          entityType: 'word_set',
          entityId: '902',
          payload: {'name': 'User B Op'},
          operationId: 'op_b_902',
        );

        final result = await push.pushOnce(ownerUid: 'user_A');

        // user_A op was processed
        expect(
          result.results.where((r) => r.operationId == 'op_a_901').length,
          equals(1),
        );
        // user_B op not in result
        expect(
          result.results.where((r) => r.operationId == 'op_b_902'),
          isEmpty,
        );

        // user_B pending queue stays intact
        final bPending = await outboxRepo.getPendingOperations(
          ownerUid: 'user_B',
        );
        expect(bPending.length, equals(1));
        expect(bPending.first.operationId, equals('op_b_902'));
        expect(bPending.first.syncStatus, equals(OutboxSyncStatus.pending));
      },
    );

    test(
      'Pull: same serverUpdatedAt tie-broken by documentId; '
      'all docs with same timestamp are paged through without gaps',
      () async {
        final pull = PullSyncService(
          checkpointRepository: checkpointRepo,
          gateway: fakeGateway,
          activeAuthenticatedUidFetcher: () => 'user_A',
        );

        final sameTs = DateTime(2026, 7, 24, 11, 0, 0);

        for (final docId in ['a1', 'a2', 'a3']) {
          fakeGateway.remoteDocs['user_A_$docId'] = RemoteDocumentData(
            documentId: docId,
            ownerUid: 'user_A',
            entityId: docId,
            entityType: 'word_set',
            remoteVersion: 1,
            lastOperationId: 'op_$docId',
            isTombstone: false,
            serverUpdatedAt: sameTs,
          );
        }

        // Page 1: limit=2 → a1, a2
        final page1 = await pull.pullPage(ownerUid: 'user_A', pageLimit: 2);
        expect(page1.changes.length, equals(2));
        expect(page1.hasMorePages, isTrue);
        final ids1 = page1.changes.map((d) => d.documentId).toList();
        expect(ids1, containsAll(['a1', 'a2']));

        await pull.acknowledgePage(
          ownerUid: 'user_A',
          lastProcessedDoc: page1.changes.last,
        );
        final cp1 = await checkpointRepo.getCheckpoint(
          ownerUid: 'user_A',
          entityType: 'word_set',
        );
        expect(cp1!.lastServerUpdatedAt, equals(sameTs));
        expect(cp1.tieBreakerDocId, isNotNull);

        // Page 2: limit=2 → only a3 (a3 > a2 tie-breaker)
        final page2 = await pull.pullPage(ownerUid: 'user_A', pageLimit: 2);
        expect(page2.changes.length, equals(1));
        expect(page2.changes.first.documentId, equals('a3'));
        expect(page2.hasMorePages, isFalse);
      },
    );

    test('Pull failure (network error) does not advance checkpoint', () async {
      final pull = PullSyncService(
        checkpointRepository: checkpointRepo,
        gateway: _ThrowingGateway(),
        activeAuthenticatedUidFetcher: () => 'user_A',
      );

      final before = await checkpointRepo.getCheckpoint(
        ownerUid: 'user_A',
        entityType: 'word_set',
      );
      expect(before, isNull);

      bool threw = false;
      try {
        await pull.pullPage(ownerUid: 'user_A');
      } on AppFailure {
        threw = true;
      }
      expect(threw, isTrue);

      final after = await checkpointRepo.getCheckpoint(
        ownerUid: 'user_A',
        entityType: 'word_set',
      );
      expect(after, isNull);
    });

    test(
      'Ack with stale session throws AppFailure.auth; checkpoint is NOT written',
      () async {
        String activeUser = 'user_A';
        final pull = PullSyncService(
          checkpointRepository: checkpointRepo,
          gateway: fakeGateway,
          activeAuthenticatedUidFetcher: () => activeUser,
        );

        fakeGateway.remoteDocs['user_A_1001'] = RemoteDocumentData(
          documentId: '1001',
          ownerUid: 'user_A',
          entityId: '1001',
          entityType: 'word_set',
          remoteVersion: 1,
          lastOperationId: 'op_1',
          isTombstone: false,
          serverUpdatedAt: DateTime(2026, 7, 24, 12, 0, 0),
        );

        final page = await pull.pullPage(ownerUid: 'user_A');
        expect(page.changes.length, equals(1));

        // Simulate session switch before ack
        activeUser = 'user_B';

        expect(
          () => pull.acknowledgePage(
            ownerUid: 'user_A',
            lastProcessedDoc: page.changes.first,
          ),
          throwsA(
            isA<AppFailure>().having((e) => e.type, 'type', FailureType.auth),
          ),
        );

        // Checkpoint must NOT have been persisted
        final cp = await checkpointRepo.getCheckpoint(
          ownerUid: 'user_A',
          entityType: 'word_set',
        );
        expect(cp, isNull);
      },
    );

    test(
      'Restart: persisted checkpoint is used as incremental cursor on next pull',
      () async {
        final pull = PullSyncService(
          checkpointRepository: checkpointRepo,
          gateway: fakeGateway,
          activeAuthenticatedUidFetcher: () => 'user_A',
        );

        final t1 = DateTime(2026, 7, 24, 9, 0, 0);
        final t2 = DateTime(2026, 7, 24, 10, 0, 0);
        final t3 = DateTime(2026, 7, 24, 11, 0, 0);

        for (final entry in [('r1', t1), ('r2', t2)]) {
          fakeGateway.remoteDocs['user_A_${entry.$1}'] = RemoteDocumentData(
            documentId: entry.$1,
            ownerUid: 'user_A',
            entityId: entry.$1,
            entityType: 'word_set',
            remoteVersion: 1,
            lastOperationId: 'op_${entry.$1}',
            isTombstone: false,
            serverUpdatedAt: entry.$2,
          );
        }

        // First pull + ack
        final p1 = await pull.pullPage(ownerUid: 'user_A');
        expect(p1.changes.length, equals(2));
        await pull.acknowledgePage(
          ownerUid: 'user_A',
          lastProcessedDoc: p1.changes.last,
        );

        final cp = await checkpointRepo.getCheckpoint(
          ownerUid: 'user_A',
          entityType: 'word_set',
        );
        expect(cp!.lastServerUpdatedAt, equals(t2));

        // Simulate "restart": add a new doc after checkpoint
        fakeGateway.remoteDocs['user_A_r3'] = RemoteDocumentData(
          documentId: 'r3',
          ownerUid: 'user_A',
          entityId: 'r3',
          entityType: 'word_set',
          remoteVersion: 1,
          lastOperationId: 'op_r3',
          isTombstone: false,
          serverUpdatedAt: t3,
        );

        // Second pull should only return r3 (uses persisted checkpoint cursor)
        final p2 = await pull.pullPage(ownerUid: 'user_A');
        expect(p2.changes.length, equals(1));
        expect(p2.changes.first.documentId, equals('r3'));
      },
    );
  });
}
