import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../auth/models/app_user.dart';
import '../../word_match/data/word_match_migration_service.dart';
import '../domain/remote_word_set_applier.dart';
import 'pull_sync_service.dart';
import 'push_sync_service.dart';
import 'sync_listener_manager.dart';

enum SyncStatus { idle, syncing, upToDate, error }

/// Orchestrates the entire sync lifecycle for a user session.
/// Handles migration, push, pull, and real-time listeners.
class SyncCoordinator extends ChangeNotifier {
  SyncCoordinator({
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
       _activeUidFetcher = activeUidFetcher;

  final WordMatchMigrationService _migrationService;
  final PushSyncService _pushService;
  final PullSyncService _pullService;
  final RemoteWordSetApplier _applier;
  final SyncListenerManager _listenerManager;
  final String? Function() _activeUidFetcher;

  SyncStatus _status = SyncStatus.idle;
  SyncStatus get status => _status;

  Future<void>? _bootstrapFuture;
  String? _activeBootstrapUid;

  void _setStatus(SyncStatus newStatus) {
    if (_status != newStatus) {
      _status = newStatus;
      notifyListeners();
    }
  }

  /// Triggers the full sync bootstrap sequence for the given user.
  /// Idempotent: safe to call multiple times for the same user.
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

  /// Stops all sync activity and resets state.
  Future<void> onUserLogout() async {
    _activeBootstrapUid = null;
    _bootstrapFuture = null;
    _listenerManager.stopListening();
    _setStatus(SyncStatus.idle);
  }

  Future<void> _runBootstrap(AppUser user) async {
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
      // Clear future if it belongs to this run so next login can re-trigger if needed,
      // but in practice, once successful, we leave it or rely on _activeBootstrapUid.
      // We keep _activeBootstrapUid to prevent re-runs, but if error, maybe allow retry?
      if (_status == SyncStatus.error) {
        _bootstrapFuture = null; // Allow retry on error
      }
    }
  }

  /// Pulls all available pages from Firestore and applies them locally.
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

      // If the applier failed to process the whole page,
      // we must break to avoid infinite loop.
      if (lastSuccessfulDoc == null) {
        debugPrint(
          'SyncCoordinator: Failed to apply any docs in page, aborting pull loop.',
        );
        break;
      }

      if (!result.hasMorePages) break; // Last page
    }
  }

  /// Triggered by SyncListenerManager when remote data changes.
  Future<void> _handleRemoteChange(String uid) async {
    if (_activeUidFetcher() != uid) return;

    // Simple debouncing/coalescing could be added here if needed,
    // but the listener is already bounded by Firestore's onSnapshot.
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
