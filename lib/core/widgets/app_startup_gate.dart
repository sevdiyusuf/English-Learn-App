import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/logic/auth_controller.dart';
import '../utils/error_message_helper.dart';
import '../utils/retry_helper.dart';
import 'loading_widget.dart';

class AppStartupGate extends ConsumerWidget {
  const AppStartupGate({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);

    return authState.when(
      data: (_) => child,
      loading: () => const FullScreenLoading(
        message: 'Uygulama başlatılıyor...',
      ),
      error:
          (error, stack) => Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      ErrorMessageHelper.getErrorIcon(error),
                      size: 56,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Başlatma sırasında bir hata oluştu',
                      style: Theme.of(context).textTheme.titleMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      ErrorMessageHelper.getErrorMessage(
                        error,
                        defaultMessage: 'Uygulama başlatılamadı. Lütfen tekrar deneyin.',
                      ),
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                    if (ErrorMessageHelper.isRetryable(error) || RetryHelper.isRetryableError(error)) ...[
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () {
                          // Retry by invalidating the auth controller
                          ref.invalidate(authControllerProvider);
                        },
                        icon: const Icon(Icons.refresh),
                        label: const Text('Yeniden Dene'),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
    );
  }
}
