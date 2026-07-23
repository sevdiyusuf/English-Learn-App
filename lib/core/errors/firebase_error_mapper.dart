import 'package:firebase_core/firebase_core.dart';
import 'app_failure.dart';

/// Maps raw Firebase exceptions and general system errors into user-friendly [AppFailure] instances.
class FirebaseErrorMapper {
  const FirebaseErrorMapper._();

  static AppFailure map(dynamic error) {
    if (error is AppFailure) {
      return error;
    }

    if (error is FirebaseException) {
      return _mapFirebaseException(error);
    }

    final errorString = error.toString().toLowerCase();

    if (errorString.contains('network') ||
        errorString.contains('socketexception') ||
        errorString.contains('connection failed') ||
        errorString.contains('host lookup')) {
      return AppFailure.network(originalError: error);
    }

    return AppFailure.unexpected(
      message: 'İşlem gerçekleştirilemedi: ${error.toString()}',
      originalError: error,
    );
  }

  static AppFailure _mapFirebaseException(FirebaseException e) {
    switch (e.code) {
      // Auth Error Codes
      case 'user-not-found':
        return AppFailure.auth(
          message: 'Bu e-posta adresine ait bir kullanıcı kaydı bulunamadı.',
          code: e.code,
          originalError: e,
        );

      case 'wrong-password':
      case 'invalid-credential':
      case 'INVALID_LOGIN_CREDENTIALS':
        return AppFailure.auth(
          message: 'E-posta adresi veya şifre hatalı.',
          code: e.code,
          originalError: e,
        );

      case 'email-already-in-use':
        return AppFailure.auth(
          message: 'Bu e-posta adresi ile zaten kayıtlı bir hesap bulunmaktadır.',
          code: e.code,
          originalError: e,
        );

      case 'invalid-email':
        return AppFailure.auth(
          message: 'Lütfen geçerli bir e-posta adresi girin.',
          code: e.code,
          originalError: e,
        );

      case 'weak-password':
        return AppFailure.auth(
          message: 'Şifre çok zayıf. En az 6 karakter uzunluğunda olmalıdır.',
          code: e.code,
          originalError: e,
        );

      case 'user-disabled':
        return AppFailure.auth(
          message: 'Bu kullanıcı hesabı askıya alınmıştır. Destek ekibiyle iletişime geçin.',
          code: e.code,
          originalError: e,
        );

      case 'operation-not-allowed':
        return AppFailure.auth(
          message: 'Bu giriş yöntemi şu anda aktif değildir.',
          code: e.code,
          originalError: e,
        );

      case 'too-many-requests':
        return AppFailure.auth(
          message: 'Çok fazla başarısız deneme yapıldı. Lütfen biraz bekleyip tekrar deneyin.',
          code: e.code,
          isRetryable: true,
          originalError: e,
        );

      case 'account-exists-with-different-credential':
        return AppFailure.auth(
          message: 'Bu e-posta adresi farklı bir giriş yöntemi ile kayıtlıdır.',
          code: e.code,
          originalError: e,
        );

      case 'requires-recent-login':
        return AppFailure.auth(
          message: 'Bu hassas işlem için lütfen tekrar giriş yapın.',
          code: e.code,
          originalError: e,
        );

      // Firestore & Database Error Codes
      case 'permission-denied':
        return AppFailure.database(
          message: 'Bu işlem için gerekli izinlere sahip değilsiniz.',
          code: e.code,
          originalError: e,
        );

      case 'unavailable':
        return AppFailure.network(
          message: 'Sunucuya ulaşılamıyor. İnternet bağlantınızı kontrol edin.',
          code: e.code,
          originalError: e,
        );

      case 'network-request-failed':
        return AppFailure.network(
          message: 'Ağ isteği başarısız oldu. Bağlantınızı kontrol edin.',
          code: e.code,
          originalError: e,
        );

      default:
        return AppFailure.unexpected(
          message: e.message ?? 'Bir Firebase hatası oluştu (${e.code}).',
          code: e.code,
          originalError: e,
        );
    }
  }

  /// Returns user-friendly string message directly from any error
  static String getErrorMessage(dynamic error) {
    return map(error).message;
  }
}
