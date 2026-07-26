import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';

import '../../../core/errors/app_failure.dart';
import '../domain/outbox_coalescer.dart';
import '../models/outbox_item.dart';

abstract class OutboxRepository {
  /// Enqueues a create operation for entity. Coalesces with existing active operations.
  Future<OutboxItem> enqueueCreate({
    required String? ownerUid,
    required String entityType,
    required String entityId,
    required Map<String, dynamic> payload,
    int localVersion = 1,
    int? remoteVersion,
    String? operationId,
  });

  /// Enqueues an update operation for entity. Coalesces with existing active operations.
  Future<OutboxItem> enqueueUpdate({
    required String? ownerUid,
    required String entityType,
    required String entityId,
    required Map<String, dynamic> payload,
    int localVersion = 1,
    int? remoteVersion,
    String? operationId,
  });

  /// Enqueues a delete operation (tombstone) for entity. Coalesces with existing active operations.
  Future<OutboxItem> enqueueDelete({
    required String? ownerUid,
    required String entityType,
    required String entityId,
    int localVersion = 1,
    int? remoteVersion,
    String? operationId,
  });

  /// Returns processable pending and retryable operations for specific ownerUid scope in deterministic order.
  Future<List<OutboxItem>> getPendingOperations({required String? ownerUid});

  /// Retrieves an outbox item by its unique operation ID.
  Future<OutboxItem?> getByOperationId(String operationId);

  /// Atomically increments attempt count and updates lastAttemptAt timestamp.
  Future<void> updateAttempt({
    required String operationId,
    String? errorMessage,
    String? errorCode,
  });

  /// Marks an operation as failed retryable with error details.
  Future<void> markFailedRetryable({
    required String operationId,
    required String errorMessage,
    String? errorCode,
  });

  /// Marks an operation as failed permanent (excluded from normal pending processing queue).
  Future<void> markFailedPermanent({
    required String operationId,
    required String errorMessage,
    String? errorCode,
  });

  /// Marks an operation as in conflict state.
  Future<void> markConflict({
    required String operationId,
    required String conflictDetails,
  });

  /// Marks an operation as successfully synchronized.
  Future<void> markSynced({required String operationId, int? remoteVersion});

  // ── Transaction-aware variants ──────────────────────────────────────────
  // These variants must be called INSIDE an already-open Isar writeTxn.
  // They do NOT open a new transaction themselves.

  /// Enqueues a create operation inside an already-open Isar writeTxn.
  Future<OutboxItem> enqueueCreateInsideTxn({
    required String? ownerUid,
    required String entityType,
    required String entityId,
    required Map<String, dynamic> payload,
    int localVersion = 1,
    int? remoteVersion,
    String? operationId,
  });

  /// Enqueues an update operation inside an already-open Isar writeTxn.
  Future<OutboxItem> enqueueUpdateInsideTxn({
    required String? ownerUid,
    required String entityType,
    required String entityId,
    required Map<String, dynamic> payload,
    int localVersion = 1,
    int? remoteVersion,
    String? operationId,
  });

  /// Enqueues a delete operation inside an already-open Isar writeTxn.
  Future<OutboxItem> enqueueDeleteInsideTxn({
    required String? ownerUid,
    required String entityType,
    required String entityId,
    int localVersion = 1,
    int? remoteVersion,
    String? operationId,
  });

  /// Clears local Outbox items belonging to the given uid.
  Future<void> clearUserData(String uid);
}

class IsarOutboxRepository implements OutboxRepository {
  IsarOutboxRepository(
    this._isar, {
    String Function()? idGenerator,
    DateTime Function()? clock,
    void Function()? onBeforeTxnCommit,
  }) : _idGenerator = idGenerator ?? _defaultIdGenerator,
       _clock = clock ?? DateTime.now,
       _onBeforeTxnCommit = onBeforeTxnCommit;

  final Isar _isar;
  final String Function() _idGenerator;
  final DateTime Function() _clock;
  final void Function()? _onBeforeTxnCommit;

