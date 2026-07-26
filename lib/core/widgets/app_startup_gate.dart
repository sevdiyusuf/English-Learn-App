import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/logic/auth_controller.dart';
import '../errors/firebase_error_mapper.dart';
import 'error_view.dart';

class AppStartupGate extends ConsumerWidget {
  const AppStartupGate({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);

    return authState.when(
      data: (_) => child,
      loading:
          () => const Scaffold(
            backgroundColor: Color(0xFF050505),
            body: ErrorView.loading(message: 'Uygulama başlatılıyor...'),
          ),
      error: (error, stack) {
        final failure = FirebaseErrorMapper.map(error);
        return Scaffold(
          backgroundColor: const Color(0xFF050505),
          body: ErrorView(
            failure: failure,
            title: 'Başlatma Sırasında Hata Oluştu',
            onRetry: () => ref.invalidate(authControllerProvider),
            retryButtonText: 'Yeniden Başlat',
          ),
        );
      },
    );
  }
}
