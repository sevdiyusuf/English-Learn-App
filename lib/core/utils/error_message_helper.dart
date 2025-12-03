import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

/// Firebase ve diğer hataları kullanıcı dostu Türkçe mesajlara çevirir
class ErrorMessageHelper {
  /// Hata objesini kullanıcı dostu Türkçe mesaja çevirir
  static String getErrorMessage(Object error, {String? defaultMessage}) {
    // Firebase Auth hataları
    if (error is FirebaseAuthException) {
      return _getFirebaseAuthErrorMessage(error);
    }

    // Firebase Functions hataları
    if (error is FirebaseException) {
      return _getFirebaseExceptionMessage(error);
    }

    // Cloud Functions hataları
    if (error is FirebaseFunctionsException) {
      return _getCloudFunctionsErrorMessage(error);
    }

    // String olarak gelen hata mesajları (örn: "deadline-exceeded")
    if (error is String) {
      return _getStringErrorMessage(error);
    }

    // Diğer hatalar
    final errorString = error.toString().toLowerCase();
    
    // Network hataları
    if (errorString.contains('network') || 
        errorString.contains('connection') ||
        errorString.contains('socket') ||
        errorString.contains('internet')) {
      return 'İnternet bağlantınızı kontrol edin ve tekrar deneyin';
    }

    // Timeout hataları
    if (errorString.contains('timeout') || 
        errorString.contains('deadline')) {
      return 'İşlem zaman aşımına uğradı. Lütfen tekrar deneyin';
    }

    // Permission hataları
    if (errorString.contains('permission') || 
        errorString.contains('unauthorized')) {
      return 'Bu işlem için yetkiniz yok';
    }

    // Default mesaj
    return defaultMessage ?? 
        'Beklenmeyen bir hata oluştu. Lütfen tekrar deneyin';
  }

  /// Firebase Auth hata mesajlarını Türkçe'ye çevirir
  static String _getFirebaseAuthErrorMessage(FirebaseAuthException error) {
    switch (error.code) {
      case 'user-disabled':
        return 'Bu hesap devre dışı bırakılmış';
      case 'user-not-found':
        return 'Kullanıcı bulunamadı';
      case 'wrong-password':
        return 'Hatalı şifre';
      case 'email-already-in-use':
        return 'Bu e-posta adresi zaten kullanılıyor';
      case 'invalid-email':
        return 'Geçersiz e-posta adresi';
      case 'weak-password':
        return 'Şifre çok zayıf';
      case 'network-request-failed':
        return 'İnternet bağlantınızı kontrol edin';
      case 'too-many-requests':
        return 'Çok fazla istek gönderildi. Lütfen daha sonra tekrar deneyin';
      case 'operation-not-allowed':
        return 'Bu işlem şu anda mümkün değil';
      default:
        return error.message ?? 'Kimlik doğrulama hatası';
    }
  }

  /// Firebase Exception mesajlarını Türkçe'ye çevirir
  static String _getFirebaseExceptionMessage(FirebaseException error) {
    switch (error.code) {
      case 'permission-denied':
        return 'Bu işlem için yetkiniz yok';
      case 'unavailable':
        return 'Servis şu anda kullanılamıyor. Lütfen daha sonra tekrar deneyin';
      case 'deadline-exceeded':
        return 'İşlem zaman aşımına uğradı';
      case 'not-found':
        return 'Aranan kayıt bulunamadı';
      case 'already-exists':
        return 'Bu kayıt zaten mevcut';
      case 'resource-exhausted':
        return 'Kaynak tükendi. Lütfen daha sonra tekrar deneyin';
      case 'failed-precondition':
        return 'İşlem için gerekli koşullar sağlanmadı';
      case 'aborted':
        return 'İşlem iptal edildi';
      case 'out-of-range':
        return 'Geçersiz aralık';
      case 'unimplemented':
        return 'Bu özellik henüz desteklenmiyor';
      case 'internal':
        return 'Sunucu hatası. Lütfen daha sonra tekrar deneyin';
      case 'unauthenticated':
        return 'Oturum bulunamadı. Lütfen tekrar giriş yapın';
      case 'cancelled':
        return 'İşlem iptal edildi';
      default:
        return error.message ?? 'Bir hata oluştu';
    }
  }