  static int _opCounter = 0;
  static String _defaultIdGenerator() {
    return 'op_${DateTime.now().microsecondsSinceEpoch}_${_opCounter++}';
  }

  @override
  Future<OutboxItem> enqueueCreate({
    required String? ownerUid,
    required String entityType,
    required String entityId,
    required Map<String, dynamic> payload,
    int localVersion = 1,
    int? remoteVersion,
    String? operationId,
  }) {
    return _enqueueOperation(
      ownerUid: ownerUid,
      entityType: entityType,
      entityId: entityId,
      incomingOperation: OutboxOperationType.create,
      payload: payload,
      localVersion: localVersion,
      remoteVersion: remoteVersion,
      operationId: operationId,
    );
  }

  @override
  Future<OutboxItem> enqueueUpdate({
    required String? ownerUid,
    required String entityType,
    required String entityId,
    required Map<String, dynamic> payload,
    int localVersion = 1,
    int? remoteVersion,
    String? operationId,
  }) {
    return _enqueueOperation(
      ownerUid: ownerUid,
      entityType: entityType,
      entityId: entityId,
      incomingOperation: OutboxOperationType.update,
      payload: payload,
      localVersion: localVersion,
      remoteVersion: remoteVersion,
      operationId: operationId,
    );
  }

  @override
  Future<OutboxItem> enqueueDelete({
    required String? ownerUid,
    required String entityType,
    required String entityId,
    int localVersion = 1,
    int? remoteVersion,
    String? operationId,
  }) {
    return _enqueueOperation(
      ownerUid: ownerUid,
      entityType: entityType,
      entityId: entityId,
      incomingOperation: OutboxOperationType.delete,
      payload: null,
      localVersion: localVersion,
      remoteVersion: remoteVersion,
      operationId: operationId,
    );
  }

  Future<OutboxItem> _enqueueOperation({
    required String? ownerUid,
    required String entityType,
    required String entityId,
    required OutboxOperationType incomingOperation,
    required Map<String, dynamic>? payload,
    required int localVersion,
    int? remoteVersion,
    required String? operationId,
  }) async {
    try {
      final now = _clock();
      final coalescingKey = OutboxCoalescer.buildCoalescingKey(
        ownerUid,
        entityType,
        entityId,
      );
      final payloadJson = payload != null ? jsonEncode(payload) : null;

      late OutboxItem resultItem;

      await _isar.writeTxn(() async {
        // Query active (un-synced) operations sharing the same coalescing key
        final existingItems =
            await _isar.outboxItems
                .where()
                .coalescingKeyEqualTo(coalescingKey)
                .findAll();

        OutboxItem? activeItem;
        for (final item in existingItems) {
          if (item.syncStatus != OutboxSyncStatus.synced) {
            activeItem = item;
            break;
          }
        }

        final coalesced = OutboxCoalescer.coalesce(
          activeItem: activeItem,
          incomingOperation: incomingOperation,
          incomingPayloadJson: payloadJson,
          incomingLocalVersion: localVersion,
          incomingRemoteVersion: remoteVersion,
          now: now,
          incomingOperationId: operationId,
        );

        switch (coalesced.action) {
          case CoalesceAction.rejectDeleted:
            throw AppFailure.database(
              message:
                  coalesced.rejectionReason ??
                  'Silinmiş entity üzerinde izinsiz operasyon.',
            );

          case CoalesceAction.duplicateIgnored:
          case CoalesceAction.updateExisting:
            resultItem = coalesced.updatedItem!;
            await _isar.outboxItems.put(resultItem);
            break;

          case CoalesceAction.createFresh:
            final newItem =
                OutboxItem()
                  ..operationId = operationId ?? _idGenerator()
                  ..entityType = entityType
                  ..entityId = entityId
                  ..coalescingKey = coalescingKey
                  ..ownerUid = ownerUid
                  ..operation = incomingOperation
                  ..syncStatus = OutboxSyncStatus.pending
                  ..localVersion = localVersion
                  ..remoteVersion = remoteVersion
                  ..createdAt = now
                  ..updatedAt = now
                  ..isTombstone =
                      incomingOperation == OutboxOperationType.delete
                  ..deletedAt =
                      incomingOperation == OutboxOperationType.delete
                          ? now
                          : null
                  ..payloadJson = payloadJson;

            await _isar.outboxItems.put(newItem);
            resultItem = newItem;
            break;
        }

        _onBeforeTxnCommit?.call();
      });

      return resultItem;
    } catch (e, stack) {
      if (e is AppFailure) rethrow;
      debugPrint('Error in _enqueueOperation: $e\n$stack');
      throw AppFailure.database(
        message:
            'Outbox operasyonu eklenirken yerel veritabanı hatası oluştu: $e',
        originalError: e,
      );
    }
  }

