import 'package:flutter_test/flutter_test.dart';
import 'package:yunoo/core/telemetry/telemetry_events.dart';
import 'package:yunoo/core/telemetry/telemetry_service.dart';

void main() {
  group('TelemetryEvents & TelemetryParams Tests', () {
    test('Event dictionary contains only required events', () {
      expect(
        TelemetryEvents.onboardingCompleted,
        equals('onboarding_completed'),
      );
      expect(TelemetryEvents.lessonStarted, equals('lesson_started'));
      expect(TelemetryEvents.lessonCompleted, equals('lesson_completed'));
      expect(
        TelemetryEvents.multiplayerMatchStarted,
        equals('multiplayer_match_started'),
      );
      expect(
        TelemetryEvents.multiplayerMatchCompleted,
        equals('multiplayer_match_completed'),
      );
      expect(
        TelemetryEvents.contentReportSubmitted,
        equals('content_report_submitted'),
      );
    });

    test(
      'Allowlist contains expected metadata keys and excludes high-cardinality IDs',
      () {
        expect(TelemetryParams.allowlist, contains('level'));
        expect(TelemetryParams.allowlist, contains('goal'));
        expect(TelemetryParams.allowlist, contains('content_type'));
        expect(TelemetryParams.allowlist, contains('content_level'));
        expect(TelemetryParams.allowlist, contains('match_mode'));
        expect(TelemetryParams.allowlist, contains('reason'));
        expect(TelemetryParams.allowlist, contains('feature'));
        expect(TelemetryParams.allowlist, isNot(contains('lesson_id')));
        expect(TelemetryParams.allowlist, isNot(contains('room_id')));
      },
    );
  });

  group('TelemetryService Privacy & Sanitization Boundary', () {
    late TelemetryService telemetryService;

    setUp(() {
      TelemetryService.resetForTesting();
      telemetryService = TelemetryService.instance;
    });

    tearDown(() {
      TelemetryService.resetForTesting();
    });

    test('Allowlisted metadata keys pass through intact', () {
      final input = <String, Object?>{
        'level': 'B1',
        'goal': 'general_english',
        'content_type': 'grammar_lesson',
        'content_level': 'A2',
        'match_mode': 'grammar_arena',
        'reason': 'spam',
        'retry_count': 2,
        'is_guest': true,
      };

      final sanitized = telemetryService.sanitizeMetadata(input);

      expect(sanitized['level'], equals('B1'));
      expect(sanitized['goal'], equals('general_english'));
      expect(sanitized['content_type'], equals('grammar_lesson'));
      expect(sanitized['content_level'], equals('A2'));
      expect(sanitized['match_mode'], equals('grammar_arena'));
      expect(sanitized['reason'], equals('spam'));
      expect(sanitized['retry_count'], equals(2));
      expect(sanitized['is_guest'], equals(true));
    });

    test('High-cardinality room_id and lesson_id are rejected strictly', () {
      final input = <String, Object?>{
        'room_id': 'room_abc_123',
        'lesson_id': 'g_a1_01',
        'level': 'A1',
      };

      final sanitized = telemetryService.sanitizeMetadata(input);

      expect(sanitized.containsKey('room_id'), isFalse);
      expect(sanitized.containsKey('lesson_id'), isFalse);
      expect(sanitized['level'], equals('A1'));
    });

    test('Forbidden PII and sensitive parameters are stripped strictly', () {
      final input = <String, Object?>{
        'email': 'user@example.com',
        'password': 'secret_password_123',
        'token': 'bearer_token_abc',
        'auth_token': 'auth_token_xyz',
        'app_check_token': 'app_check_token_123',
        'fcm_token': 'fcm_token_999',
        'uid': 'user_uid_12345',
        'user_id': 'user_uid_12345',
        'display_name': 'Secret User Name',
        'displayName': 'Secret User Name',
        'answer': 'The user answer text',
        'message': 'Chat message content',
        'body': 'Full request body',
        'title': 'Secret Title',
        'details': 'Detailed report text from user',
        'user_text': 'Arbitrary user input',
        'text': 'Some random text',
        // Valid key alongside sensitive ones
        'level': 'A2',
      };

      final sanitized = telemetryService.sanitizeMetadata(input);

      expect(sanitized.containsKey('email'), isFalse);
      expect(sanitized.containsKey('password'), isFalse);
      expect(sanitized.containsKey('token'), isFalse);
      expect(sanitized.containsKey('auth_token'), isFalse);
      expect(sanitized.containsKey('app_check_token'), isFalse);
      expect(sanitized.containsKey('fcm_token'), isFalse);
      expect(sanitized.containsKey('uid'), isFalse);
      expect(sanitized.containsKey('user_id'), isFalse);
      expect(sanitized.containsKey('display_name'), isFalse);
      expect(sanitized.containsKey('displayName'), isFalse);
      expect(sanitized.containsKey('answer'), isFalse);
      expect(sanitized.containsKey('message'), isFalse);
      expect(sanitized.containsKey('body'), isFalse);
      expect(sanitized.containsKey('title'), isFalse);
      expect(sanitized.containsKey('details'), isFalse);
      expect(sanitized.containsKey('user_text'), isFalse);
      expect(sanitized.containsKey('text'), isFalse);

      // Only allowed key remains
      expect(sanitized.length, equals(1));
      expect(sanitized['level'], equals('A2'));
    });

    test('Un-allowlisted arbitrary parameters are stripped', () {
      final input = <String, Object?>{
        'arbitrary_key': 'some_value',
        'custom_param': 12345,
        'level': 'C1',
      };

      final sanitized = telemetryService.sanitizeMetadata(input);

      expect(sanitized.containsKey('arbitrary_key'), isFalse);
      expect(sanitized.containsKey('custom_param'), isFalse);
      expect(sanitized['level'], equals('C1'));
    });

    test('String values longer than 100 characters are safely truncated', () {
      final longString = 'A' * 150;
      final input = <String, Object?>{'level': longString};

      final sanitized = telemetryService.sanitizeMetadata(input);

      expect((sanitized['level'] as String).length, equals(100));
    });

    test('Controlled test crash throws StateError when flag is false', () {
      expect(
        () => telemetryService.triggerControlledTestCrash(),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            contains('ENABLE_TEST_CRASH'),
          ),
        ),
      );
    });
  });
}
