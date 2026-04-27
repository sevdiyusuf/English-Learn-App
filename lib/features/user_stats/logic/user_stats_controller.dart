import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/repositories/user_stats_repo.dart';
import '../../auth/logic/auth_controller.dart';
import '../../auth/models/app_user.dart';
import '../../profile_settings/logic/user_settings_controller.dart';
import '../../profile_settings/models/user_settings.dart';
import '../models/user_stats.dart';

/// Controller for managing user statistics
class UserStatsController extends AutoDisposeAsyncNotifier<UserStats> {
  StreamSubscription<UserStats>? _statsSubscription;

  @override
  Future<UserStats> build() async {
    final authState = ref.watch(authControllerProvider);
    final repo = ref.watch(userStatsRepoProvider);

    return authState.when(
      data: (user) async {
        if (user == null) {
          return const UserStats();
        }
        // Load initial stats
        final initialStats = await repo.getUserStats(user);

        // Subscribe to stats stream for updates
        _statsSubscription?.cancel();
        _statsSubscription = repo
            .watchUserStats(user)
            .listen(
              (stats) {
                // Update hardestWords from trap_words subcollection asynchronously
                _updateHardestWords(user, stats, repo);
                state = AsyncValue.data(stats);
              },
              onError: (error, stackTrace) {
                state = AsyncValue.error(error, stackTrace);
              },
            );

        // Clean up subscription on dispose
        ref.onDispose(() {
          _statsSubscription?.cancel();
        });

        return initialStats;
      },
      loading: () => const UserStats(),
      error: (_, __) => const UserStats(),
    );
  }

  /// Get today's goal progress percentage
  double getTodayGoalProgressPercent() {
    final stats = state.valueOrNull;
    final settingsAsync = ref.read(userSettingsControllerProvider);
    final settings = settingsAsync.valueOrNull ?? const UserSettings();

    if (stats == null) return 0.0;

    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);

    final todayActivity = stats.last30Days.firstWhere((day) {
      final dayDate = DateTime(day.date.year, day.date.month, day.date.day);
      return dayDate == todayDate;
    }, orElse: () => DailyActivityPoint(date: todayDate));

    if (settings.dailyGoalType == 'words') {
      if (settings.dailyGoalValue == 0) return 0.0;
      return (todayActivity.practicedWords / settings.dailyGoalValue).clamp(
        0.0,
        1.0,
      );
    } else {
      // minutes
      if (settings.dailyGoalValue == 0) return 0.0;
      return (todayActivity.minutes / settings.dailyGoalValue).clamp(0.0, 1.0);
    }
  }

  /// Get mode stats for a specific mode
  ModeStats? getModeStats(String modeId) {
    final stats = state.valueOrNull;
    return stats?.modeStats[modeId];
  }

  /// Get accuracy percentage for a mode
  double? getModeAccuracy(String modeId) {
    final modeStats = getModeStats(modeId);
    if (modeStats == null || modeStats.totalQuestions == 0) {
      return null;
    }
    return (modeStats.correctAnswers / modeStats.totalQuestions) * 100;
  }

  /// Update hardestWords from trap_words subcollection
  void _updateHardestWords(AppUser user, UserStats stats, UserStatsRepo repo) {
    // Update hardestWords asynchronously without blocking
    repo
        .getHardestWords(user, limit: 10)
        .then((hardestWordsData) {
          final hardestWordsList =
              hardestWordsData
                  .map((w) => w['word'] as String)
                  .whereType<String>()
                  .toList();
          final updatedStats = stats.copyWith(hardestWords: hardestWordsList);
          // Update state if controller is still active
          // Note: AutoDisposeAsyncNotifier doesn't have isDisposed, but state updates are safe
          state = AsyncValue.data(updatedStats);
        })
        .catchError((e) {
          // If fetching fails, keep current stats
          // Error is silently handled
        });
  }
}

final userStatsControllerProvider =
    AutoDisposeAsyncNotifierProvider<UserStatsController, UserStats>(
      UserStatsController.new,
    );
