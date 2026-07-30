import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:yunoo/core/utils/browser_storage_stub.dart'
    if (dart.library.html) 'package:yunoo/core/utils/browser_storage_web.dart';
import 'package:yunoo/features/auth/models/app_user.dart';
import 'package:yunoo/features/word_match/data/word_match_migration_service.dart';
import 'package:yunoo/features/word_match/data/word_match_repo_interface.dart';
import 'package:yunoo/features/word_match/data/word_match_repo_prefs.dart';
import 'package:yunoo/features/word_match/data/word_match_repo_web.dart';
import 'package:yunoo/features/word_match/models/word_pair.dart';

/// Fake FirebaseFirestore for testing migration without network connection.
class FakeFirestore implements FirebaseFirestore {
  final Map<String, Map<String, dynamic>> collections = {};
  bool shouldFailWrite = false;
  String? failWriteForPath;

  @override
  CollectionReference<Map<String, dynamic>> collection(String path) {
    return FakeCollectionReference(this, path);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// ignore: subtype_of_sealed_class
class FakeCollectionReference
    implements CollectionReference<Map<String, dynamic>> {
  FakeCollectionReference(this._firestore, this._path);
  final FakeFirestore _firestore;
  final String _path;

  @override
  DocumentReference<Map<String, dynamic>> doc([String? path]) {
    final docId =
        path ?? 'generated_cloud_id_${DateTime.now().microsecondsSinceEpoch}';
    return FakeDocumentReference(_firestore, '$_path/$docId', docId);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// ignore: subtype_of_sealed_class
class FakeDocumentReference implements DocumentReference<Map<String, dynamic>> {
  FakeDocumentReference(this._firestore, this._fullPath, this._id);
  final FakeFirestore _firestore;
  final String _fullPath;
  final String _id;

  @override
  String get id => _id;

  @override
  CollectionReference<Map<String, dynamic>> collection(String path) {
    return FakeCollectionReference(_firestore, '$_fullPath/$path');
  }

  @override
  Future<void> set(Map<String, dynamic> data, [SetOptions? options]) async {
    if (_firestore.shouldFailWrite ||
        (_firestore.failWriteForPath != null &&
            _fullPath.contains(_firestore.failWriteForPath!))) {
      throw Exception('Simulated Firestore Write Failure');
    }
    final existing = _firestore.collections[_fullPath] ?? <String, dynamic>{};
    final merged = Map<String, dynamic>.from(existing)..addAll(data);
    _firestore.collections[_fullPath] = merged;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class ErrorPairsRepoPrefs extends WordMatchRepoPrefs {
  ErrorPairsRepoPrefs({super.activeOwnerUid});
  final Set<int> failSetIds = {};

  @override
  Future<List<WordPair>> getUnmigratedGuestPairs(int setId) async {
    if (failSetIds.contains(setId)) {
      throw Exception('Simulated Pair Reading Failure');
    }
    return super.getUnmigratedGuestPairs(setId);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    clearStorage();
  });

  group('Sprint 4B — Scope Isolation Tests (Prefs & Web Repositories)', () {
    test(
      'Prefs: Guest scope sees only ownerUid == null and builtin sets',
      () async {
        final guestRepo = WordMatchRepoPrefs(activeOwnerUid: null);
        final userARepo = WordMatchRepoPrefs(activeOwnerUid: 'user_A');

        final guestSetId = await guestRepo.createSet('Guest Set Prefs');
        final userASetId = await userARepo.createSet('User A Set Prefs');

        final guestSets = await guestRepo.watchSets().first;
        expect(
          guestSets.any((s) => s.id == guestSetId && s.ownerUid == null),
          isTrue,
        );
        expect(guestSets.any((s) => s.id == userASetId), isFalse);
      },
    );

    test(
      'Web: Guest scope sees only ownerUid == null and builtin sets',
      () async {
        final guestRepo = WordMatchRepoWeb(activeOwnerUid: null);
        final userARepo = WordMatchRepoWeb(activeOwnerUid: 'user_A');

        final guestSetId = await guestRepo.createSet('Guest Set Web');
        final userASetId = await userARepo.createSet('User A Set Web');

        final guestSets = await guestRepo.watchSets().first;
        expect(
          guestSets.any((s) => s.id == guestSetId && s.ownerUid == null),
          isTrue,
        );
        expect(guestSets.any((s) => s.id == userASetId), isFalse);
      },
    );

    test(
      'savePairs normalizes uninitialized WordPair.setId and prevents LateInitializationError',
      () async {
        final userARepo = WordMatchRepoPrefs(activeOwnerUid: 'user_A');
        final setId = await userARepo.createSet('Uninitialized SetId Test');

        final uninitializedPair =
            WordPair()
              ..english = 'grape'
              ..turkish = 'üzüm';

        // Calling savePairs should NOT throw LateInitializationError
        await userARepo.savePairs(
          setId: setId,
          setName: 'Uninitialized SetId Test',
          pairs: [uninitializedPair],
        );

        final fetchedPairs = await userARepo.fetchPairs(setId);
        expect(fetchedPairs.length, equals(1));
        expect(fetchedPairs.first.setId, equals(setId));
        expect(fetchedPairs.first.english, equals('grape'));
      },
    );

    test(
      'Cross-Owner Access Prevention (User B cannot read/update/delete User A set)',
      () async {
        final userARepo = WordMatchRepoPrefs(activeOwnerUid: 'user_A');
        final userBRepo = WordMatchRepoPrefs(activeOwnerUid: 'user_B');

        final userASetId = await userARepo.createSet('User A Private Set');
        await userARepo.savePairs(
          setId: userASetId,
          setName: 'User A Private Set',
          pairs: [
            WordPair()
              ..english = 'apple'
              ..turkish = 'elma',
          ],
        );

        // User B cannot getSet
        expect(await userBRepo.getSet(userASetId), isNull);

        // User B cannot fetchPairs
        expect(await userBRepo.fetchPairs(userASetId), isEmpty);

        // User B renameSet throws StateError
        expect(
          () => userBRepo.renameSet(id: userASetId, name: 'Stolen Name'),
          throwsA(isA<StateError>()),
        );

        // User B deleteSet throws StateError
        expect(
          () => userBRepo.deleteSet(userASetId),
          throwsA(isA<StateError>()),
        );

        // User B updateSetOwnerUid throws StateError
        expect(
          () => userBRepo.updateSetOwnerUid(userASetId, 'user_B'),
          throwsA(isA<StateError>()),
        );

        // User A set remains unchanged
        final setA = await userARepo.getSet(userASetId);
        expect(setA, isNotNull);
        expect(setA!.id, equals(userASetId));
        expect(setA.ownerUid, equals('user_A'));
        expect(setA.name, equals('User A Private Set'));
        expect((await userARepo.fetchPairs(userASetId)).length, equals(1));
      },
    );

    test('Scope Bypass Prevention with reserved wordsFromGamesSetName', () async {
      final userARepo = WordMatchRepoPrefs(activeOwnerUid: 'user_A');
      final userBRepo = WordMatchRepoPrefs(activeOwnerUid: 'user_B');

      // User A creates a custom set named "Words from Games"
      final customSetId = await userARepo.createSet(
        WordMatchRepoInterface.wordsFromGamesSetName,
      );

      // User B MUST NOT see User A's custom set even though it's named "Words from Games"
      final userBSets = await userBRepo.watchSets().first;
      expect(userBSets.any((s) => s.id == customSetId), isFalse);
    });

    test(
      'ensureInitialUserSet creates set with activeOwnerUid and respects scope',
      () async {
        final userARepo = WordMatchRepoPrefs(activeOwnerUid: 'user_A');
        final userBRepo = WordMatchRepoPrefs(activeOwnerUid: 'user_B');

        await userARepo.ensureInitialUserSet();
        expect(await userARepo.countSets(), equals(1));

        // User B should also get their initial set created because User A's set is isolated
        await userBRepo.ensureInitialUserSet();
        expect(await userBRepo.countSets(), equals(1));

        final setA = (await userARepo.watchSets().first).firstWhere(
          (s) => !s.isBuiltin,
        );
        final setB = (await userBRepo.watchSets().first).firstWhere(
          (s) => !s.isBuiltin,
        );

        expect(setA.ownerUid, equals('user_A'));
        expect(setB.ownerUid, equals('user_B'));
        expect(setA.id, isNot(equals(setB.id)));
      },
    );
  });

  group('Sprint 4B — WordMatchMigrationService Tests', () {
    late FakeFirestore fakeFirestore;
    late WordMatchRepoPrefs guestRepo;
    late WordMatchRepoPrefs userARepo;

    setUp(() {
      fakeFirestore = FakeFirestore();
      guestRepo = WordMatchRepoPrefs(activeOwnerUid: null);
      userARepo = WordMatchRepoPrefs(activeOwnerUid: 'user_A');
    });

    test(
      'Migration reads pairs using getUnmigratedGuestPairs and writes canonical schema to word_match_sets',
      () async {
        final setId = await guestRepo.createSet('My Guest Set');
        await guestRepo.savePairs(
          setId: setId,
          setName: 'My Guest Set',
          pairs: [
            WordPair()
              ..english = 'book'
              ..turkish = 'kitap'
              ..learned = true,
            WordPair()
              ..english = 'pen'
              ..turkish = 'kalem'
              ..learned = false,
          ],
        );

        final migrationService = WordMatchMigrationService(
          fakeFirestore,
          userARepo,
        );
        final userA = AppUser(uid: 'user_A', email: 'a@example.com');

        await migrationService.migrateLocalSetsForUser(userA);

        // Check Firestore payload
        expect(fakeFirestore.collections.length, equals(1));
        final entry = fakeFirestore.collections.entries.first;

        expect(entry.key, startsWith('users/user_A/word_match_sets/'));
        expect(entry.key, isNot(contains('users/user_A/sets/')));

        final payload = entry.value;
        expect(payload['name'], equals('My Guest Set'));
        expect(payload['pairs'], isA<List>());
        final pairs = payload['pairs'] as List;
        expect(pairs.length, equals(2));
        expect(pairs[0]['english'], equals('book'));
        expect(pairs[0]['turkish'], equals('kitap'));
        expect(pairs[0]['learned'], isTrue);

        // Verify local ownership updated to user_A
        final setA = await userARepo.getSet(setId);
        expect(setA, isNotNull);
        expect(setA!.id, equals(setId));
        expect(setA.ownerUid, equals('user_A'));
      },
    );

    test(
      'Migration idempotency (running twice produces only 1 document)',
      () async {
        final setId = await guestRepo.createSet('Idempotent Set');
        await guestRepo.savePairs(
          setId: setId,
          setName: 'Idempotent Set',
          pairs: [
            WordPair()
              ..english = 'cat'
              ..turkish = 'kedi',
          ],
        );

        final migrationService = WordMatchMigrationService(
          fakeFirestore,
          userARepo,
        );
        final userA = AppUser(uid: 'user_A', email: 'a@example.com');

        await migrationService.migrateLocalSetsForUser(userA);
        expect(fakeFirestore.collections.length, equals(1));

        // Run second time
        await migrationService.migrateLocalSetsForUser(userA);
        expect(fakeFirestore.collections.length, equals(1));
      },
    );

    test(
      'Remote write failure leaves ownerUid null and preserves cloudId + pendingMigrationUid',
      () async {
        final setId = await guestRepo.createSet('Failure Set');
        await guestRepo.savePairs(
          setId: setId,
          setName: 'Failure Set',
          pairs: [
            WordPair()
              ..english = 'dog'
              ..turkish = 'köpek',
          ],
        );

        fakeFirestore.shouldFailWrite = true;

        final migrationService = WordMatchMigrationService(
          fakeFirestore,
          userARepo,
        );
        final userA = AppUser(uid: 'user_A', email: 'a@example.com');

        await migrationService.migrateLocalSetsForUser(userA);

        // Check local set state
        final unmigrated = await guestRepo.getUnmigratedGuestSets();
        expect(unmigrated.length, equals(1));

        final failedSet = unmigrated.first;
        expect(failedSet.id, equals(setId));
        expect(failedSet.ownerUid, isNull);
        expect(failedSet.cloudId, isNotNull);
        expect(failedSet.pendingMigrationUid, equals('user_A'));
      },
    );

    test('Failed migration for User A cannot be claimed by User B', () async {
      final setId = await guestRepo.createSet('User A Pending Set');
      await guestRepo.savePairs(
        setId: setId,
        setName: 'User A Pending Set',
        pairs: [
          WordPair()
            ..english = 'sun'
            ..turkish = 'güneş',
        ],
      );

      fakeFirestore.shouldFailWrite = true;

      final migrationServiceA = WordMatchMigrationService(
        fakeFirestore,
        userARepo,
      );
      final userA = AppUser(uid: 'user_A', email: 'a@example.com');

      // User A migration fails, setting pendingMigrationUid = 'user_A'
      await migrationServiceA.migrateLocalSetsForUser(userA);

      // Now User B tries to migrate
      fakeFirestore.shouldFailWrite = false;
      final userBRepo = WordMatchRepoPrefs(activeOwnerUid: 'user_B');
      final migrationServiceB = WordMatchMigrationService(
        fakeFirestore,
        userBRepo,
      );
      final userB = AppUser(uid: 'user_B', email: 'b@example.com');

      await migrationServiceB.migrateLocalSetsForUser(userB);

      // User B MUST NOT have migrated User A's pending set
      expect(fakeFirestore.collections.length, equals(0));

      final unmigrated = await guestRepo.getUnmigratedGuestSets();
      expect(unmigrated.first.id, equals(setId));
      expect(unmigrated.first.ownerUid, isNull);
      expect(unmigrated.first.pendingMigrationUid, equals('user_A'));
    });

    test(
      'Pair reading error does NOT cause remote write or owner change',
      () async {
        final errorRepo = ErrorPairsRepoPrefs(activeOwnerUid: 'user_A');
        final guestRepoLocal = ErrorPairsRepoPrefs(activeOwnerUid: null);

        final setId = await guestRepoLocal.createSet('Corrupted Pair Set');
        await guestRepoLocal.savePairs(
          setId: setId,
          setName: 'Corrupted Pair Set',
          pairs: [
            WordPair()
              ..english = 'tree'
              ..turkish = 'ağaç',
          ],
        );

        // Mark set to throw error on pair read
        errorRepo.failSetIds.add(setId);

        final migrationService = WordMatchMigrationService(
          fakeFirestore,
          errorRepo,
        );
        final userA = AppUser(uid: 'user_A', email: 'a@example.com');

        await migrationService.migrateLocalSetsForUser(userA);

        // Remote write MUST NOT be attempted
        expect(fakeFirestore.collections.length, equals(0));

        // Local set ownerUid MUST remain null
        final unmigrated = await guestRepoLocal.getUnmigratedGuestSets();
        expect(unmigrated.length, equals(1));
        expect(unmigrated.first.ownerUid, isNull);
      },
    );

    test('Multiple sets partial success and safe retry', () async {
      final setId1 = await guestRepo.createSet('Guest Set 1');
      await guestRepo.savePairs(
        setId: setId1,
        setName: 'Guest Set 1',
        pairs: [
          WordPair()
            ..english = 'one'
            ..turkish = 'bir',
        ],
      );

      final setId2 = await guestRepo.createSet('Guest Set 2');
      await guestRepo.savePairs(
        setId: setId2,
        setName: 'Guest Set 2',
        pairs: [
          WordPair()
            ..english = 'two'
            ..turkish = 'iki',
        ],
      );

      // Fail write for set 2 cloud ID candidate
      fakeFirestore.failWriteForPath =
          'generated_cloud_id_'; // We'll target fail on 2nd set
      // Generate set 1 cloudId first to make failWriteForPath target set 2
      final doc2 = fakeFirestore
          .collection('users')
          .doc('user_A')
          .collection('word_match_sets')
          .doc('set2_target_cloud_id');
      await guestRepo.updateSetCloudId(setId2, doc2.id);
      fakeFirestore.failWriteForPath = doc2.id;

      final migrationService = WordMatchMigrationService(
        fakeFirestore,
        userARepo,
      );
      final userA = AppUser(uid: 'user_A', email: 'a@example.com');

      // First run: Set 1 succeeds, Set 2 fails
      await migrationService.migrateLocalSetsForUser(userA);

      // Set 1 migrated to cloud and owner updated
      final set1 = await userARepo.getSet(setId1);
      expect(set1, isNotNull);
      expect(set1!.ownerUid, equals('user_A'));

      // Set 2 write failed, ownerUid remains null, cloudId & pendingMigrationUid preserved
      final unmigratedAfterRun1 = await guestRepo.getUnmigratedGuestSets();
      expect(unmigratedAfterRun1.length, equals(1));
      expect(unmigratedAfterRun1.first.id, equals(setId2));
      expect(unmigratedAfterRun1.first.ownerUid, isNull);
      expect(unmigratedAfterRun1.first.cloudId, equals(doc2.id));
      expect(unmigratedAfterRun1.first.pendingMigrationUid, equals('user_A'));

      // Retry run: Clear write failure
      fakeFirestore.failWriteForPath = null;
      await migrationService.migrateLocalSetsForUser(userA);

      // Set 2 successfully completed under same cloud ID
      final set2 = await userARepo.getSet(setId2);
      expect(set2, isNotNull);
      expect(set2!.ownerUid, equals('user_A'));
      expect(set2.pendingMigrationUid, isNull);
      expect(set2.cloudId, equals(doc2.id));

      // Verify canonical collections count is exactly 2 documents
      expect(fakeFirestore.collections.length, equals(2));
    });

    test('Pre-existing cloud document protection (Crash recovery)', () async {
      final setId = await guestRepo.createSet('Recovery Set');
      await guestRepo.savePairs(
        setId: setId,
        setName: 'Recovery Set',
        pairs: [
          WordPair()
            ..english = 'star'
            ..turkish = 'yıldız',
        ],
      );

      const existingCloudId = 'existing_cloud_doc_123';
      await guestRepo.updateSetCloudId(setId, existingCloudId);
      await guestRepo.updateSetPendingMigrationUid(setId, 'user_A');

      // Populate pre-existing document in fake firestore with sentinel field
      final docPath = 'users/user_A/word_match_sets/$existingCloudId';
      fakeFirestore.collections[docPath] = {
        'name': 'Recovery Set',
        'sentinel': 'PRE_EXISTING_SENTINEL',
      };

      final migrationService = WordMatchMigrationService(
        fakeFirestore,
        userARepo,
      );
      final userA = AppUser(uid: 'user_A', email: 'a@example.com');

      await migrationService.migrateLocalSetsForUser(userA);

      // Sentinel field MUST be preserved in merged payload
      expect(
        fakeFirestore.collections[docPath]?['sentinel'],
        equals('PRE_EXISTING_SENTINEL'),
      );

      // Local set ownerUid updated to user_A and pendingMigrationUid cleared
      final setA = await userARepo.getSet(setId);
      expect(setA, isNotNull);
      expect(setA!.ownerUid, equals('user_A'));
      expect(setA.pendingMigrationUid, isNull);

      // Subsequent migration run is idempotent
      await migrationService.migrateLocalSetsForUser(userA);
      expect(fakeFirestore.collections.length, equals(1));
    });
  });
}
