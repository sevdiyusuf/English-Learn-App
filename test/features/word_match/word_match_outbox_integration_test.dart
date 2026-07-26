import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';

import 'package:yunoo/core/errors/app_failure.dart';
import 'package:yunoo/features/sync/data/outbox_repository.dart';
import 'package:yunoo/features/sync/models/local_schema_metadata.dart';
import 'package:yunoo/features/sync/models/outbox_item.dart';
import 'package:yunoo/features/word_match/data/word_match_repo.dart';
import 'package:yunoo/features/word_match/models/word_pair.dart';
import 'package:yunoo/features/word_match/models/word_set.dart';

class FakeOutboxRepoForIntegration implements OutboxRepository {
  bool enqueueCalled = false;
  bool shouldThrow = false;

  @override
  Future<OutboxItem> enqueueCreate({
    required String? ownerUid,
    required String entityType,
    required String entityId,
    required Map<String, dynamic> payload,
    int localVersion = 1,
    int? remoteVersion,
    String? operationId,
  }) => throw UnimplementedError();

  @override
  Future<OutboxItem> enqueueUpdate({
    required String? ownerUid,
    required String entityType,
    required String entityId,
    required Map<String, dynamic> payload,
    int localVersion = 1,
    int? remoteVersion,
    String? operationId,
  }) => throw UnimplementedError();

  @override
  Future<OutboxItem> enqueueDelete({
    required String? ownerUid,
    required String entityType,
    required String entityId,
    int localVersion = 1,
    int? remoteVersion,
    String? operationId,
  }) => throw UnimplementedError();

  @override
  Future<List<OutboxItem>> getPendingOperations({required String? ownerUid}) =>
      throw UnimplementedError();

  @override
  Future<OutboxItem?> getByOperationId(String operationId) =>
      throw UnimplementedError();

  @override
  Future<void> updateAttempt({
    required String operationId,
    String? errorMessage,
    String? errorCode,
  }) => throw UnimplementedError();

  @override
  Future<void> markSynced({required String operationId, int? remoteVersion}) =>
      throw UnimplementedError();

  @override
  Future<void> markConflict({
    required String operationId,
    required String conflictDetails,
  }) => throw UnimplementedError();

  @override
  Future<void> markFailedRetryable({
    required String operationId,
    required String errorMessage,
    String? errorCode,
  }) => throw UnimplementedError();

  @override
  Future<void> markFailedPermanent({
    required String operationId,
    required String errorMessage,
    String? errorCode,
  }) => throw UnimplementedError();

  @override
  Future<OutboxItem> enqueueCreateInsideTxn({
    required String? ownerUid,
    required String entityType,
    required String entityId,
    required Map<String, dynamic> payload,
    int localVersion = 1,
    int? remoteVersion,
    String? operationId,
  }) async {
    enqueueCalled = true;
    if (shouldThrow) {
      throw AppFailure.database(message: 'Simulated Outbox Failure');
    }
    return OutboxItem();
  }

  @override
  Future<OutboxItem> enqueueUpdateInsideTxn({
    required String? ownerUid,
    required String entityType,
    required String entityId,
    required Map<String, dynamic> payload,
    int localVersion = 1,
    int? remoteVersion,
    String? operationId,
  }) async {
    enqueueCalled = true;
    if (shouldThrow) {
      throw AppFailure.database(message: 'Simulated Outbox Failure');
    }
    return OutboxItem();
  }

  @override
  Future<OutboxItem> enqueueDeleteInsideTxn({
    required String? ownerUid,
    required String entityType,
    required String entityId,
    int localVersion = 1,
    int? remoteVersion,
    String? operationId,
  }) async {
    enqueueCalled = true;
    if (shouldThrow) {
      throw AppFailure.database(message: 'Simulated Outbox Failure');
    }
    return OutboxItem();
  }

  @override
  Future<void> clearUserData(String uid) async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Directory? tempDir;
  Isar? isar;
  late WordMatchRepo wordMatchRepo;
  late FakeOutboxRepoForIntegration fakeOutbox;

  setUpAll(() async {
    HttpOverrides.global = null;
    await Isar.initializeIsarCore(download: true);
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp(
      'word_match_outbox_integration_test_',
    );
    isar = await Isar.open(
      [
        WordSetSchema,
        WordPairSchema,
        OutboxItemSchema,
        LocalSchemaMetadataSchema,
      ],
      directory: tempDir!.path,
      name: 'word_match_outbox_${DateTime.now().microsecondsSinceEpoch}',
    );

    fakeOutbox = FakeOutboxRepoForIntegration();
    wordMatchRepo = WordMatchRepo(
      isar!,
      activeOwnerUid: 'test_user',
      outboxRepo: fakeOutbox,
    );
  });

