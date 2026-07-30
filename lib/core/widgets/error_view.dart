import 'package:flutter/material.dart';
import 'package:yunoo/l10n/app_localizations.dart';

import '../errors/app_failure.dart';
import '../errors/firebase_error_mapper.dart';
import 'responsive_content.dart';

enum ErrorViewMode { error, loading, empty }

class ErrorView extends StatelessWidget {
  const ErrorView({
    super.key,
    this.failure,
    this.error,
    this.title,
    this.message,
    this.icon,
    this.onRetry,
    this.retryButtonText,
    this.mode = ErrorViewMode.error,
  });

  const ErrorView.loading({super.key, this.message})
    : failure = null,
      error = null,
      title = null,
      icon = null,
      onRetry = null,
      retryButtonText = null,
      mode = ErrorViewMode.loading;

  const ErrorView.empty({
    super.key,
    this.title,
    this.message,
    this.icon = Icons.inbox_outlined,
    this.onRetry,
    this.retryButtonText,
  }) : failure = null,
       error = null,
       mode = ErrorViewMode.empty;

  final AppFailure? failure;
  final Object? error;
  final String? title;
  final String? message;
  final IconData? icon;
  final VoidCallback? onRetry;
  final String? retryButtonText;
  final ErrorViewMode mode;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (mode == ErrorViewMode.loading) {
      final label = message ?? l10n.loading;
      return Semantics(
        label: label,
        liveRegion: true,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(label, textAlign: TextAlign.center),
            ],
          ),
        ),
      );
    }

    final resolvedFailure =
        failure ?? (error != null ? FirebaseErrorMapper.map(error) : null);
    final displayTitle =
        title ??
        (mode == ErrorViewMode.empty
            ? l10n.emptyStateTitle
            : l10n.genericErrorTitle);
    final displayMessage =
        message ??
        resolvedFailure?.message ??
        (mode == ErrorViewMode.empty
            ? l10n.emptyStateMessage
            : l10n.errorGeneric);
    final displayIcon = icon ?? _getIconForFailure(resolvedFailure, mode);
    final canRetry = onRetry != null && (resolvedFailure?.isRetryable ?? true);

    return ResponsiveContent(
      maxWidth: 640,
      alignment: Alignment.center,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Semantics(
          liveRegion: mode == ErrorViewMode.error,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ExcludeSemantics(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: (mode == ErrorViewMode.empty
                            ? Colors.blueAccent
                            : Colors.redAccent)
                        .withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    displayIcon,
                    size: 48,
                    color:
                        mode == ErrorViewMode.empty
                            ? Colors.blueAccent
                            : Colors.redAccent,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Semantics(
                header: true,
                child: Text(
                  displayTitle,
                  style: Theme.of(context).textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                displayMessage,
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              if (canRetry) ...[
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: Text(retryButtonText ?? l10n.retryAction),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  static IconData _getIconForFailure(AppFailure? failure, ErrorViewMode mode) {
    if (mode == ErrorViewMode.empty) return Icons.inbox_outlined;
    if (failure == null) return Icons.error_outline_rounded;
    return switch (failure.type) {
      FailureType.network => Icons.wifi_off_rounded,
      FailureType.auth => Icons.lock_outline_rounded,
      FailureType.database => Icons.storage_rounded,
      FailureType.server => Icons.cloud_off_rounded,
      FailureType.unexpected => Icons.error_outline_rounded,
    };
  }
}
