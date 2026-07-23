import 'package:flutter/material.dart';
import '../errors/app_failure.dart';
import '../errors/firebase_error_mapper.dart';

enum ErrorViewMode {
  error,
  loading,
  empty,
}

class ErrorView extends StatelessWidget {
  const ErrorView({
    super.key,
    this.failure,
    this.error,
    this.title,
    this.message,
    this.icon,
    this.onRetry,
    this.retryButtonText = 'Tekrar Dene',
    this.mode = ErrorViewMode.error,
  });

  const ErrorView.loading({
    super.key,
    this.message = 'Yükleniyor...',
  })  : failure = null,
        error = null,
        title = null,
        icon = null,
        onRetry = null,
        retryButtonText = 'Tekrar Dene',
        mode = ErrorViewMode.loading;

  const ErrorView.empty({
    super.key,
    this.title = 'Henüz veri bulunmuyor',
    this.message = 'Burada gösterilecek herhangi bir içerik henüz eklenmedi.',
    this.icon = Icons.inbox_outlined,
    this.onRetry,
    this.retryButtonText = 'Yenile',
  })  : failure = null,
        error = null,
        mode = ErrorViewMode.empty;

  final AppFailure? failure;
  final dynamic error;
  final String? title;
  final String? message;
  final IconData? icon;
  final VoidCallback? onRetry;
  final String retryButtonText;
  final ErrorViewMode mode;

  @override
  Widget build(BuildContext context) {
    if (mode == ErrorViewMode.loading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            if (message != null) ...[
              const SizedBox(height: 16),
              Text(
                message!,
                style: const TextStyle(color: Colors.white70, fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      );
    }

    final resolvedFailure = failure ?? (error != null ? FirebaseErrorMapper.map(error) : null);
    final displayTitle = title ?? (mode == ErrorViewMode.empty ? 'Veri Bulunamadı' : 'Bir Hata Oluştu');
    final displayMessage = message ?? resolvedFailure?.message ?? 'Beklenmeyen bir durum oluştu.';
    final displayIcon = icon ?? _getIconForFailure(resolvedFailure, mode);
    final canRetry = onRetry != null && (resolvedFailure?.isRetryable ?? true);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: (mode == ErrorViewMode.empty ? Colors.blueAccent : Colors.redAccent).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                displayIcon,
                size: 48,
                color: mode == ErrorViewMode.empty ? Colors.blueAccent : Colors.redAccent,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              displayTitle,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              displayMessage,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            if (canRetry) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onRetry,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: Text(retryButtonText),
              ),
            ],
          ],
        ),
      ),
    );
  }

  static IconData _getIconForFailure(AppFailure? failure, ErrorViewMode mode) {
    if (mode == ErrorViewMode.empty) {
      return Icons.inbox_outlined;
    }
    if (failure == null) {
      return Icons.error_outline_rounded;
    }

    switch (failure.type) {
      case FailureType.network:
        return Icons.wifi_off_rounded;
      case FailureType.auth:
        return Icons.lock_outline_rounded;
      case FailureType.database:
        return Icons.storage_rounded;
      case FailureType.server:
        return Icons.cloud_off_rounded;
      case FailureType.unexpected:
        return Icons.error_outline_rounded;
    }
  }
}
