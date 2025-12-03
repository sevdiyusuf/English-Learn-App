import 'dart:async';

import 'package:flutter/foundation.dart';

/// Retry helper for network operations
class RetryHelper {
  /// Execute a function with automatic retry on failure
  /// 
  /// [fn] - The function to execute
  /// [maxRetries] - Maximum number of retries (default: 3)
  /// [retryDelay] - Delay between retries (default: 1 second)
  /// [shouldRetry] - Function to determine if error should be retried
  static Future<T> withRetry<T>({
    required Future<T> Function() fn,
    int maxRetries = 3,
    Duration retryDelay = const Duration(seconds: 1),
    bool Function(Object error)? shouldRetry,
  }) async {
    int attempts = 0;
    
    while (attempts <= maxRetries) {
      try {
        return await fn();
      } catch (error) {
        attempts++;
        
        // Check if we should retry this error
        if (shouldRetry != null && !shouldRetry(error)) {
          rethrow;
        }
        
        // Check if we've exhausted retries
        if (attempts > maxRetries) {
          rethrow;
        }
        
        // Wait before retrying
        if (kDebugMode) {
          debugPrint('Retry attempt $attempts/$maxRetries after error: $error');
        }
        await Future.delayed(retryDelay * attempts); // Exponential backoff
      }
    }
    
    throw StateError('Retry logic error: should not reach here');
  }

  /// Check if an error is retryable (network/timeout errors)
  static bool isRetryableError(Object error) {
    final errorString = error.toString().toLowerCase();
    return errorString.contains('network') ||
        errorString.contains('timeout') ||
        errorString.contains('connection') ||
        errorString.contains('unavailable') ||
        errorString.contains('deadline-exceeded') ||
        errorString.contains('internal');
  }
}

