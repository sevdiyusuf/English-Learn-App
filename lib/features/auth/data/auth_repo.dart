import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../app/di.dart';
import '../../../core/errors/app_failure.dart';
import '../../../core/errors/firebase_error_mapper.dart';
import '../../../core/utils/error_logger.dart';
import '../services/social_auth_service.dart';
import 'package:cloud_functions/cloud_functions.dart';

import '../models/app_user.dart';

class AuthRepository {
  AuthRepository(this._auth, this._socialAuth, this._functions);

  final firebase_auth.FirebaseAuth _auth;
  final SocialAuthService _socialAuth;
  final FirebaseFunctions _functions;

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
        throw AppFailure.auth(
          message: 'Giriş başarılı oldu ancak kullanıcı bilgisi alınamadı',
        );
      }
      return AppUser.fromFirebaseUser(user);
    } catch (e, stack) {
      ErrorLogger.instance.logError(
        e,
        stackTrace: stack,
        context: 'ensureAnonymousGuestSignedIn',
      );
      throw FirebaseErrorMapper.map(e);
    }
  }

  /// Sign in with Google (For login only)
  Future<AppUser> signInWithGoogle() async {
    try {
      if (_socialAuth.isWeb) {
        final googleProvider = firebase_auth.GoogleAuthProvider();
        final userCredential = await _auth.signInWithPopup(googleProvider);
        final user = userCredential.user;
        if (user == null) {
          throw AppFailure.auth(message: 'Giriş başarısız oldu');
        }
        return AppUser.fromFirebaseUser(user);
      }

      final credential = await _socialAuth.getGoogleCredential();
      if (credential == null) {
        throw AppFailure.auth(message: 'Giriş iptal edildi');
      }
      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user;
      if (user == null) {
        throw AppFailure.auth(message: 'Giriş başarısız oldu');
      }
      return AppUser.fromFirebaseUser(user);
    } catch (e, stack) {
      if (e is firebase_auth.FirebaseAuthException &&
          (e.code == 'auth/popup-closed-by-user' ||
              e.code == 'auth/cancelled-popup-request')) {
        throw AppFailure.auth(message: 'Giriş iptal edildi');
      }
      ErrorLogger.instance.logError(
        e,
        stackTrace: stack,
        context: 'signInWithGoogle',
      );
      throw FirebaseErrorMapper.map(e);
    }
  }

  /// Sign in with Apple
  Future<AppUser> signInWithApple() async {
    try {
      final credential = await _socialAuth.getAppleCredential();
      if (credential == null) {
        throw AppFailure.auth(message: 'Giriş iptal edildi');
      }
      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user;
      if (user == null) {
        throw AppFailure.auth(message: 'Giriş başarısız oldu');
      }
      return AppUser.fromFirebaseUser(user);
    } catch (e, stack) {
      ErrorLogger.instance.logError(
        e,
        stackTrace: stack,
        context: 'signInWithApple',
      );
      throw FirebaseErrorMapper.map(e);
    }
  }

  /// Link Google Account to current user
  Future<AppUser> linkGoogleAccount() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw AppFailure.auth(message: 'Aktif bir kullanıcı bulunamadı.');
      }

      if (_socialAuth.isWeb) {
        final googleProvider = firebase_auth.GoogleAuthProvider();
        final userCredential = await currentUser.linkWithPopup(googleProvider);
        final user = userCredential.user;
        if (user == null) {
          throw AppFailure.auth(message: 'Hesap bağlantısı başarısız oldu');
        }
        return AppUser.fromFirebaseUser(user);
      }

      final credential = await _socialAuth.getGoogleCredential();
      if (credential == null) {
        throw AppFailure.auth(message: 'Bağlantı iptal edildi');
      }

      await currentUser.linkWithCredential(credential);
      final updatedUser = _auth.currentUser;
      if (updatedUser == null) {
        throw AppFailure.auth(message: 'Hesap bağlantısı başarısız oldu');
      }
      return AppUser.fromFirebaseUser(updatedUser);
    } catch (e, stack) {
      if (e is firebase_auth.FirebaseAuthException &&
          (e.code == 'auth/popup-closed-by-user' ||
              e.code == 'auth/cancelled-popup-request')) {
        throw AppFailure.auth(message: 'Giriş iptal edildi');
      }
      ErrorLogger.instance.logError(
        e,
        stackTrace: stack,
        context: 'linkGoogleAccount',
      );
      throw FirebaseErrorMapper.map(e);
    }
  }

  /// Link Apple Account to current user
  Future<AppUser> linkAppleAccount() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw AppFailure.auth(message: 'Aktif bir kullanıcı bulunamadı.');
      }
      final credential = await _socialAuth.getAppleCredential();
      if (credential == null) {
        throw AppFailure.auth(message: 'Bağlantı iptal edildi');
      }

      await currentUser.linkWithCredential(credential);
      final updatedUser = _auth.currentUser;
      if (updatedUser == null) {
        throw AppFailure.auth(message: 'Hesap bağlantısı başarısız oldu');
      }
      return AppUser.fromFirebaseUser(updatedUser);
    } catch (e, stack) {
      ErrorLogger.instance.logError(
        e,
        stackTrace: stack,
        context: 'linkAppleAccount',
      );
      throw FirebaseErrorMapper.map(e);
    }
  }

  /// Reauthenticate with Google
  Future<void> reauthenticateWithGoogle() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw AppFailure.auth(message: 'Aktif bir kullanıcı bulunamadı.');
      }
      if (_socialAuth.isWeb) {
        throw AppFailure.auth(
          message: 'Web platformunda yeniden doğrulama şu an desteklenmiyor.',
        );
      }
      final credential = await _socialAuth.getGoogleCredential();
      if (credential == null) {
        throw AppFailure.auth(message: 'İşlem iptal edildi');
      }
      await currentUser.reauthenticateWithCredential(credential);
    } catch (e, stack) {
      ErrorLogger.instance.logError(
        e,
        stackTrace: stack,
        context: 'reauthenticateWithGoogle',
      );
      throw FirebaseErrorMapper.map(e);
    }
  }

  /// Reauthenticate with Password
  Future<void> reauthenticateWithPassword(String password) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null || currentUser.email == null) {
        throw AppFailure.auth(message: 'Aktif bir kullanıcı bulunamadı.');
      }
      final credential = firebase_auth.EmailAuthProvider.credential(
        email: currentUser.email!,
        password: password,
      );
      await currentUser.reauthenticateWithCredential(credential);
    } catch (e, stack) {
      ErrorLogger.instance.logError(
        e,
        stackTrace: stack,
        context: 'reauthenticateWithPassword',
      );
      throw FirebaseErrorMapper.map(e);
    }
  }

  /// Reauthenticate with Apple
  Future<void> reauthenticateWithApple() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw AppFailure.auth(message: 'Aktif bir kullanıcı bulunamadı.');
      }
      final credential = await _socialAuth.getAppleCredential();
      if (credential == null) {
        throw AppFailure.auth(message: 'İşlem iptal edildi');
      }
      await currentUser.reauthenticateWithCredential(credential);
    } catch (e, stack) {
      ErrorLogger.instance.logError(
        e,
        stackTrace: stack,
        context: 'reauthenticateWithApple',
      );
      throw FirebaseErrorMapper.map(e);
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
              throw FirebaseErrorMapper.map(createError);
            }
          }
        } catch (e) {
          // If linking also fails, throw mapped
          throw FirebaseErrorMapper.map(e);
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
        throw AppFailure.auth(message: 'Kayıt başarısız oldu');
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
      throw FirebaseErrorMapper.map(e);
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
            throw AppFailure.auth(message: 'Hesap bağlantısı başarısız oldu');
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
              throw AppFailure.auth(message: 'Giriş başarısız oldu');
            }
            return AppUser.fromFirebaseUser(user);
          }
          // Other linking errors
          throw FirebaseErrorMapper.map(e);
        }
      } else {
        // Normal sign in (no anonymous user)
        await _auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
        final user = _auth.currentUser;
        if (user == null) {
          throw AppFailure.auth(message: 'Giriş başarısız oldu');
        }
        return AppUser.fromFirebaseUser(user);
      }
    } catch (e, stack) {
      ErrorLogger.instance.logError(
        e,
        stackTrace: stack,
        context: 'signInWithEmail',
      );
      throw FirebaseErrorMapper.map(e);
    }
  }

  /// Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e, stack) {
      if (e is firebase_auth.FirebaseAuthException &&
          e.code == 'user-not-found') {
        // Email enumeration prevention: Silently succeed if user not found
        ErrorLogger.instance.logWarning(
          'Password reset requested for non-existent email: $email',
          context: 'sendPasswordResetEmail',
        );
        return;
      }
      ErrorLogger.instance.logError(
        e,
        stackTrace: stack,
        context: 'sendPasswordResetEmail',
      );
      throw FirebaseErrorMapper.map(e);
    }
  }

  /// Update user display name
  Future<void> updateDisplayName(String name) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw AppFailure.auth(message: 'Kullanıcı bulunamadı');
      }

      await user.updateDisplayName(name);
      await user.reload();
    } catch (e, stack) {
      ErrorLogger.instance.logError(
        e,
        stackTrace: stack,
        context: 'updateDisplayName',
      );
      throw FirebaseErrorMapper.map(e);
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
      throw FirebaseErrorMapper.map(e);
    }
  }

  /// Delete account and data
  /// Calls the secure backend function 'requestAccountDeletion'
  Future<void> deleteAccountAndData() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw AppFailure.auth(message: 'Silinecek kullanıcı bulunamadı');
      }

      // Call Cloud Function to delete all data AND the Auth user
      final callable = _functions.httpsCallable('requestAccountDeletion');
      await callable.call();

      // Force local sign out to drop the invalidated session immediately
      await _auth.signOut();
    } catch (e, stack) {
      ErrorLogger.instance.logError(
        e,
        stackTrace: stack,
        context: 'deleteAccountAndData',
      );
      throw FirebaseErrorMapper.map(e);
    }
  }

  // Backward compatibility methods
  Stream<firebase_auth.User?> authStateChanges() => _auth.authStateChanges();
  Future<firebase_auth.UserCredential> signInAnonymously() =>
      _auth.signInAnonymously();
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final auth = ref.watch(firebaseAuthProvider);
  final socialAuth = ref.watch(socialAuthServiceProvider);
  final functions = ref.watch(firebaseFunctionsProvider);
  return AuthRepository(auth, socialAuth, functions);
});
