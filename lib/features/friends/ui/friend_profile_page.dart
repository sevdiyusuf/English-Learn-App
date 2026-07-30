import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/repositories/user_stats_repo.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/gradient_background.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/models/app_user.dart';
import '../../auth/logic/auth_controller.dart';
import '../../moderation/moderation_actions.dart';
import '../../user_stats/models/user_stats.dart';
import '../../word_match/data/word_match_share_repo.dart';
import '../models/friend_models.dart';

final friendStatsProvider = FutureProvider.family<UserStats, UserProfile>((
  ref,
  profile,
) async {
  final statsRepo = ref.watch(userStatsRepoProvider);
  // Create AppUser from UserProfile for stats fetching
  final appUser = AppUser(
    uid: profile.uid,
    displayName: profile.displayName,
    photoUrl: profile.photoUrl,
    isAnonymous: false,
    isGuestMode: false,
  );
  return statsRepo.getUserStats(appUser);
});

final friendSetsProvider = FutureProvider.family<
  List<SharedWordSet>,
  UserProfile
>((ref, profile) async {
  final shareRepo = await ref.watch(wordMatchShareRepositoryProvider.future);
  // Fetch both public and friends-only sets (we are friends)
  return shareRepo.fetchUserSets(targetUid: profile.uid, isFriend: true);
});

class FriendProfilePage extends ConsumerWidget {
  const FriendProfilePage({super.key, required this.profile});

  final UserProfile profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final statsAsync = ref.watch(friendStatsProvider(profile));
    final setsAsync = ref.watch(friendSetsProvider(profile));

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: AppColors.surfaceDark.withValues(alpha: 0.9),
          title: Text(
            profile.displayName ?? 'Arkadaş Profili',
            style: const TextStyle(color: Colors.white),
          ),
          iconTheme: const IconThemeData(color: Colors.white),
          actions: [
            if (ref.watch(authControllerProvider).value?.uid != profile.uid)
              PopupMenuButton<int>(
                icon: const Icon(Icons.more_vert),
                onSelected: (value) async {
                  if (value == 0) {
                    await showReportDialog(
                      context,
                      ref,
                      type: 'user',
                      targetId: profile.uid,
                      title: l10n.reportUser,
                    );
                  } else if (value == 1) {
                    await showBlockDialog(context, ref, profile.uid);
                  } else {
                    await showReportAndBlockDialog(context, ref, profile.uid);
                  }
                },
                itemBuilder:
                    (context) => [
                      PopupMenuItem(value: 0, child: Text(l10n.reportUser)),
                      PopupMenuItem(value: 1, child: Text(l10n.block)),
                      PopupMenuItem(value: 2, child: Text(l10n.reportAndBlock)),
                    ],
              ),
          ],
          bottom: TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: AppColors.primary,
            tabs: const [Tab(text: 'İstatistikler'), Tab(text: 'Setler')],
          ),
        ),
        body: GradientBackground(
          child: SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: TabBarView(
                    children: [
                      _buildStatsTab(ref, statsAsync),
                      _buildSetsTab(ref, setsAsync),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surfaceDark.withValues(alpha: 0.5),
        border: Border(
          bottom: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: AppColors.primary,
            child: Text(
              (profile.displayName ?? 'K').substring(0, 1).toUpperCase(),
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            profile.displayName ?? 'Kullanıcı',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Kod: ${profile.userCode ?? '-'}',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsTab(WidgetRef ref, AsyncValue<UserStats> statsAsync) {
    return statsAsync.when(
      data: (stats) {
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildStatCard(
              'Toplam Öğrenilen Kelime',
              '${stats.totalLearnedWords}',
              Icons.book,
            ),
            const SizedBox(height: 12),
            _buildStatCard(
              'Toplam Seans',
              '${stats.totalSessions}',
              Icons.play_circle_outline,
            ),
            const SizedBox(height: 12),
            _buildStatCard('Toplam Puan', '${stats.totalScore}', Icons.star),
            const SizedBox(height: 12),
            _buildStatCard(
              'Günlük Seri',
              '${stats.currentStreakDays} gün',
              Icons.local_fire_department,
            ),
            const SizedBox(height: 12),
            _buildStatCard(
              'En İyi Seri',
              '${stats.bestStreakDays} gün',
              Icons.emoji_events,
            ),
            if (stats.modeStats.isNotEmpty) ...[
              const SizedBox(height: 24),
              Text(
                'Mod İstatistikleri',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              ...stats.modeStats.entries.map((entry) {
                final modeStats = entry.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceDark.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getModeName(entry.key),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildMiniStat('Seans', '${modeStats.sessions}'),
                            _buildMiniStat(
                              'Doğru',
                              '${modeStats.correctAnswers}',
                            ),
                            _buildMiniStat(
                              'Yanlış',
                              '${modeStats.wrongAnswers}',
                            ),
                            _buildMiniStat(
                              'Dakika',
                              '${modeStats.totalMinutes}',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ],
        );
      },
      loading:
          () => const Center(
            child: CircularProgressIndicator(color: Colors.white),
          ),
      error:
          (e, s) => Center(
            child: Text(
              'İstatistikler yüklenemedi: $e',
              style: const TextStyle(color: Colors.redAccent),
            ),
          ),
    );
  }

  Widget _buildSetsTab(
    WidgetRef ref,
    AsyncValue<List<SharedWordSet>> setsAsync,
  ) {
    return setsAsync.when(
      data: (sets) {
        if (sets.isEmpty) {
          return Center(
            child: Text(
              'Paylaşılan set bulunamadı',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: sets.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final set = sets[index];
            return Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceDark.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: ListTile(
                title: Text(
                  set.setName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  '${set.pairs.length} kelime',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
                ),
                trailing: IconButton(
                  icon: const Icon(
                    Icons.download_rounded,
                    color: AppColors.primary,
                  ),
                  onPressed: () => _copySet(context, ref, set),
                  tooltip: 'Seti Kopyala',
                ),
              ),
            );
          },
        );
      },
      loading:
          () => const Center(
            child: CircularProgressIndicator(color: Colors.white),
          ),
      error:
          (e, s) => Center(
            child: Text(
              'Setler yüklenemedi: $e',
              style: const TextStyle(color: Colors.redAccent),
            ),
          ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppColors.primary, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.6),
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  String _getModeName(String modeId) {
    switch (modeId) {
      case 'word_match':
        return 'Kelime Eşleştirme';
      case 'flash_opposites':
        return 'Zıt Anlamlılar';
      case 'flash_synonym':
        return 'Eş Anlamlılar';
      case 'cargo_categories':
        return 'Kargo Kategorileri';
      case 'word_echo_classic':
        return 'Kelime Yansıması (Klasik)';
      case 'word_echo_grid':
        return 'Kelime Yansıması (Izgara)';
      case 'multiplayer':
        return 'Çok Oyunculu';
      default:
        return modeId;
    }
  }

  Future<void> _copySet(
    BuildContext context,
    WidgetRef ref,
    SharedWordSet set,
  ) async {
    try {
      final shareRepo = await ref.read(wordMatchShareRepositoryProvider.future);
      await shareRepo.importSharedSetToLocal(shared: set);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${set.setName} kütüphanene eklendi!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }
}
