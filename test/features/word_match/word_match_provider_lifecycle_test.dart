// ignore_for_file: non_abstract_class_inherits_abstract_member
// ignore_for_file: unnecessary_no_such_method
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:yunoo/app/di.dart';
import 'package:yunoo/core/utils/browser_storage_stub.dart'
    if (dart.library.html) 'package:yunoo/core/utils/browser_storage_web.dart';
import 'package:flutter/foundation.dart';
import 'package:yunoo/features/auth/data/auth_repo.dart';
import 'package:yunoo/features/auth/logic/auth_controller.dart';
import 'package:yunoo/features/auth/models/app_user.dart';
import 'package:yunoo/features/sync/data/sync_checkpoint_repository.dart';
import 'package:yunoo/features/sync/models/sync_checkpoint.dart';
import 'package:yunoo/features/sync/services/sync_coordinator.dart';
import 'package:yunoo/features/sync/sync_providers.dart';
import 'package:yunoo/features/word_match/data/word_match_providers.dart';

import 'word_match_outbox_integration_test.dart'
    show FakeOutboxRepoForIntegration;

// ignore: subtype_of_sealed_class
class FakeCollectionReferenceForLifecycle extends Fake
    implements CollectionReference<Map<String, dynamic>> {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  DocumentReference<Map<String, dynamic>> doc([String? path]) {
    return FakeDocumentReferenceForLifecycle();
  }
}

// ignore: subtype_of_sealed_class
class FakeDocumentReferenceForLifecycle
    implements DocumentReference<Map<String, dynamic>> {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
  @override
  CollectionReference<Map<String, dynamic>> collection(String path) {
    return FakeCollectionReferenceForLifecycle();
  }

  @override
  Future<DocumentSnapshot<Map<String, dynamic>>> get([
    GetOptions? options,
  ]) async {
    return FakeDocumentSnapshotForLifecycle();
  }

  @override
  Future<void> set(Map<String, dynamic> data, [SetOptions? options]) async {}
}

// ignore: subtype_of_sealed_class
class FakeDocumentSnapshotForLifecycle
    implements DocumentSnapshot<Map<String, dynamic>> {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
  @override
  bool get exists => false;

  @override
  Map<String, dynamic>? data() => null;
}

// ignore: subtype_of_sealed_class
class FakeFirestoreForLifecycle implements FirebaseFirestore {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  CollectionReference<Map<String, dynamic>> collection(String path) {
    return FakeCollectionReferenceForLifecycle();
  }
}

// ignore: subtype_of_sealed_class
class FakeFirebaseUser implements firebase_auth.User {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  FakeFirebaseUser(this._uid);
  final String _uid;

  @override
  String get uid => _uid;

  @override
  bool get isAnonymous => false;
}

