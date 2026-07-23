import 'dart:ui';

import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/error_message_helper.dart';
import '../logic/auth_controller.dart';
import 'email_auth_dialog.dart';

/// Shows account management bottom sheet
void showAccountSheet(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.5),
    builder: (context) => const AccountSheet(),
  );
}

class AccountSheet extends ConsumerStatefulWidget {
  const AccountSheet({super.key});

  @override
  ConsumerState<AccountSheet> createState() => _AccountSheetState();
}

class _AccountSheetState extends ConsumerState<AccountSheet> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final authController = ref.read(authControllerProvider.notifier);

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.surfaceDark.withValues(alpha: 0.95),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
            border: Border(
              top: BorderSide(
                color: Colors.white.withValues(alpha: 0.15),
                width: 1,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.6),
                blurRadius: 30,
                offset: const Offset(0, -10),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: authState.when(
              data: (user) {
                if (user == null) {
                  return _buildGuestContent(context, authController);
                }
                if (user.isGuestMode) {
                  return _buildGuestContent(context, authController);
                }
                return _buildLoggedInContent(context, user, authController);
              },
              loading:
                  () => const Padding(
                    padding: EdgeInsets.all(24.0),
                    child: Center(child: CircularProgressIndicator()),
                  ),
              error: (error, stack) => _buildErrorContent(context, error),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGuestContent(
    BuildContext context,
    AuthController authController,
  ) {
    final isIOS =
        !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.iOS ||
            defaultTargetPlatform == TargetPlatform.macOS);

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle bar
            Container(
              width: 48,
              height: 5,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
            ),

            // Title
            Text(
              'Devam Et',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Hesabınızı bağlayarak ilerlemenizi kaydedin',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // Guest continue button
            OutlinedButton.icon(
              onPressed:
                  _isLoading
                      ? null
                      : () {
                        Navigator.of(context).pop();
                      },
              icon: const Icon(Icons.person_outline),
              label: const Text('Misafir olarak devam et'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textSecondary,
                side: BorderSide(color: AppColors.surfaceLight),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Google Sign In
            FilledButton.icon(
              onPressed:
                  _isLoading
                      ? null
                      : () => _handleGoogleSignIn(context, authController),
              icon: const Icon(Icons.g_mobiledata, size: 28),
              label: const Text('Google ile giriş yap'),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black87,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Apple Sign In (iOS/macOS only)
            if (isIOS)
              FilledButton.icon(
                onPressed:
                    _isLoading
                        ? null
                        : () => _handleAppleSignIn(context, authController),
                icon: const Icon(Icons.apple, size: 28),
                label: const Text('Apple ile giriş yap'),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            if (isIOS) const SizedBox(height: 12),

            // Email Sign In
            OutlinedButton.icon(
              onPressed:
                  _isLoading
                      ? null
                      : () {
                        Navigator.of(context).pop();
                        showEmailAuthDialog(context);
                      },
              icon: const Icon(Icons.email_outlined),
              label: const Text('E-posta ile kayıt/giriş'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: BorderSide(color: AppColors.primary),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoggedInContent(
    BuildContext context,
    user,
    AuthController authController,
  ) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle bar
            Container(
              width: 48,
              height: 5,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
            ),

            // User info
            Row(
              children: [
                // Avatar
                CircleAvatar(
                  radius: 32,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                  backgroundImage:
                      user.photoUrl != null
                          ? NetworkImage(user.photoUrl!)
                          : null,
                  child:
                      user.photoUrl == null
                          ? Text(
                            (user.displayName?.isNotEmpty == true
                                    ? user.displayName![0]
                                    : user.email?.isNotEmpty == true
                                    ? user.email![0]
                                    : '?')
                                .toUpperCase(),
                            style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                          : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.displayName ?? user.email ?? 'Kullanıcı',
                        style: Theme.of(
                          context,
                        ).textTheme.titleMedium?.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (user.email != null && user.displayName != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          user.email!,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: AppColors.textSecondary),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // UID (for debugging, small font)
            Text(
              'UID: ${user.uid}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textTertiary,
                fontSize: 10,
              ),
            ),
            const SizedBox(height: 32),

            // Profile & Settings button
            FilledButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                context.go('/profile');
              },
              icon: const Icon(Icons.settings_outlined),
              label: const Text('Profili & Ayarları Aç'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Sign out button
            OutlinedButton.icon(
              onPressed:
                  _isLoading
                      ? null
                      : () => _handleSignOut(context, authController),
              icon: const Icon(Icons.logout),
              label: const Text('Çıkış yap'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: BorderSide(color: AppColors.error),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorContent(BuildContext context, Object error) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, color: AppColors.error, size: 48),
          const SizedBox(height: 16),
          Text(
            'Bir hata oluştu',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: AppColors.textPrimary),
          ),
          const SizedBox(height: 8),
          Text(
            ErrorMessageHelper.getErrorMessage(error),
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Kapat'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleGoogleSignIn(
    BuildContext context,
    AuthController authController,
  ) async {
    if (!mounted) return;
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    
    setState(() => _isLoading = true);
    try {
      await authController.signInWithGoogle();
      if (!mounted) return;
      navigator.pop();
      HapticFeedback.lightImpact();
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Google ile giriş başarılı'),
          backgroundColor: AppColors.success,
        ),
      );
    } on AppException catch (e) {
      if (!mounted) return;
      if (e.message.contains('iptal') || e.message.contains('cancel')) {
        // User cancelled popup, silently return
        return;
      }
      messenger.showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: AppColors.error),
      );
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString();
      if (msg.contains('iptal') || msg.contains('cancel')) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text('Giriş başarısız: $msg'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleAppleSignIn(
    BuildContext context,
    AuthController authController,
  ) async {
    if (!mounted) return;
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    
    setState(() => _isLoading = true);
    try {
      await authController.signInWithApple();
      if (!mounted) return;
      navigator.pop();
      HapticFeedback.lightImpact();
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Apple ile giriş başarılı'),
          backgroundColor: AppColors.success,
        ),
      );
    } on AppException catch (e) {
      if (!mounted) return;
      if (e.message.contains('iptal') || e.message.contains('cancel')) return;
      messenger.showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: AppColors.error),
      );
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString();
      if (msg.contains('iptal') || msg.contains('cancel')) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text('Giriş başarısız: $msg'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleSignOut(
    BuildContext context,
    AuthController authController,
  ) async {
    if (!mounted) return;
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    
    setState(() => _isLoading = true);
    try {
      await authController.signOut();
      if (!mounted) return;
      navigator.pop();
      HapticFeedback.lightImpact();
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Çıkış yapıldı'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text('Çıkış başarısız: ${e.toString()}'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