  @override
  Future<List<OutboxItem>> getPendingOperations({
    required String? ownerUid,
  }) async {
    try {
      final allItems = await _isar.outboxItems.where().findAll();
      final filtered =
          allItems.where((item) {
            final matchesOwner = item.ownerUid == ownerUid;
            final isProcessable =
                item.syncStatus == OutboxSyncStatus.pending ||
                item.syncStatus == OutboxSyncStatus.failedRetryable;
            return matchesOwner && isProcessable;
          }).toList();

      filtered.sort((a, b) {
        final cmp = a.createdAt.compareTo(b.createdAt);
        if (cmp != 0) return cmp;
        return a.id.compareTo(b.id);
      });

      return filtered;
    } catch (e, stack) {
      if (e is AppFailure) rethrow;
      debugPrint('Error in getPendingOperations: $e\n$stack');
      throw AppFailure.database(
        message: 'Bekleyen outbox operasyonları okunurken hata oluştu: $e',
        originalError: e,
      );
    }
  }

  @override
  Future<OutboxItem?> getByOperationId(String operationId) async {
    try {
      return await _isar.outboxItems
          .where()
          .operationIdEqualTo(operationId)
          .findFirst();
    } catch (e, stack) {
      if (e is AppFailure) rethrow;
      debugPrint('Error in getByOperationId: $e\n$stack');
      throw AppFailure.database(
        message: 'Operation ID ile outbox kaydı aranırken hata oluştu: $e',
        originalError: e,
      );
    }
  }

  @override
  Future<void> updateAttempt({
    required String operationId,
    String? errorMessage,
    String? errorCode,
  }) async {
    try {
      await _isar.writeTxn(() async {
        final item =
            await _isar.outboxItems
                .where()
                .operationIdEqualTo(operationId)
                .findFirst();

        if (item == null) {
          throw AppFailure.database(
            message: 'Güncellenecek outbox kaydı bulunamadı: $operationId',
          );
        }

        item.attemptCount += 1;
        item.lastAttemptAt = _clock();
        if (errorMessage != null) item.lastErrorMessage = errorMessage;
        if (errorCode != null) item.lastErrorCode = errorCode;
        item.updatedAt = _clock();

        await _isar.outboxItems.put(item);
      });
    } catch (e, stack) {
      if (e is AppFailure) rethrow;
      debugPrint('Error in updateAttempt: $e\n$stack');
      throw AppFailure.database(
        message: 'Outbox denemesi güncellenirken hata oluştu: $e',
        originalError: e,
      );
    }
  }

  @override
  Future<void> markFailedRetryable({
    required String operationId,
    required String errorMessage,
    String? errorCode,
  }) async {
    try {
      await _isar.writeTxn(() async {
        final item =
            await _isar.outboxItems
                .where()
                .operationIdEqualTo(operationId)
                .findFirst();

        if (item == null) {
          throw AppFailure.database(
            message: 'Güncellenecek outbox kaydı bulunamadı: $operationId',
          );
        }

        item.syncStatus = OutboxSyncStatus.failedRetryable;
        item.lastErrorMessage = errorMessage;
        if (errorCode != null) item.lastErrorCode = errorCode;
        item.lastAttemptAt = _clock();
        item.updatedAt = _clock();

        await _isar.outboxItems.put(item);
      });
    } catch (e, stack) {
      if (e is AppFailure) rethrow;
      debugPrint('Error in markFailedRetryable: $e\n$stack');
      throw AppFailure.database(
        message:
            'Outbox kaydı failedRetryable olarak işaretlenirken hata oluştu: $e',
        originalError: e,
      );
    }
  }

