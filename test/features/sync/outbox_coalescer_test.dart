import 'package:flutter_test/flutter_test.dart';
import 'package:yunoo/features/sync/domain/outbox_coalescer.dart';
import 'package:yunoo/features/sync/models/outbox_item.dart';

void main() {
  group('Sprint 4C — OutboxCoalescer Unit Tests', () {
    final now = DateTime(2026, 7, 24, 12, 0, 0);

    test('coalescingKey formatting for user and guest', () {
      expect(
        OutboxCoalescer.buildCoalescingKey('user_A', 'word_set', '10'),
        equals('user_A_word_set_10'),
      );
      expect(
        OutboxCoalescer.buildCoalescingKey(null, 'word_set', '10'),
        equals('guest_word_set_10'),
      );
      expect(
        OutboxCoalescer.buildCoalescingKey('', 'word_set', '10'),
        equals('guest_word_set_10'),
      );
    });

    test('null activeItem results in createFresh', () {
      final res = OutboxCoalescer.coalesce(
        activeItem: null,
        incomingOperation: OutboxOperationType.create,
        incomingPayloadJson: '{"name":"Deck 1"}',
        incomingLocalVersion: 1,
        now: now,
      );

      expect(res.action, equals(CoalesceAction.createFresh));
    });

    test('duplicate operationId returns duplicateIgnored', () {
      final active =
          OutboxItem()
            ..operationId = 'op_100'
            ..entityType = 'word_set'
            ..entityId = '1'
            ..coalescingKey = 'user_A_word_set_1'
            ..operation = OutboxOperationType.create
            ..syncStatus = OutboxSyncStatus.pending;

      final res = OutboxCoalescer.coalesce(
        activeItem: active,
        incomingOperation: OutboxOperationType.create,
        incomingPayloadJson: '{"name":"Deck 1"}',
        incomingLocalVersion: 1,
        now: now,
        incomingOperationId: 'op_100',
      );

      expect(res.action, equals(CoalesceAction.duplicateIgnored));
      expect(res.updatedItem, equals(active));
    });

    test(
      'pendingCreate + update -> single pendingCreate with updated payload',
      () {
        final active =
            OutboxItem()
              ..operationId = 'op_create_1'
              ..entityType = 'word_set'
              ..entityId = '1'
              ..coalescingKey = 'user_A_word_set_1'
              ..operation = OutboxOperationType.create
              ..syncStatus = OutboxSyncStatus.pending
              ..payloadJson = '{"name":"Original"}';

        final res = OutboxCoalescer.coalesce(
          activeItem: active,
          incomingOperation: OutboxOperationType.update,
          incomingPayloadJson: '{"name":"Updated"}',
          incomingLocalVersion: 2,
          now: now,
        );

        expect(res.action, equals(CoalesceAction.updateExisting));
        expect(res.updatedItem!.operation, equals(OutboxOperationType.create));
        expect(res.updatedItem!.payloadJson, equals('{"name":"Updated"}'));
        expect(res.updatedItem!.localVersion, equals(2));
        expect(res.updatedItem!.operationId, equals('op_create_1'));
      },
    );

    test(
      'pendingUpdate + update -> single pendingUpdate with updated payload',
      () {
        final active =
            OutboxItem()
              ..operationId = 'op_update_1'
              ..entityType = 'word_set'
              ..entityId = '1'
              ..coalescingKey = 'user_A_word_set_1'
              ..operation = OutboxOperationType.update
              ..syncStatus = OutboxSyncStatus.pending
              ..payloadJson = '{"name":"V1"}';

        final res = OutboxCoalescer.coalesce(
          activeItem: active,
          incomingOperation: OutboxOperationType.update,
          incomingPayloadJson: '{"name":"V2"}',
          incomingLocalVersion: 2,
          now: now,
        );

        expect(res.action, equals(CoalesceAction.updateExisting));
        expect(res.updatedItem!.operation, equals(OutboxOperationType.update));
        expect(res.updatedItem!.payloadJson, equals('{"name":"V2"}'));
      },
    );

    test('pendingCreate + delete -> single pendingDelete (tombstone)', () {
      final active =
          OutboxItem()
            ..operationId = 'op_create_1'
            ..entityType = 'word_set'
            ..entityId = '1'
            ..coalescingKey = 'user_A_word_set_1'
            ..operation = OutboxOperationType.create
            ..syncStatus = OutboxSyncStatus.pending
            ..payloadJson = '{"name":"Deck"}';

      final res = OutboxCoalescer.coalesce(
        activeItem: active,
        incomingOperation: OutboxOperationType.delete,
        incomingPayloadJson: null,
        incomingLocalVersion: 2,
        now: now,
      );

      expect(res.action, equals(CoalesceAction.updateExisting));
      expect(res.updatedItem!.operation, equals(OutboxOperationType.delete));
      expect(res.updatedItem!.isTombstone, isTrue);
      expect(res.updatedItem!.deletedAt, equals(now));
      expect(res.updatedItem!.payloadJson, isNull);
      expect(res.updatedItem!.operationId, equals('op_create_1'));
    });

    test('pendingUpdate + delete -> single pendingDelete (tombstone)', () {
      final active =
          OutboxItem()
            ..operationId = 'op_update_1'
            ..entityType = 'word_set'
            ..entityId = '1'
            ..coalescingKey = 'user_A_word_set_1'
            ..operation = OutboxOperationType.update
            ..syncStatus = OutboxSyncStatus.pending
            ..payloadJson = '{"name":"Deck"}';

      final res = OutboxCoalescer.coalesce(
        activeItem: active,
        incomingOperation: OutboxOperationType.delete,
        incomingPayloadJson: null,
        incomingLocalVersion: 2,
        now: now,
      );

      expect(res.action, equals(CoalesceAction.updateExisting));
      expect(res.updatedItem!.operation, equals(OutboxOperationType.delete));
      expect(res.updatedItem!.isTombstone, isTrue);
      expect(res.updatedItem!.deletedAt, equals(now));
      expect(res.updatedItem!.payloadJson, isNull);
    });

    test('pendingDelete + delete -> duplicate delete ignored', () {
      final active =
          OutboxItem()
            ..operationId = 'op_del_1'
            ..entityType = 'word_set'
            ..entityId = '1'
            ..coalescingKey = 'user_A_word_set_1'
            ..operation = OutboxOperationType.delete
            ..isTombstone = true
            ..syncStatus = OutboxSyncStatus.pending;

      final res = OutboxCoalescer.coalesce(
        activeItem: active,
        incomingOperation: OutboxOperationType.delete,
        incomingPayloadJson: null,
        incomingLocalVersion: 2,
        now: now,
      );

      expect(res.action, equals(CoalesceAction.duplicateIgnored));
    });

    test(
      'pendingDelete + update/create -> rejected (no silent resurrection)',
      () {
        final active =
            OutboxItem()
              ..operationId = 'op_del_1'
              ..entityType = 'word_set'
              ..entityId = '1'
              ..coalescingKey = 'user_A_word_set_1'
              ..operation = OutboxOperationType.delete
              ..isTombstone = true
              ..syncStatus = OutboxSyncStatus.pending;

        final res = OutboxCoalescer.coalesce(
          activeItem: active,
          incomingOperation: OutboxOperationType.update,
          incomingPayloadJson: '{"name":"Resurrected"}',
          incomingLocalVersion: 3,
          now: now,
        );

        expect(res.action, equals(CoalesceAction.rejectDeleted));
        expect(res.rejectionReason, isNotNull);
      },
    );
  });
}
