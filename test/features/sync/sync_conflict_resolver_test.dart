import 'package:flutter_test/flutter_test.dart';
import 'package:yunoo/features/sync/domain/sync_conflict_resolver.dart';
import 'package:yunoo/features/sync/domain/word_set_sync_codec.dart';
import 'package:yunoo/features/sync/models/idempotency_receipt.dart';
import 'package:yunoo/features/sync/models/outbox_item.dart';

void main() {
  group('Sprint 4D — SyncConflictResolver Unit Tests', () {
    final now = DateTime(2026, 7, 24, 12, 0, 0);

    OutboxItem createLocalOp({
      required OutboxOperationType op,
      String opId = 'op_1',
      int? remoteVer,
      String? payloadJson = '{"name":"Deck"}',
      bool isTombstone = false,
    }) {
      return OutboxItem()
        ..operationId = opId
        ..entityType = 'word_set'
        ..entityId = '101'
        ..coalescingKey = 'user_A_word_set_101'
        ..ownerUid = 'user_A'
        ..operation = op
        ..remoteVersion = remoteVer
        ..payloadJson = payloadJson
        ..isTombstone = isTombstone
        ..createdAt = now
        ..updatedAt = now;
    }

    RemoteDocumentData createRemoteDoc({
      int ver = 1,
      bool isTombstone = false,
      String lastOpId = 'op_0',
    }) {
      return RemoteDocumentData(
        documentId: '101',
        ownerUid: 'user_A',
        entityId: '101',
        entityType: 'word_set',
        remoteVersion: ver,
        lastOperationId: lastOpId,
        isTombstone: isTombstone,
        serverUpdatedAt: now,
      );
    }

    test('Create + missing remote -> apply (remoteVersion = 1)', () {
      final op = createLocalOp(op: OutboxOperationType.create);
      final decision = SyncConflictResolver.resolve(
        localOp: op,
        remoteDoc: null,
        existingReceipt: null,
      );

      expect(decision.type, equals(ConflictDecisionType.applyMutation));
      expect(decision.nextRemoteVersion, equals(1));
    });

    test('Duplicate receipt -> alreadyApplied', () {
      final op = createLocalOp(op: OutboxOperationType.create, opId: 'op_dup');
      final receipt = IdempotencyReceipt(
        operationId: 'op_dup',
        ownerUid: 'user_A',
        entityType: 'word_set',
        entityId: '101',
        appliedRemoteVersion: 1,
        appliedAt: now,
      );

      final decision = SyncConflictResolver.resolve(
        localOp: op,
        remoteDoc: null,
        existingReceipt: receipt,
      );

      expect(decision.type, equals(ConflictDecisionType.alreadyApplied));
      expect(decision.nextRemoteVersion, equals(1));
    });

    test('Create + existing live remote -> conflict', () {
      final op = createLocalOp(op: OutboxOperationType.create);
      final remote = createRemoteDoc(ver: 1);

      final decision = SyncConflictResolver.resolve(
        localOp: op,
        remoteDoc: remote,
        existingReceipt: null,
      );

      expect(decision.type, equals(ConflictDecisionType.conflict));
      expect(decision.conflictReason, contains('live document already exists'));
    });

    test('Create/update + tombstone -> conflict', () {
      final opCreate = createLocalOp(op: OutboxOperationType.create);
      final remoteTombstone = createRemoteDoc(ver: 2, isTombstone: true);

      final decisionCreate = SyncConflictResolver.resolve(
        localOp: opCreate,
        remoteDoc: remoteTombstone,
        existingReceipt: null,
      );
      expect(decisionCreate.type, equals(ConflictDecisionType.conflict));

      final opUpdate = createLocalOp(
        op: OutboxOperationType.update,
        remoteVer: 2,
      );
      final decisionUpdate = SyncConflictResolver.resolve(
        localOp: opUpdate,
        remoteDoc: remoteTombstone,
        existingReceipt: null,
      );
      expect(decisionUpdate.type, equals(ConflictDecisionType.conflict));
    });

    test(
      'Update + matching version -> apply (nextRemoteVersion = prev + 1)',
      () {
        final op = createLocalOp(op: OutboxOperationType.update, remoteVer: 1);
        final remote = createRemoteDoc(ver: 1);

        final decision = SyncConflictResolver.resolve(
          localOp: op,
          remoteDoc: remote,
          existingReceipt: null,
        );

        expect(decision.type, equals(ConflictDecisionType.applyMutation));
        expect(decision.nextRemoteVersion, equals(2));
      },
    );

    test('Update + mismatched version -> conflict', () {
      final op = createLocalOp(op: OutboxOperationType.update, remoteVer: 1);
      final remote = createRemoteDoc(ver: 3);

      final decision = SyncConflictResolver.resolve(
        localOp: op,
        remoteDoc: remote,
        existingReceipt: null,
      );

      expect(decision.type, equals(ConflictDecisionType.conflict));
      expect(decision.expectedRemoteVersion, equals(1));
      expect(decision.actualRemoteVersion, equals(3));
    });

    test(
      'Delete + matching live version -> tombstone (nextRemoteVersion = prev + 1)',
      () {
        final op = createLocalOp(
          op: OutboxOperationType.delete,
          remoteVer: 1,
          isTombstone: true,
        );
        final remote = createRemoteDoc(ver: 1);

        final decision = SyncConflictResolver.resolve(
          localOp: op,
          remoteDoc: remote,
          existingReceipt: null,
        );

        expect(decision.type, equals(ConflictDecisionType.applyMutation));
        expect(decision.nextRemoteVersion, equals(2));
      },
    );

    test('Delete + already tombstoned -> idempotent success', () {
      final op = createLocalOp(
        op: OutboxOperationType.delete,
        isTombstone: true,
      );
      final remote = createRemoteDoc(ver: 2, isTombstone: true);

      final decision = SyncConflictResolver.resolve(
        localOp: op,
        remoteDoc: remote,
        existingReceipt: null,
      );

      expect(decision.type, equals(ConflictDecisionType.alreadyApplied));
    });

    test('Delete + newer live version -> conflict', () {
      final op = createLocalOp(
        op: OutboxOperationType.delete,
        remoteVer: 1,
        isTombstone: true,
      );
      final remote = createRemoteDoc(ver: 5);

      final decision = SyncConflictResolver.resolve(
        localOp: op,
        remoteDoc: remote,
        existingReceipt: null,
      );

      expect(decision.type, equals(ConflictDecisionType.conflict));
    });
  });
}