  @override
  Future<void> markFailedPermanent({
    required String operationId,
    required String errorMessage,
    String? errorCode,
  }) async {
    try {
      await _isar.writeTxn(() async {
        final item =
            await _isar.outboxItems
                .where()
                .operationIdEqualTo(operationId)
                .findFirst();

        if (item == null) {
          throw AppFailure.database(
            message: 'Güncellenecek outbox kaydı bulunamadı: $operationId',
          );
        }

        item.syncStatus = OutboxSyncStatus.failedPermanent;
        item.lastErrorMessage = errorMessage;
        if (errorCode != null) item.lastErrorCode = errorCode;
        item.lastAttemptAt = _clock();
        item.updatedAt = _clock();

        await _isar.outboxItems.put(item);
      });
    } catch (e, stack) {
      if (e is AppFailure) rethrow;
      debugPrint('Error in markFailedPermanent: $e\n$stack');
      throw AppFailure.database(
        message:
            'Outbox kaydı failedPermanent olarak işaretlenirken hata oluştu: $e',
        originalError: e,
      );
    }
  }

  @override
  Future<void> markConflict({
    required String operationId,
    required String conflictDetails,
  }) async {
    try {
      await _isar.writeTxn(() async {
        final item =
            await _isar.outboxItems
                .where()
                .operationIdEqualTo(operationId)
                .findFirst();

        if (item == null) {
          throw AppFailure.database(
            message: 'Güncellenecek outbox kaydı bulunamadı: $operationId',
          );
        }

        item.syncStatus = OutboxSyncStatus.conflict;
        item.conflictDetails = conflictDetails;
        item.lastAttemptAt = _clock();
        item.updatedAt = _clock();

        await _isar.outboxItems.put(item);
      });
    } catch (e, stack) {
      if (e is AppFailure) rethrow;
      debugPrint('Error in markConflict: $e\n$stack');
      throw AppFailure.database(
        message: 'Outbox kaydı conflict olarak işaretlenirken hata oluştu: $e',
        originalError: e,
      );
    }
  }

  @override
  Future<void> markSynced({
    required String operationId,
    int? remoteVersion,
  }) async {
    try {
      await _isar.writeTxn(() async {
        final item =
            await _isar.outboxItems
                .where()
                .operationIdEqualTo(operationId)
                .findFirst();

        if (item == null) {
          throw AppFailure.database(
            message: 'Güncellenecek outbox kaydı bulunamadı: $operationId',
          );
        }

        item.syncStatus = OutboxSyncStatus.synced;
        if (remoteVersion != null) item.remoteVersion = remoteVersion;
        item.updatedAt = _clock();

        await _isar.outboxItems.put(item);
      });
    } catch (e, stack) {
      if (e is AppFailure) rethrow;
      debugPrint('Error in markSynced: $e\n$stack');
      throw AppFailure.database(
        message: 'Outbox kaydı synced olarak işaretlenirken hata oluştu: $e',
        originalError: e,
      );
    }
  }

  // ── Transaction-aware variants ──────────────────────────────────────────
  // Must be called INSIDE an already-open _isar.writeTxn().

  @override
  Future<OutboxItem> enqueueCreateInsideTxn({
    required String? ownerUid,
    required String entityType,
    required String entityId,
    required Map<String, dynamic> payload,
    int localVersion = 1,
    int? remoteVersion,
    String? operationId,
  }) {
    return _enqueueOperationInsideTxn(
      ownerUid: ownerUid,
      entityType: entityType,
      entityId: entityId,
      incomingOperation: OutboxOperationType.create,
      payload: payload,
      localVersion: localVersion,
      remoteVersion: remoteVersion,
      operationId: operationId,
    );
  }

