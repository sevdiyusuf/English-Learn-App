import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/errors/app_failure.dart';
import '../data/firestore_sync_gateway.dart';
import '../domain/word_set_sync_codec.dart';

class SyncListenerManager {
  SyncListenerManager({
    required FirestoreSyncGateway gateway,
    String? Function()? activeAuthenticatedUidFetcher,
  }) : _gateway = gateway,
       _activeAuthenticatedUidFetcher = activeAuthenticatedUidFetcher;

  final FirestoreSyncGateway _gateway;
  final String? Function()? _activeAuthenticatedUidFetcher;

  StreamSubscription<List<RemoteDocumentData>>? _subscription;
  String? _currentOwnerUid;
  int _sessionGeneration = 0;
  bool _isDisposed = false;

  String? get currentOwnerUid => _currentOwnerUid;
  bool get isListening => _subscription != null && !_isDisposed;

  void startListening({
    required String? ownerUid,
    required void Function(List<RemoteDocumentData> changes) onChanges,
    void Function(AppFailure failure)? onError,
  }) {
    if (_isDisposed) {
      debugPrint(
        'SyncListenerManager: Cannot start listening on disposed manager.',
      );
      return;
    }

    if (ownerUid == null || ownerUid.isEmpty) {
      onError?.call(
        AppFailure.auth(
          message: 'Guest / unauthenticated scope için listener başlatılamaz.',
        ),
      );
      return;
    }

    if (_activeAuthenticatedUidFetcher != null) {
      final currentAuth = _activeAuthenticatedUidFetcher();
      if (currentAuth == null || currentAuth != ownerUid) {
        onError?.call(
          AppFailure.auth(
            message:
                'Aktif oturum UID ($currentAuth) ile ownerUid ($ownerUid) eşleşmiyor.',
          ),
        );
        return;
      }
    }

    // Stop existing listener if any
    stopListening();

    _currentOwnerUid = ownerUid;
    _sessionGeneration++;
    final currentGen = _sessionGeneration;

    try {
      final stream = _gateway.listenToChanges(ownerUid: ownerUid);
      _subscription = stream.listen(
        (changes) {
          if (_isDisposed || _sessionGeneration != currentGen) {
            debugPrint(
              'SyncListenerManager: Discarding stale event for generation $currentGen',
            );
            return;
          }

          if (_activeAuthenticatedUidFetcher != null) {
            final currentAuth = _activeAuthenticatedUidFetcher();
            if (currentAuth != ownerUid) {
              debugPrint(
                'SyncListenerManager: Discarding event due to owner mismatch.',
              );
              stopListening();
              return;
            }
          }

          onChanges(changes);
        },
        onError: (error) {
          if (_isDisposed || _sessionGeneration != currentGen) return;
          final failure =
              error is AppFailure
                  ? error
                  : AppFailure.database(
                    message: 'Listener hatası: $error',
                    originalError: error,
                  );
          onError?.call(failure);
        },
      );
    } catch (e) {
      final failure =
          e is AppFailure
              ? e
              : AppFailure.database(
                message: 'Listener başlatılamadı: $e',
                originalError: e,
              );
      onError?.call(failure);
    }
  }

  void stopListening() {
    _sessionGeneration++;
    _subscription?.cancel();
    _subscription = null;
    _currentOwnerUid = null;
  }

  void dispose() {
    if (_isDisposed) return;
    _isDisposed = true;
    stopListening();
  }
}
