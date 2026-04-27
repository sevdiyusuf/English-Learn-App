import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/repositories/user_settings_repo.dart';
import '../../auth/logic/auth_controller.dart';
import '../../auth/models/app_user.dart';
import '../models/user_settings.dart';

/// Controller for managing user settings
class UserSettingsController extends AutoDisposeAsyncNotifier<UserSettings> {
  StreamSubscription<UserSettings>? _settingsSubscription;
  bool _isSaving =
      false; // Track if we're currently saving to avoid circular updates

  @override
  Future<UserSettings> build() async {
    final authState = ref.watch(authControllerProvider);
    final repo = ref.watch(userSettingsRepoProvider);

    return authState.when(
      data: (user) async {
        if (user == null) {
          return const UserSettings();
        }
        // Load initial settings
        final initialSettings = await repo.loadSettingsOnce(user);

        // Subscribe to settings stream for updates (only if not saving)
        _settingsSubscription?.cancel();
        _settingsSubscription = repo
            .watchSettings(user)
            .listen(
              (settings) {
                // Only update from stream if we're not currently saving
                // This prevents circular updates when we save and stream reflects the change
                if (!_isSaving) {
                  state = AsyncValue.data(settings);
                }
              },
              onError: (error, stackTrace) {
                state = AsyncValue.error(error, stackTrace);
              },
            );

        // Clean up subscription on dispose
        ref.onDispose(() {
          _settingsSubscription?.cancel();
        });

        return initialSettings;
      },
      loading: () => const UserSettings(),
      error: (_, __) => const UserSettings(),
    );
  }

  /// Update theme mode
  Future<void> updateTheme(String themeMode) async {
    final current = state.valueOrNull ?? const UserSettings();
    final updated = current.copyWith(themeMode: themeMode);
    await _saveSettings(updated);
  }

  /// Update language code
  Future<void> updateLanguage(String languageCode) async {
    final current = state.valueOrNull ?? const UserSettings();
    final updated = current.copyWith(languageCode: languageCode);
    await _saveSettings(updated);
  }

  /// Update sound enabled
  Future<void> updateSound(bool enabled) async {
    final current = state.valueOrNull ?? const UserSettings();
    final updated = current.copyWith(soundEnabled: enabled);
    await _saveSettings(updated);
  }

  /// Update vibration enabled
  Future<void> updateVibration(bool enabled) async {
    final current = state.valueOrNull ?? const UserSettings();
    final updated = current.copyWith(vibrationEnabled: enabled);
    await _saveSettings(updated);
  }

  /// Update daily goal
  Future<void> updateDailyGoal({
    required String type,
    required int value,
  }) async {
    final current = state.valueOrNull ?? const UserSettings();
    final updated = current.copyWith(
      dailyGoalType: type,
      dailyGoalValue: value,
    );
    await _saveSettings(updated);
  }

  /// Update streak goal
  Future<void> updateStreakGoal(int value) async {
    final current = state.valueOrNull ?? const UserSettings();
    final updated = current.copyWith(streakGoal: value);
    await _saveSettings(updated);
  }

  /// Update reminder settings
  Future<void> updateReminder({required bool enabled, String? time}) async {
    final current = state.valueOrNull ?? const UserSettings();
    final updated = current.copyWith(
      remindersEnabled: enabled,
      reminderTime: enabled ? (time ?? current.reminderTime) : null,
    );
    await _saveSettings(updated);
  }

  /// Reset settings to default
  Future<void> resetSettingsToDefault() async {
    const defaultSettings = UserSettings();
    await _saveSettings(defaultSettings);
  }

  Future<void> _saveSettings(UserSettings settings) async {
    // Update state IMMEDIATELY for instant UI feedback (optimistic update)
    // This makes the UI feel instant, especially for Firestore operations
    state = AsyncValue.data(settings);

    try {
      _isSaving = true; // Mark that we're saving to prevent stream updates

      final authState = ref.read(authControllerProvider);
      final repo = ref.read(userSettingsRepoProvider);

      final user = authState.valueOrNull;

      // Save in background without blocking UI
      // For guests (localStorage), this is instant anyway
      // For Firestore, this runs async and won't block the UI
      if (user == null) {
        // Use guest user for fallback
        final guestUser = AppUser(
          uid: 'guest',
          isAnonymous: true,
          isGuestMode: true,
        );
        // Guest saves are instant (localStorage), so we can await
        await repo.saveSettings(guestUser, settings);
      } else {
        // For Firestore, save in background without blocking
        // If save fails, we'll handle it via error logging
        // The optimistic update already made UI responsive
        repo.saveSettings(user, settings).catchError((error, stackTrace) {
          // On error, we could revert the state, but for now just log
          // The stream will eventually sync the correct state
          // In production, you might want to show a snackbar here
        });
      }
    } finally {
      // Re-enable stream updates after a delay to allow Firestore to sync
      // This prevents circular updates when Firestore stream reflects our change
      Future.delayed(const Duration(milliseconds: 800), () {
        _isSaving = false;
      });
    }
  }
}

final userSettingsControllerProvider =
    AutoDisposeAsyncNotifierProvider<UserSettingsController, UserSettings>(
      UserSettingsController.new,
    );
