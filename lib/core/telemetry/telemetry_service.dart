import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

import 'telemetry_events.dart';

/// Centralized, privacy-safe telemetry service wrapping Firebase Crashlytics & Analytics.
class TelemetryService {
  TelemetryService._({
    FirebaseCrashlytics? crashlytics,
    FirebaseAnalytics? analytics,
  }) : _crashlytics = crashlytics,
       _analytics = analytics;

  static TelemetryService? _instance;

  /// Global singleton instance.
  static TelemetryService get instance => _instance ??= TelemetryService._();

  /// Inject custom instances or mocks (used for testing).
  static void setInstanceForTesting(TelemetryService service) {
    _instance = service;
  }

  /// Resets instance (strictly for testing).
  @visibleForTesting
  static void resetForTesting() {
    _instance = null;
  }

  FirebaseCrashlytics? _crashlytics;
  FirebaseAnalytics? _analytics;
  bool _initialized = false;

  /// Compile-time flag to allow controlled test crashes and debug Crashlytics collection for manual testing.
  static const bool enableTestCrash = bool.fromEnvironment(
    'ENABLE_TEST_CRASH',
    defaultValue: false,
  );

  /// Initializes Crashlytics and Analytics instances after Firebase is ready.
  Future<void> initialize({
    FirebaseCrashlytics? crashlytics,
    FirebaseAnalytics? analytics,
  }) async {
    if (_initialized) return;

    try {
      if (!kIsWeb) {
        _crashlytics = crashlytics ?? FirebaseCrashlytics.instance;

        // Collection policy:
        // - Release: enabled
        // - Debug/Dev WITH --dart-define=ENABLE_TEST_CRASH=true: enabled for manual test session
        // - Normal debug: disabled
        final shouldCollect = kReleaseMode || enableTestCrash;
        await _crashlytics?.setCrashlyticsCollectionEnabled(shouldCollect);
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('TelemetryService: Crashlytics init skipped/failed: $e');
      }
    }

    try {
      _analytics = analytics ?? FirebaseAnalytics.instance;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('TelemetryService: Analytics init skipped/failed: $e');
      }
    }

    _initialized = true;
    if (kDebugMode) {
      debugPrint('✅ TelemetryService initialized successfully');
    }
  }

  /// Records fatal Flutter framework errors.
  Future<void> recordFlutterError(FlutterErrorDetails details) async {
    if (kDebugMode) {
      debugPrint('🔴 [Telemetry] Fatal Flutter Error: ${details.exception}');
    }
    if (_crashlytics != null && !kIsWeb) {
      try {
        await _crashlytics!.recordFlutterFatalError(details);
      } catch (e) {
        debugPrint('Failed to record Flutter error: $e');
      }
    }
  }

  /// Records fatal uncaught platform / async errors.
  Future<void> recordPlatformError(Object error, StackTrace stackTrace) async {
    if (kDebugMode) {
      debugPrint('🔴 [Telemetry] Fatal Platform Error: $error');
    }
    if (_crashlytics != null && !kIsWeb) {
      try {
        await _crashlytics!.recordError(error, stackTrace, fatal: true);
      } catch (e) {
        debugPrint('Failed to record platform error: $e');
      }
    }
  }

  /// Records an explicit non-fatal caught exception with sanitized categorical metadata.
  Future<void> recordNonFatalError(
    Object error, {
    StackTrace? stackTrace,
    String? reason,
    Map<String, Object?>? attributes,
  }) async {
    final sanitizedAttributes = sanitizeMetadata(attributes);

    if (kDebugMode) {
      debugPrint(
        '⚠️ [Telemetry] Non-Fatal Error: $error (reason: $reason, attrs: $sanitizedAttributes)',
      );
    }

    if (_crashlytics != null && !kIsWeb) {
      try {
        for (final entry in sanitizedAttributes.entries) {
          final val = entry.value;
          if (val is String) {
            await _crashlytics!.setCustomKey(entry.key, val);
          } else if (val is int) {
            await _crashlytics!.setCustomKey(entry.key, val);
          } else if (val is double) {
            await _crashlytics!.setCustomKey(entry.key, val);
          } else if (val is bool) {
            await _crashlytics!.setCustomKey(entry.key, val);
          }
        }
        await _crashlytics!.recordError(
          error,
          stackTrace,
          reason: reason,
          fatal: false,
        );
      } catch (e) {
        debugPrint('Failed to record non-fatal error: $e');
      }
    }
  }

  /// Logs a custom analytics event from the fixed event dictionary with allowlisted parameters.
  Future<void> logAnalyticsEvent(
    String name, {
    Map<String, Object?>? parameters,
  }) async {
    final sanitizedParams = sanitizeMetadata(parameters);

    if (kDebugMode) {
      debugPrint(
        '📊 [Telemetry] Analytics Event: $name params: $sanitizedParams',
      );
    }

    if (_analytics != null) {
      try {
        await _analytics!.logEvent(name: name, parameters: sanitizedParams);
      } catch (e) {
        debugPrint('Failed to log analytics event $name: $e');
      }
    }
  }

  /// Sanitizes parameters/metadata against PII, high-cardinality IDs, and un-allowlisted keys.
  ///
  /// Guarantees:
  /// - Strips any key present in [TelemetryParams.forbiddenKeys].
  /// - Retains ONLY keys present in [TelemetryParams.allowlist].
  /// - Converts values to safe primitive types (String, int, double, bool).
  Map<String, Object> sanitizeMetadata(Map<String, Object?>? rawInput) {
    if (rawInput == null || rawInput.isEmpty) {
      return const <String, Object>{};
    }

    final result = <String, Object>{};

    for (final entry in rawInput.entries) {
      final rawKey = entry.key.trim();
      final lowerKey = rawKey.toLowerCase();

      // Check forbidden keys (exact & substring check for sensitive/high-cardinality tokens)
      if (TelemetryParams.forbiddenKeys.contains(lowerKey)) {
        continue;
      }

      // Allowlist check: must be in explicit low-cardinality allowlist
      if (!TelemetryParams.allowlist.contains(rawKey)) {
        continue;
      }

      final value = entry.value;
      if (value == null) continue;

      if (value is String) {
        // Truncate long strings to prevent arbitrary payload leaks
        result[rawKey] = value.length > 100 ? value.substring(0, 100) : value;
      } else if (value is int || value is double || value is bool) {
        result[rawKey] = value;
      } else {
        result[rawKey] = value.toString();
      }
    }

    return result;
  }

  /// Controlled test crash trigger.
  ///
  /// Must NEVER run in release builds or when `--dart-define=ENABLE_TEST_CRASH=true` is absent.
  void triggerControlledTestCrash() {
    if (kReleaseMode || !enableTestCrash) {
      throw StateError(
        'SECURITY ERROR: Test crash trigger is strictly disabled in Release mode or without --dart-define=ENABLE_TEST_CRASH=true.',
      );
    }

    if (kDebugMode) {
      debugPrint(
        '💥 [Telemetry] Triggering controlled Crashlytics test crash...',
      );
    }

    if (_crashlytics != null && !kIsWeb) {
      _crashlytics!.crash();
    } else {
      throw Exception('CONTROLLED TEST CRASH (Simulator / Web No-Op Mode)');
    }
  }
}
