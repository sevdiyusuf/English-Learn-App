import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../profile_settings/logic/user_settings_controller.dart';
import '../../profile_settings/models/user_settings.dart';
import '../logic/user_stats_controller.dart';
import '../models/user_stats.dart';

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

class UserStatsPage extends ConsumerStatefulWidget {
  const UserStatsPage({super.key});

  @override
  ConsumerState<UserStatsPage> createState() => _UserStatsPageState();
}

class _UserStatsPageState extends ConsumerState<UserStatsPage> {
  @override
  Widget build(BuildContext context) {
    final statsAsync = ref.watch(userStatsControllerProvider);
    final settingsAsync = ref.watch(userSettingsControllerProvider);
    final statsController = ref.read(userStatsControllerProvider.notifier);

    return Scaffold(
      backgroundColor: _backgroundColor,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'İstatistik',
          style: TextStyle(
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
            child: statsAsync.when(
              data: (stats) {
                final settings = settingsAsync.valueOrNull ?? const UserSettings();
                return _buildContent(context, stats, settings, statsController);
              },
              loading: () => const Center(child: CircularProgressIndicator(color: _accentColor)),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 48,
                      color: AppColors.error,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'İstatistikler yüklenemedi',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(color: _primaryTextColor),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => ref.invalidate(userStatsControllerProvider),
                      child: const Text('Yeniden Dene', style: TextStyle(color: _accentColor)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    UserStats stats,
    UserSettings settings,
    UserStatsController controller,
  ) {
    // Check if stats are empty (new user)
    final isEmpty = stats.totalSessions == 0 &&
        stats.totalLearnedWords == 0 &&
        stats.currentStreakDays == 0;

    if (isEmpty) {
      return _buildEmptyState(context);
    }

    final todayProgress = controller.getTodayGoalProgressPercent();

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildSectionHeader(context, 'GENEL BAKIŞ'),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                context,
                'Öğrenilen',
                '${stats.totalLearnedWords}',
                Icons.book_outlined,
                AppColors.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                context,
                'Oturum',
                '${stats.totalSessions}',
                Icons.play_circle_outline,
                AppColors.accent,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                context,
                'Puan',
                '${stats.totalScore}',
                Icons.stars_outlined,
                AppColors.warning,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                context,
                'Seri',
                '${stats.currentStreakDays} gün',
                Icons.local_fire_department_outlined,
                Colors.orangeAccent,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                context,
                'En İyi Seri',
                '${stats.bestStreakDays} gün',
                Icons.emoji_events_outlined,
                AppColors.success,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: SizedBox(), // Boş kart (dengeli görünüm için)
            ),
          ],
        ),
        const SizedBox(height: 24),

        _buildSectionHeader(context, 'BUGÜNKÜ İLERLEME'),
        Container(
          padding: const EdgeInsets.all(20),
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Günlük Hedef',
                    style: TextStyle(color: _primaryTextColor, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  Text(
                    '${(todayProgress * 100).toInt()}%',
                    style: const TextStyle(
                      color: _accentColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: todayProgress,
                  backgroundColor: const Color(0xFF1C1C1E),
                  valueColor: const AlwaysStoppedAnimation<Color>(_accentColor),
                  minHeight: 8,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                settings.dailyGoalType == 'words'
                    ? '${_getTodayWords(stats)} / ${settings.dailyGoalValue} kelime'
                    : '${_getTodayMinutes(stats)} / ${settings.dailyGoalValue} dakika',
                style: const TextStyle(
                  color: _secondaryTextColor,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        _buildSectionHeader(context, 'SON 7 GÜN'),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: _stoneGradient,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: _borderSideColor, width: 1),
          ),
          child: _buildActivityChart(context, stats),
        ),
        const SizedBox(height: 24),

        _buildSectionHeader(context, 'MOD İSTATİSTİKLERİ'),
        ..._buildModeStats(context, stats, controller),
        const SizedBox(height: 24),

        _buildSectionHeader(context, 'ZOR KELİMELER'),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: _stoneGradient,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: _borderSideColor, width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (stats.hardestWords.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Henüz zor kelime yok. Devam edin!',
                    style: TextStyle(
                      color: _secondaryTextColor,
                    ),
                  ),
                )
              else
                ...stats.hardestWords.take(10).map(
                      (word) => ListTile(
                        dense: true,
                        leading: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppColors.warning.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.warning_amber_rounded,
                            color: AppColors.warning,
                            size: 20,
                          ),
                        ),
                        title: Text(word, style: const TextStyle(color: _primaryTextColor)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                    ),
            ],
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.analytics_outlined,
              size: 80,
              color: _secondaryTextColor.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 24),
            const Text(
              'Henüz İstatistik Yok',
              style: TextStyle(color: _primaryTextColor, fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            const Text(
              'İlk oturumunu oynayarak istatistiklerini oluştur!',
              style: TextStyle(color: _secondaryTextColor, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: () => context.go('/mode-select'),
              style: FilledButton.styleFrom(
                backgroundColor: _accentColor,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              icon: const Icon(Icons.play_arrow, color: Colors.black),
              label: const Text('Oyunlara Git', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: _stoneGradient,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _borderSideColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: const TextStyle(
              color: _primaryTextColor,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: _secondaryTextColor,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 0, 16),
      child: Text(
        title,
        style: const TextStyle(
          color: _secondaryTextColor,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _buildActivityChart(BuildContext context, UserStats stats) {
    final last7Days = stats.last30Days.take(7).toList();
    if (last7Days.isEmpty) {
      return const Text(
        'Henüz aktivite yok',
        style: TextStyle(color: _secondaryTextColor),
      );
    }

    final maxMinutes = last7Days
        .map((day) => day.minutes)
        .reduce((a, b) => a > b ? a : b);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: last7Days.reversed.map((day) {
        final height = maxMinutes > 0 ? (day.minutes / maxMinutes) : 0.0;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: 100,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1C1C1E),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      height: 100 * height,
                      decoration: BoxDecoration(
                        color: _accentColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${day.date.day}/${day.date.month}',
                  style: const TextStyle(
                    color: _secondaryTextColor,
                    fontSize: 10,
                  ),
                ),
                Text(
                  '${day.minutes}dk',
                  style: const TextStyle(
                    color: _secondaryTextColor,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  List<Widget> _buildModeStats(
    BuildContext context,
    UserStats stats,
    UserStatsController controller,
  ) {
    final modeNames = {
      'word_match': 'Word Match',
      'flash_opposites': 'Flash Opposites',
      'flash_synonym': 'Flash Synonym',
      'cargo_categories': 'Cargo Categories',
      'word_echo_classic': 'Word Echo (Classic)',
      'word_echo_grid': 'Word Echo (Grid)',
      'multiplayer': 'Multiplayer',
    };

    final widgets = <Widget>[];

    for (final entry in stats.modeStats.entries) {
      final modeId = entry.key;
      final modeStats = entry.value;
      final accuracy = controller.getModeAccuracy(modeId);

      if (modeStats.sessions == 0) continue;

      widgets.add(
        Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            gradient: _stoneGradient,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _borderSideColor, width: 1),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            title: Text(modeNames[modeId] ?? modeId, style: const TextStyle(color: _primaryTextColor, fontWeight: FontWeight.bold)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                if (accuracy != null) Text('Doğruluk: %${accuracy.toInt()}', style: const TextStyle(color: _secondaryTextColor, fontSize: 12)),
                Text('Süre: ${modeStats.totalMinutes} dk', style: const TextStyle(color: _secondaryTextColor, fontSize: 12)),
                Text('Oturum: ${modeStats.sessions}', style: const TextStyle(color: _secondaryTextColor, fontSize: 12)),
              ],
            ),
            trailing: accuracy != null
                ? SizedBox(
                    width: 46,
                    height: 46,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CircularProgressIndicator(
                          value: accuracy / 100,
                          backgroundColor: const Color(0xFF1C1C1E),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            accuracy >= 70
                                ? AppColors.success
                                : accuracy >= 50
                                    ? AppColors.warning
                                    : AppColors.error,
                          ),
                          strokeWidth: 4,
                        ),
                        Text(
                          '${accuracy.toInt()}',
                          style: const TextStyle(color: _primaryTextColor, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  )
                : null,
          ),
        ),
      );
    }

    if (widgets.isEmpty) {
      widgets.add(
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: _stoneGradient,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _borderSideColor, width: 1),
          ),
          child: const Text(
            'Henüz mod istatistiği yok',
            style: TextStyle(color: _secondaryTextColor),
          ),
        ),
      );
    }

    return widgets;
  }

  int _getTodayWords(UserStats stats) {
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);

    final todayActivity = stats.last30Days.firstWhere((day) {
      final dayDate = DateTime(day.date.year, day.date.month, day.date.day);
      return dayDate == todayDate;
    }, orElse: () => DailyActivityPoint(date: todayDate));

    return todayActivity.practicedWords;
  }

  int _getTodayMinutes(UserStats stats) {
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);

    final todayActivity = stats.last30Days.firstWhere((day) {
      final dayDate = DateTime(day.date.year, day.date.month, day.date.day);
      return dayDate == todayDate;
    }, orElse: () => DailyActivityPoint(date: todayDate));

    return todayActivity.minutes;
  }
}
