import 'dart:async';

import '../../../core/errors/app_failure.dart';
import '../data/firestore_sync_gateway.dart';
import '../data/sync_checkpoint_repository.dart';
import '../domain/word_set_sync_codec.dart';

class PullSyncResult {
  const PullSyncResult({
    required this.ownerUid,
    required this.changes,
    required this.hasMorePages,
    required this.lastServerUpdatedAt,
    required this.lastTieBreakerDocId,
  });

  final String ownerUid;
  final List<RemoteDocumentData> changes;
  final bool hasMorePages;
  final DateTime? lastServerUpdatedAt;
  final String? lastTieBreakerDocId;
}

class PullSyncService {
  PullSyncService({
    required SyncCheckpointRepository checkpointRepository,
    required FirestoreSyncGateway gateway,
    String? Function()? activeAuthenticatedUidFetcher,
  }) : _checkpointRepo = checkpointRepository,
       _gateway = gateway,
       _activeAuthenticatedUidFetcher = activeAuthenticatedUidFetcher;

  final SyncCheckpointRepository _checkpointRepo;
  final FirestoreSyncGateway _gateway;
  final String? Function()? _activeAuthenticatedUidFetcher;

  Future<PullSyncResult> pullPage({
    required String? ownerUid,
    String entityType = 'word_set',
    int pageLimit = 20,
  }) async {
    if (ownerUid == null || ownerUid.isEmpty) {
      throw AppFailure.auth(
        message:
            'Guest / unauthenticated scope için pull işlemi çalıştırılamaz.',
      );
    }

    if (_activeAuthenticatedUidFetcher != null) {
      final currentAuth = _activeAuthenticatedUidFetcher();
      if (currentAuth == null || currentAuth != ownerUid) {
        throw AppFailure.auth(
          message:
              'Aktif oturum UID ($currentAuth) ile ownerUid ($ownerUid) eşleşmiyor.',
        );
      }
    }

    final checkpoint = await _checkpointRepo.getCheckpoint(
      ownerUid: ownerUid,
      entityType: entityType,
    );

    final changes = await _gateway.fetchIncrementalChanges(
      ownerUid: ownerUid,
      sinceServerUpdatedAt: checkpoint?.lastServerUpdatedAt,
      tieBreakerDocId: checkpoint?.tieBreakerDocId,
      limit: pageLimit,
    );

    final hasMore = changes.length == pageLimit;
    final lastDoc = changes.isNotEmpty ? changes.last : null;

    return PullSyncResult(
      ownerUid: ownerUid,
      changes: changes,
      hasMorePages: hasMore,
      lastServerUpdatedAt:
          lastDoc?.serverUpdatedAt ?? checkpoint?.lastServerUpdatedAt,
      lastTieBreakerDocId: lastDoc?.documentId ?? checkpoint?.tieBreakerDocId,
    );
  }

  Future<void> acknowledgePage({
    required String? ownerUid,
    required RemoteDocumentData lastProcessedDoc,
    String entityType = 'word_set',
  }) async {
    if (ownerUid == null || ownerUid.isEmpty) return;

    if (_activeAuthenticatedUidFetcher != null) {
      final currentAuth = _activeAuthenticatedUidFetcher();
      if (currentAuth != ownerUid) {
        throw AppFailure.auth(
          message: 'Session changed during page acknowledge.',
        );
      }
    }

    await _checkpointRepo.saveCheckpoint(
      ownerUid: ownerUid,
      entityType: entityType,
      lastServerUpdatedAt: lastProcessedDoc.serverUpdatedAt,
      tieBreakerDocId: lastProcessedDoc.documentId,
    );
  }
}
