import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    // Always check kIsWeb first for iOS Safari compatibility
    // iOS Safari should be treated as web platform
    // This is the safest approach for web browsers on iOS
    try {
      if (kIsWeb) {
        return web;
      }
    } catch (e) {
      // If kIsWeb check fails for any reason, assume web (safer for iOS Safari)
      return web;
    }

    // For non-web platforms, use defaultTargetPlatform
    // This should never execute on iOS Safari (which is web)
    try {
      final platform = defaultTargetPlatform;
      switch (platform) {
        case TargetPlatform.android:
          return android;
        case TargetPlatform.iOS:
          return ios;
        case TargetPlatform.macOS:
          return ios;
        case TargetPlatform.windows:
        case TargetPlatform.linux:
          throw UnsupportedError(
            'FirebaseOptions have not been configured for this platform.',
          );
        default:
          // Fallback to web for unknown platforms (safer for iOS Safari)
          return web;
      }
    } catch (e) {
      // If there's any error determining platform, fall back to web
      // This is safer for iOS Safari edge cases
      return web;
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyByotpukb4AtLC_lZQxc0CojeSq4DlWk44',
    appId: '1:55568769953:web:3dd0f776ec8324a1f921e0',
    messagingSenderId: '55568769953',
    projectId: 'my-english-project-f25ff',
    authDomain: 'my-english-project-f25ff.firebaseapp.com',
    storageBucket: 'my-english-project-f25ff.firebasestorage.app',
    measurementId: 'G-V2QYPYTFRV',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCwjmzOdDqqoDtNZkHC_7VgOzcUFFq8SyY',
    appId: '1:55568769953:android:2fe5073ef2d7ca2cf921e0',
    messagingSenderId: '55568769953',
    projectId: 'my-english-project-f25ff',
    storageBucket: 'my-english-project-f25ff.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAxeI2ZrzfW80ZpQR4NnVoGqIT_I6RfHQE',
    appId: '1:55568769953:ios:5a54255394dc8cd8f921e0',
    messagingSenderId: '55568769953',
    projectId: 'my-english-project-f25ff',
    storageBucket: 'my-english-project-f25ff.firebasestorage.app',
    iosBundleId: 'english-word',
  );
}
