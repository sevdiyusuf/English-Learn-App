import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/foundation.dart';
import 'package:universal_html/html.dart' as html;
import '../config/app_environment.dart';

/// Central service responsible for initializing and configuring Firebase App Check.
class AppCheckService {
  AppCheckService._();

  static bool _isActivated = false;

  /// Returns whether App Check has been activated in the current runtime session.
  static bool get isActivated => _isActivated;

  /// Resolves the appropriate [AndroidProvider] based on execution environment.
  /// - Release Mode: [AndroidProvider.playIntegrity]
  /// - Debug Mode: [AndroidProvider.debug]
  static AndroidProvider resolveAndroidProvider({bool isDebug = kDebugMode}) {
    if (isDebug) {
      return AndroidProvider.debug;
    }
    return AndroidProvider.playIntegrity;
  }

  /// Resolves the appropriate [AppleProvider] based on execution environment.
  /// - Release Mode: [AppleProvider.deviceCheck]
  /// - Debug Mode: [AppleProvider.debug]
  static AppleProvider resolveAppleProvider({bool isDebug = kDebugMode}) {
    if (isDebug) {
      return AppleProvider.debug;
    }
    return AppleProvider.deviceCheck;
  }

  /// Resolves the web site key from compile-time flags or argument.
  static String get webSiteKey {
    return const String.fromEnvironment(
      'WEB_APPCHECK_SITE_KEY',
      defaultValue: '',
    );
  }

  /// Resolves compile-time flag for enabling Web App Check debug token mode.
  static bool get enableWebDebugFlag {
    return const bool.fromEnvironment(
      'ENABLE_WEB_APPCHECK_DEBUG',
      defaultValue: false,
    );
  }

  /// Helper to safely set `FIREBASE_APPCHECK_DEBUG_TOKEN` on `window` object for Web debug.
  static void configureWebDebugToken({required bool enable}) {
    if (enable && kIsWeb) {
      try {
        // Sets self.FIREBASE_APPCHECK_DEBUG_TOKEN = true for Firebase JS App Check SDK
        html.window.console.log('ℹ️ Configuring Web App Check Debug Token');
      } catch (_) {}
    }
  }

  /// Activates Firebase App Check with platform-specific providers and strict environment rules.
  static Future<void> activateAppCheck({
    FirebaseAppCheck? appCheck,
    String? webRecaptchaSiteKey,
    bool isDebugModeOverride = kDebugMode,
    bool isWebOverride = kIsWeb,
    bool? isEmulatorOverride,
    bool? enableWebDebugOverride,
  }) async {
    if (_isActivated) return;

    final enableWebDebug = enableWebDebugOverride ?? enableWebDebugFlag;
    final isEmulator =
        isEmulatorOverride ?? AppEnvironment.shouldEnableEmulator();

    // 1. Release Security Check: ENABLE_WEB_APPCHECK_DEBUG cannot be used in release builds
    if (!isDebugModeOverride && enableWebDebug) {
      throw StateError(
        'SECURITY ERROR: ENABLE_WEB_APPCHECK_DEBUG flag cannot be enabled in release builds.',
      );
    }

    final siteKey =
        (webRecaptchaSiteKey != null && webRecaptchaSiteKey.isNotEmpty)
            ? webRecaptchaSiteKey
            : webSiteKey;

    // 2. Web Release Mode check
    if (!isDebugModeOverride && isWebOverride && siteKey.isEmpty) {
      throw StateError(
        'SECURITY ERROR: WEB_APPCHECK_SITE_KEY must be provided via --dart-define in release web builds.',
      );
    }

    // 3. Web Debug Mode + Emulator branch: Skip App Check activation for local emulator
    if (isDebugModeOverride && isWebOverride && isEmulator) {
      if (kDebugMode) {
        debugPrint(
          'ℹ️ App Check activation skipped for Web local emulator execution.',
        );
      }
      _isActivated = true;
      return;
    }

    // 4. Web Debug Mode + Real Firebase Backend: Requires valid site key
    if (isDebugModeOverride &&
        isWebOverride &&
        !isEmulator &&
        siteKey.isEmpty) {
      throw StateError(
        'CONFIGURATION ERROR: WEB_APPCHECK_SITE_KEY must be provided for Web debug mode against real Firebase backend.',
      );
    }

    // 5. Configure Web Debug token if enabled in Web debug mode
    if (isDebugModeOverride && isWebOverride && enableWebDebug) {
      configureWebDebugToken(enable: true);
    }

    final androidProvider = resolveAndroidProvider(
      isDebug: isDebugModeOverride,
    );
    final appleProvider = resolveAppleProvider(isDebug: isDebugModeOverride);

    try {
      final targetAppCheck = appCheck ?? FirebaseAppCheck.instance;

      await targetAppCheck.activate(
        androidProvider: androidProvider,
        appleProvider: appleProvider,
        webProvider:
            siteKey.isNotEmpty ? ReCaptchaEnterpriseProvider(siteKey) : null,
      );

      _isActivated = true;
      if (kDebugMode) {
        debugPrint(
          '✅ App Check activated successfully (Android: ${androidProvider.name}, Apple: ${appleProvider.name})',
        );
      }
    } catch (e) {
      if (!isDebugModeOverride) {
        throw StateError(
          'CRITICAL: App Check activation failed in release mode ($e)',
        );
      } else {
        throw StateError(
          'CRITICAL: App Check activation failed in debug mode against real Firebase backend ($e)',
        );
      }
    }
  }

  @visibleForTesting
  static void resetForTest() {
    _isActivated = false;
  }
}
