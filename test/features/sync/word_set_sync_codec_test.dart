import 'package:flutter_test/flutter_test.dart';
import 'package:yunoo/core/errors/app_failure.dart';
import 'package:yunoo/features/sync/domain/word_set_sync_codec.dart';

void main() {
  group('Sprint 4D — WordSetSyncCodec Unit Tests', () {
    final now = DateTime(2026, 7, 24, 12, 0, 0);

    test('Encode canonical Word Match payload', () {
      final payload = {
        'name': 'Test Deck',
        'createdAt': now.toIso8601String(),
        'updatedAt': now.toIso8601String(),
        'visibility': 'private',
        'pairs': [
          {'english': 'apple', 'turkish': 'elma', 'learned': true},
        ],
      };

      final map = WordSetSyncCodec.encode(
        ownerUid: 'user_A',
        entityId: '101',
        entityType: 'word_set',
        remoteVersion: 2,
        operationId: 'op_encode_1',
        isTombstone: false,
        payload: payload,
      );

      expect(map['ownerUid'], equals('user_A'));
      expect(map['entityId'], equals('101'));
      expect(map['remoteVersion'], equals(2));
      expect(map['lastOperationId'], equals('op_encode_1'));
      expect(map['isTombstone'], isFalse);
      expect(map['name'], equals('Test Deck'));
      expect(map['pairs'], isNotEmpty);
    });

    test('Encode tombstone clears canonical payload', () {
      final map = WordSetSyncCodec.encode(
        ownerUid: 'user_A',
        entityId: '101',
        entityType: 'word_set',
        remoteVersion: 3,
        operationId: 'op_del_1',
        isTombstone: true,
        deletedAt: now,
      );

      expect(map['isTombstone'], isTrue);
      expect(map['deletedAt'], isNotNull);
      expect(map.containsKey('name'), isFalse);
      expect(map.containsKey('pairs'), isFalse);
    });

    test('Decode document map safely', () {
      final data = {
        'ownerUid': 'user_A',
        'entityId': '101',
        'entityType': 'word_set',
        'remoteVersion': 2,
        'lastOperationId': 'op_1',
        'isTombstone': false,
        'name': 'Decoded Deck',
        'serverUpdatedAt': now.toIso8601String(),
      };

      final decoded = WordSetSyncCodec.decode(documentId: '101', data: data);
      expect(decoded.ownerUid, equals('user_A'));
      expect(decoded.entityId, equals('101'));
      expect(decoded.remoteVersion, equals(2));
      expect(decoded.payload?['name'], equals('Decoded Deck'));
    });

    test('Decode rejects missing ownerUid with AppFailure.database', () {
      final malformed = {'entityId': '101', 'remoteVersion': 1};

      expect(
        () => WordSetSyncCodec.decode(documentId: '101', data: malformed),
        throwsA(isA<AppFailure>()),
      );
    });
  });
}
