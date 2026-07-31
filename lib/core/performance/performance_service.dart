import 'package:firebase_performance/firebase_performance.dart';
import 'package:flutter/foundation.dart';

import 'performance_traces.dart';

/// Centralized service wrapping Firebase Performance Monitoring safely.
class PerformanceService {
  PerformanceService._({FirebasePerformance? performance})
    : _performance = performance;

  static PerformanceService? _instance;

  /// Global singleton instance.
  static PerformanceService get instance =>
      _instance ??= PerformanceService._();

  /// Inject custom instance or mock for testing.
  static void setInstanceForTesting(PerformanceService service) {
    _instance = service;
  }

  /// Resets instance (strictly for unit testing).
  @visibleForTesting
  static void resetForTesting() {
    _instance = null;
  }

  FirebasePerformance? _performance;
  bool _initialized = false;

  /// Initializes Performance Monitoring instance safely.
  Future<void> initialize({FirebasePerformance? performance}) async {
    if (_initialized) return;

    try {
      if (!kIsWeb) {
        _performance = performance ?? FirebasePerformance.instance;
        await _performance?.setPerformanceCollectionEnabled(true);
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('PerformanceService init skipped/failed: $e');
      }
    }

    _initialized = true;
  }

  /// Runs an async operation wrapped inside a named custom performance trace.
  ///
  /// Guarantees that the trace is stopped safely in both success and error paths.
  Future<T> traceAsync<T>(
    String traceName,
    Future<T> Function() action, {
    Map<String, String>? attributes,
  }) async {
    if (!PerformanceTraces.validTraces.contains(traceName)) {
      if (kDebugMode) {
        debugPrint('⚠️ [Performance] Ignored invalid trace name: $traceName');
      }
      return action();
    }

    Trace? trace;
    try {
      if (_performance != null && !kIsWeb) {
        trace = _performance!.newTrace(traceName);
        final sanitizedAttrs = sanitizeAttributes(attributes);
        for (final entry in sanitizedAttrs.entries) {
          trace.putAttribute(entry.key, entry.value);
        }
        await trace.start();
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Performance trace start error ($traceName): $e');
      }
    }

    try {
      return await action();
    } finally {
      try {
        await trace?.stop();
      } catch (e) {
        if (kDebugMode) {
          debugPrint('Performance trace stop error ($traceName): $e');
        }
      }
    }
  }

  /// Sanitizes trace attributes against forbidden keys, high-cardinality values, PII, and controlled vocabularies.
  Map<String, String> sanitizeAttributes(Map<String, String>? rawInput) {
    if (rawInput == null || rawInput.isEmpty) {
      return const <String, String>{};
    }

    final result = <String, String>{};
    for (final entry in rawInput.entries) {
      final key = entry.key.trim();
      final lowerKey = key.toLowerCase();

      // Forbidden key check
      if (PerformanceParams.forbiddenKeys.contains(lowerKey)) {
        continue;
      }

      // Allowlist check
      if (!PerformanceParams.allowlist.contains(key)) {
        continue;
      }

      final value = entry.value.trim();
      if (value.isEmpty) continue;

      // Check controlled vocabularies if defined for this key
      final allowedVocab = PerformanceParams.controlledVocabularies[key];
      if (allowedVocab != null && !allowedVocab.contains(value)) {
        if (kDebugMode) {
          debugPrint(
            '⚠️ [Performance] Value "$value" rejected for attribute "$key": not in controlled vocabulary.',
          );
        }
        continue;
      }

      result[key] = value.length > 100 ? value.substring(0, 100) : value;
    }

    return result;
  }
}