  /// Cloud Functions hata mesajlarını Türkçe'ye çevirir
  static String _getCloudFunctionsErrorMessage(FirebaseFunctionsException error) {
    switch (error.code) {
      case 'invalid-argument':
        return error.message ?? 'Geçersiz parametre';
      case 'deadline-exceeded':
        return 'Tur süresi dolmuş';
      case 'not-found':
        return 'Oda bulunamadı';
      case 'permission-denied':
        return 'Bu işlem için yetkiniz yok';
      case 'failed-precondition':
        return error.message ?? 'İşlem için gerekli koşullar sağlanmadı';
      case 'aborted':
        return 'İşlem iptal edildi';
      case 'out-of-range':
        return 'Geçersiz aralık';
      case 'unimplemented':
        return 'Bu özellik henüz desteklenmiyor';
      case 'internal':
        return 'Sunucu hatası. Lütfen daha sonra tekrar deneyin';
      case 'unavailable':
        return 'Servis şu anda kullanılamıyor';
      case 'unauthenticated':
        return 'Oturum bulunamadı. Lütfen tekrar giriş yapın';
      case 'cancelled':
        return 'İşlem iptal edildi';
      default:
        // Eğer hata mesajı zaten Türkçe ise, onu kullan
        final message = error.message;
        if (message != null && _isTurkish(message)) {
          return message;
        }
        return message ?? 'Bir hata oluştu';
    }
  }

  /// String hata mesajlarını kontrol eder
  static String _getStringErrorMessage(String error) {
    final lowerError = error.toLowerCase();
    
    if (lowerError.contains('deadline-exceeded') || 
        lowerError.contains('tur süresi')) {
      return 'Tur süresi dolmuş';
    }
    
    if (lowerError.contains('permission-denied') || 
        lowerError.contains('yetkiniz yok')) {
      return 'Bu işlem için yetkiniz yok';
    }
    
    if (lowerError.contains('network') || 
        lowerError.contains('internet')) {
      return 'İnternet bağlantınızı kontrol edin';
    }
    
    if (lowerError.contains('not-found') || 
        lowerError.contains('bulunamadı')) {
      return 'Aranan kayıt bulunamadı';
    }
    
    // Eğer mesaj zaten Türkçe görünüyorsa, olduğu gibi döndür
    if (_isTurkish(error)) {
      return error;
    }
    
    return 'Bir hata oluştu: $error';
  }

  /// Metnin Türkçe karakter içerip içermediğini kontrol eder
  static bool _isTurkish(String text) {
    final turkishChars = RegExp(r'[çğıöşüÇĞİÖŞÜ]');
    return turkishChars.hasMatch(text);
  }

  /// Hatanın retry edilebilir olup olmadığını kontrol eder
  static bool isRetryable(Object error) {
    if (error is FirebaseException) {
      return error.code == 'unavailable' || 
             error.code == 'deadline-exceeded' ||
             error.code == 'internal' ||
             error.code == 'cancelled';
    }
    
    if (error is FirebaseFunctionsException) {
      return error.code == 'unavailable' || 
             error.code == 'deadline-exceeded' ||
             error.code == 'internal' ||
             error.code == 'cancelled';
    }
    
    final errorString = error.toString().toLowerCase();
    return errorString.contains('network') || 
           errorString.contains('timeout') ||
           errorString.contains('connection');
  }

  /// Hata için uygun icon döndürür
  static IconData getErrorIcon(Object error) {
    if (error is FirebaseException || error is FirebaseFunctionsException) {
      final code = (error is FirebaseException) 
          ? error.code 
          : (error as FirebaseFunctionsException).code;
      
      switch (code) {
        case 'permission-denied':
        case 'unauthenticated':
          return Icons.lock_outline;
        case 'network-request-failed':
        case 'unavailable':
          return Icons.wifi_off;
        case 'deadline-exceeded':
          return Icons.timer_off;
        case 'not-found':
          return Icons.search_off;
        default:
          return Icons.error_outline;
      }
    }
    
    final errorString = error.toString().toLowerCase();
    if (errorString.contains('network') || errorString.contains('connection')) {
      return Icons.wifi_off;
    }
    
    return Icons.error_outline;
  }
}

