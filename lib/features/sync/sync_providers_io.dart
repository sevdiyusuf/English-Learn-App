import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/di.dart';
import '../auth/data/auth_repo.dart';
import '../word_match/data/word_match_providers.dart';
import '../word_match/data/word_match_migration_service.dart';
import 'data/firestore_sync_gateway.dart';
import 'data/outbox_repository.dart';
import 'data/sync_checkpoint_repository.dart';
import 'domain/remote_word_set_applier.dart';
import 'services/pull_sync_service.dart';
import 'services/push_sync_service.dart';
import 'services/sync_coordinator.dart';
import 'services/sync_coordinator_impl.dart';
import 'services/sync_listener_manager.dart';

// Provides active owner UID dynamically.
final activeUidFetcherProvider = Provider<String? Function()>((ref) {
  return () => ref.read(authRepositoryProvider).currentUser?.uid;
});

// Outbox Repository
final outboxRepositoryProvider = FutureProvider<OutboxRepository>((ref) async {
  final isar = await ref.watch(appIsarProvider.future);
  if (isar == null) {
    throw StateError('Isar is required for OutboxRepository');
  }
  return IsarOutboxRepository(isar);
});

// Sync Checkpoint Repository
final syncCheckpointRepositoryProvider =
    FutureProvider<SyncCheckpointRepository>((ref) async {
      final isar = await ref.watch(appIsarProvider.future);
      if (isar == null) {
        throw StateError('Isar is required for SyncCheckpointRepository');
      }
      return IsarSyncCheckpointRepository(isar);
    });

// Firestore Sync Gateway
final firestoreSyncGatewayProvider = Provider<FirestoreSyncGateway>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return DefaultFirestoreSyncGateway(firestore);
});

// Push Sync Service
final pushSyncServiceProvider = FutureProvider<PushSyncService>((ref) async {
  final outboxRepo = await ref.watch(outboxRepositoryProvider.future);
  final gateway = ref.watch(firestoreSyncGatewayProvider);
  return PushSyncService(
    outboxRepository: outboxRepo,
    gateway: gateway,
    activeAuthenticatedUidFetcher: ref.watch(activeUidFetcherProvider),
  );
});

// Pull Sync Service
final pullSyncServiceProvider = FutureProvider<PullSyncService>((ref) async {
  final checkpointRepo = await ref.watch(
    syncCheckpointRepositoryProvider.future,
  );
  final gateway = ref.watch(firestoreSyncGatewayProvider);
  return PullSyncService(
    gateway: gateway,
    checkpointRepository: checkpointRepo,
    activeAuthenticatedUidFetcher: ref.watch(activeUidFetcherProvider),
  );
});

// Remote Word Set Applier
final remoteWordSetApplierProvider = FutureProvider<RemoteWordSetApplier>((
  ref,
) async {
  final localRepo = await ref.watch(wordMatchRepoProvider.future);
  final outboxRepo = await ref.watch(outboxRepositoryProvider.future);
  return RemoteWordSetApplier(
    localRepo: localRepo,
    outboxRepo: outboxRepo,
    activeUidFetcher: ref.watch(activeUidFetcherProvider),
  );
});

// Sync Listener Manager
final syncListenerManagerProvider = Provider<SyncListenerManager>((ref) {
  final gateway = ref.watch(firestoreSyncGatewayProvider);
  return SyncListenerManager(
    gateway: gateway,
    activeAuthenticatedUidFetcher: ref.watch(activeUidFetcherProvider),
  );
});

// Sync Coordinator
final syncCoordinatorProvider = FutureProvider<SyncCoordinator>((ref) async {
  final migrationService = await ref.watch(
    wordMatchMigrationServiceProvider.future,
  );
  final pushService = await ref.watch(pushSyncServiceProvider.future);
  final pullService = await ref.watch(pullSyncServiceProvider.future);
  final applier = await ref.watch(remoteWordSetApplierProvider.future);
  final listenerManager = ref.watch(syncListenerManagerProvider);
  final activeUidFetcher = ref.watch(activeUidFetcherProvider);

  final coordinator = DefaultSyncCoordinator(
    migrationService: migrationService,
    pushService: pushService,
    pullService: pullService,
    applier: applier,
    listenerManager: listenerManager,
    activeUidFetcher: activeUidFetcher,
  );

  ref.onDispose(() {
    coordinator.dispose();
  });

  return coordinator;
});
