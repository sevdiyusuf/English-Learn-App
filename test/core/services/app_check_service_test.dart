import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yunoo/core/services/app_check_service.dart';

class MockFirebaseAppCheck extends Fake implements FirebaseAppCheck {
  bool activateCalled = false;
  AndroidProvider? passedAndroidProvider;
  AppleProvider? passedAppleProvider;
  String? passedWebSiteKey;
  bool shouldThrow = false;

  @override
  Future<void> activate({
    AndroidProvider? androidProvider,
    AppleProvider? appleProvider,
    Object? webProvider,
  }) async {
    if (shouldThrow) {
      throw Exception('Simulated activation error');
    }
    activateCalled = true;
    passedAndroidProvider = androidProvider;
    passedAppleProvider = appleProvider;
    if (webProvider is ReCaptchaEnterpriseProvider) {
      passedWebSiteKey = webProvider.siteKey;
    }
  }
}

void main() {
  late MockFirebaseAppCheck mockAppCheck;

  setUp(() {
    AppCheckService.resetForTest();
    mockAppCheck = MockFirebaseAppCheck();
  });

  group('AppCheckService Unit Tests', () {
    test('1. Web release + key missing throws StateError', () async {
      expect(
        () => AppCheckService.activateAppCheck(
          appCheck: mockAppCheck,
          isDebugModeOverride: false,
          isWebOverride: true,
          isEmulatorOverride: false,
          webRecaptchaSiteKey: '',
          enableWebDebugOverride: false,
        ),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            contains('WEB_APPCHECK_SITE_KEY must be provided'),
          ),
        ),
      );
      expect(AppCheckService.isActivated, false);
      expect(mockAppCheck.activateCalled, false);
    });

    test('2. Web release + key present uses Enterprise provider', () async {
      await AppCheckService.activateAppCheck(
        appCheck: mockAppCheck,
        isDebugModeOverride: false,
        isWebOverride: true,
        isEmulatorOverride: false,
        webRecaptchaSiteKey: 'prod-site-key-123',
        enableWebDebugOverride: false,
      );

      expect(AppCheckService.isActivated, true);
      expect(mockAppCheck.activateCalled, true);
      expect(mockAppCheck.passedWebSiteKey, 'prod-site-key-123');
    });

    test(
      '3. Release + ENABLE_WEB_APPCHECK_DEBUG=true throws StateError',
      () async {
        expect(
          () => AppCheckService.activateAppCheck(
            appCheck: mockAppCheck,
            isDebugModeOverride: false,
            isWebOverride: true,
            isEmulatorOverride: false,
            webRecaptchaSiteKey: 'prod-site-key-123',
            enableWebDebugOverride: true,
          ),
          throwsA(
            isA<StateError>().having(
              (e) => e.message,
              'message',
              contains(
                'ENABLE_WEB_APPCHECK_DEBUG flag cannot be enabled in release builds',
              ),
            ),
          ),
        );
        expect(AppCheckService.isActivated, false);
      },
    );

    test(
      '4. Web debug + real Firebase + key missing throws StateError',
      () async {
        expect(
          () => AppCheckService.activateAppCheck(
            appCheck: mockAppCheck,
            isDebugModeOverride: true,
            isWebOverride: true,
            isEmulatorOverride: false,
            webRecaptchaSiteKey: '',
            enableWebDebugOverride: false,
          ),
          throwsA(
            isA<StateError>().having(
              (e) => e.message,
              'message',
              contains(
                'WEB_APPCHECK_SITE_KEY must be provided for Web debug mode',
              ),
            ),
          ),
        );
        expect(AppCheckService.isActivated, false);
      },
    );

    test(
      '5. Web debug + real Firebase + key present succeeds with debug token path',
      () async {
        await AppCheckService.activateAppCheck(
          appCheck: mockAppCheck,
          isDebugModeOverride: true,
          isWebOverride: true,
          isEmulatorOverride: false,
          webRecaptchaSiteKey: 'debug-real-site-key',
          enableWebDebugOverride: true,
        );

        expect(AppCheckService.isActivated, true);
        expect(mockAppCheck.activateCalled, true);
        expect(mockAppCheck.passedWebSiteKey, 'debug-real-site-key');
      },
    );

    test(
      '6. Web debug + emulator skips activation cleanly via emulator branch',
      () async {
        await AppCheckService.activateAppCheck(
          appCheck: mockAppCheck,
          isDebugModeOverride: true,
          isWebOverride: true,
          isEmulatorOverride: true,
          webRecaptchaSiteKey: '',
          enableWebDebugOverride: false,
        );

        expect(AppCheckService.isActivated, true);
        expect(
          mockAppCheck.activateCalled,
          false,
        ); // Skipped cleanly for emulator
      },
    );

    test('7. Android and Apple provider resolution remain unchanged', () {
      expect(
        AppCheckService.resolveAndroidProvider(isDebug: true),
        AndroidProvider.debug,
      );
      expect(
        AppCheckService.resolveAndroidProvider(isDebug: false),
        AndroidProvider.playIntegrity,
      );
      expect(
        AppCheckService.resolveAppleProvider(isDebug: true),
        AppleProvider.debug,
      );
      expect(
        AppCheckService.resolveAppleProvider(isDebug: false),
        AppleProvider.deviceCheck,
      );
    });
  });
}
