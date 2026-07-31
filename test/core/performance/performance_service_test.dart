import 'package:flutter_test/flutter_test.dart';
import 'package:yunoo/core/performance/performance_service.dart';
import 'package:yunoo/core/performance/performance_traces.dart';

void main() {
  group('PerformanceTraces & PerformanceParams Tests', () {
    test('Dictionary contains expected fixed traces', () {
      expect(PerformanceTraces.validTraces, contains('app_bootstrap'));
      expect(PerformanceTraces.validTraces, contains('lesson_load'));
      expect(PerformanceTraces.validTraces, contains('worksheet_load'));
      expect(PerformanceTraces.validTraces, contains('sync_cycle'));
      expect(PerformanceTraces.validTraces.length, equals(4));
    });

    test('Allowlist contains expected categorical attribute keys', () {
      expect(PerformanceParams.allowlist, contains('content_type'));
      expect(PerformanceParams.allowlist, contains('content_level'));
      expect(PerformanceParams.allowlist, contains('operation'));
      expect(PerformanceParams.allowlist, contains('stage'));
      expect(PerformanceParams.allowlist, contains('source_type'));
      expect(PerformanceParams.allowlist, contains('result_category'));
      expect(PerformanceParams.allowlist, contains('is_guest'));
    });
  });

  group('PerformanceService Privacy & Controlled Vocabulary Boundaries', () {
    late PerformanceService service;

    setUp(() {
      PerformanceService.resetForTesting();
      service = PerformanceService.instance;
    });

    tearDown(() {
      PerformanceService.resetForTesting();
    });

    test('Allowed controlled vocabulary values pass through intact', () {
      final input = <String, String>{
        'content_type': 'grammar_lesson',
        'content_level': 'B1',
        'operation': 'sync_bootstrap',
        'stage': 'bootstrap',
        'source_type': 'local_cache',
        'result_category': 'success',
        'is_guest': 'false',
      };

      final sanitized = service.sanitizeAttributes(input);

      expect(sanitized['content_type'], equals('grammar_lesson'));
      expect(sanitized['content_level'], equals('B1'));
      expect(sanitized['operation'], equals('sync_bootstrap'));
      expect(sanitized['stage'], equals('bootstrap'));
      expect(sanitized['source_type'], equals('local_cache'));
      expect(sanitized['result_category'], equals('success'));
      expect(sanitized['is_guest'], equals('false'));
    });

    test('Values outside controlled vocabulary are strictly rejected', () {
      final input = <String, String>{
        'content_type': 'unregistered_freeform_value',
        'content_level': 'SuperExpertLevel99',
        'operation': 'arbitrary_operation_id',
        'stage': 'bootstrap',
      };

      final sanitized = service.sanitizeAttributes(input);

      expect(sanitized.containsKey('content_type'), isFalse);
      expect(sanitized.containsKey('content_level'), isFalse);
      expect(sanitized.containsKey('operation'), isFalse);
      expect(sanitized['stage'], equals('bootstrap'));
      expect(sanitized.length, equals(1));
    });

    test(
      'Forbidden high-cardinality IDs, PII, and sensitive fields are strictly rejected',
      () {
        final input = <String, String>{
          'email': 'user@example.com',
          'password': 'secret_password',
          'token': 'bearer_token_123',
          'auth_token': 'auth_token_xyz',
          'app_check_token': 'app_check_token_abc',
          'fcm_token': 'fcm_token_999',
          'uid': 'user_12345',
          'user_id': 'user_12345',
          'room_id': 'room_abc',
          'lesson_id': 'g_a1_01',
          'set_id': 'set_xyz',
          'answer': 'User answer text',
          'message': 'Chat message text',
          'body': 'Request body',
          'title': 'Secret title',
          'text': 'Some random text',
          'display_name': 'Secret User',
          'stage': 'bootstrap',
        };

        final sanitized = service.sanitizeAttributes(input);

        expect(sanitized.containsKey('email'), isFalse);
        expect(sanitized.containsKey('password'), isFalse);
        expect(sanitized.containsKey('token'), isFalse);
        expect(sanitized.containsKey('auth_token'), isFalse);
        expect(sanitized.containsKey('app_check_token'), isFalse);
        expect(sanitized.containsKey('fcm_token'), isFalse);
        expect(sanitized.containsKey('uid'), isFalse);
        expect(sanitized.containsKey('user_id'), isFalse);
        expect(sanitized.containsKey('room_id'), isFalse);
        expect(sanitized.containsKey('lesson_id'), isFalse);
        expect(sanitized.containsKey('set_id'), isFalse);
        expect(sanitized.containsKey('answer'), isFalse);
        expect(sanitized.containsKey('message'), isFalse);
        expect(sanitized.containsKey('body'), isFalse);
        expect(sanitized.containsKey('title'), isFalse);
        expect(sanitized.containsKey('text'), isFalse);
        expect(sanitized.containsKey('display_name'), isFalse);
        expect(sanitized.length, equals(1));
        expect(sanitized['stage'], equals('bootstrap'));
      },
    );

    test('Unknown attribute keys not in allowlist are rejected', () {
      final input = <String, String>{
        'unknown_key': 'custom_val',
        'stage': 'bootstrap',
      };

      final sanitized = service.sanitizeAttributes(input);

      expect(sanitized.containsKey('unknown_key'), isFalse);
      expect(sanitized['stage'], equals('bootstrap'));
    });

    test(
      'traceAsync completes successfully and returns action result',
      () async {
        final result = await service.traceAsync(
          PerformanceTraces.appBootstrap,
          () async => 42,
        );

        expect(result, equals(42));
      },
    );

    test(
      'traceAsync propagates exceptions safely without swallowing',
      () async {
        expect(
          () => service.traceAsync(
            PerformanceTraces.lessonLoad,
            () async => throw StateError('Simulated Load Error'),
          ),
          throwsStateError,
        );
      },
    );

    test('Invalid trace names fall back safely to running action', () async {
      final result = await service.traceAsync(
        'invalid_unregistered_trace',
        () async => 'fallback_ok',
      );

      expect(result, equals('fallback_ok'));
    });
  });
}
