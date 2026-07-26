import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Environment modes supported by the application.
enum AppEnvironmentMode {
  debug,
  dev,
  release;

  static AppEnvironmentMode get current {
    if (kReleaseMode) return AppEnvironmentMode.release;
    const env = String.fromEnvironment('APP_ENV', defaultValue: '');
    if (env.toLowerCase() == 'dev') return AppEnvironmentMode.dev;
    return AppEnvironmentMode.debug;
  }
}

/// Central environment and Firebase emulator configuration manager.
class AppEnvironment {
  AppEnvironment._();

  static bool _emulatorsConfigured = false;

  /// Returns whether Firebase emulators have been activated in the current session.
  static bool get emulatorsConfigured => _emulatorsConfigured;

  /// Determines if emulators should be used based on compile-time environment flags.
  /// Default: false. Must be explicitly requested via `--dart-define=USE_FIREBASE_EMULATOR=true`.
  static bool shouldEnableEmulator() {
    const useEmulatorFlag = bool.fromEnvironment(
      'USE_FIREBASE_EMULATOR',
      defaultValue: false,
    );
    return useEmulatorFlag;
  }

  /// Resolves the appropriate host for emulator connections depending on platform.
  /// Android emulator requires `10.0.2.2` to access host localhost.
  /// Web, iOS simulator, and desktop platforms use `127.0.0.1`.
  static String get emulatorHost {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return '10.0.2.2';
    }
    return '127.0.0.1';
  }

  /// Configures Firebase Emulators for Auth, Firestore, and Functions safely.
  ///
  /// Safety Guarantees:
  /// 1. Fails fast with [StateError] if emulator usage is requested in Release mode.
  /// 2. Only runs if explicitly enabled via `shouldEnableEmulator()`.
  /// 3. Prevents duplicate invocations of `use...Emulator`.
  static Future<void> configureEmulators({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    FirebaseFunctions? functions,
    bool forceEnableForTest = false,
    String? customHost,
  }) async {
    final enable = forceEnableForTest || shouldEnableEmulator();
    if (!enable) {
      return;
    }

    // Fail-fast protection against running emulators in release builds
    if (kReleaseMode && !forceEnableForTest) {
      throw StateError(
        'SECURITY ERROR: Firebase Emulators cannot be enabled in Release mode!',
      );
    }

    if (_emulatorsConfigured) {
      return;
    }

    final host = customHost ?? emulatorHost;
    const authPort = 9099;
    const firestorePort = 8080;
    const functionsPort = 5001;

    try {
      final targetAuth = auth ?? FirebaseAuth.instance;
      await targetAuth.useAuthEmulator(host, authPort);

      final targetFirestore = firestore ?? FirebaseFirestore.instance;
      targetFirestore.useFirestoreEmulator(host, firestorePort);

      final targetFunctions =
          functions ?? FirebaseFunctions.instanceFor(region: 'us-central1');
      targetFunctions.useFunctionsEmulator(host, functionsPort);

      _emulatorsConfigured = true;
      if (kDebugMode) {
        debugPrint(
          '✅ Firebase Emulators connected successfully ($host: Auth:$authPort, Firestore:$firestorePort, Functions:$functionsPort)',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error configuring Firebase Emulators: $e');
      }
      rethrow;
    }
  }

  /// Resets configuration flag (strictly for testing purposes).
  @visibleForTesting
  static void resetForTest() {
    _emulatorsConfigured = false;
  }
}
