import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../../../app/di.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/utils/error_logger.dart';
import '../models/app_user.dart';

class AuthRepository {
  AuthRepository(this._auth);

  final firebase_auth.FirebaseAuth _auth;

  /// Get current Firebase user (for backward compatibility)
  firebase_auth.User? get currentUser => _auth.currentUser;

  /// Watch auth state changes and map to AppUser
  Stream<AppUser?> watchAuthUser() {
    return _auth.authStateChanges().map((user) {
      if (user == null) return null;
      return AppUser.fromFirebaseUser(user);
    });
  }

  /// Get current user as AppUser
  Future<AppUser?> getCurrentUser() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    return AppUser.fromFirebaseUser(user);
  }

  /// Ensure anonymous guest is signed in (for immediate play)
  Future<AppUser> ensureAnonymousGuestSignedIn() async {
    final current = _auth.currentUser;
    if (current != null) {
      return AppUser.fromFirebaseUser(current);
    }

    try {
      final credential = await _auth.signInAnonymously();
      final user = credential.user;
      if (user == null) {
        throw AppException(
          'Giriş başarılı oldu ancak kullanıcı bilgisi alınamadı',
        );
      }
      return AppUser.fromFirebaseUser(user);
    } catch (e, stack) {
      ErrorLogger.instance.logError(
        e,
        stackTrace: stack,
        context: 'ensureAnonymousGuestSignedIn',
      );
      rethrow;
    }
  }

  /// Sign in with Google
  Future<AppUser> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        // Web'de Firebase Auth'un kendi Google Sign-In metodunu kullan
        // Bu People API'ye ihtiyaç duymaz
        return await _signInWithGoogleWeb();
      } else {
        // Mobil/Desktop için google_sign_in paketini kullan
        return await _signInWithGoogleMobile();
      }
    } catch (e, stack) {
      ErrorLogger.instance.logError(
        e,
        stackTrace: stack,
        context: 'signInWithGoogle',
      );
      if (e is AppException) rethrow;
      throw AppException('Google ile giriş yapılamadı: ${e.toString()}');
    }
  }

  /// Web için Google Sign-In (Firebase Auth'un native signInWithPopup metodunu kullanır)
  /// Bu yöntem People API'ye ihtiyaç duymaz
  Future<AppUser> _signInWithGoogleWeb() async {
    try {
      final currentUser = _auth.currentUser;
      final googleProvider = firebase_auth.GoogleAuthProvider();

      // If current user is anonymous, try to link
      if (currentUser != null && currentUser.isAnonymous) {
        try {
          // Web'de linkWithPopup kullan
          final userCredential = await currentUser.linkWithPopup(
            googleProvider,
          );
          final user = userCredential.user;
          if (user == null) {
            throw AppException('Hesap bağlantısı başarısız oldu');
          }
          return AppUser.fromFirebaseUser(user);
        } on firebase_auth.FirebaseAuthException catch (e) {
          // If linking fails (e.g., credential already in use), sign in with popup
          if (e.code == 'credential-already-in-use' ||
              e.code == 'email-already-in-use') {
            final userCredential = await _auth.signInWithPopup(googleProvider);
            final user = userCredential.user;
            if (user == null) {
              throw AppException('Giriş başarısız oldu');
            }
            return AppUser.fromFirebaseUser(user);
          }
          rethrow;
        }
      } else {
        // Normal sign in with popup
        final userCredential = await _auth.signInWithPopup(googleProvider);
        final user = userCredential.user;
        if (user == null) {
          throw AppException('Giriş başarısız oldu');
        }
        return AppUser.fromFirebaseUser(user);
      }
    } on firebase_auth.FirebaseAuthException catch (e) {
      if (e.code == 'auth/popup-closed-by-user' ||
          e.code == 'auth/cancelled-popup-request') {
        throw AppException('Giriş iptal edildi');
      }
      rethrow;
    } catch (e) {
      if (e is AppException) rethrow;
      rethrow;
    }
  }

  /// Mobil/Desktop için Google Sign-In (google_sign_in paketi ile)
  Future<AppUser> _signInWithGoogleMobile() async {
    final GoogleSignIn googleSignIn = GoogleSignIn(
      scopes: ['email', 'profile'],
    );

    final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

    if (googleUser == null) {
      // User cancelled the sign-in
      throw AppException('Giriş iptal edildi');
    }

    final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;

    // Null check'ler
    if (googleAuth.accessToken == null && googleAuth.idToken == null) {
      throw AppException('Google kimlik doğrulama bilgileri alınamadı');
    }

    final credential = firebase_auth.GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final currentUser = _auth.currentUser;

    // If current user is anonymous, try to link
    if (currentUser != null && currentUser.isAnonymous) {
      try {
        await currentUser.linkWithCredential(credential);
        final updatedUser = _auth.currentUser;
        if (updatedUser == null) {
          throw AppException('Hesap bağlantısı başarısız oldu');
        }
        return AppUser.fromFirebaseUser(updatedUser);
      } on firebase_auth.FirebaseAuthException catch (e) {
        // If linking fails (e.g., credential already in use), sign in with credential
        if (e.code == 'credential-already-in-use' ||
            e.code == 'email-already-in-use') {
          await _auth.signInWithCredential(credential);
          final user = _auth.currentUser;
          if (user == null) {
            throw AppException('Giriş başarısız oldu');
          }
          return AppUser.fromFirebaseUser(user);
        }
        rethrow;
      }
    } else {
      // Normal sign in
      await _auth.signInWithCredential(credential);
      final user = _auth.currentUser;
      if (user == null) {
        throw AppException('Giriş başarısız oldu');
      }
      return AppUser.fromFirebaseUser(user);
    }
  }

  /// Sign in with Apple (iOS/macOS only)
  Future<AppUser> signInWithApple() async {
    if (kIsWeb) {
      throw AppException('Apple ile giriş web platformunda desteklenmiyor');
    }

    try {
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final oauthCredential = firebase_auth.OAuthProvider(
        'apple.com',
      ).credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );

      final currentUser = _auth.currentUser;

      // If current user is anonymous, try to link
      if (currentUser != null && currentUser.isAnonymous) {
        try {
          await currentUser.linkWithCredential(oauthCredential);
          final updatedUser = _auth.currentUser;
          if (updatedUser == null) {
            throw AppException('Hesap bağlantısı başarısız oldu');
          }
          return AppUser.fromFirebaseUser(updatedUser);
        } on firebase_auth.FirebaseAuthException catch (e) {
          // If linking fails, sign in with credential
          if (e.code == 'credential-already-in-use' ||
              e.code == 'email-already-in-use') {
            await _auth.signInWithCredential(oauthCredential);
            final user = _auth.currentUser;
            if (user == null) {
              throw AppException('Giriş başarısız oldu');
            }
            return AppUser.fromFirebaseUser(user);
          }
          rethrow;
        }
      } else {
        // Normal sign in
        await _auth.signInWithCredential(oauthCredential);
        final user = _auth.currentUser;
        if (user == null) {
          throw AppException('Giriş başarısız oldu');
        }
        return AppUser.fromFirebaseUser(user);
      }
    } catch (e, stack) {
      ErrorLogger.instance.logError(
        e,
        stackTrace: stack,
        context: 'signInWithApple',
      );
      if (e is AppException) rethrow;
      if (e is SignInWithAppleAuthorizationException) {
        if (e.code == AuthorizationErrorCode.canceled) {
          throw AppException('Giriş iptal edildi');
        }
        throw AppException('Apple ile giriş yapılamadı: ${e.message}');
      }
      throw AppException('Apple ile giriş yapılamadı: ${e.toString()}');
    }
  }

  /// Register with email and password
  Future<AppUser> registerWithEmail({
    required String email,
    required String password,
    String? name,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      firebase_auth.User? user;

      // If current user is anonymous, try to link
      if (currentUser != null && currentUser.isAnonymous) {
        try {
          // First, try to create the account (this will fail if email exists)
          // If it fails, we'll try to link
          try {
            final credential = await _auth.createUserWithEmailAndPassword(
              email: email,
              password: password,
            );
            user = credential.user;
          } on firebase_auth.FirebaseAuthException catch (createError) {
            // If email already exists, try to link anonymous account
            if (createError.code == 'email-already-in-use') {
              final linkCredential = firebase_auth.EmailAuthProvider.credential(
                email: email,
                password: password,
              );
              await currentUser.linkWithCredential(linkCredential);
              user = _auth.currentUser;
            } else {
              // Other errors from createUserWithEmailAndPassword
              rethrow;
            }
          }
        } catch (e) {
          // If linking also fails, rethrow the error
          rethrow;
        }
      } else {
        // Normal registration (no anonymous user)
        final credential = await _auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
        user = credential.user;
      }

      if (user == null) {
        throw AppException('Kayıt başarısız oldu');
      }

      // Update display name if provided
      if (name != null && name.isNotEmpty) {
        await user.updateDisplayName(name);
        await user.reload();
        user = _auth.currentUser;
      }

      return AppUser.fromFirebaseUser(user!);
    } catch (e, stack) {
      ErrorLogger.instance.logError(
        e,
        stackTrace: stack,
        context: 'registerWithEmail',
      );
      if (e is AppException) rethrow;
      if (e is firebase_auth.FirebaseAuthException) {
        final errorMessage = _getFirebaseAuthErrorMessage(e);
        throw AppException(errorMessage);
      }
      throw AppException('Kayıt başarısız oldu: ${e.toString()}');
    }
  }

  /// Sign in with email and password
  Future<AppUser> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final currentUser = _auth.currentUser;

      // If current user is anonymous, try to link
      if (currentUser != null && currentUser.isAnonymous) {
        try {
          final credential = firebase_auth.EmailAuthProvider.credential(
            email: email,
            password: password,
          );
          await currentUser.linkWithCredential(credential);
          final updatedUser = _auth.currentUser;
          if (updatedUser == null) {
            throw AppException('Hesap bağlantısı başarısız oldu');
          }
          return AppUser.fromFirebaseUser(updatedUser);
        } on firebase_auth.FirebaseAuthException catch (e) {
          // If linking fails (e.g., credential already in use), sign out and sign in
          if (e.code == 'credential-already-in-use' ||
              e.code == 'email-already-in-use' ||
              e.code == 'invalid-credential') {
            // Sign out anonymous user first
            await _auth.signOut();
            // Wait a bit for sign out to complete
            await Future.delayed(const Duration(milliseconds: 100));
            // Then sign in with the email/password
            await _auth.signInWithEmailAndPassword(
              email: email,
              password: password,
            );
            final user = _auth.currentUser;
            if (user == null) {
              throw AppException('Giriş başarısız oldu');
            }
            return AppUser.fromFirebaseUser(user);
          }
          // Other linking errors - rethrow
          rethrow;
        }
      } else {
        // Normal sign in (no anonymous user)
        await _auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
        final user = _auth.currentUser;
        if (user == null) {
          throw AppException('Giriş başarısız oldu');
        }
        return AppUser.fromFirebaseUser(user);
      }
    } catch (e, stack) {
      ErrorLogger.instance.logError(
        e,
        stackTrace: stack,
        context: 'signInWithEmail',
      );
      if (e is AppException) rethrow;
      if (e is firebase_auth.FirebaseAuthException) {
        final errorMessage = _getFirebaseAuthErrorMessage(e);
        throw AppException(errorMessage);
      }
      throw AppException('Giriş başarısız oldu: ${e.toString()}');
    }
  }

  /// Update user display name
  Future<void> updateDisplayName(String name) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw AppException('Kullanıcı bulunamadı');
      }

      await user.updateDisplayName(name);
      await user.reload();
    } catch (e, stack) {
      ErrorLogger.instance.logError(
        e,
        stackTrace: stack,
        context: 'updateDisplayName',
      );
      if (e is AppException) rethrow;
      throw AppException('İsim güncellenemedi: ${e.toString()}');
    }
  }

  /// Sign out current user
  Future<void> signOut() async {
    try {
      // Web'de GoogleSignIn() People API'yi çağırmaya çalışır, bu yüzden web'de atlıyoruz
      if (!kIsWeb) {
        try {
          final googleSignIn = GoogleSignIn();
          await googleSignIn.signOut();
        } catch (e) {
          // Ignore Google sign out errors
          ErrorLogger.instance.logWarning(
            'Google sign out failed: $e',
            context: 'signOut',
          );
        }
      }

      await _auth.signOut();
    } catch (e, stack) {
      ErrorLogger.instance.logError(e, stackTrace: stack, context: 'signOut');
      rethrow;
    }
  }

  /// Delete account and data
  /// Note: Firestore data deletion should be handled by Cloud Function
  /// TODO: Call Cloud Function 'deleteUserData' after successful deletion
  Future<void> deleteAccountAndData() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw AppException('Silinecek kullanıcı bulunamadı');
      }

      // TODO: Call Cloud Function to delete Firestore data
      // Example: await firebaseFunctions.httpsCallable('deleteUserData').call({'uid': user.uid});

      await user.delete();
    } catch (e, stack) {
      ErrorLogger.instance.logError(
        e,
        stackTrace: stack,
        context: 'deleteAccountAndData',
      );
      if (e is AppException) rethrow;
      if (e is firebase_auth.FirebaseAuthException) {
        final errorMessage = _getFirebaseAuthErrorMessage(e);
        throw AppException(errorMessage);
      }
      throw AppException('Hesap silme başarısız oldu: ${e.toString()}');
    }
  }

  /// Helper to get user-friendly error messages from Firebase Auth exceptions
  String _getFirebaseAuthErrorMessage(firebase_auth.FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'Şifre çok zayıf. Daha güçlü bir şifre seçin.';
      case 'email-already-in-use':
        return 'Bu e-posta adresi zaten kullanılıyor.';
      case 'invalid-email':
        return 'Geçersiz e-posta adresi.';
      case 'user-disabled':
        return 'Bu hesap devre dışı bırakılmış.';
      case 'user-not-found':
        return 'Kullanıcı bulunamadı.';
      case 'wrong-password':
        return 'Yanlış şifre.';
      case 'credential-already-in-use':
        return 'Bu hesap zaten başka bir yöntemle bağlı.';
      case 'operation-not-allowed':
        return 'Bu işlem izin verilmiyor.';
      case 'requires-recent-login':
        return 'Güvenlik için lütfen tekrar giriş yapın.';
      default:
        return e.message ?? 'Bir hata oluştu: ${e.code}';
    }
  }

  // Backward compatibility methods
  Stream<firebase_auth.User?> authStateChanges() => _auth.authStateChanges();
  Future<firebase_auth.UserCredential> signInAnonymously() =>
      _auth.signInAnonymously();
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final auth = ref.watch(firebaseAuthProvider);
  return AuthRepository(auth);
});
