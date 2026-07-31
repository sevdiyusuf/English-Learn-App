import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yunoo/features/multiplayer/grammar_arena/models/arena_models.dart';

void main() {
  group('ArenaPlayer callable payload boundary tests', () {
    test(
      'toCallablePayload produces primitive-only map with name and photoUrl',
      () {
        final now = DateTime.now();
        final player = ArenaPlayer(
          id: 'user_123',
          name: 'Test Player',
          photoUrl: 'https://example.com/avatar.png',
          score: 100,
          isOnline: true,
          lastPing: now,
        );

        final payload = player.toCallablePayload();

        expect(payload['name'], equals('Test Player'));
        expect(payload['photoUrl'], equals('https://example.com/avatar.png'));
      },
    );

    test('toCallablePayload handles null photoUrl safely', () {
      final player = const ArenaPlayer(
        id: 'user_456',
        name: 'No Photo Player',
        photoUrl: null,
      );

      final payload = player.toCallablePayload();

      expect(payload['name'], equals('No Photo Player'));
      expect(payload.containsKey('photoUrl'), isTrue);
      expect(payload['photoUrl'], isNull);
    });

    test('toCallablePayload strictly excludes lastPing and Timestamp', () {
      final player = ArenaPlayer(
        id: 'user_789',
        name: 'Ping Player',
        lastPing: DateTime.now(),
      );

      final payload = player.toCallablePayload();

      expect(payload.containsKey('lastPing'), isFalse);
      expect(payload.values.any((v) => v is Timestamp), isFalse);
    });

    test(
      'toCallablePayload strictly excludes client-authoritative id, score, and isOnline fields',
      () {
        final player = ArenaPlayer(
          id: 'client_uid_should_not_be_sent',
          name: 'Authoritative Test',
          score: 999,
          isOnline: false,
        );

        final payload = player.toCallablePayload();

        expect(payload.containsKey('id'), isFalse);
        expect(payload.containsKey('uid'), isFalse);
        expect(payload.containsKey('score'), isFalse);
        expect(payload.containsKey('isOnline'), isFalse);
      },
    );

    test(
      'toCallablePayload contains only callable-safe primitive or null values',
      () {
        final player = ArenaPlayer(
          id: 'user_primitive',
          name: 'Primitive Check',
          photoUrl: 'https://example.com/pic.jpg',
          score: 50,
          isOnline: true,
          lastPing: DateTime.now(),
        );

        final payload = player.toCallablePayload();

        for (final entry in payload.entries) {
          final val = entry.value;
          expect(
            val == null || val is String || val is num || val is bool,
            isTrue,
            reason:
                'Field ${entry.key} with value $val is not a primitive/null callable-safe type',
          );
        }
      },
    );

    test(
      'Preserves original ArenaPlayer.toJson Firestore TimestampConverter behavior',
      () {
        final now = DateTime.now();
        final player = ArenaPlayer(
          id: 'user_firestore',
          name: 'Firestore Player',
          lastPing: now,
        );

        final firestoreJson = player.toJson();

        // Verify toJson() continues to serialize lastPing as Timestamp for Firestore document persistence
        expect(firestoreJson['lastPing'], isA<Timestamp>());
        expect((firestoreJson['lastPing'] as Timestamp).toDate(), equals(now));
      },
    );
  });
}
