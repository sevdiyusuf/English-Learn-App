import 'package:flutter/foundation.dart';

import '../telemetry/telemetry_service.dart';

/// Centralized error logging service
class ErrorLogger {
  static ErrorLogger? _instance;
  static ErrorLogger get instance => _instance ??= ErrorLogger._();

  ErrorLogger._();

  /// Logs an error with optional context
  void logError(
    Object error, {
    StackTrace? stackTrace,
    String? context,
    Map<String, dynamic>? additionalData,
  }) {
    if (kDebugMode) {
      debugPrint('========================================');
      debugPrint('ERROR LOG: ${DateTime.now()}');
      if (context != null) {
        debugPrint('Context: $context');
      }
      debugPrint('Error: $error');
      debugPrint('Error Type: ${error.runtimeType}');
      if (stackTrace != null) {
        debugPrint('Stack Trace:');
        debugPrint(stackTrace.toString());
      }
      if (additionalData != null && additionalData.isNotEmpty) {
        debugPrint('Additional Data:');
        additionalData.forEach((key, value) {
          debugPrint('  $key: $value');
        });
      }
      debugPrint('========================================');
    }
  }

  /// Controlled test crash trigger.
  /// Strictly gated by dev/debug mode and compile-time flag --dart-define=ENABLE_TEST_CRASH=true.
  void triggerControlledTestCrash() {
    TelemetryService.instance.triggerControlledTestCrash();
  }

  /// Logs a warning
  void logWarning(
    String message, {
    String? context,
    Map<String, dynamic>? additionalData,
  }) {
    if (kDebugMode) {
      debugPrint('========================================');
      debugPrint('WARNING LOG: ${DateTime.now()}');
      if (context != null) {
        debugPrint('Context: $context');
      }
      debugPrint('Message: $message');
      if (additionalData != null && additionalData.isNotEmpty) {
        debugPrint('Additional Data:');
        additionalData.forEach((key, value) {
          debugPrint('  $key: $value');
        });
      }
      debugPrint('========================================');
    }
  }

  /// Logs an info message
  void logInfo(
    String message, {
    String? context,
    Map<String, dynamic>? additionalData,
  }) {
    if (kDebugMode) {
      debugPrint('INFO: ${context != null ? "[$context] " : ""}$message');
      if (additionalData != null && additionalData.isNotEmpty) {
        debugPrint('  Data: $additionalData');
      }
    }
  }

  /// Logs a Firebase error specifically
  void logFirebaseError(
    Object error, {
    StackTrace? stackTrace,
    String? operation,
    Map<String, dynamic>? additionalData,
  }) {
    logError(
      error,
      stackTrace: stackTrace,
      context: 'Firebase Operation: ${operation ?? "Unknown"}',
      additionalData: additionalData,
    );
  }

  /// Logs a network error
  void logNetworkError(
    Object error, {
    StackTrace? stackTrace,
    String? url,
    String? method,
    Map<String, dynamic>? additionalData,
  }) {
    logError(
      error,
      stackTrace: stackTrace,
      context: 'Network Error: ${method ?? "Unknown"} ${url ?? "Unknown URL"}',
      additionalData: additionalData,
    );
  }
}