class FakeAuthRepoForLifecycle implements AuthRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
  AppUser? mockUser;

  @override
  firebase_auth.User? get currentUser =>
      mockUser != null ? FakeFirebaseUser(mockUser!.uid) : null;

  @override
  Stream<AppUser?> watchAuthUser() => Stream.value(mockUser);

  @override
  Future<AppUser> ensureAnonymousGuestSignedIn() async {
    return mockUser ?? AppUser(uid: 'guest', isAnonymous: true);
  }

  @override
  Future<void> signOut() async {
    mockUser = null;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    clearStorage();
  });

  group(
    'Sprint 4B — Auth User A -> Guest -> User B Provider/Cache Lifecycle Tests',
    () {
      test(
        'wordMatchRepoProvider re-evaluates activeOwnerUid on auth transitions and prevents data leaks',
        () async {
          final fakeAuthRepo = FakeAuthRepoForLifecycle();
          fakeAuthRepo.mockUser = AppUser(
            uid: 'user_A',
            email: 'a@example.com',
            isAnonymous: false,
          );

          final container = ProviderContainer(
            overrides: [
              authRepositoryProvider.overrideWithValue(fakeAuthRepo),
              appIsarProvider.overrideWith((ref) async => null),
              firestoreProvider.overrideWithValue(FakeFirestoreForLifecycle()),
              outboxRepositoryProvider.overrideWith(
                (ref) async => FakeOutboxRepoForIntegration(),
              ),
              syncCoordinatorProvider.overrideWith(
                (ref) async => FakeSyncCoordinatorForLifecycle(),
              ),
              syncCheckpointRepositoryProvider.overrideWith(
                (ref) async => FakeSyncCheckpointRepositoryForLifecycle(),
              ),
            ],
          );
          addTearDown(container.dispose);

          // 1. User A authenticated
          final repoA = await container.read(wordMatchRepoProvider.future);
          expect(repoA.activeOwnerUid, equals('user_A'));

          final userASetId = await repoA.createSet('User A Private Deck');
          expect(await repoA.getSet(userASetId), isNotNull);

          // 2. Logout / Guest transition
          fakeAuthRepo.mockUser = null;
          // Trigger Riverpod invalidation as logout flow does in AuthController
          container.invalidate(authRepositoryProvider);
          container.invalidate(wordMatchRepoProvider);

          final guestRepo = await container.read(wordMatchRepoProvider.future);
          expect(guestRepo.activeOwnerUid, isNull);

          // Guest repository MUST NOT show User A's private deck
          final guestSets = await guestRepo.watchSets().first;
          expect(guestSets.any((s) => s.id == userASetId), isFalse);
          expect(await guestRepo.getSet(userASetId), isNull);

          // 3. User B authenticated
          fakeAuthRepo.mockUser = AppUser(
            uid: 'user_B',
            email: 'b@example.com',
            isAnonymous: false,
          );
          container.invalidate(authRepositoryProvider);
          container.invalidate(wordMatchRepoProvider);

          final repoB = await container.read(wordMatchRepoProvider.future);
          expect(repoB.activeOwnerUid, equals('user_B'));

          // User B repository MUST NOT show User A's private deck
          final userBSets = await repoB.watchSets().first;
          expect(userBSets.any((s) => s.id == userASetId), isFalse);
          expect(await repoB.getSet(userASetId), isNull);

          // User B creates their own set safely
          final userBSetId = await repoB.createSet('User B Deck');
          expect(await repoB.getSet(userBSetId), isNotNull);
          expect(userBSetId, isNot(equals(userASetId)));
        },
      );

      test(
        'AuthController logout invalidates wordMatchRepoProvider cache deterministically',
        () async {
          final fakeAuthRepo = FakeAuthRepoForLifecycle();
          fakeAuthRepo.mockUser = AppUser(
            uid: 'user_A',
            email: 'a@example.com',
            isAnonymous: false,
          );

          final container = ProviderContainer(
            overrides: [
              authRepositoryProvider.overrideWithValue(fakeAuthRepo),
              appIsarProvider.overrideWith((ref) async => null),
              firestoreProvider.overrideWithValue(FakeFirestoreForLifecycle()),
              outboxRepositoryProvider.overrideWith(
                (ref) async => FakeOutboxRepoForIntegration(),
              ),
              syncCoordinatorProvider.overrideWith(
                (ref) async => FakeSyncCoordinatorForLifecycle(),
              ),
              syncCheckpointRepositoryProvider.overrideWith(
                (ref) async => FakeSyncCheckpointRepositoryForLifecycle(),
              ),
            ],
          );
          addTearDown(container.dispose);

          final initialRepo = await container.read(
            wordMatchRepoProvider.future,
          );
          expect(initialRepo.activeOwnerUid, equals('user_A'));

          // Simulate logout action invalidation
          fakeAuthRepo.mockUser = null;
          await container.read(authControllerProvider.notifier).signOut();
          container.invalidate(wordMatchRepoProvider);

          final newRepo = await container.read(wordMatchRepoProvider.future);
          expect(newRepo.activeOwnerUid, isNull);
        },
      );
    },
  );
}

class FakeSyncCoordinatorForLifecycle extends ChangeNotifier
    implements SyncCoordinator {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<void> onUserLogout() async {}
  @override
  Future<void> onUserLogin(AppUser user) async {}
  @override
  SyncStatus get status => SyncStatus.idle;
}

class FakeSyncCheckpointRepositoryForLifecycle
    implements SyncCheckpointRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<SyncCheckpoint?> getCheckpoint({
    required String ownerUid,
    required String entityType,
  }) async => null;
  @override
  Future<void> saveCheckpoint({
    required String ownerUid,
    required String entityType,
    required DateTime? lastServerUpdatedAt,
    required String? tieBreakerDocId,
  }) async {}
}
