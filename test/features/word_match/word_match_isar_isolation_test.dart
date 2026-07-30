import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';

import 'package:yunoo/features/sync/models/local_schema_metadata.dart';
import 'package:yunoo/features/sync/models/outbox_item.dart';
import 'package:yunoo/features/sync/models/sync_checkpoint.dart';
import 'package:yunoo/features/word_match/data/word_match_repo.dart';
import 'package:yunoo/features/word_match/data/word_match_repo_interface.dart';
import 'package:yunoo/features/word_match/models/word_pair.dart';
import 'package:yunoo/features/word_match/models/word_set.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Directory? tempDir;
  late Isar isar;
  var isarInitialized = false;

  setUpAll(() async {
    HttpOverrides.global = null;
    await Isar.initializeIsarCore(download: true);
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('isar_isolation_test_');
    isar = await Isar.open(
      [
        WordSetSchema,
        WordPairSchema,
        OutboxItemSchema,
        LocalSchemaMetadataSchema,
        SyncCheckpointSchema,
      ],
      directory: tempDir!.path,
      name: 'test_isar_${DateTime.now().microsecondsSinceEpoch}',
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

  group('Sprint 4B — Real Isar Repository Scope & Mutation Isolation', () {
    test(
      'Scope visibility: Guest, User A, and User B see only authorized sets',
      () async {
        final guestRepo = WordMatchRepo(isar, activeOwnerUid: null);
        final userARepo = WordMatchRepo(isar, activeOwnerUid: 'user_A');
        final userBRepo = WordMatchRepo(isar, activeOwnerUid: 'user_B');

        // Create builtin set directly in Isar
        final builtinSet =
            WordSet()
              ..name = 'Builtin Level Set'
              ..createdAt = DateTime.now()
              ..updatedAt = DateTime.now()
              ..isBuiltin = true;

        await isar.writeTxn(() async {
          await isar.wordSets.put(builtinSet);
        });

        final guestSetId = await guestRepo.createSet('Guest Set');
        final userASetId = await userARepo.createSet('User A Set');
        final userBSetId = await userBRepo.createSet('User B Set');

        // Guest visibility
        final guestSets = await guestRepo.watchSets().first;
        expect(
          guestSets.any((s) => s.id == guestSetId && s.ownerUid == null),
          isTrue,
        );
        expect(guestSets.any((s) => s.id == builtinSet.id), isTrue);
        expect(guestSets.any((s) => s.id == userASetId), isFalse);
        expect(guestSets.any((s) => s.id == userBSetId), isFalse);

        // User A visibility
        final userASets = await userARepo.watchSets().first;
        expect(
          userASets.any((s) => s.id == userASetId && s.ownerUid == 'user_A'),
          isTrue,
        );
        expect(userASets.any((s) => s.id == builtinSet.id), isTrue);
        expect(userASets.any((s) => s.id == guestSetId), isFalse);
        expect(userASets.any((s) => s.id == userBSetId), isFalse);

        // User B visibility
        final userBSets = await userBRepo.watchSets().first;
        expect(
          userBSets.any((s) => s.id == userBSetId && s.ownerUid == 'user_B'),
          isTrue,
        );
        expect(userBSets.any((s) => s.id == builtinSet.id), isTrue);
        expect(userBSets.any((s) => s.id == guestSetId), isFalse);
        expect(userBSets.any((s) => s.id == userASetId), isFalse);
      },
    );

    test(
      'Cross-owner read prevention: User B cannot read User A set via getSet or fetchPairs',
      () async {
        final userARepo = WordMatchRepo(isar, activeOwnerUid: 'user_A');
        final userBRepo = WordMatchRepo(isar, activeOwnerUid: 'user_B');

        final userASetId = await userARepo.createSet('User A Private');
        await userARepo.savePairs(
          setId: userASetId,
          setName: 'User A Private',
          pairs: [
            WordPair()
              ..english = 'secret'
              ..turkish = 'gizli',
          ],
        );

        // User B getSet returns null
        expect(await userBRepo.getSet(userASetId), isNull);

        // User B fetchPairs returns empty
        expect(await userBRepo.fetchPairs(userASetId), isEmpty);
      },
    );

    test(
      'Cross-owner mutation prevention: Unauthorized mutations throw StateError and preserve target data',
      () async {
        final userARepo = WordMatchRepo(isar, activeOwnerUid: 'user_A');
        final userBRepo = WordMatchRepo(isar, activeOwnerUid: 'user_B');

        final userASetId = await userARepo.createSet('User A Intact Set');
        await userARepo.savePairs(
          setId: userASetId,
          setName: 'User A Intact Set',
          pairs: [
            WordPair()
              ..english = 'sun'
              ..turkish = 'güneş',
          ],
        );

        // Unauthorized renameSet
        expect(
          () => userBRepo.renameSet(id: userASetId, name: 'Hacked Name'),
          throwsA(isA<StateError>()),
        );

        // Unauthorized deleteSet
        expect(
          () => userBRepo.deleteSet(userASetId),
          throwsA(isA<StateError>()),
        );

        // Unauthorized savePairs
        expect(
          () => userBRepo.savePairs(
            setId: userASetId,
            setName: 'User A Intact Set',
            pairs: [
              WordPair()
                ..english = 'moon'
                ..turkish = 'ay',
            ],
          ),
          throwsA(isA<StateError>()),
        );

        // Unauthorized updateSetOwnerUid
        expect(
          () => userBRepo.updateSetOwnerUid(userASetId, 'user_B'),
          throwsA(isA<StateError>()),
        );

        // Verify User A set data remains completely unchanged
        final setA = await userARepo.getSet(userASetId);
        expect(setA, isNotNull);
        expect(setA!.name, equals('User A Intact Set'));
        expect(setA.ownerUid, equals('user_A'));

        final pairsA = await userARepo.fetchPairs(userASetId);
        expect(pairsA.length, equals(1));
        expect(pairsA.first.english, equals('sun'));
      },
    );

    test('Owner valid mutations succeed on owned sets', () async {
      final userARepo = WordMatchRepo(isar, activeOwnerUid: 'user_A');
      final setId = await userARepo.createSet('Original Name');

      await userARepo.renameSet(id: setId, name: 'Renamed Name');
      final updatedSet = await userARepo.getSet(setId);
      expect(updatedSet!.name, equals('Renamed Name'));

      await userARepo.savePairs(
        setId: setId,
        setName: 'Renamed Name',
        pairs: [
          WordPair()
            ..english = 'star'
            ..turkish = 'yıldız',
        ],
      );

      final pairs = await userARepo.fetchPairs(setId);
      expect(pairs.length, equals(1));
      expect(pairs.first.english, equals('star'));

      await userARepo.deleteSet(setId);
      expect(await userARepo.getSet(setId), isNull);
    });

    test('Builtin set mutations are rejected according to contract', () async {
      final userARepo = WordMatchRepo(isar, activeOwnerUid: 'user_A');

      final builtinSet =
          WordSet()
            ..name = WordMatchRepoInterface.wordsFromGamesSetName
            ..createdAt = DateTime.now()
            ..updatedAt = DateTime.now()
            ..isBuiltin = true;

      await isar.writeTxn(() async {
        await isar.wordSets.put(builtinSet);
      });

      expect(
        () => userARepo.renameSet(id: builtinSet.id, name: 'New Builtin Name'),
        throwsA(isA<StateError>()),
      );

      expect(
        () => userARepo.deleteSet(builtinSet.id),
        throwsA(isA<StateError>()),
      );

      expect(
        () => userARepo.savePairs(
          setId: builtinSet.id,
          setName: WordMatchRepoInterface.wordsFromGamesSetName,
          pairs: [
            WordPair()
              ..english = 'test'
              ..turkish = 'test',
          ],
        ),
        throwsA(isA<StateError>()),
      );
    });
  });
}
