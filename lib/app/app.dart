import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/widgets/app_startup_gate.dart';
import '../core/widgets/gradient_background.dart';
import '../core/widgets/network_status_indicator.dart';
import '../core/widgets/notification_banner.dart';
import '../features/auth/logic/auth_controller.dart';
import 'router.dart';
import 'theme.dart';

class VeniVidiApp extends ConsumerWidget {
  const VeniVidiApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final theme = ref.watch(appThemeProvider);
    final darkTheme = ref.watch(appDarkThemeProvider);

    // Watch auth controller - AppStartupGate will handle loading/error states
    ref.watch(authControllerProvider);

    return MaterialApp.router(
      title: 'VeniVidi Word Battle',
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      theme: theme,
      darkTheme: darkTheme,
      themeMode: ThemeMode.dark, // Always use dark theme
      builder: (context, child) {
        return AppStartupGate(
          child: GradientBackground(
            child: Stack(
              children: [
                Column(
                  children: [
                    const NetworkStatusIndicator(),
                    Expanded(
                      child: child ?? const SizedBox.shrink(),
                    ),
                  ],
                ),
                const NotificationToast(),
              ],
            ),
          ),
        );
      },
    );
  }
}
