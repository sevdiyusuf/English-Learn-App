import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:yunoo/core/errors/app_failure.dart';
import 'package:yunoo/features/sync/domain/sync_retry_policy.dart';

void main() {
  group('Sprint 4D — SyncRetryPolicy & Classifier Unit Tests', () {
    test('Retryable codes return true', () {
      expect(
        FirebaseFailureClassifier.isRetryable(AppFailure.network()),
        isTrue,
      );
      expect(
        FirebaseFailureClassifier.isRetryable(AppFailure.server()),
        isTrue,
      );
      expect(FirebaseFailureClassifier.isRetryable('unavailable'), isTrue);
      expect(FirebaseFailureClassifier.isRetryable('timeout'), isTrue);
    });

    test('Permanent error codes return false', () {
      expect(
        FirebaseFailureClassifier.isRetryable('permission-denied'),
        isFalse,
      );
      expect(FirebaseFailureClassifier.isRetryable('unauthenticated'), isFalse);
      expect(
        FirebaseFailureClassifier.isRetryable('invalid-argument'),
        isFalse,
      );
    });

    test('Unknown error code defaults to false (no infinite retries)', () {
      expect(
        FirebaseFailureClassifier.isRetryable('some-unknown-custom-error'),
        isFalse,
      );
    });

    test('Exponential backoff delay calculation and max delay clamp', () {
      final policy = SyncRetryPolicy(
        maxAttempts: 3,
        baseDelayMs: 1000,
        maxDelayMs: 5000,
        random: Random(1), // Fixed random seed for deterministic test
      );

      final delay1 = policy.calculateBackoffDelay(1);
      final delay2 = policy.calculateBackoffDelay(2);
      final delay10 = policy.calculateBackoffDelay(10);

      expect(delay1.inMilliseconds, greaterThanOrEqualTo(1000));
      expect(delay2.inMilliseconds, greaterThanOrEqualTo(2000));
      expect(
        delay10.inMilliseconds,
        lessThanOrEqualTo(6000),
      ); // clamped near maxDelayMs (5000) + jitter
    });

    test('Stopping condition when max attempts reached', () {
      final policy = SyncRetryPolicy(maxAttempts: 3);

      expect(
        policy.shouldRetry(currentAttempts: 1, error: 'unavailable'),
        isTrue,
      );
      expect(
        policy.shouldRetry(currentAttempts: 2, error: 'unavailable'),
        isTrue,
      );
      expect(
        policy.shouldRetry(currentAttempts: 3, error: 'unavailable'),
        isFalse, // Reached max attempts (3)
      );
    });
  });
}
