import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:yunoo/l10n/app_localizations.dart';

import '../../../core/repositories/user_stats_repo.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/feedback_bottom_sheet.dart';
import '../../auth/data/auth_repo.dart';
import '../../auth/logic/auth_controller.dart';
import '../../auth/models/app_user.dart';
import '../../auth/ui/account_sheet.dart';
import '../../friends/logic/friends_controller.dart';
import '../../friends/models/friend_models.dart';
import '../logic/user_settings_controller.dart';
import '../models/user_settings.dart';

// Ana Sayfa Tema Sabitleri
const _backgroundColor = Color(0xFF050505);
const _accentColor = Color(0xFF2997FF);
const _stoneGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [
    Color(0xFF2C2C2E),
    Color(0xFF1C1C1E),
  ],
);
final _borderSideColor = Colors.white.withValues(alpha: 0.08);
const _primaryTextColor = Colors.white;
const _secondaryTextColor = Color(0xFF98989F);

class ProfileSettingsPage extends ConsumerStatefulWidget {
  const ProfileSettingsPage({super.key});

  @override
  ConsumerState<ProfileSettingsPage> createState() =>
      _ProfileSettingsPageState();
}

class _ProfileSettingsPageState extends ConsumerState<ProfileSettingsPage> {
  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final friendsState = ref.watch(friendsControllerProvider);
    final settingsAsync = ref.watch(userSettingsControllerProvider);
    final settingsController = ref.read(
      userSettingsControllerProvider.notifier,
    );
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: _backgroundColor,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          l10n.profileAndSettings,
          style: const TextStyle(
            color: _primaryTextColor,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        automaticallyImplyLeading: false,
      ),
      body: Stack(
        children: [
          // Arka plan blur (Ana Sayfa stili)
          Positioned(
            top: -100,
            right: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _accentColor.withValues(alpha: 0.05),
                boxShadow: [
                  BoxShadow(
                    color: _accentColor.withValues(alpha: 0.05),
                    blurRadius: 100,
                  ),
                ],
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
                child: Container(),
              ),
            ),
          ),
          SafeArea(
            child: settingsAsync.when(
              data: (settings) => _buildContent(
                context,
                authState.valueOrNull,
                friendsState.profile,
                settings,
                settingsController,
              ),
              loading: () => const Center(child: CircularProgressIndicator(color: _accentColor)),
              error: (error, stack) {
                return _buildContent(
                  context,
                  authState.valueOrNull,
                  friendsState.profile,
                  UserSettings(),
                  ref.read(userSettingsControllerProvider.notifier),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    AppUser? user,
    UserProfile? profile,
    UserSettings settings,
    UserSettingsController controller,
  ) {
    final l10n = AppLocalizations.of(context)!;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Profile Header
        _buildProfileHeader(context, user, profile),
        const SizedBox(height: 24),

        // Appearance Section
        _buildSectionHeader(context, l10n.appearance),
        _buildEliteCard(
          child: Column(
            children: [
              _buildThemeSelector(context, settings, controller),
              const Divider(),
              _buildLanguageSelector(context, settings, controller),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Feedback Section
        _buildSectionHeader(context, l10n.soundAndVibration),
        _buildEliteCard(
          child: Column(
            children: [
              SwitchListTile(
                title: Text(l10n.sound),
                subtitle: Text(l10n.soundSubtitle),
                value: settings.soundEnabled,
                onChanged: (value) async {
                  if (!mounted) return;
                  final messenger = ScaffoldMessenger.of(context);
                  HapticFeedback.lightImpact();
                  try {
                    await controller.updateSound(value);
                  } catch (e) {
                    if (!mounted) return;
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text(l10n.errorOccurred(e.toString())),
                        backgroundColor: AppColors.error,
                      ),
                    );
                  }
                },
              ),
              const Divider(),
              SwitchListTile(
                title: Text(l10n.vibration),
                subtitle: Text(l10n.vibrationSubtitle),
                value: settings.vibrationEnabled,
                onChanged: (value) async {
                  if (!mounted) return;
                  final messenger = ScaffoldMessenger.of(context);
                  HapticFeedback.lightImpact();
                  try {
                    await controller.updateVibration(value);
                  } catch (e) {
                    if (!mounted) return;
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text(l10n.errorOccurred(e.toString())),
                        backgroundColor: AppColors.error,
                      ),
                    );
                  }
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Daily Goal Section
        _buildSectionHeader(context, l10n.dailyGoal),
        _buildEliteCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  l10n.goalType,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SegmentedButton<String>(
                  segments: [
                    ButtonSegment(
                      value: 'words',
                      label: Text(
                        l10n.words.isEmpty
                            ? ''
                            : '${l10n.words[0].toUpperCase()}${l10n.words.substring(1)}',
                      ),
                    ),
                    ButtonSegment(value: 'minutes', label: Text(l10n.duration)),
                  ],
                  selected: {settings.dailyGoalType},
                  onSelectionChanged: (Set<String> selected) async {
                    if (!mounted) return;
                    final messenger = ScaffoldMessenger.of(context);
                    HapticFeedback.lightImpact();
                    try {
                      final type = selected.first;
                      await controller.updateDailyGoal(
                        type: type,
                        value: settings.dailyGoalValue,
                      );
                    } catch (e) {
                      if (!mounted) return;
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text(l10n.errorOccurred(e.toString())),
                          backgroundColor: AppColors.error,
                        ),
                      );
                    }
                  },
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  settings.dailyGoalType == 'words'
                      ? l10n.wordCount
                      : l10n.minutes,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Wrap(
                  spacing: 8,
                  children:
                      (settings.dailyGoalType == 'words'
                              ? [5, 10, 15, 20]
                              : [5, 10, 15])
                          .map((value) {
                            final isSelected = settings.dailyGoalValue == value;
                            return FilterChip(
                              label: Text(
                                settings.dailyGoalType == 'words'
                                    ? '$value ${l10n.words}'
                                    : '$value ${l10n.min}',
                              ),
                              selected: isSelected,
                              onSelected: (selected) async {
                                if (!selected || !mounted) return;
                                final messenger = ScaffoldMessenger.of(context);
                                HapticFeedback.lightImpact();
                                try {
                                  await controller.updateDailyGoal(
                                    type: settings.dailyGoalType,
                                    value: value,
                                  );
                                } catch (e) {
                                  if (!mounted) return;
                                  messenger.showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        l10n.errorOccurred(e.toString()),
                                      ),
                                      backgroundColor: AppColors.error,
                                    ),
                                  );
                                }
                              },
                            );
                          })
                          .toList(),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Text(
                  l10n.dailyGoalDescription,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Seri Hedefi',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Wrap(
                  spacing: 8,
                  children: [3, 10, 20, 30, 50].map((value) {
                    final isSelected = settings.streakGoal == value;
                    return FilterChip(
                      label: Text('$value Gün'),
                      selected: isSelected,
                      onSelected: (selected) async {
                        if (!selected || !mounted) return;
                        final messenger = ScaffoldMessenger.of(context);
                        HapticFeedback.lightImpact();
                        try {
                          await controller.updateStreakGoal(value);
                        } catch (e) {
                          if (!mounted) return;
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text(l10n.errorOccurred(e.toString())),
                              backgroundColor: AppColors.error,
                            ),
                          );
                        }
                      },
                    );
                  }).toList(),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                child: Text(
                  'Seri hedefiniz ana ekrandaki bar üzerinde gösterilir.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Notifications Section
        _buildSectionHeader(context, l10n.notifications),
        _buildEliteCard(
          child: Column(
            children: [
              SwitchListTile(
                title: Text(l10n.dailyReminder),
                subtitle: Text(l10n.dailyReminderSubtitle),
                value: settings.remindersEnabled,
                onChanged: (value) async {
                  if (!mounted) return;
                  final messenger = ScaffoldMessenger.of(context);
                  HapticFeedback.lightImpact();
                  try {
                    await controller.updateReminder(
                      enabled: value,
                      time: value ? (settings.reminderTime ?? '21:00') : null,
                    );
                  } catch (e) {
                    if (!mounted) return;
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text(l10n.errorOccurred(e.toString())),
                        backgroundColor: AppColors.error,
                      ),
                    );
                  }
                },
              ),
              if (settings.remindersEnabled) ...[
                const Divider(),
                ListTile(
                  title: Text(l10n.reminderTime),
                  subtitle: Text(
                    settings.reminderTime ?? '21:00',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  trailing: const Icon(Icons.access_time),
                  onTap: () => _showTimePicker(context, settings, controller),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Statistics Section
        _buildSectionHeader(context, l10n.statistics),
        _buildEliteCard(
          child: ListTile(
            title: Text(l10n.progressAndStats),
            subtitle: Text(l10n.progressAndStatsSubtitle),
            leading: const Icon(
              Icons.analytics_outlined,
              color: AppColors.primary,
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.go('/stats'),
          ),
        ),
        const SizedBox(height: 16),

        // Data & Privacy Section
        _buildSectionHeader(context, l10n.dataAndPrivacy),
        _buildEliteCard(
          child: Column(
            children: [
              ListTile(
                title: Text(l10n.resetProgress),
                subtitle: Text(l10n.resetProgressSubtitle),
                leading: const Icon(Icons.refresh, color: AppColors.warning),
                onTap: () => _showResetProgressDialog(context, controller),
              ),
              if (user != null && !user.isGuestMode) ...[
                const Divider(),
                ListTile(
                  title: Text(l10n.deleteAccount),
                  subtitle: Text(l10n.deleteAccountSubtitle),
                  leading: const Icon(
                    Icons.delete_forever,
                    color: AppColors.error,
                  ),
                  onTap: () => _showDeleteAccountDialog(context),
                ),
              ],
              const Divider(),
              ListTile(
                title: Text(l10n.privacyPolicy),
                subtitle: Text(l10n.privacyPolicySubtitle),
                leading: const Icon(Icons.privacy_tip),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  // TODO: Open privacy policy URL
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.privacyPolicyComingSoon)),
                  );
                },
              ),
            ],
          ),
        ),
        // Feedback / Destek
        const SizedBox(height: 16),
        _buildSectionHeader(context, 'DESTEK'),
        _buildEliteCard(
          child: ListTile(
            title: const Text('Geri Bildirim Gönder'),
            subtitle: const Text('Hata bildirimi veya öneride bulunun'),
            leading: const Icon(Icons.feedback_outlined, color: _accentColor),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              FeedbackBottomSheet.show(context, pageName: 'Profil Sayfası');
            },
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildProfileHeader(
    BuildContext context,
    AppUser? user,
    UserProfile? profile,
  ) {
    final l10n = AppLocalizations.of(context)!;

    return _buildEliteCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 32,
              backgroundColor: AppColors.primary.withValues(alpha: 0.2),
              backgroundImage:
                  user?.photoUrl != null ? NetworkImage(user!.photoUrl!) : null,
              child:
                  user?.photoUrl == null
                      ? Text(
                        (user?.displayName?.isNotEmpty == true
                                ? user!.displayName![0]
                                : user?.email?.isNotEmpty == true
                                ? user!.email![0]
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
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          user?.isGuestMode == true
                              ? l10n.guestUser
                              : (user?.displayName ?? user?.email ?? l10n.user),
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      if (user != null && !user.isGuestMode)
                        IconButton(
                          icon: const Icon(
                            Icons.edit,
                            size: 18,
                            color: AppColors.primary,
                          ),
                          onPressed:
                              () => _showEditNameDialog(
                                context,
                                user.displayName,
                              ),
                          padding: const EdgeInsets.only(left: 8),
                          constraints: const BoxConstraints(),
                          visualDensity: VisualDensity.compact,
                        ),
                    ],
                  ),
                  if (user?.email != null && user?.displayName != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      user!.email!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                  if (profile?.userCode != null) ...[
                    const SizedBox(height: 4),
                    SelectableText(
                      l10n.userCode(profile!.userCode!),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                  if (user?.isGuestMode == true) ...[
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: () {
                        showAccountSheet(context);
                      },
                      icon: const Icon(Icons.link, size: 16),
                      label: Text(l10n.linkAccount),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showEditNameDialog(
    BuildContext context,
    String? currentName,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController(text: currentName);
    return showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(l10n.changeName),
            content: TextField(
              controller: controller,
              decoration: InputDecoration(
                labelText: l10n.displayName,
                hintText: l10n.enterName,
              ),
              textCapitalization: TextCapitalization.words,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(l10n.cancel),
              ),
              FilledButton(
                onPressed: () async {
                  final newName = controller.text.trim();
                  if (newName.isEmpty) return;

                  Navigator.pop(context);
                  try {
                    await ref
                        .read(authControllerProvider.notifier)
                        .updateDisplayName(newName);
                    if (context.mounted) {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text(l10n.nameUpdated)));
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(l10n.errorOccurred(e.toString())),
                          backgroundColor: AppColors.error,
                        ),
                      );
                    }
                  }
                },
                child: Text(l10n.save),
              ),
            ],
          ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 0, 16),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          color: _secondaryTextColor,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _buildEliteCard({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        gradient: _stoneGradient,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _borderSideColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Material(
          color: Colors.transparent,
          child: child,
        ),
      ),
    );
  }

  Widget _buildThemeSelector(
    BuildContext context,
    settings,
    UserSettingsController controller,
  ) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.theme, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          SegmentedButton<String>(
            segments: [
              ButtonSegment(value: 'system', label: Text(l10n.system)),
              ButtonSegment(value: 'dark', label: Text(l10n.dark)),
              ButtonSegment(value: 'light', label: Text(l10n.light)),
            ],
            selected: {settings.themeMode},
            onSelectionChanged: (Set<String> selected) async {
              if (!mounted) return;
              final messenger = ScaffoldMessenger.of(context);
              HapticFeedback.lightImpact();
              try {
                await controller.updateTheme(selected.first);
              } catch (e) {
                if (!mounted) return;
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(l10n.errorOccurred(e.toString())),
                    backgroundColor: AppColors.error,
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageSelector(
    BuildContext context,
    settings,
    UserSettingsController controller,
  ) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.appLanguage, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'tr', label: Text('TR')),
              ButtonSegment(value: 'en', label: Text('EN')),
            ],
            selected: {settings.languageCode},
            onSelectionChanged: (Set<String> selected) async {
              if (!mounted) return;
              final messenger = ScaffoldMessenger.of(context);
              HapticFeedback.lightImpact();
              try {
                await controller.updateLanguage(selected.first);
              } catch (e) {
                if (!mounted) return;
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(l10n.errorOccurred(e.toString())),
                    backgroundColor: AppColors.error,
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Future<void> _showTimePicker(
    BuildContext context,
    settings,
    UserSettingsController controller,
  ) async {
    final currentTime = settings.reminderTime ?? '21:00';
    final parts = currentTime.split(':');
    final initialTime = TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );

    final picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );

    if (picked != null) {
      final timeString =
          '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      controller.updateReminder(enabled: true, time: timeString);
    }
  }

  Future<void> _showResetProgressDialog(
    BuildContext context,
    UserSettingsController controller,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(l10n.resetProgressDialogTitle),
            content: Text(l10n.resetProgressDialogContent),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(l10n.cancel),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: FilledButton.styleFrom(backgroundColor: AppColors.error),
                child: Text(l10n.reset),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      if (!context.mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      try {
        final authState = ref.read(authControllerProvider);
        final user = authState.valueOrNull;
        if (user != null) {
          final statsRepo = ref.read(userStatsRepoProvider);
          await statsRepo.resetAllStats(user);
          if (!mounted) return;
          messenger.showSnackBar(
            SnackBar(
              content: Text(l10n.progressResetSuccess),
              backgroundColor: AppColors.success,
            ),
          );
        } else {
          if (!mounted) return;
          messenger.showSnackBar(
            SnackBar(
              content: Text(l10n.userNotFound),
              backgroundColor: AppColors.error,
            ),
          );
        }
      } catch (e) {
        if (!mounted) return;
        messenger.showSnackBar(
          SnackBar(
            content: Text(l10n.progressResetFailed(e.toString())),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _showDeleteAccountDialog(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(l10n.deleteAccount),
            content: Text(l10n.deleteAccountDialogContent),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(l10n.cancel),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: FilledButton.styleFrom(backgroundColor: AppColors.error),
                child: Text(l10n.delete),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      if (!context.mounted) return;
      // Second confirmation
      final confirmed2 = await showDialog<bool>(
        context: context,
        builder:
            (context) => AlertDialog(
              title: Text(l10n.finalConfirmation),
              content: Text(l10n.deleteAccountFinalConfirmation),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text(l10n.cancel),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.error,
                  ),
                  child: Text(l10n.yesDelete),
                ),
              ],
            ),
      );

      if (confirmed2 == true) {
        if (!context.mounted) return;
        final router = GoRouter.of(context);
        final messenger = ScaffoldMessenger.of(context);
        try {
          final authRepo = ref.read(authRepositoryProvider);
          await authRepo.deleteAccountAndData();
          if (!context.mounted) return;
          router.go('/mode-select');
          messenger.showSnackBar(
            SnackBar(
              content: Text(l10n.accountDeletedSuccess),
              backgroundColor: AppColors.success,
            ),
          );
        } catch (e) {
          if (!context.mounted) return;
          messenger.showSnackBar(
            SnackBar(
              content: Text(l10n.accountDeleteFailed(e.toString())),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }
}
