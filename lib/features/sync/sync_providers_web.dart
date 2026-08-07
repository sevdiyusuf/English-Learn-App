import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/data/auth_repo.dart';
import '../auth/models/app_user.dart';
import 'services/sync_coordinator.dart';

// Provides active owner UID dynamically.
final activeUidFetcherProvider = Provider<String? Function()>((ref) {
  return () => ref.read(authRepositoryProvider).currentUser?.uid;
});

class WebSyncCoordinator extends SyncCoordinator {
  WebSyncCoordinator() : super.custom();

  @override
  SyncStatus get status => SyncStatus.upToDate;

  @override
  Future<void> onUserLogin(AppUser user) async {}

  @override
  Future<void> onUserLogout() async {}

  @override
  Future<void> triggerSync() async {}
}

final outboxRepositoryProvider = FutureProvider<dynamic>((ref) async {
  throw UnsupportedError('OutboxRepository is not supported on Web');
});

final syncCheckpointRepositoryProvider = FutureProvider<dynamic>((ref) async {
  throw UnsupportedError('SyncCheckpointRepository is not supported on Web');
});

final firestoreSyncGatewayProvider = Provider<dynamic>((ref) {
  throw UnsupportedError('FirestoreSyncGateway is not supported on Web');
});

final pushSyncServiceProvider = FutureProvider<dynamic>((ref) async {
  throw UnsupportedError('PushSyncService is not supported on Web');
});

final pullSyncServiceProvider = FutureProvider<dynamic>((ref) async {
  throw UnsupportedError('PullSyncService is not supported on Web');
});

final remoteWordSetApplierProvider = FutureProvider<dynamic>((ref) async {
  throw UnsupportedError('RemoteWordSetApplier is not supported on Web');
});

final syncListenerManagerProvider = Provider<dynamic>((ref) {
  throw UnsupportedError('SyncListenerManager is not supported on Web');
});

final syncCoordinatorProvider = FutureProvider<SyncCoordinator>((ref) async {
  final coordinator = WebSyncCoordinator();
  ref.onDispose(() {
    coordinator.dispose();
  });
  return coordinator;
});
