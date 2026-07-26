import 'dart:math';

import '../../../core/errors/app_failure.dart';

class FirebaseFailureClassifier {
  static const Set<String> _retryableCodes = {
    'unavailable',
    'deadline-exceeded',
    'resource-exhausted',
    'aborted',
    'network-error',
    'timeout',
    '503',
    '504',
  };

  static const Set<String> _permanentCodes = {
    'permission-denied',
    'unauthenticated',
    'invalid-argument',
    'not-found',
    'already-exists',
    'failed-precondition',
    'out-of-range',
    'unimplemented',
    'data-loss',
  };

  static bool isRetryable(dynamic error) {
    if (error is AppFailure) {
      if (error.type == FailureType.network ||
          error.type == FailureType.server) {
        return true;
      }
      final code = error.code?.toLowerCase() ?? '';
      if (_retryableCodes.contains(code)) return true;
      if (_permanentCodes.contains(code)) return false;
      return error.isRetryable;
    }

    final errStr = error.toString().toLowerCase();
    for (final code in _retryableCodes) {
      if (errStr.contains(code)) return true;
    }
    for (final code in _permanentCodes) {
      if (errStr.contains(code)) return false;
    }

    // Default for unknown errors is NON-RETRYABLE to prevent infinite loops
    return false;
  }
}

class SyncRetryPolicy {
  SyncRetryPolicy({
    this.maxAttempts = 3,
    this.baseDelayMs = 1000,
    this.maxDelayMs = 30000,
    Random? random,
    DateTime Function()? clock,
    Future<void> Function(Duration duration)? sleeper,
  }) : _random = random ?? Random(42),
       _clock = clock ?? DateTime.now,
       _sleeper = sleeper ?? _defaultSleeper;

  final int maxAttempts;
  final int baseDelayMs;
  final int maxDelayMs;
  final Random _random;
  final DateTime Function() _clock;
  final Future<void> Function(Duration duration) _sleeper;

  static Future<void> _defaultSleeper(Duration duration) async {
    await Future.delayed(duration);
  }

  bool shouldRetry({required int currentAttempts, required dynamic error}) {
    if (currentAttempts >= maxAttempts) return false;
    return FirebaseFailureClassifier.isRetryable(error);
  }

  Duration calculateBackoffDelay(int attempt) {
    final exp = min(attempt - 1, 10);
    final calculatedMs = baseDelayMs * (1 << exp);
    final clampedMs = min(calculatedMs, maxDelayMs);
    final jitterMs = _random.nextInt(max(1, (clampedMs * 0.1).toInt()));
    return Duration(milliseconds: clampedMs + jitterMs);
  }

  Future<void> sleepForRetry(int attempt) async {
    final delay = calculateBackoffDelay(attempt);
    await _sleeper(delay);
  }

  DateTime now() => _clock();
}
