import 'package:flutter/foundation.dart';

enum FailureType { network, auth, database, server, unexpected }

enum AuthFailureReason {
  collision,
  wrongPassword,
  userNotFound,
  cancelled,
  invalidEmail,
  weakPassword,
  disabled,
  tooManyRequests,
  network,
  unknown,
}

@immutable
class AppAuthFailure extends AppFailure {
  const AppAuthFailure({
    required super.message,
    super.code,
    required this.reason,
    super.isRetryable = false,
    super.originalError,
  }) : super(type: FailureType.auth);

  final AuthFailureReason reason;
}

@immutable
class AppFailure implements Exception {
  const AppFailure({
    required this.message,
    this.code,
    this.type = FailureType.unexpected,
    this.isRetryable = true,
    this.originalError,
  });

  final String message;
  final String? code;
  final FailureType type;
  final bool isRetryable;
  final dynamic originalError;

  factory AppFailure.network({
    String message =
        'İnternet bağlantısı kurulamadı. Lütfen bağlantınızı kontrol edin.',
    String? code = 'network-error',
    dynamic originalError,
  }) {
    return AppFailure(
      message: message,
      code: code,
      type: FailureType.network,
      isRetryable: true,
      originalError: originalError,
    );
  }

  factory AppFailure.auth({
    required String message,
    String? code,
    bool isRetryable = false,
    dynamic originalError,
  }) {
    return AppFailure(
      message: message,
      code: code,
      type: FailureType.auth,
      isRetryable: isRetryable,
      originalError: originalError,
    );
  }

  factory AppFailure.database({
    String message = 'Veritabanı işlemi sırasında bir hata oluştu.',
    String? code = 'database-error',
    dynamic originalError,
  }) {
    return AppFailure(
      message: message,
      code: code,
      type: FailureType.database,
      isRetryable: true,
      originalError: originalError,
    );
  }

  factory AppFailure.server({
    String message = 'Sunucu yanıt vermiyor. Lütfen daha sonra tekrar deneyin.',
    String? code = 'server-error',
    dynamic originalError,
  }) {
    return AppFailure(
      message: message,
      code: code,
      type: FailureType.server,
      isRetryable: true,
      originalError: originalError,
    );
  }

  factory AppFailure.unexpected({
    String message = 'Beklenmeyen bir hata oluştu. Lütfen tekrar deneyin.',
    String? code = 'unexpected-error',
    dynamic originalError,
  }) {
    return AppFailure(
      message: message,
      code: code,
      type: FailureType.unexpected,
      isRetryable: true,
      originalError: originalError,
    );
  }

  @override
  String toString() => code == null ? message : '[$code] $message';
}