  @override
  Future<OutboxItem> enqueueUpdateInsideTxn({
    required String? ownerUid,
    required String entityType,
    required String entityId,
    required Map<String, dynamic> payload,
    int localVersion = 1,
    int? remoteVersion,
    String? operationId,
  }) {
    return _enqueueOperationInsideTxn(
      ownerUid: ownerUid,
      entityType: entityType,
      entityId: entityId,
      incomingOperation: OutboxOperationType.update,
      payload: payload,
      localVersion: localVersion,
      remoteVersion: remoteVersion,
      operationId: operationId,
    );
  }

  @override
  Future<OutboxItem> enqueueDeleteInsideTxn({
    required String? ownerUid,
    required String entityType,
    required String entityId,
    int localVersion = 1,
    int? remoteVersion,
    String? operationId,
  }) {
    return _enqueueOperationInsideTxn(
      ownerUid: ownerUid,
      entityType: entityType,
      entityId: entityId,
      incomingOperation: OutboxOperationType.delete,
      payload: null,
      localVersion: localVersion,
      remoteVersion: remoteVersion,
      operationId: operationId,
    );
  }

  /// Internal: enqueues an operation WITHOUT opening a new writeTxn.
  /// Must be called within an existing open writeTxn on the same Isar instance.
  Future<OutboxItem> _enqueueOperationInsideTxn({
    required String? ownerUid,
    required String entityType,
    required String entityId,
    required OutboxOperationType incomingOperation,
    required Map<String, dynamic>? payload,
    required int localVersion,
    int? remoteVersion,
    required String? operationId,
  }) async {
    final now = _clock();
    final coalescingKey = OutboxCoalescer.buildCoalescingKey(
      ownerUid,
      entityType,
      entityId,
    );
    final payloadJson = payload != null ? jsonEncode(payload) : null;

    final existingItems =
        await _isar.outboxItems
            .where()
            .coalescingKeyEqualTo(coalescingKey)
            .findAll();

    OutboxItem? activeItem;
    for (final item in existingItems) {
      if (item.syncStatus != OutboxSyncStatus.synced) {
        activeItem = item;
        break;
      }
    }

    final coalesced = OutboxCoalescer.coalesce(
      activeItem: activeItem,
      incomingOperation: incomingOperation,
      incomingPayloadJson: payloadJson,
      incomingLocalVersion: localVersion,
      incomingRemoteVersion: remoteVersion,
      now: now,
      incomingOperationId: operationId,
    );

    switch (coalesced.action) {
      case CoalesceAction.rejectDeleted:
        throw AppFailure.database(
          message:
              coalesced.rejectionReason ??
              'Silinmiş entity üzerinde izinsiz operasyon.',
        );

      case CoalesceAction.duplicateIgnored:
      case CoalesceAction.updateExisting:
        final updated = coalesced.updatedItem!;
        await _isar.outboxItems.put(updated);
        return updated;

      case CoalesceAction.createFresh:
        final newItem =
            OutboxItem()
              ..operationId = operationId ?? _idGenerator()
              ..entityType = entityType
              ..entityId = entityId
              ..coalescingKey = coalescingKey
              ..ownerUid = ownerUid
              ..operation = incomingOperation
              ..syncStatus = OutboxSyncStatus.pending
              ..localVersion = localVersion
              ..remoteVersion = remoteVersion
              ..createdAt = now
              ..updatedAt = now
              ..isTombstone = incomingOperation == OutboxOperationType.delete
              ..deletedAt =
                  incomingOperation == OutboxOperationType.delete ? now : null
              ..payloadJson = payloadJson;

        await _isar.outboxItems.put(newItem);
        return newItem;
    }
  }

  /// Clears local Outbox items belonging to the given uid.
  @override
  Future<void> clearUserData(String uid) async {
    await _isar.writeTxn(() async {
      final items =
          await _isar.outboxItems.filter().ownerUidEqualTo(uid).findAll();
      final ids = items.map((e) => e.id).toList();
      await _isar.outboxItems.deleteAll(ids);
    });
  }
}
