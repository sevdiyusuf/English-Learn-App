import 'package:isar/isar.dart';

import '../../../core/errors/app_failure.dart';
import '../models/sync_checkpoint.dart';

abstract class SyncCheckpointRepository {
  Future<SyncCheckpoint?> getCheckpoint({
    required String ownerUid,
    required String entityType,
  });

  Future<void> saveCheckpoint({
    required String ownerUid,
    required String entityType,
    required DateTime? lastServerUpdatedAt,
    required String? tieBreakerDocId,
  });
}

class IsarSyncCheckpointRepository implements SyncCheckpointRepository {
  IsarSyncCheckpointRepository(this._isar);

  final Isar _isar;

  static String buildCheckpointKey(String ownerUid, String entityType) {
    return '${ownerUid}_$entityType';
  }

  @override
  Future<SyncCheckpoint?> getCheckpoint({
    required String ownerUid,
    required String entityType,
  }) async {
    try {
      final key = buildCheckpointKey(ownerUid, entityType);
      return await _isar.syncCheckpoints
          .where()
          .checkpointKeyEqualTo(key)
          .findFirst();
    } catch (e) {
      if (e is AppFailure) rethrow;
      throw AppFailure.database(
        message: 'Checkpoint verisi okunurken veritabanı hatası oluştu: $e',
        originalError: e,
      );
    }
  }

  @override
  Future<void> saveCheckpoint({
    required String ownerUid,
    required String entityType,
    required DateTime? lastServerUpdatedAt,
    required String? tieBreakerDocId,
  }) async {
    try {
      final key = buildCheckpointKey(ownerUid, entityType);
      final now = DateTime.now();

      await _isar.writeTxn(() async {
        final existing =
            await _isar.syncCheckpoints
                .where()
                .checkpointKeyEqualTo(key)
                .findFirst();

        final checkpoint =
            existing ??
            (SyncCheckpoint()
              ..checkpointKey = key
              ..ownerUid = ownerUid
              ..entityType = entityType);

        checkpoint.lastServerUpdatedAt = lastServerUpdatedAt;
        checkpoint.tieBreakerDocId = tieBreakerDocId;
        checkpoint.updatedAt = now;

        await _isar.syncCheckpoints.put(checkpoint);
      });
    } catch (e) {
      if (e is AppFailure) rethrow;
      throw AppFailure.database(
        message: 'Checkpoint verisi kaydedilirken veritabanı hatası oluştu: $e',
        originalError: e,
      );
    }
  }
}
