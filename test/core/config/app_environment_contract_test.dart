import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yunoo/core/config/app_environment.dart';

void main() {
  group('AppEnvironment Contract & Parsing Tests', () {
    tearDown(() {
      AppEnvironment.resetForTest();
    });

    test('AppEnvironmentMode correctly reflects kReleaseMode', () {
      if (kReleaseMode) {
        expect(AppEnvironmentMode.current, AppEnvironmentMode.release);
      } else {
        expect(AppEnvironmentMode.current, isNot(AppEnvironmentMode.release));
      }
    });

    test(
      'emulatorHost returns 10.0.2.2 for Android and 127.0.0.1 for desktop/web',
      () {
        final host = AppEnvironment.emulatorHost;
        if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
          expect(host, '10.0.2.2');
        } else {
          expect(host, '127.0.0.1');
        }
      },
    );

    test('emulatorsConfigured state starts false', () {
      expect(AppEnvironment.emulatorsConfigured, isFalse);
    });
  });
}