  tearDown(() async {
    final database = isar;
    isar = null;
    if (database?.isOpen ?? false) {
      await database!.close(deleteFromDisk: true);
    }
    final directory = tempDir;
    tempDir = null;
    if (directory != null && await directory.exists()) {
      await directory.delete(recursive: true);
    }
  });

  group('Sprint 4E — WordMatchRepo & Outbox Integration', () {
    test(
      'createSet, renameSet, deleteSet ve savePairs için entity mutation + Outbox enqueue aynı Isar transaction\'ında gerçekleşiyor',
      () async {
        // Create
        fakeOutbox.enqueueCalled = false;
        final setId = await wordMatchRepo.createSet('My New Set');
        expect(
          fakeOutbox.enqueueCalled,
          isTrue,
          reason: 'createSet should enqueue outbox item',
        );

        final createdSet = await wordMatchRepo.getSet(setId);
        expect(createdSet, isNotNull);
        expect(createdSet!.name, equals('My New Set'));

        // Update
        fakeOutbox.enqueueCalled = false;
        await wordMatchRepo.renameSet(id: setId, name: 'Renamed Set');
        expect(
          fakeOutbox.enqueueCalled,
          isTrue,
          reason: 'renameSet should enqueue outbox item',
        );

        final renamedSet = await wordMatchRepo.getSet(setId);
        expect(renamedSet!.name, equals('Renamed Set'));

        // Save Pairs
        fakeOutbox.enqueueCalled = false;
        final pair =
            WordPair()
              ..english = 'Apple'
              ..turkish = 'Elma'
              ..setId = setId;
        await wordMatchRepo.savePairs(
          setId: setId,
          setName: 'Renamed Set',
          pairs: [pair],
        );
        expect(
          fakeOutbox.enqueueCalled,
          isTrue,
          reason: 'savePairs should enqueue outbox item',
        );

        final pairs = await wordMatchRepo.fetchPairs(setId);
        expect(pairs.length, equals(1));

        // Delete
        fakeOutbox.enqueueCalled = false;
        await wordMatchRepo.deleteSet(setId);
        expect(
          fakeOutbox.enqueueCalled,
          isTrue,
          reason: 'deleteSet should enqueue outbox item',
        );

        final deletedSet = await wordMatchRepo.getSet(setId);
        expect(deletedSet, isNull);
      },
    );

    test('Enqueue hatasında create/update/delete rollback oluyor', () async {
      fakeOutbox.shouldThrow = true; // Inject failure

      // Attempt Create
      await expectLater(
        wordMatchRepo.createSet('Will Rollback Set'),
        throwsA(isA<AppFailure>()),
      );

      // Verify rollback
      final allSets = await wordMatchRepo.watchSets().first;
      expect(allSets, isEmpty, reason: 'Create should be rolled back');

      // Setup a valid set first
      fakeOutbox.shouldThrow = false;
      final validSetId = await wordMatchRepo.createSet('Valid Set');

      // Attempt Update
      fakeOutbox.shouldThrow = true;
      await expectLater(
        wordMatchRepo.renameSet(id: validSetId, name: 'Should Not Rename'),
        throwsA(isA<AppFailure>()),
      );

      // Verify rollback
      final unchangedSet = await wordMatchRepo.getSet(validSetId);
      expect(
        unchangedSet!.name,
        equals('Valid Set'),
        reason: 'Rename should be rolled back',
      );

      // Attempt Save Pairs
      final pair =
          WordPair()
            ..english = 'Cat'
            ..turkish = 'Kedi'
            ..setId = validSetId;
      await expectLater(
        wordMatchRepo.savePairs(
          setId: validSetId,
          setName: 'Valid Set',
          pairs: [pair],
        ),
        throwsA(isA<AppFailure>()),
      );

      // Verify rollback
      final pairs = await wordMatchRepo.fetchPairs(validSetId);
      expect(pairs, isEmpty, reason: 'savePairs should be rolled back');

      // Attempt Delete
      await expectLater(
        wordMatchRepo.deleteSet(validSetId),
        throwsA(isA<AppFailure>()),
      );

      // Verify rollback
      final stillExistingSet = await wordMatchRepo.getSet(validSetId);
      expect(
        stillExistingSet,
        isNotNull,
        reason: 'Delete should be rolled back',
      );
    });
  });
}
