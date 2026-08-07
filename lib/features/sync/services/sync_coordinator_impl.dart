import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/performance/performance_service.dart';
import '../../../core/performance/performance_traces.dart';
import '../../auth/models/app_user.dart';
import '../../word_match/data/word_match_migration_service.dart';
import '../domain/remote_word_set_applier.dart';
import 'pull_sync_service.dart';
import 'push_sync_service.dart';
import 'sync_coordinator.dart';
import 'sync_listener_manager.dart';

/// Concrete IO implementation orchestrating sync for native platforms.
class DefaultSyncCoordinator extends SyncCoordinator {
  DefaultSyncCoordinator({
    required WordMatchMigrationService migrationService,
    required PushSyncService pushService,
    required PullSyncService pullService,
    required RemoteWordSetApplier applier,
    required SyncListenerManager listenerManager,
    required String? Function() activeUidFetcher,
  }) : _migrationService = migrationService,
       _pushService = pushService,
       _pullService = pullService,
       _applier = applier,
       _listenerManager = listenerManager,
       _activeUidFetcher = activeUidFetcher,
       super.custom();

  final WordMatchMigrationService _migrationService;
  final PushSyncService _pushService;
  final PullSyncService _pullService;
  final RemoteWordSetApplier _applier;
  final SyncListenerManager _listenerManager;
  final String? Function() _activeUidFetcher;

  SyncStatus _status = SyncStatus.idle;

  @override
  SyncStatus get status => _status;

  Future<void>? _bootstrapFuture;
  String? _activeBootstrapUid;

  void _setStatus(SyncStatus newStatus) {
    if (_status != newStatus) {
      _status = newStatus;
      notifyListeners();
    }
  }

  @override
  Future<void> onUserLogin(AppUser user) async {
    final uid = user.uid;
    if (_activeUidFetcher() != uid) {
      debugPrint(
        'SyncCoordinator: Ignoring login for $uid, active session is different.',
      );
      return;
    }

    if (_activeBootstrapUid == uid && _bootstrapFuture != null) {
      debugPrint('SyncCoordinator: Bootstrap already in progress for $uid.');
      return _bootstrapFuture;
    }

    _activeBootstrapUid = uid;
    _bootstrapFuture = _runBootstrap(user);
    await _bootstrapFuture;
  }

  @override
  Future<void> onUserLogout() async {
    _activeBootstrapUid = null;
    _bootstrapFuture = null;
    _listenerManager.stopListening();
    _setStatus(SyncStatus.idle);
  }

  @override
  Future<void> triggerSync() async {
    final activeUid = _activeUidFetcher();
    if (activeUid != null && activeUid.isNotEmpty) {
      await _handleRemoteChange(activeUid);
    }
  }

  Future<void> _runBootstrap(AppUser user) async {
    await PerformanceService.instance.traceAsync(
      PerformanceTraces.syncCycle,
      () async {
        try {
          _setStatus(SyncStatus.syncing);
          final uid = user.uid;

          // 1. Guest -> User Migration
          debugPrint('SyncCoordinator: Starting migration for $uid');
          await _migrationService.migrateLocalSetsForUser(user);
          if (_activeUidFetcher() != uid) return;

          // 2. Initial Push (flush existing outbox items)
          debugPrint('SyncCoordinator: Starting initial push for $uid');
          await _pushService.pushOnce(ownerUid: uid, batchLimit: 10);
          if (_activeUidFetcher() != uid) return;

          // 3. Full Pull (catch up from last checkpoint)
          debugPrint('SyncCoordinator: Starting full pull for $uid');
          await _runPullLoop(uid);
          if (_activeUidFetcher() != uid) return;

          // 4. Start Real-time Listener
          debugPrint('SyncCoordinator: Starting real-time listener for $uid');
          _listenerManager.startListening(
            ownerUid: uid,
            onChanges: (changes) => _handleRemoteChange(uid),
          );

          if (_activeUidFetcher() == uid) {
            _setStatus(SyncStatus.upToDate);
            debugPrint('SyncCoordinator: Bootstrap completed for $uid');
          }
        } catch (e, stack) {
          debugPrint(
            'SyncCoordinator: Bootstrap failed for ${user.uid}: $e\n$stack',
          );
          if (_activeUidFetcher() == user.uid) {
            _setStatus(SyncStatus.error);
          }
        } finally {
          if (_status == SyncStatus.error) {
            _bootstrapFuture = null; // Allow retry on error
          }
        }
      },
      attributes: {PerformanceParams.operation: 'sync_bootstrap'},
    );
  }

  Future<void> _runPullLoop(String uid) async {
    while (true) {
      if (_activeUidFetcher() != uid) return;

      final result = await _pullService.pullPage(ownerUid: uid, pageLimit: 10);
      if (result.changes.isEmpty) break; // Reached end

      // Apply local changes
      final lastSuccessfulDoc = await _applier.applyPage(
        ownerUid: uid,
        changes: result.changes,
      );

      // Advance checkpoint if at least one document succeeded
      if (lastSuccessfulDoc != null) {
        await _pullService.acknowledgePage(
          ownerUid: uid,
          lastProcessedDoc: lastSuccessfulDoc,
        );
      }

      if (lastSuccessfulDoc == null) {
        debugPrint(
          'SyncCoordinator: Failed to apply any docs in page, aborting pull loop.',
        );
        break;
      }

      if (!result.hasMorePages) break; // Last page
    }
  }

  Future<void> _handleRemoteChange(String uid) async {
    if (_activeUidFetcher() != uid) return;

    try {
      _setStatus(SyncStatus.syncing);
      await _runPullLoop(uid);
      if (_activeUidFetcher() == uid) {
        _setStatus(SyncStatus.upToDate);
      }
    } catch (e, stack) {
      debugPrint('SyncCoordinator: Remote change pull failed: $e\n$stack');
      if (_activeUidFetcher() == uid) {
        _setStatus(SyncStatus.error);
      }
    }
  }

  @override
  void dispose() {
    _listenerManager.stopListening();
    super.dispose();
  }
}
