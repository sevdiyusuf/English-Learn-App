import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';
import 'package:yunoo/features/sync/models/local_schema_metadata.dart';
import 'package:yunoo/features/sync/models/outbox_item.dart';
import 'package:yunoo/features/word_match/models/word_pair.dart';
import 'package:yunoo/features/word_match/models/word_set.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    HttpOverrides.global = null;
    await Isar.initializeIsarCore(download: true);
  });

  group('Isar Schema & Persistence Contracts', () {
    Directory? tempDir;
    late Isar isar;
    var isarInitialized = false;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('isar_contract_test_');
      isar = await Isar.open(
        [
          WordSetSchema,
          WordPairSchema,
          OutboxItemSchema,
          LocalSchemaMetadataSchema,
        ],
        directory: tempDir!.path,
        name: 'test_contract_${DateTime.now().microsecondsSinceEpoch}',
      );
      isarInitialized = true;
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

    test('Isar collection names and schemas remain deterministic', () {
      final schemas = [
        WordSetSchema,
        WordPairSchema,
        OutboxItemSchema,
        LocalSchemaMetadataSchema,
      ];

      expect(WordSetSchema.name, 'WordSet319');
      expect(WordPairSchema.name, 'WordPair365');
      expect(OutboxItemSchema.name, 'OutboxItem1');
      expect(LocalSchemaMetadataSchema.name, 'LocalSchemaMetadata1');

      for (final schema in schemas) {
        expect(schema.name, isNotEmpty);
        expect(schema.idName, isNotEmpty);
      }
    });

    test('OutboxItem and WordSet schema ID names stability', () {
      expect(OutboxItemSchema.idName, 'id');
      expect(WordSetSchema.idName, 'id');
      expect(WordPairSchema.idName, 'id');
    });

    test(
      'Legacy/partial records without ownerUid or optional fields load safely',
      () async {
        final legacySet =
            WordSet()
              ..name = 'Legacy Set'
              ..ownerUid = null
              ..cloudId = null
              ..lastPracticedAt = null
              ..isBuiltin = false
              ..createdAt = DateTime.now()
              ..updatedAt = DateTime.now();

        await isar.writeTxn(() async {
          await isar.wordSets.put(legacySet);
        });

        final loadedSet = await isar.wordSets.get(legacySet.id);
        expect(loadedSet, isNotNull);
        expect(loadedSet?.name, 'Legacy Set');
        expect(loadedSet?.ownerUid, isNull);
        expect(loadedSet?.cloudId, isNull);
        expect(loadedSet?.lastPracticedAt, isNull);
      },
    );

    test(
      'Owner isolation in queries is preserved across account switches',
      () async {
        final setA =
            WordSet()
              ..name = 'Set User A'
              ..ownerUid = 'user_A'
              ..createdAt = DateTime.now()
              ..updatedAt = DateTime.now();

        final setB =
            WordSet()
              ..name = 'Set User B'
              ..ownerUid = 'user_B'
              ..createdAt = DateTime.now()
              ..updatedAt = DateTime.now();

        await isar.writeTxn(() async {
          await isar.wordSets.putAll([setA, setB]);
        });

        final resultsA =
            await isar.wordSets.filter().ownerUidEqualTo('user_A').findAll();
        expect(resultsA.length, 1);
        expect(resultsA.first.name, 'Set User A');

        final resultsB =
            await isar.wordSets.filter().ownerUidEqualTo('user_B').findAll();
        expect(resultsB.length, 1);
        expect(resultsB.first.name, 'Set User B');

        final resultsGuest =
            await isar.wordSets.filter().ownerUidIsNull().findAll();
        expect(resultsGuest.length, 0);
      },
    );

    test(
      'Database closes and reopens existing file on disk preserving all records, identities and isolation',
      () async {
        final dbName =
            'persisted_db_test_${DateTime.now().microsecondsSinceEpoch}';
        final dbDir = await Directory.systemTemp.createTemp(
          'isar_persist_test_',
        );

        // Step 1: Open initial database and populate records
        var instance1 = await Isar.open(
          [
            WordSetSchema,
            WordPairSchema,
            OutboxItemSchema,
            LocalSchemaMetadataSchema,
          ],
          directory: dbDir.path,
          name: dbName,
        );

        final wordSet =
            WordSet()
              ..name = 'Persisted Set'
              ..ownerUid = 'user_persistent'
              ..createdAt = DateTime.now()
              ..updatedAt = DateTime.now();

        final wordPair =
            WordPair()
              ..setId = 101
              ..english = 'apple'
              ..turkish = 'elma'
              ..learned = true;

        final outboxItem =
            OutboxItem()
              ..operationId = 'op_persist_1'
              ..entityType = 'word_set'
              ..entityId = '101'
              ..coalescingKey = 'user_persistent_word_set_101'
              ..ownerUid = 'user_persistent'
              ..operation = OutboxOperationType.create
              ..createdAt = DateTime.now()
              ..updatedAt = DateTime.now();

        final metadata =
            LocalSchemaMetadata()
              ..version = 1
              ..appliedAt = DateTime.now()
              ..isSuccessful = true
              ..description = 'Initial schema';

        await instance1.writeTxn(() async {
          await instance1.wordSets.put(wordSet);
          await instance1.wordPairs.put(wordPair);
          await instance1.outboxItems.put(outboxItem);
          await instance1.localSchemaMetadatas.put(metadata);
        });

        // Verify count in initial instance
        expect(await instance1.wordSets.count(), 1);
        expect(await instance1.wordPairs.count(), 1);
        expect(await instance1.outboxItems.count(), 1);
        expect(await instance1.localSchemaMetadatas.count(), 1);

        // Step 2: Close instance without deleting files on disk
        await instance1.close(deleteFromDisk: false);

        // Step 3: Reopen database from exact same directory & name
        var instance2 = await Isar.open(
          [
            WordSetSchema,
            WordPairSchema,
            OutboxItemSchema,
            LocalSchemaMetadataSchema,
          ],
          directory: dbDir.path,
          name: dbName,
        );

        // Verify all records survived intact
        final reloadedSets =
            await instance2.wordSets
                .filter()
                .ownerUidEqualTo('user_persistent')
                .findAll();
        expect(reloadedSets.length, 1);
        expect(reloadedSets.first.name, 'Persisted Set');

        final reloadedPairs =
            await instance2.wordPairs.filter().setIdEqualTo(101).findAll();
        expect(reloadedPairs.length, 1);
        expect(reloadedPairs.first.english, 'apple');
        expect(reloadedPairs.first.turkish, 'elma');
        expect(reloadedPairs.first.learned, true);

        final reloadedOutbox =
            await instance2.outboxItems
                .filter()
                .operationIdEqualTo('op_persist_1')
                .findAll();
        expect(reloadedOutbox.length, 1);
        expect(
          reloadedOutbox.first.coalescingKey,
          'user_persistent_word_set_101',
        );

        final reloadedMeta =
            await instance2.localSchemaMetadatas
                .filter()
                .versionEqualTo(1)
                .findAll();
        expect(reloadedMeta.length, 1);
        expect(reloadedMeta.first.isSuccessful, true);

        // Cleanup
        await instance2.close(deleteFromDisk: true);
        if (await dbDir.exists()) {
          await dbDir.delete(recursive: true);
        }
      },
    );
  });
}
