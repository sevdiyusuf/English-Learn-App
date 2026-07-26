import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../../core/errors/app_failure.dart';
import '../../../core/errors/firebase_error_mapper.dart';
import '../domain/sync_conflict_resolver.dart';
import '../domain/word_set_sync_codec.dart';
import '../models/idempotency_receipt.dart';
import '../models/outbox_item.dart';

abstract class FirestoreSyncGateway {
  Future<RemoteDocumentData?> fetchDocument({
    required String ownerUid,
    required String entityId,
  });

  Future<IdempotencyReceipt?> fetchReceipt({
    required String ownerUid,
    required String operationId,
  });

  Future<ConflictDecision> executeIdempotentTransaction({
    required String ownerUid,
    required OutboxItem localOp,
  });

  Future<List<RemoteDocumentData>> fetchIncrementalChanges({
    required String ownerUid,
    DateTime? sinceServerUpdatedAt,
    String? tieBreakerDocId,
    int limit = 20,
  });

  Stream<List<RemoteDocumentData>> listenToChanges({required String ownerUid});
}

class DefaultFirestoreSyncGateway implements FirestoreSyncGateway {
  DefaultFirestoreSyncGateway(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _setsRef(String ownerUid) {
    return _firestore
        .collection('users')
        .doc(ownerUid)
        .collection('word_match_sets');
  }

  CollectionReference<Map<String, dynamic>> _receiptsRef(String ownerUid) {
    return _firestore
        .collection('users')
        .doc(ownerUid)
        .collection('outbox_receipts');
  }

  @override
  Future<RemoteDocumentData?> fetchDocument({
    required String ownerUid,
    required String entityId,
  }) async {
    try {
      final docSnapshot = await _setsRef(ownerUid).doc(entityId).get();
      if (!docSnapshot.exists || docSnapshot.data() == null) return null;
      return WordSetSyncCodec.decode(
        documentId: docSnapshot.id,
        data: docSnapshot.data()!,
      );
    } catch (e, stack) {
      if (e is AppFailure) rethrow;
      debugPrint('Error fetching document: $e\n$stack');
      throw FirebaseErrorMapper.map(e);
    }
  }

  @override
  Future<IdempotencyReceipt?> fetchReceipt({
    required String ownerUid,
    required String operationId,
  }) async {
    try {
      final receiptSnapshot =
          await _receiptsRef(ownerUid).doc(operationId).get();
      if (!receiptSnapshot.exists || receiptSnapshot.data() == null) {
        return null;
      }
      return IdempotencyReceipt.fromMap(
        receiptSnapshot.id,
        receiptSnapshot.data()!,
      );
    } catch (e, stack) {
      if (e is AppFailure) rethrow;
      debugPrint('Error fetching receipt: $e\n$stack');
      throw FirebaseErrorMapper.map(e);
    }
  }

  @override
  Future<ConflictDecision> executeIdempotentTransaction({
    required String ownerUid,
    required OutboxItem localOp,
  }) async {
    try {
      final docRef = _setsRef(ownerUid).doc(localOp.entityId);
      final receiptRef = _receiptsRef(ownerUid).doc(localOp.operationId);

      final decision = await _firestore.runTransaction<ConflictDecision>((
        txn,
      ) async {
        final receiptSnap = await txn.get(receiptRef);
        IdempotencyReceipt? receipt;
        if (receiptSnap.exists && receiptSnap.data() != null) {
          receipt = IdempotencyReceipt.fromMap(
            receiptSnap.id,
            receiptSnap.data()!,
          );
        }

        final docSnap = await txn.get(docRef);
        RemoteDocumentData? remoteDoc;
        if (docSnap.exists && docSnap.data() != null) {
          remoteDoc = WordSetSyncCodec.decode(
            documentId: docSnap.id,
            data: docSnap.data()!,
          );
        }

        final decision = SyncConflictResolver.resolve(
          localOp: localOp,
          remoteDoc: remoteDoc,
          existingReceipt: receipt,
        );

        if (decision.type == ConflictDecisionType.applyMutation) {
          final isTombstone = localOp.operation == OutboxOperationType.delete;
          final encodedDoc = WordSetSyncCodec.encode(
            ownerUid: ownerUid,
            entityId: localOp.entityId,
            entityType: localOp.entityType,
            remoteVersion: decision.nextRemoteVersion!,
            operationId: localOp.operationId,
            isTombstone: isTombstone,
            deletedAt:
                isTombstone ? (localOp.deletedAt ?? DateTime.now()) : null,
            payload: localOp.payload,
            serverTimestampFieldValue: FieldValue.serverTimestamp(),
          );

          final newReceipt = IdempotencyReceipt(
            operationId: localOp.operationId,
            ownerUid: ownerUid,
            entityType: localOp.entityType,
            entityId: localOp.entityId,
            appliedRemoteVersion: decision.nextRemoteVersion!,
            appliedAt: DateTime.now(),
          );

          txn.set(docRef, encodedDoc, SetOptions(merge: true));
          txn.set(receiptRef, newReceipt.toMap(), SetOptions(merge: true));
        }

        return decision;
      });

      return decision;
    } catch (e, stack) {
      if (e is AppFailure) rethrow;
      debugPrint('Error executing idempotent transaction: $e\n$stack');
      throw FirebaseErrorMapper.map(e);
    }
  }

  @override
  Future<List<RemoteDocumentData>> fetchIncrementalChanges({
    required String ownerUid,
    DateTime? sinceServerUpdatedAt,
    String? tieBreakerDocId,
    int limit = 20,
  }) async {
    try {
      Query<Map<String, dynamic>> query = _setsRef(ownerUid)
          .orderBy('serverUpdatedAt', descending: false)
          .orderBy(FieldPath.documentId, descending: false);

      if (sinceServerUpdatedAt != null) {
        if (tieBreakerDocId != null && tieBreakerDocId.isNotEmpty) {
          query = query.startAfter([
            Timestamp.fromDate(sinceServerUpdatedAt),
            tieBreakerDocId,
          ]);
        } else {
          query = query.startAfter([Timestamp.fromDate(sinceServerUpdatedAt)]);
        }
      }

      query = query.limit(limit);
      final querySnap = await query.get();

      final results = <RemoteDocumentData>[];
      for (final doc in querySnap.docs) {
        if (doc.exists && doc.data().isNotEmpty) {
          try {
            final parsed = WordSetSyncCodec.decode(
              documentId: doc.id,
              data: doc.data(),
            );
            results.add(parsed);
          } catch (e) {
            debugPrint('Skipping malformed remote doc ${doc.id}: $e');
          }
        }
      }
      return results;
    } catch (e, stack) {
      if (e is AppFailure) rethrow;
      debugPrint('Error fetching incremental changes: $e\n$stack');
      throw FirebaseErrorMapper.map(e);
    }
  }

  @override
  Stream<List<RemoteDocumentData>> listenToChanges({required String ownerUid}) {
    try {
      final stream = _setsRef(ownerUid).snapshots();
      return stream
          .map((querySnap) {
            final list = <RemoteDocumentData>[];
            for (final doc in querySnap.docs) {
              if (doc.exists && doc.data().isNotEmpty) {
                try {
                  final parsed = WordSetSyncCodec.decode(
                    documentId: doc.id,
                    data: doc.data(),
                  );
                  list.add(parsed);
                } catch (_) {}
              }
            }
            return list;
          })
          .transform(
            StreamTransformer.fromHandlers(
              handleError: (error, stack, sink) {
                sink.addError(FirebaseErrorMapper.map(error));
              },
            ),
          );
    } catch (e) {
      throw FirebaseErrorMapper.map(e);
    }
  }
}
