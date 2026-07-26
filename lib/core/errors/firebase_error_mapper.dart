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
      case 'user-not-found':
        return AppAuthFailure(
          message: 'Bu e-posta adresine ait bir kullanıcı kaydı bulunamadı.',
          code: e.code,
          reason: AuthFailureReason.userNotFound,
          originalError: e,
        );
      case 'wrong-password':
      case 'invalid-credential':
      case 'INVALID_LOGIN_CREDENTIALS':
        return AppAuthFailure(
          message: 'E-posta adresi veya şifre hatalı.',
          code: e.code,
          reason: AuthFailureReason.wrongPassword,
          originalError: e,
        );
      case 'credential-already-in-use':
      case 'email-already-in-use':
      case 'account-exists-with-different-credential':
        return AppAuthFailure(
          message: 'Bu hesap veya e-posta adresi zaten başka bir hesaba bağlı.',
          code: e.code,
          reason: AuthFailureReason.collision,
          originalError: e,
        );
      case 'invalid-email':
        return AppAuthFailure(
          message: 'Lütfen geçerli bir e-posta adresi girin.',
          code: e.code,
          reason: AuthFailureReason.invalidEmail,
          originalError: e,
        );
      case 'weak-password':
        return AppAuthFailure(
          message: 'Şifre çok zayıf. En az 6 karakter uzunluğunda olmalıdır.',
          code: e.code,
          reason: AuthFailureReason.weakPassword,
          originalError: e,
        );
      case 'user-disabled':
        return AppAuthFailure(
          message:
              'Bu kullanıcı hesabı askıya alınmıştır. Destek ekibiyle iletişime geçin.',
          code: e.code,
          reason: AuthFailureReason.disabled,
          originalError: e,
        );
      case 'too-many-requests':
        return AppAuthFailure(
          message:
              'Çok fazla başarısız deneme yapıldı. Lütfen biraz bekleyip tekrar deneyin.',
          code: e.code,
          isRetryable: true,
          reason: AuthFailureReason.tooManyRequests,
          originalError: e,
        );
      case 'operation-not-allowed':
        return AppAuthFailure(
          message: 'Bu giriş yöntemi şu anda aktif değildir.',
          code: e.code,
          reason: AuthFailureReason.unknown,
          originalError: e,
        );
      case 'network-request-failed':
        return AppFailure.network(
          message:
              'İnternet bağlantısı kurulamadı. Lütfen bağlantınızı kontrol edin.',
          code: e.code,
          originalError: e,
        );
      default:
        return AppAuthFailure(
          message: 'Kimlik doğrulama işlemi sırasında bir hata oluştu: ',
          code: e.code,
          reason: AuthFailureReason.unknown,
          originalError: e,
        );
    }
  }

  /// Returns user-friendly string message directly from any error
  static String getErrorMessage(dynamic error) {
    return map(error).message;
  }
}
