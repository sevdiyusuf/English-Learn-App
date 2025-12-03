import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../data/word_match_providers.dart';
import '../logic/word_match_sets_controller.dart';

class WordMatchHomePage extends ConsumerWidget {
  const WordMatchHomePage({super.key});

  static const routeName = 'wordMatchSets';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final setsState = ref.watch(wordMatchSetsControllerProvider);

    return Scaffold(
      backgroundColor: Colors.transparent, // Arka plan resmi görünsün
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceDark.withValues(alpha: 0.9),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Kelime Setleri',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            shadows: [Shadow(blurRadius: 5, color: Colors.black)],
          ),
        ),
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.5),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => context.go('/mode-select'),
            tooltip: 'Ana sayfaya dön',
          ),
        ),
      ),
      body: Stack(
        children: [
          // Background image
          Positioned.fill(
            child: Image.asset(
              'assets/images/background2.png',
              fit: BoxFit.cover,
            ),
          ),
          // Content
          SafeArea(
            child: Column(
              children: [
                // BİLGİLENDİRME KARTI (Modern)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B).withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.amber.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: SvgPicture.asset(
                            'assets/icons/info.svg',
                            width: 24,
                            height: 24,
                            colorFilter: const ColorFilter.mode(
                              Colors.amber,
                              BlendMode.srcIn,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  SvgPicture.asset(
                                    'assets/icons/star.svg',
                                    width: 14,
                                    height: 14,
                                    colorFilter: const ColorFilter.mode(
                                      Colors.amber,
                                      BlendMode.srcIn,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Öğrendiğim kelimeler',
                                    style: TextStyle(
                                      color: Colors.white.withValues(
                                        alpha: 0.9,
                                      ),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  SvgPicture.asset(
                                    'assets/icons/star_empty.svg',
                                    width: 14,
                                    height: 14,
                                    colorFilter: ColorFilter.mode(
                                      Colors.white.withValues(alpha: 0.5),
                                      BlendMode.srcIn,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Öğrenmekte olduğum kelimeler',
                                    style: TextStyle(
                                      color: Colors.white.withValues(
                                        alpha: 0.7,
                                      ),
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // SET LİSTESİ
                Expanded(
                  child: setsState.when(
                    data:
                        (data) => _SetList(
                          state: data,
                          onCreateSet: () => _onCreateSet(context, ref),
                        ),
                    loading:
                        () => const Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        ),
                    error:
                        (error, stackTrace) => Center(
                          child: Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.error_outline,
                                  color: Colors.redAccent,
                                  size: 48,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Setler yüklenemedi: $error',
                                  style: const TextStyle(color: Colors.white),
                                ),
                                const SizedBox(height: 12),
                                ElevatedButton(
                                  onPressed:
                                      () => ref.refresh(
                                        wordMatchSetsControllerProvider,
                                      ),
                                  child: const Text('Tekrar dene'),
                                ),
                              ],
                            ),
                          ),
                        ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: setsState.maybeWhen(
        data:
            (data) => FloatingActionButton.extended(
              onPressed:
                  data.canCreateMore
                      ? () => _onCreateSet(context, ref)
                      : () => _showLimitDialog(context),
              backgroundColor: AppColors.primary,
              icon: SvgPicture.asset(
                'assets/icons/add.svg',
                width: 24,
                height: 24,
                colorFilter: const ColorFilter.mode(
                  Colors.white,
                  BlendMode.srcIn,
                ),
              ),
              label: const Text(
                'YENİ SET',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
        orElse: () => null,
      ),
    );
  }

  Future<void> _onCreateSet(BuildContext context, WidgetRef ref) async {
    final controller = ref.read(wordMatchSetsControllerProvider.notifier);
    final name = await _promptForName(context);
    if (name == null) {
      return;
    }
    try {
      final id = await controller.createSet(name);
      if (context.mounted) {
        context.go('/word-match/edit/$id');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Set oluşturulamadı: $e')));
      }
    }
  }

  Future<String?> _promptForName(BuildContext context) async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E293B), // Koyu diyalog
          title: const Text('Yeni Set', style: TextStyle(color: Colors.white)),
          content: TextField(
            controller: controller,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Örn. Ünite 5 Fiiller',
              hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
              enabledBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.white54),
              ),
              focusedBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: AppColors.primary),
              ),
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Vazgeç',
                style: TextStyle(color: Colors.white70),
              ),
            ),
            FilledButton(
              onPressed: () {
                final text = controller.text.trim();
                if (text.isEmpty) {
                  return;
                }
                Navigator.pop(context, text);
              },
              style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
              child: const Text('Oluştur'),
            ),
          ],
        );
      },
    );
  }

  void _showLimitDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          title: const Text(
            'Limit dolu',
            style: TextStyle(color: Colors.white),
          ),
          content: const Text(
            'En fazla 50 kelime seti oluşturabilirsiniz.',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Tamam',
                style: TextStyle(color: AppColors.primary),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _SetList extends ConsumerWidget {
  const _SetList({required this.state, required this.onCreateSet});

  final WordMatchSetsState state;
  final VoidCallback onCreateSet;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (state.sets.isEmpty) {
      return _EmptyState(onCreateTap: onCreateSet);
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      physics: const BouncingScrollPhysics(),
      itemCount: state.sets.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final overview = state.sets[index];
        final set = overview.set;
        final isBuiltin = set.isBuiltin;

        // Renk belirleme
        Color stripeColor = const Color(0xFF607D8B); // Varsayılan: Mavi

        if (set.name == 'Words from Games') {
          stripeColor = const Color(0xFFFF9800); // Turuncu (Hex kodu)
        } else if (!isBuiltin) {
          stripeColor = const Color(0xFFD946EF); // Mor (Kullanıcı seti)
        } else {
          stripeColor = const Color(0xFF26A69A); // Turkuaz (Hex kodu)
        }

        final learnedStatusesAsync = ref.watch(
          _learnedStatusesProvider(set.id),
        );
        final learnedStatuses = learnedStatusesAsync.valueOrNull;
        final activeCount =
            learnedStatuses != null
                ? learnedStatuses.values.where((v) => !v).length
                : overview.pairCount;

        return Container(
          decoration: BoxDecoration(
            color: const Color(
              0xFF1E293B,
            ).withValues(alpha: 0.95), // Tok Koyu Zemin
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: stripeColor.withValues(alpha: 0.5), // Hafif renkli çerçeve
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => _showSetActions(context, ref, overview),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // SOL ŞERİT
                  Container(
                    width: 6,
                    decoration: BoxDecoration(color: stripeColor),
                  ),

                  // İÇERİK
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  set.name,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              if (isBuiltin)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.star,
                                        size: 12,
                                        color: stripeColor,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Hazır',
                                        style: TextStyle(
                                          color: Colors.white.withValues(
                                            alpha: 0.8,
                                          ),
                                          fontSize: 10,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // CHIPS (Wrap)
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _CustomChip(
                                label: '${overview.pairCount} Kelime',
                                svgIcon: 'assets/icons/list_alt.svg',
                                color: Colors.blueAccent,
                              ),
                              _CustomChip(
                                label: 'Aktif: $activeCount',
                                icon: Icons.check_circle_outline,
                                color: Colors.greenAccent,
                              ),
                              _CustomChip(
                                label: _formatLastPracticed(
                                  set.lastPracticedAt,
                                ),
                                svgIcon: 'assets/icons/history.svg',
                                color: Colors.orangeAccent,
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),

                          // AKSİYON BUTONLARI (Alt Bar)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              // Detay
                              _ActionButton(
                                label: 'Detay',
                                svgIcon: 'assets/icons/info.svg',
                                color: Colors.white70,
                                onTap:
                                    () => _showSetDetail(
                                      context,
                                      overview.set.id,
                                    ),
                              ),
                              const SizedBox(width: 12),

                              // Düzenle (Varsa)
                              if (!isBuiltin ||
                                  set.name == 'Words from Games') ...[
                                _ActionButton(
                                  label: 'Düzenle',
                                  icon: Icons.edit,
                                  color: Colors.white70,
                                  onTap:
                                      () => _editSetDirect(
                                        context,
                                        overview.set.id,
                                      ),
                                ),
                                const SizedBox(width: 12),
                              ],

                              // Oyna (Vurgulu)
                              Material(
                                color: stripeColor,
                                borderRadius: BorderRadius.circular(20),
                                child: InkWell(
                                  onTap:
                                      () => _startPracticeDirect(
                                        context,
                                        overview,
                                      ),
                                  borderRadius: BorderRadius.circular(20),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    child: Row(
                                      children: const [
                                        Icon(
                                          Icons.play_arrow_rounded,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                        SizedBox(width: 4),
                                        Text(
                                          'BAŞLA',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Henüz yok';
    return '${date.day}.${date.month}.${date.year}';
  }

  String _formatLastPracticed(DateTime? date) {
    if (date == null) return 'Yeni';
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays <= 0) return 'Bugün';
    if (diff.inDays == 1) return 'Dün';
    if (diff.inDays < 7) return '${diff.inDays} gün';
    return _formatDate(date);
  }

  void _startPracticeDirect(BuildContext context, WordSetOverview overview) {
    if (context.mounted) {
      context.push('/word-match/practice/${overview.set.id}');
    }
  }

  void _editSetDirect(BuildContext context, int setId) {
    if (context.mounted) {
      context.push('/word-match/edit/$setId');
    }
  }

  void _showSetDetail(BuildContext context, int setId) {
    if (context.mounted) {
      context.push('/word-match/detail/$setId');
    }
  }

  Future<void> _showSetActions(
    BuildContext context,
    WidgetRef ref,
    WordSetOverview overview,
  ) async {
    final result = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.play_arrow, color: AppColors.success),
                title: const Text(
                  'Eşleştirmeye Başla',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () => Navigator.pop(context, 'practice'),
              ),
              if (!overview.set.isBuiltin ||
                  overview.set.name == 'Words from Games') ...[
                ListTile(
                  leading: const Icon(Icons.edit, color: Colors.white70),
                  title: const Text(
                    'Düzenle',
                    style: TextStyle(color: Colors.white),
                  ),
                  onTap: () => Navigator.pop(context, 'edit'),
                ),
              ],
              if (!overview.set.isBuiltin) ...[
                ListTile(
                  leading: const Icon(
                    Icons.delete_outline,
                    color: Colors.redAccent,
                  ),
                  title: const Text(
                    'Sil',
                    style: TextStyle(color: Colors.redAccent),
                  ),
                  onTap: () => Navigator.pop(context, 'delete'),
                ),
              ],
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );

    // ... (Switch case mantığı aynı kalacak, sadece UI değişti)
    switch (result) {
      case 'practice':
        if (context.mounted) _startPracticeDirect(context, overview);
        return;
      case 'edit':
        if (context.mounted) _editSetDirect(context, overview.set.id);
        return;
      case 'delete':
        if (context.mounted) {
          if (overview.set.isBuiltin) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Yerleşik setler silinemez')),
            );
            return;
          }
          final confirm = await showDialog<bool>(
            context: context,
            builder: (context) {
              return AlertDialog(
                backgroundColor: const Color(0xFF1E293B),
                title: Text(
                  '"${overview.set.name}" silinsin mi?',
                  style: const TextStyle(color: Colors.white),
                ),
                content: const Text(
                  'Bu set ve içindeki kelimeler kalıcı olarak silinecek.',
                  style: TextStyle(color: Colors.white70),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text(
                      'Vazgeç',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                    ),
                    child: const Text('Sil'),
                  ),
                ],
              );
            },
          );
          if (confirm == true) {
            final notifier = ref.read(wordMatchSetsControllerProvider.notifier);
            try {
              await notifier.deleteSet(overview.set.id);
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('Silme hatası: $e')));
              }
            }
          }
        }
        return;
      default:
        return;
    }
  }
}

// --- YENİ KÜÇÜK CHIP WIDGET ---
class _CustomChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final String? svgIcon;
  final Color color;

  const _CustomChip({
    required this.label,
    this.icon,
    this.svgIcon,
    required this.color,
  }) : assert(
         icon != null || svgIcon != null,
         'Either icon or svgIcon must be provided',
       );

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (svgIcon != null)
            SvgPicture.asset(
              svgIcon!,
              width: 12,
              height: 12,
              colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
            )
          else if (icon != null)
            Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// --- AKSİYON BUTONU ---
class _ActionButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final String? svgIcon;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    this.icon,
    this.svgIcon,
    required this.color,
    required this.onTap,
  }) : assert(
         icon != null || svgIcon != null,
         'Either icon or svgIcon must be provided',
       );

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Row(
          children: [
            if (svgIcon != null)
              SvgPicture.asset(
                svgIcon!,
                width: 16,
                height: 16,
                colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
              )
            else if (icon != null)
              Icon(icon, size: 16, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

final _learnedStatusesProvider = FutureProvider.family<Map<int, bool>, int>((
  ref,
  setId,
) async {
  final repo = await ref.watch(wordMatchRepoProvider.future);
  return repo.getLearnedStatuses(setId);
});

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onCreateTap});

  final VoidCallback onCreateTap;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.style_outlined,
              size: 64,
              color: Colors.white54,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Henüz kelime setin yok.',
            style: TextStyle(fontSize: 18, color: Colors.white),
          ),
          const SizedBox(height: 8),
          const Text(
            'Yeni bir set oluşturarak hemen çalışmaya başlayabilirsin.',
            style: TextStyle(color: Colors.white70),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: onCreateTap,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SvgPicture.asset(
                  'assets/icons/add.svg',
                  width: 24,
                  height: 24,
                  colorFilter: const ColorFilter.mode(
                    Colors.white,
                    BlendMode.srcIn,
                  ),
                ),
                const SizedBox(width: 8),
                const Text('İlk setimi oluştur'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
