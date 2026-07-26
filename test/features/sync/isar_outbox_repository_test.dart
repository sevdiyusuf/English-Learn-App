import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';

import 'package:yunoo/core/errors/app_failure.dart';
import 'package:yunoo/features/sync/data/outbox_repository.dart';
import 'package:yunoo/features/sync/models/local_schema_metadata.dart';
import 'package:yunoo/features/sync/models/outbox_item.dart';
import 'package:yunoo/features/sync/services/schema_migration_service.dart';
import 'package:yunoo/features/word_match/models/word_pair.dart';
import 'package:yunoo/features/word_match/models/word_set.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    HttpOverrides.global = null;
    await Isar.initializeIsarCore(download: true);
  });

  group('Sprint 4C — Isar Schema Migration Tests', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('isar_migration_test_');
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('Fresh database initialized with current schema version', () async {
      final dbName = 'test_fresh_${DateTime.now().microsecondsSinceEpoch}';
      final isar = await Isar.open(
        [
          WordSetSchema,
          WordPairSchema,
          OutboxItemSchema,
          LocalSchemaMetadataSchema,
        ],
        directory: tempDir.path,
        name: dbName,
      );

      final migrationService = SchemaMigrationService();
      await migrationService.runMigrations(isar);

      final metadataList = await isar.localSchemaMetadatas.where().findAll();
      expect(metadataList.length, equals(1));
      expect(
        metadataList.first.version,
        equals(SchemaMigrationService.kCurrentLocalSchemaVersion),
      );
      expect(metadataList.first.isSuccessful, isTrue);

      await isar.close(deleteFromDisk: true);
    });

    test('Migration runner is idempotent when called multiple times', () async {
      final dbName = 'test_idempotent_${DateTime.now().microsecondsSinceEpoch}';
      final isar = await Isar.open(
        [
          WordSetSchema,
          WordPairSchema,
          OutboxItemSchema,
          LocalSchemaMetadataSchema,
        ],
        directory: tempDir.path,
        name: dbName,
      );

      final migrationService = SchemaMigrationService();
      await migrationService.runMigrations(isar);
      await migrationService.runMigrations(isar);

      final metadataList = await isar.localSchemaMetadatas.where().findAll();
      expect(metadataList.length, equals(1));

      await isar.close(deleteFromDisk: true);
    });

    test(
      'Existing WordSet and WordPair data preserved after migration',
      () async {
        final dbName = 'test_preserve_${DateTime.now().microsecondsSinceEpoch}';
        final isar = await Isar.open(
          [
            WordSetSchema,
            WordPairSchema,
            OutboxItemSchema,
            LocalSchemaMetadataSchema,
          ],
          directory: tempDir.path,
          name: dbName,
        );

        final set =
            WordSet()
              ..name = 'Preserved Set'
              ..createdAt = DateTime.now()
              ..updatedAt = DateTime.now()
              ..ownerUid = 'user_A';

        await isar.writeTxn(() async {
          await isar.wordSets.put(set);
        });

        final migrationService = SchemaMigrationService();
        await migrationService.runMigrations(isar);

        final fetchedSets = await isar.wordSets.where().findAll();
        expect(fetchedSets.length, equals(1));
        expect(fetchedSets.first.name, equals('Preserved Set'));
        expect(fetchedSets.first.ownerUid, equals('user_A'));

        await isar.close(deleteFromDisk: true);
      },
    );

    test(
      'Migration step failure preserves previous version and rolls back partial metadata',
      () async {
        final dbName =
            'test_fail_step_${DateTime.now().microsecondsSinceEpoch}';
        final isar = await Isar.open(
          [
            WordSetSchema,
            WordPairSchema,
            OutboxItemSchema,
            LocalSchemaMetadataSchema,
          ],
          directory: tempDir.path,
          name: dbName,
        );

        // Run v1 migration successfully first
        final v1Service = SchemaMigrationService(targetSchemaVersion: 1);
        await v1Service.runMigrations(isar);

        final initialMetadata =
            await isar.localSchemaMetadatas.where().findAll();
        expect(initialMetadata.length, equals(1));
        expect(initialMetadata.first.version, equals(1));

        // Create failing v2 migration service
        final failingService = SchemaMigrationService(
          targetSchemaVersion: 2,
          customStepHandlers: {
            2:
                (isar) async =>
                    throw Exception('Disk write error during step 2'),
          },
        );

        await expectLater(
          failingService.runMigrations(isar),
          throwsA(
            isA<AppFailure>().having(
              (e) => e.type,
              'type',
              equals(FailureType.database),
            ),
          ),
        );

        // Verify v2 was not written, v1 remains intact, no partial record
        final metadataAfterFailure =
            await isar.localSchemaMetadatas.where().findAll();
        expect(metadataAfterFailure.length, equals(1));
        expect(metadataAfterFailure.first.version, equals(1));

        // Verify same runner can be rerun safely with a succeeding handler
        final succeedingService = SchemaMigrationService(
          targetSchemaVersion: 2,
          customStepHandlers: {
            2: (isar) async {
              // Migration step 2 succeeds cleanly
            },
          },
        );

        await succeedingService.runMigrations(isar);

        final metadataAfterSuccess =
            await isar.localSchemaMetadatas.where().findAll();
        expect(metadataAfterSuccess.length, equals(2));
        final versions = metadataAfterSuccess.map((m) => m.version).toList();
        expect(versions, containsAll([1, 2]));

        await isar.close(deleteFromDisk: true);
      },
    );
  });

  group('Sprint 4C — Isar Outbox Persistence & Coalescing Tests', () {
    Directory? tempDir;
    late Isar isar;
    var isarInitialized = false;
    late IsarOutboxRepository repo;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('isar_outbox_test_');
      final dbName = 'test_outbox_${DateTime.now().microsecondsSinceEpoch}';
      isar = await Isar.open(
        [
          WordSetSchema,
          WordPairSchema,
          OutboxItemSchema,
          LocalSchemaMetadataSchema,
        ],
        directory: tempDir!.path,
        name: dbName,
      );
      isarInitialized = true;
      repo = IsarOutboxRepository(isar);
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

    test('Pending create persisted to Isar across database restart', () async {
      await repo.enqueueCreate(
        ownerUid: 'user_A',
        entityType: 'word_set',
        entityId: '101',
        payload: {'name': 'Restart Deck'},
        operationId: 'op_restart_create',
      );

      final dbPath = tempDir!.path;
      final dbName = isar.name;
      await isar.close(deleteFromDisk: false);

      final reopenedIsar = await Isar.open(
        [
          WordSetSchema,
          WordPairSchema,
          OutboxItemSchema,
          LocalSchemaMetadataSchema,
        ],
        directory: dbPath,
        name: dbName,
      );

      final reopenedRepo = IsarOutboxRepository(reopenedIsar);
      final pending = await reopenedRepo.getPendingOperations(
        ownerUid: 'user_A',
      );
      expect(pending.length, equals(1));
      expect(pending.first.operationId, equals('op_restart_create'));
      expect(pending.first.payload?['name'], equals('Restart Deck'));

      await reopenedIsar.close(deleteFromDisk: true);
    });

    test('Pending update preserved across restart', () async {
      await repo.enqueueUpdate(
        ownerUid: 'user_A',
        entityType: 'word_set',
        entityId: '102',
        payload: {'name': 'Update V1'},
        operationId: 'op_restart_update',
      );

      final dbPath = tempDir!.path;
      final dbName = isar.name;
      await isar.close(deleteFromDisk: false);

      final reopenedIsar = await Isar.open(
        [
          WordSetSchema,
          WordPairSchema,
          OutboxItemSchema,
          LocalSchemaMetadataSchema,
        ],
        directory: dbPath,
        name: dbName,
      );

      final reopenedRepo = IsarOutboxRepository(reopenedIsar);
      final pending = await reopenedRepo.getPendingOperations(
        ownerUid: 'user_A',
      );
      expect(pending.length, equals(1));
      expect(pending.first.operation, equals(OutboxOperationType.update));
      expect(pending.first.payload?['name'], equals('Update V1'));

      await reopenedIsar.close(deleteFromDisk: true);
    });

    test('Pending delete/tombstone preserved across restart', () async {
      await repo.enqueueDelete(
        ownerUid: 'user_A',
        entityType: 'word_set',
        entityId: '103',
        operationId: 'op_restart_delete',
      );

      final dbPath = tempDir!.path;
      final dbName = isar.name;
      await isar.close(deleteFromDisk: false);

      final reopenedIsar = await Isar.open(
        [
          WordSetSchema,
          WordPairSchema,
          OutboxItemSchema,
          LocalSchemaMetadataSchema,
        ],
        directory: dbPath,
        name: dbName,
      );

      final reopenedRepo = IsarOutboxRepository(reopenedIsar);
      final pending = await reopenedRepo.getPendingOperations(
        ownerUid: 'user_A',
      );
      expect(pending.length, equals(1));
      expect(pending.first.operation, equals(OutboxOperationType.delete));
      expect(pending.first.isTombstone, isTrue);
      expect(pending.first.deletedAt, isNotNull);

      await reopenedIsar.close(deleteFromDisk: true);
    });

    test(
      'Duplicate operation ID enqueued twice produces single record',
      () async {
        await repo.enqueueCreate(
          ownerUid: 'user_A',
          entityType: 'word_set',
          entityId: '104',
          payload: {'name': 'Fixed ID'},
          operationId: 'op_fixed_104',
        );

        await repo.enqueueCreate(
          ownerUid: 'user_A',
          entityType: 'word_set',
          entityId: '104',
          payload: {'name': 'Fixed ID'},
          operationId: 'op_fixed_104',
        );

        final allItems = await isar.outboxItems.where().findAll();
        expect(allItems.length, equals(1));
      },
    );

    test(
      'Entity create -> update coalesces into single pendingCreate',
      () async {
        await repo.enqueueCreate(
          ownerUid: 'user_A',
          entityType: 'word_set',
          entityId: '105',
          payload: {'name': 'Initial Name'},
          operationId: 'op_c_105',
        );

        await repo.enqueueUpdate(
          ownerUid: 'user_A',
          entityType: 'word_set',
          entityId: '105',
          payload: {'name': 'Coalesced Name'},
        );

        final pending = await repo.getPendingOperations(ownerUid: 'user_A');
        expect(pending.length, equals(1));
        expect(pending.first.operation, equals(OutboxOperationType.create));
        expect(pending.first.payload?['name'], equals('Coalesced Name'));
        expect(pending.first.operationId, equals('op_c_105'));
      },
    );

    test(
      'Entity update -> update coalesces into single pendingUpdate',
      () async {
        await repo.enqueueUpdate(
          ownerUid: 'user_A',
          entityType: 'word_set',
          entityId: '106',
          payload: {'name': 'Update V1'},
          operationId: 'op_u_106',
        );

        await repo.enqueueUpdate(
          ownerUid: 'user_A',
          entityType: 'word_set',
          entityId: '106',
          payload: {'name': 'Update V2'},
        );

        final pending = await repo.getPendingOperations(ownerUid: 'user_A');
        expect(pending.length, equals(1));
        expect(pending.first.operation, equals(OutboxOperationType.update));
        expect(pending.first.payload?['name'], equals('Update V2'));
      },
    );

    test(
      'Create/update -> delete coalesces into single pendingDelete (tombstone)',
      () async {
        await repo.enqueueCreate(
          ownerUid: 'user_A',
          entityType: 'word_set',
          entityId: '107',
          payload: {'name': 'Temp Set'},
          operationId: 'op_c_107',
        );

        await repo.enqueueDelete(
          ownerUid: 'user_A',
          entityType: 'word_set',
          entityId: '107',
        );

        final pending = await repo.getPendingOperations(ownerUid: 'user_A');
        expect(pending.length, equals(1));
        expect(pending.first.operation, equals(OutboxOperationType.delete));
        expect(pending.first.isTombstone, isTrue);
        expect(pending.first.payloadJson, isNull);
      },
    );

    test('Delete -> delete does not produce duplicate', () async {
      await repo.enqueueDelete(
        ownerUid: 'user_A',
        entityType: 'word_set',
        entityId: '108',
      );

      await repo.enqueueDelete(
        ownerUid: 'user_A',
        entityType: 'word_set',
        entityId: '108',
      );

      final pending = await repo.getPendingOperations(ownerUid: 'user_A');
      expect(pending.length, equals(1));
    });

    test(
      'Mutation after pending delete without restore is rejected safely',
      () async {
        await repo.enqueueDelete(
          ownerUid: 'user_A',
          entityType: 'word_set',
          entityId: '109',
        );

        expect(
          () => repo.enqueueUpdate(
            ownerUid: 'user_A',
            entityType: 'word_set',
            entityId: '109',
            payload: {'name': 'Resurrected'},
          ),
          throwsA(isA<AppFailure>()),
        );
      },
    );

    test('User A query does not return User B or guest records', () async {
      await repo.enqueueCreate(
        ownerUid: 'user_A',
        entityType: 'word_set',
        entityId: '201',
        payload: {'name': 'A Deck'},
      );

      await repo.enqueueCreate(
        ownerUid: 'user_B',
        entityType: 'word_set',
        entityId: '202',
        payload: {'name': 'B Deck'},
      );

      await repo.enqueueCreate(
        ownerUid: null,
        entityType: 'word_set',
        entityId: '203',
        payload: {'name': 'Guest Deck'},
      );

      final pendingA = await repo.getPendingOperations(ownerUid: 'user_A');
      expect(pendingA.length, equals(1));
      expect(pendingA.first.entityId, equals('201'));
      expect(pendingA.first.ownerUid, equals('user_A'));
    });

    test('Guest query does not return user records', () async {
      await repo.enqueueCreate(
        ownerUid: 'user_A',
        entityType: 'word_set',
        entityId: '301',
        payload: {'name': 'A Deck'},
      );

      await repo.enqueueCreate(
        ownerUid: null,
        entityType: 'word_set',
        entityId: '302',
        payload: {'name': 'Guest Deck'},
      );

      final pendingGuest = await repo.getPendingOperations(ownerUid: null);
      expect(pendingGuest.length, equals(1));
      expect(pendingGuest.first.entityId, equals('302'));
      expect(pendingGuest.first.ownerUid, isNull);
    });

    test(
      'Attempt recording atomically increments attempt count and updates lastAttemptAt',
      () async {
        final item = await repo.enqueueCreate(
          ownerUid: 'user_A',
          entityType: 'word_set',
          entityId: '401',
          payload: {'name': 'Attempt Test'},
        );

        expect(item.attemptCount, equals(0));

        await repo.updateAttempt(
          operationId: item.operationId,
          errorMessage: 'Network timeout',
          errorCode: 'timeout-504',
        );

        final updated = await repo.getByOperationId(item.operationId);
        expect(updated, isNotNull);
        expect(updated!.attemptCount, equals(1));
        expect(updated.lastAttemptAt, isNotNull);
        expect(updated.lastErrorMessage, equals('Network timeout'));
        expect(updated.lastErrorCode, equals('timeout-504'));
      },
    );

    test('Retryable failure remains in processable pending state', () async {
      final item = await repo.enqueueCreate(
        ownerUid: 'user_A',
        entityType: 'word_set',
        entityId: '501',
        payload: {'name': 'Retryable Test'},
      );

      await repo.markFailedRetryable(
        operationId: item.operationId,
        errorMessage: 'Temporary 503 Service Unavailable',
      );

      final pending = await repo.getPendingOperations(ownerUid: 'user_A');
      expect(pending.length, equals(1));
      expect(
        pending.first.syncStatus,
        equals(OutboxSyncStatus.failedRetryable),
      );
    });

    test(
      'Permanent failure is excluded from pending queue but remains persisted',
      () async {
        final item = await repo.enqueueCreate(
          ownerUid: 'user_A',
          entityType: 'word_set',
          entityId: '601',
          payload: {'name': 'Permanent Fail Test'},
        );

        await repo.markFailedPermanent(
          operationId: item.operationId,
          errorMessage: 'Invalid payload structure (400)',
        );

        final pending = await repo.getPendingOperations(ownerUid: 'user_A');
        expect(pending, isEmpty);

        final persisted = await repo.getByOperationId(item.operationId);
        expect(persisted, isNotNull);
        expect(persisted!.syncStatus, equals(OutboxSyncStatus.failedPermanent));
      },
    );

    test('Synced item is removed from pending processing queue', () async {
      final item = await repo.enqueueCreate(
        ownerUid: 'user_A',
        entityType: 'word_set',
        entityId: '701',
        payload: {'name': 'Synced Test'},
      );

      await repo.markSynced(operationId: item.operationId, remoteVersion: 5);

      final pending = await repo.getPendingOperations(ownerUid: 'user_A');
      expect(pending, isEmpty);

      final syncedItem = await repo.getByOperationId(item.operationId);
      expect(syncedItem, isNotNull);
      expect(syncedItem!.syncStatus, equals(OutboxSyncStatus.synced));
      expect(syncedItem.remoteVersion, equals(5));
    });

    test('Conflict status is persisted with details', () async {
      final item = await repo.enqueueCreate(
        ownerUid: 'user_A',
        entityType: 'word_set',
        entityId: '801',
        payload: {'name': 'Conflict Test'},
      );

      await repo.markConflict(
        operationId: item.operationId,
        conflictDetails: 'Remote document was updated by another device',
      );

      final conflictItem = await repo.getByOperationId(item.operationId);
      expect(conflictItem, isNotNull);
      expect(conflictItem!.syncStatus, equals(OutboxSyncStatus.conflict));
      expect(
        conflictItem.conflictDetails,
        equals('Remote document was updated by another device'),
      );
    });

    test('Isar database errors are mapped to AppFailure.database', () async {
      final item = await repo.enqueueCreate(
        ownerUid: 'user_A',
        entityType: 'word_set',
        entityId: '901',
        payload: {'name': 'Error Mapping Test'},
      );

      await isar.close(deleteFromDisk: false);

      await expectLater(
        repo.getByOperationId(item.operationId),
        throwsA(isA<AppFailure>()),
      );
    });

    test(
      'Outbox transaction failure rolls back transaction without corrupting existing active operation',
      () async {
        // 1. Initialize schema v1
        final migrationService = SchemaMigrationService();
        await migrationService.runMigrations(isar);

        final initialMetadataCount =
            await isar.localSchemaMetadatas.where().count();
        expect(initialMetadataCount, equals(1));

        // 2. Create existing active operation in normal repository
        final activeItem = await repo.enqueueCreate(
          ownerUid: 'user_A',
          entityType: 'word_set',
          entityId: '1001',
          payload: {'name': 'Original Deck'},
          operationId: 'op_active_1001',
        );

        expect(activeItem.payload?['name'], equals('Original Deck'));

        // 3. Instantiate repository with failing transaction callback
        final failingRepo = IsarOutboxRepository(
          isar,
          onBeforeTxnCommit: () {
            throw IsarError('Disk I/O transaction error simulation');
          },
        );

        // 4. Attempt update through failing repo
        await expectLater(
          failingRepo.enqueueUpdate(
            ownerUid: 'user_A',
            entityType: 'word_set',
            entityId: '1001',
            payload: {'name': 'Corrupted Deck'},
          ),
          throwsA(
            isA<AppFailure>().having(
              (e) => e.type,
              'type',
              equals(FailureType.database),
            ),
          ),
        );

        // 5. Verify transaction was completely rolled back:
        // - Outbox items count is still 1
        // - Active item is intact with original operation, payload, and status
        final allOutboxItems = await isar.outboxItems.where().findAll();
        expect(allOutboxItems.length, equals(1));
        expect(allOutboxItems.first.operationId, equals('op_active_1001'));
        expect(
          allOutboxItems.first.operation,
          equals(OutboxOperationType.create),
        );
        expect(allOutboxItems.first.payload?['name'], equals('Original Deck'));
        expect(
          allOutboxItems.first.syncStatus,
          equals(OutboxSyncStatus.pending),
        );

        // - Schema metadata remains untouched
        final metadataAfterFailure =
            await isar.localSchemaMetadatas.where().count();
        expect(metadataAfterFailure, equals(initialMetadataCount));
      },
    );
  });
}
