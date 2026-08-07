import 'package:flutter_test/flutter_test.dart';
import 'package:yunoo/core/errors/app_failure.dart';
import 'package:yunoo/features/sync/domain/remote_word_set_applier.dart';
import 'package:yunoo/features/sync/services/pull_sync_service.dart';
import 'package:yunoo/features/sync/services/push_sync_service.dart';
import 'package:yunoo/features/sync/services/sync_coordinator.dart';
import 'package:yunoo/features/sync/services/sync_coordinator_impl.dart';
import 'package:yunoo/features/sync/services/sync_listener_manager.dart';
import 'package:yunoo/features/word_match/data/word_match_migration_service.dart';
import 'package:yunoo/features/sync/domain/word_set_sync_codec.dart';
import 'package:yunoo/features/auth/models/app_user.dart';

class FakePushSyncService implements PushSyncService {
  int pushCalled = 0;

  @override
  Future<PushSyncResult> pushOnce({
    required String? ownerUid,
    int batchLimit = 10,
  }) async {
    pushCalled++;
    return PushSyncResult(
      ownerUid: ownerUid ?? '',
      results: [],
      hasMorePending: false,
    );
  }
}

class FakePullSyncService implements PullSyncService {
  int pullCalled = 0;

  @override
  Future<PullSyncResult> pullPage({
    required String? ownerUid,
    String entityType = 'word_set',
    int pageLimit = 20,
  }) async {
    pullCalled++;
    return PullSyncResult(
      ownerUid: ownerUid ?? '',
      changes: [],
      hasMorePages: false,
      lastServerUpdatedAt: null,
      lastTieBreakerDocId: null,
    );
  }

  @override
  Future<void> acknowledgePage({
    required String? ownerUid,
    required RemoteDocumentData lastProcessedDoc,
    String entityType = 'word_set',
  }) async {}
}

class FakeSyncListenerManager implements SyncListenerManager {
  int startCalled = 0;
  int stopCalled = 0;
  String? _currentOwnerUid;

  @override
  String? get currentOwnerUid => _currentOwnerUid;

  @override
  bool get isListening => startCalled > stopCalled;

  @override
  void startListening({
    required String? ownerUid,
    void Function(List<RemoteDocumentData>)? onChanges,
    void Function(AppFailure)? onError,
  }) {
    startCalled++;
    _currentOwnerUid = ownerUid;
  }

  @override
  void stopListening() {
    stopCalled++;
    _currentOwnerUid = null;
  }

  @override
  void dispose() {
    stopListening();
  }
}

class FakeRemoteWordSetApplier implements RemoteWordSetApplier {
  @override
  Future<RemoteDocumentData?> applyPage({
    required String ownerUid,
    required List<RemoteDocumentData> changes,
  }) async {
    return null;
  }
}

class FakeWordMatchMigrationService implements WordMatchMigrationService {
  int migrationCalled = 0;
  bool shouldThrow = false;
  String? Function()? activeUidFetcher;

  @override
  Future<void> migrateLocalSetsForUser(AppUser user) async {
    migrationCalled++;

    // Simulate active UID changing during migration
    if (activeUidFetcher != null) {
      activeUidFetcher!(); // Just triggers any side-effects in the test if needed
    }

    if (shouldThrow) {
      throw AppFailure.database(message: 'err');
    }
  }
}

void main() {
  late SyncCoordinator coordinator;
  late FakePushSyncService fakePushService;
  late FakePullSyncService fakePullService;
  late FakeSyncListenerManager fakeListenerManager;
  late FakeRemoteWordSetApplier fakeApplier;
  late FakeWordMatchMigrationService fakeMigrationService;

  String? activeUid;

  setUp(() {
    fakePushService = FakePushSyncService();
    fakePullService = FakePullSyncService();
    fakeListenerManager = FakeSyncListenerManager();
    fakeApplier = FakeRemoteWordSetApplier();
    fakeMigrationService = FakeWordMatchMigrationService();

    activeUid = 'test_user';

    coordinator = DefaultSyncCoordinator(
      pushService: fakePushService,
      pullService: fakePullService,
      listenerManager: fakeListenerManager,
      applier: fakeApplier,
      migrationService: fakeMigrationService,
      activeUidFetcher: () => activeUid,
    );
  });

  group('SyncCoordinator Bootstrap', () {
    final testUser = const AppUser(
      uid: 'test_user',
      email: 'a@a.com',
      isAnonymous: false,
    );

    test(
      'successfully orchestrates migration, push, pull, and listener startup',
      () async {
        coordinator.onUserLogin(testUser);

        await Future.delayed(const Duration(milliseconds: 100));

        expect(fakeMigrationService.migrationCalled, equals(1));
        expect(fakePushService.pushCalled, equals(1));
        expect(fakePullService.pullCalled, equals(1));
        expect(fakeListenerManager.startCalled, equals(1));
        expect(coordinator.status, equals(SyncStatus.upToDate));
      },
    );

    test('aborts early if user logs out during migration', () async {
      fakeMigrationService.activeUidFetcher = () {
        activeUid = 'other_user';
        return null;
      };

      coordinator.onUserLogin(testUser);
      await Future.delayed(const Duration(milliseconds: 100));

      expect(fakeMigrationService.migrationCalled, equals(1));
      expect(fakePushService.pushCalled, equals(0)); // Should abort before push
    });

    test('handles errors gracefully and sets error status', () async {
      fakeMigrationService.shouldThrow = true;

      coordinator.onUserLogin(testUser);
      await Future.delayed(const Duration(milliseconds: 100));

      expect(fakeMigrationService.migrationCalled, equals(1));
      expect(fakePushService.pushCalled, equals(0));
      expect(coordinator.status, equals(SyncStatus.error));
    });
  });

  group('SyncCoordinator Cleanup', () {
    test('cleanup cancels listener and resets status', () {
      coordinator.onUserLogout();

      expect(fakeListenerManager.stopCalled, equals(1));
      expect(coordinator.status, equals(SyncStatus.idle));
    });
  });
}
