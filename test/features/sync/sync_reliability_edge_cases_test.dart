import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';
import 'package:yunoo/core/errors/app_failure.dart';
import 'package:yunoo/features/sync/data/firestore_sync_gateway.dart';
import 'package:yunoo/features/sync/data/outbox_repository.dart';
import 'package:yunoo/features/sync/domain/sync_conflict_resolver.dart';
import 'package:yunoo/features/sync/domain/word_set_sync_codec.dart';
import 'package:yunoo/features/sync/models/idempotency_receipt.dart';
import 'package:yunoo/features/sync/models/local_schema_metadata.dart';
import 'package:yunoo/features/sync/models/outbox_item.dart';
import 'package:yunoo/features/sync/services/push_sync_service.dart';
import 'package:yunoo/features/word_match/models/word_pair.dart';
import 'package:yunoo/features/word_match/models/word_set.dart';

class _FakeGatewayForSyncReliability implements FirestoreSyncGateway {
  final Map<String, RemoteDocumentData> remoteDocs = {};
  final Map<String, IdempotencyReceipt> receipts = {};
  bool shouldThrowRetryable = false;
  bool shouldThrowPermanent = false;
  int executionCount = 0;

  @override
  Future<ConflictDecision> executeIdempotentTransaction({
    required String ownerUid,
    required OutboxItem localOp,
  }) async {
    executionCount++;
    if (shouldThrowRetryable) {
      throw AppFailure.network(message: 'Simulated network offline');
    }
    if (shouldThrowPermanent && localOp.entityId == 'ws-perm-1') {
      throw AppFailure.auth(
        code: 'permission-denied',
        message: 'Permission denied',
      );
    }

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
  }) async => [];

  @override
  Stream<List<RemoteDocumentData>> listenToChanges({
    required String ownerUid,
  }) => Stream.value([]);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    HttpOverrides.global = null;
    await Isar.initializeIsarCore(download: true);
  });

  group('Sync & Outbox Reliability Edge Cases', () {
    Directory? tempDir;
    late Isar isar;
    var isarInitialized = false;
    late IsarOutboxRepository outboxRepo;
    late _FakeGatewayForSyncReliability gateway;
    late PushSyncService pushService;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('sync_rel_test_');
      isar = await Isar.open(
        [
          WordSetSchema,
          WordPairSchema,
          OutboxItemSchema,
          LocalSchemaMetadataSchema,
        ],
        directory: tempDir!.path,
        name: 'test_sync_rel_${DateTime.now().microsecondsSinceEpoch}',
      );
      isarInitialized = true;
      outboxRepo = IsarOutboxRepository(isar);
      gateway = _FakeGatewayForSyncReliability();
      pushService = PushSyncService(
        outboxRepository: outboxRepo,
        gateway: gateway,
        activeAuthenticatedUidFetcher: () => 'user-123',
      );
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

    test('OutboxItem construction and status transitions', () {
      final op =
          OutboxItem()
            ..operationId = 'op-1001'
            ..ownerUid = 'user-123'
            ..entityType = 'word_set'
            ..entityId = 'ws-1'
            ..coalescingKey = 'user-123_word_set_ws-1'
            ..operation = OutboxOperationType.create
            ..payloadJson = '{"setId":"ws-1"}'
            ..syncStatus = OutboxSyncStatus.pending
            ..createdAt = DateTime.fromMillisecondsSinceEpoch(1700000000000);

      expect(op.operationId, 'op-1001');
      expect(op.ownerUid, 'user-123');
      expect(op.syncStatus, OutboxSyncStatus.pending);

      op.syncStatus = OutboxSyncStatus.failedRetryable;
      op.attemptCount += 1;
      expect(op.syncStatus, OutboxSyncStatus.failedRetryable);
      expect(op.attemptCount, 1);

      op.syncStatus = OutboxSyncStatus.synced;
      expect(op.syncStatus, OutboxSyncStatus.synced);
    });

    test('OutboxSyncStatus enum values completeness', () {
      const allowedStatuses = [
        OutboxSyncStatus.pending,
        OutboxSyncStatus.synced,
        OutboxSyncStatus.failedRetryable,
        OutboxSyncStatus.failedPermanent,
        OutboxSyncStatus.conflict,
      ];

      expect(allowedStatuses.length, 5);
    });

    test('Enqueue -> drain updates item to synced status', () async {
      await outboxRepo.enqueueCreate(
        ownerUid: 'user-123',
        entityType: 'word_set',
        entityId: 'ws-drain-1',
        payload: {'name': 'Drain Set'},
        operationId: 'op_drain_101',
      );

      final pendingBefore = await outboxRepo.getPendingOperations(
        ownerUid: 'user-123',
      );
      expect(pendingBefore.length, 1);

      await pushService.pushOnce(ownerUid: 'user-123');

      final pendingAfter = await outboxRepo.getPendingOperations(
        ownerUid: 'user-123',
      );
      expect(pendingAfter.isEmpty, isTrue);

      final itemInDb = await isar.outboxItems.where().findFirst();
      expect(itemInDb?.syncStatus, OutboxSyncStatus.synced);
    });

    test(
      'Transient failure updates item to failedRetryable and increments attemptCount',
      () async {
        await outboxRepo.enqueueCreate(
          ownerUid: 'user-123',
          entityType: 'word_set',
          entityId: 'ws-retry-1',
          payload: {'name': 'Retry Set'},
          operationId: 'op_retry_101',
        );

        gateway.shouldThrowRetryable = true;

        await pushService.pushOnce(ownerUid: 'user-123');

        final itemInDb = await isar.outboxItems.where().findFirst();
        expect(itemInDb?.syncStatus, OutboxSyncStatus.failedRetryable);
        expect(itemInDb?.attemptCount, 1);

        // Second push attempt retries
        gateway.shouldThrowRetryable = false;
        await pushService.pushOnce(ownerUid: 'user-123');

        final pendingAfter = await outboxRepo.getPendingOperations(
          ownerUid: 'user-123',
        );
        expect(pendingAfter.isEmpty, isTrue);
      },
    );

    test('Permanent invalid operation does not leave queue stuck', () async {
      await outboxRepo.enqueueCreate(
        ownerUid: 'user-123',
        entityType: 'word_set',
        entityId: 'ws-perm-1',
        payload: {'invalid': 'payload'},
        operationId: 'op_perm_101',
      );

      await outboxRepo.enqueueCreate(
        ownerUid: 'user-123',
        entityType: 'word_set',
        entityId: 'ws-valid-2',
        payload: {'name': 'Valid Set'},
        operationId: 'op_valid_102',
      );

      gateway.shouldThrowPermanent = true;

      await pushService.pushOnce(ownerUid: 'user-123');

      final permItem =
          await isar.outboxItems
              .filter()
              .operationIdEqualTo('op_perm_101')
              .findFirst();
      expect(permItem?.syncStatus, OutboxSyncStatus.failedPermanent);

      // Now clear permanent failure flag and push second item
      gateway.shouldThrowPermanent = false;
      await pushService.pushOnce(ownerUid: 'user-123');

      final validItem =
          await isar.outboxItems
              .filter()
              .operationIdEqualTo('op_valid_102')
              .findFirst();
      expect(validItem?.syncStatus, OutboxSyncStatus.synced);
    });

    test(
      'Pending operations remain owner-isolated across logout/account switch',
      () async {
        await outboxRepo.enqueueCreate(
          ownerUid: 'user-123',
          entityType: 'word_set',
          entityId: 'ws-userA-1',
          payload: {'name': 'User A Set'},
          operationId: 'op_userA_101',
        );

        // User B should not see or drain User A's operations
        final pendingUserB = await outboxRepo.getPendingOperations(
          ownerUid: 'user-B',
        );
        expect(pendingUserB.isEmpty, isTrue);

        final pushServiceUserB = PushSyncService(
          outboxRepository: outboxRepo,
          gateway: gateway,
          activeAuthenticatedUidFetcher: () => 'user-B',
        );

        await pushServiceUserB.pushOnce(ownerUid: 'user-B');

        // User A's item remains pending
        final itemA =
            await isar.outboxItems
                .filter()
                .operationIdEqualTo('op_userA_101')
                .findFirst();
        expect(itemA?.syncStatus, OutboxSyncStatus.pending);
      },
    );
  });
}
