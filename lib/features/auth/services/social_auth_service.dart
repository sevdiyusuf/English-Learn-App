import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../../../core/errors/app_failure.dart';
import '../../../core/errors/firebase_error_mapper.dart';
import '../../../core/utils/error_logger.dart';

final socialAuthServiceProvider = Provider<SocialAuthService>((ref) {
  return const SocialAuthServiceImpl();
});

/// Abstract service for generating OAuth credentials from Social providers (Google, Apple).
/// By abstracting this, we can mock it in tests.
abstract class SocialAuthService {
  /// Gets a Google OAuthCredential. Returns null if user cancelled.
  Future<OAuthCredential?> getGoogleCredential();

  /// Gets an Apple OAuthCredential. Returns null if user cancelled.
  Future<OAuthCredential?> getAppleCredential();

  /// Checks if current platform is web (for testing abstractions)
  bool get isWeb;
}

class SocialAuthServiceImpl implements SocialAuthService {
  const SocialAuthServiceImpl();

  @override
  bool get isWeb => kIsWeb;

  @override
  Future<OAuthCredential?> getGoogleCredential() async {
    try {
      if (kIsWeb) {
        throw UnsupportedError('getGoogleCredential is not for Web.');
      }

      final GoogleSignIn googleSignIn = GoogleSignIn(
        scopes: ['email', 'profile'],
      );

      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        return null; // User cancelled
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      if (googleAuth.accessToken == null && googleAuth.idToken == null) {
        throw AppFailure.auth(
          message: 'Google kimlik doğrulama bilgileri alınamadı',
        );
      }

      return GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
    } catch (e, stack) {
      ErrorLogger.instance.logError(
        e,
        stackTrace: stack,
        context: 'SocialAuthServiceImpl.getGoogleCredential',
      );
      throw FirebaseErrorMapper.map(e);
    }
  }

  @override
  Future<OAuthCredential?> getAppleCredential() async {
    if (kIsWeb) {
      throw AppFailure.auth(
        message: 'Apple ile giriş web platformunda desteklenmiyor',
      );
    }

    try {
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      return OAuthProvider('apple.com').credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );
    } catch (e, stack) {
      if (e.toString().contains('canceled')) {
        return null; // Cancelled by user
      }
      ErrorLogger.instance.logError(
        e,
        stackTrace: stack,
        context: 'SocialAuthServiceImpl.getAppleCredential',
      );
      throw FirebaseErrorMapper.map(e);
    }
  }
}
