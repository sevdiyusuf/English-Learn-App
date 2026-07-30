import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yunoo/core/config/app_environment.dart';

void main() {
  setUp(() {
    AppEnvironment.resetForTest();
  });

  group('AppEnvironment Tests', () {
    test('AppEnvironmentMode defaults to debug when not in release', () {
      expect(AppEnvironmentMode.current, AppEnvironmentMode.debug);
    });

    test('shouldEnableEmulator defaults to false without dart-define flag', () {
      expect(AppEnvironment.shouldEnableEmulator(), isFalse);
    });

    test('emulatorHost returns correct host based on platform', () {
      final host = AppEnvironment.emulatorHost;
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
        expect(host, '10.0.2.2');
      } else {
        expect(host, '127.0.0.1');
      }
    });

    test('configureEmulators skips execution when not enabled', () async {
      await AppEnvironment.configureEmulators();
      expect(AppEnvironment.emulatorsConfigured, isFalse);
    });
  });
}
