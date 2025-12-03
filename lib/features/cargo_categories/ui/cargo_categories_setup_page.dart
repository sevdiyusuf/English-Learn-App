import 'dart:ui'; // Blur efekti için gerekli
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../core/responsive/responsive_utils.dart';
import '../../../core/theme/app_colors.dart';
import '../data/cargo_service.dart';
import '../logic/cargo_categories_controller.dart';
import '../models/cargo_categories_state.dart';
import '../models/category.dart';

class CargoCategoriesSetupPage extends ConsumerStatefulWidget {
  const CargoCategoriesSetupPage({super.key});

  static const routeName = 'cargoCategoriesSetup';

  @override
  ConsumerState<CargoCategoriesSetupPage> createState() =>
      _CargoCategoriesSetupPageState();
}

class _CargoCategoriesSetupPageState
    extends ConsumerState<CargoCategoriesSetupPage> {
  late Future<void> _loadDataFuture;

  @override
  void initState() {
    super.initState();
    _loadDataFuture = CargoService.instance.loadData();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(cargoCategoriesControllerProvider);

    // Setup sayfasına her geldiğinde, eğer oyun çalışıyorsa reset et
    // Bu sayede oyunu oynarken geri tuşuna basıldığında buton aktif olur
    // Ancak oyun başlatılırken reset etme (isRunning true olabilir ama henüz game sayfasına gidilmemiş olabilir)
    if (state.isFinished) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ref.read(cargoCategoriesControllerProvider.notifier).reset();
        }
      });
    }

    return FutureBuilder<void>(
      future: _loadDataFuture,
      builder: (context, snapshot) {
        // --- LOADING STATE ---
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Colors.transparent,
            body: Center(child: CircularProgressIndicator(color: Colors.white)),
          );
        }

        // --- ERROR STATE ---
        if (snapshot.hasError) {
          return Scaffold(
            backgroundColor: Colors.transparent,
            appBar: _buildAppBar(context),
            body: Center(
              child: _GlassContainer(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.redAccent,
                      size: 48,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Hata: ${snapshot.error}',
                      style: const TextStyle(color: Colors.white),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () {
                        setState(() {
                          _loadDataFuture = CargoService.instance.loadData();
                        });
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.white24,
                      ),
                      child: const Text('Tekrar Dene'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        // --- SUCCESS STATE ---
        final categories = CargoService.instance.getCategories();
        final padding = ResponsiveUtils.responsivePadding(context);
        final spacing = ResponsiveUtils.responsiveSpacing(context);
        final maxWidth = ResponsiveUtils.responsive<double>(
          context: context,
          mobile: double.infinity,
          tablet: 600,
          desktop: 700,
        );

        return Scaffold(
          backgroundColor: Colors.transparent,
          extendBodyBehindAppBar: true,
          appBar: _buildAppBar(context),
          body: Stack(
            children: [
              // 1. KATMAN: Vignette (Karartma)
              const SizedBox.expand(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment.center,
                      radius: 1.2,
                      colors: [Colors.transparent, Colors.black87],
                      stops: [0.3, 1.0],
                    ),
                  ),
                ),
              ),

              // 2. KATMAN: İçerik
              SafeArea(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Center(
                    child: Padding(
                      padding: padding,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: maxWidth),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            SizedBox(height: spacing),

                            // Title Section
                            _GlassContainer(
                              padding: const EdgeInsets.symmetric(
                                vertical: 20,
                                horizontal: 16,
                              ),
                              child: Text(
                                'OYUN AYARLARI',
                                style: Theme.of(
                                  context,
                                ).textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  letterSpacing: 2,
                                  shadows: [
                                    Shadow(
                                      blurRadius: 10,
                                      color: AppColors.primary.withValues(
                                        alpha: 0.8,
                                      ),
                                      offset: const Offset(0, 0),
                                    ),
                                  ],
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),

                            SizedBox(height: spacing * 2),

                            // Difficulty Section
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8.0,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceDark.withValues(
                                  alpha: 0.9,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'ZORLUK SEVİYESİ',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.8),
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            Row(
                              children: [
                                Expanded(
                                  child: _DifficultyButton(
                                    difficulty: Difficulty.slow,
                                    isSelected:
                                        state.selectedDifficulty ==
                                        Difficulty.slow,
                                    onTap: () {
                                      ref
                                          .read(
                                            cargoCategoriesControllerProvider
                                                .notifier,
                                          )
                                          .selectDifficulty(Difficulty.slow);
                                    },
                                  ),
                                ),
                                SizedBox(width: spacing),
                                Expanded(
                                  child: _DifficultyButton(
                                    difficulty: Difficulty.normal,
                                    isSelected:
                                        state.selectedDifficulty ==
                                        Difficulty.normal,
                                    onTap: () {
                                      ref
                                          .read(
                                            cargoCategoriesControllerProvider
                                                .notifier,
                                          )
                                          .selectDifficulty(Difficulty.normal);
                                    },
                                  ),
                                ),
                                SizedBox(width: spacing),
                                Expanded(
                                  child: _DifficultyButton(
                                    difficulty: Difficulty.fast,
                                    isSelected:
                                        state.selectedDifficulty ==
                                        Difficulty.fast,
                                    onTap: () {
                                      ref
                                          .read(
                                            cargoCategoriesControllerProvider
                                                .notifier,
                                          )
                                          .selectDifficulty(Difficulty.fast);
                                    },
                                  ),
                                ),
                              ],
                            ),

                            SizedBox(height: spacing * 3),

                            // Category Section Header
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8.0,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceDark.withValues(
                                      alpha: 0.9,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'KATEGORİLERİ SEÇ',
                                    style: TextStyle(
                                      color: Colors.white.withValues(
                                        alpha: 0.8,
                                      ),
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                        state.selectedCategories.length == 3
                                            ? AppColors.success
                                            : Colors.white.withValues(
                                              alpha: 0.1,
                                            ),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color:
                                          state.selectedCategories.length == 3
                                              ? AppColors.success
                                              : Colors.white.withValues(
                                                alpha: 0.3,
                                              ),
                                    ),
                                    boxShadow:
                                        state.selectedCategories.length == 3
                                            ? [
                                              BoxShadow(
                                                color: AppColors.success
                                                    .withValues(alpha: 0.5),
                                                blurRadius: 10,
                                              ),
                                            ]
                                            : [],
                                  ),
                                  child: Text(
                                    '${state.selectedCategories.length} / 3',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            SizedBox(height: spacing),

                            // Category Chips
                            _GlassContainer(
                              padding: const EdgeInsets.all(16),
                              child: Wrap(
                                spacing: spacing,
                                runSpacing: spacing,
                                alignment: WrapAlignment.center,
                                children:
                                    categories.map((category) {
                                      final isSelected = state
                                          .selectedCategories
                                          .contains(category.id);
                                      return _CategoryChip(
                                        category: category,
                                        isSelected: isSelected,
                                        onTap: () {
                                          ref
                                              .read(
                                                cargoCategoriesControllerProvider
                                                    .notifier,
                                              )
                                              .toggleCategory(category.id);
                                        },
                                      );
                                    }).toList(),
                              ),
                            ),

                            SizedBox(height: spacing * 4),

                            // Start Button
                            AnimatedOpacity(
                              duration: const Duration(milliseconds: 300),
                              opacity: state.canStartGame ? 1.0 : 0.5,
                              child: Container(
                                width: double.infinity,
                                height: 64,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow:
                                      state.canStartGame
                                          ? [
                                            BoxShadow(
                                              color: AppColors.primary
                                                  .withValues(alpha: 0.6),
                                              blurRadius: 20,
                                              offset: const Offset(0, 5),
                                            ),
                                          ]
                                          : [],
                                ),
                                child: FilledButton(
                                  onPressed:
                                      state.canStartGame
                                          ? () async {
                                            // Önce oyunu başlat
                                            ref
                                                .read(
                                                  cargoCategoriesControllerProvider
                                                      .notifier,
                                                )
                                                .startGame();
                                            // State'in güncellenmesi için kısa bir bekleme
                                            await Future.delayed(
                                              const Duration(milliseconds: 100),
                                            );
                                            // Sonra game sayfasına git
                                            if (mounted) {
                                              await context.push(
                                                '/cargo-categories/game',
                                              );
                                            }
                                          }
                                          : null,
                                  style: FilledButton.styleFrom(
                                    backgroundColor:
                                        state.canStartGame
                                            ? AppColors.primary
                                            : Colors.grey.withValues(
                                              alpha: 0.3,
                                            ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        'OYUNU BAŞLAT',
                                        style: Theme.of(
                                          context,
                                        ).textTheme.titleLarge?.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 1.5,
                                        ),
                                      ),
                                      if (state.canStartGame) ...[
                                        const SizedBox(width: 12),
                                        const Icon(
                                          Icons.play_arrow_rounded,
                                          size: 32,
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: spacing * 2),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      leading: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.3),
          shape: BoxShape.circle,
        ),
        child: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            // Oyun çalışıyorsa durdur
            final state = ref.read(cargoCategoriesControllerProvider);
            if (state.isRunning) {
              ref.read(cargoCategoriesControllerProvider.notifier).reset();
            }
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/mode-select');
            }
          },
          tooltip: 'Geri dön',
        ),
      ),
      title: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.surfaceDark.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Text(
          'Cargo Categories',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            shadows: [Shadow(blurRadius: 5, color: Colors.black)],
          ),
        ),
      ),
    );
  }
}

// --- ZORLUK SEVİYESİ BUTONU ---
class _DifficultyButton extends StatelessWidget {
  const _DifficultyButton({
    required this.difficulty,
    required this.isSelected,
    required this.onTap,
  });

  final Difficulty difficulty;
  final bool isSelected;
  final VoidCallback onTap;

  Color get _color {
    switch (difficulty) {
      case Difficulty.slow:
        return AppColors.success;
      case Difficulty.normal:
        return AppColors.primary;
      case Difficulty.fast:
        return AppColors.error;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(vertical: 20),
            decoration: BoxDecoration(
              // Blur efekti için yarı şeffaf koyu zemin
              color: const Color(0xFF1E293B).withValues(alpha: 0.4),
              // Seçiliyse renkli gradyan overlay, değilse şeffaf
              gradient:
                  isSelected
                      ? LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          _color.withValues(alpha: 0.4),
                          _color.withValues(alpha: 0.1),
                        ],
                      )
                      : LinearGradient(
                        colors: [
                          Colors.white.withValues(alpha: 0.1),
                          Colors.white.withValues(alpha: 0.05),
                        ],
                      ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color:
                    isSelected
                        ? _color // Parlak kenarlık
                        : Colors.white.withValues(alpha: 0.2), // Soluk kenarlık
                width: isSelected ? 2 : 1,
              ),
              boxShadow: [
                if (isSelected)
                  BoxShadow(
                    color: _color.withValues(alpha: 0.4),
                    blurRadius: 15,
                    spreadRadius: 1,
                  )
                else
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 5,
                  ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SvgPicture.asset(
                  'assets/icons/speed.svg',
                  width: 32,
                  height: 32,
                  colorFilter: ColorFilter.mode(
                    isSelected
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.5),
                    BlendMode.srcIn,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  difficulty.displayName,
                  style: TextStyle(
                    color:
                        isSelected
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.7),
                    fontWeight: isSelected ? FontWeight.w900 : FontWeight.w500,
                    fontSize: 16,
                    shadows:
                        isSelected
                            ? [Shadow(blurRadius: 8, color: _color)]
                            : [],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// --- KATEGORİ ÇİPİ ---
class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.category,
    required this.isSelected,
    required this.onTap,
  });

  final Category category;
  final bool isSelected;
  final VoidCallback onTap;

  Color get _categoryColor {
    try {
      final colorString = category.color.replaceAll('#', '');
      return Color(int.parse('FF$colorString', radix: 16));
    } catch (e) {
      return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          // Seçiliyse kategori renginde gradyan, değilse cam
          gradient:
              isSelected
                  ? LinearGradient(
                    colors: [
                      _categoryColor.withValues(alpha: 0.5),
                      _categoryColor.withValues(alpha: 0.2),
                    ],
                  )
                  : LinearGradient(
                    colors: [
                      Colors.white.withValues(alpha: 0.1),
                      Colors.white.withValues(alpha: 0.05),
                    ],
                  ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color:
                isSelected
                    ? _categoryColor
                    : Colors.white.withValues(alpha: 0.3),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: _categoryColor.withValues(alpha: 0.4),
                blurRadius: 12,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedScale(
              duration: const Duration(milliseconds: 200),
              scale: isSelected ? 1.0 : 0.0,
              child:
                  isSelected
                      ? Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: Icon(
                          Icons.check_circle,
                          color: Colors.white,
                          size: 20,
                        ),
                      )
                      : const SizedBox(),
            ),
            Text(
              category.name,
              style: TextStyle(
                color: Colors.white,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                fontSize: 16,
                shadows: const [
                  Shadow(
                    blurRadius: 2,
                    color: Colors.black54,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- YARDIMCI: GLASS PANEL ---
class _GlassContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const _GlassContainer({required this.child, this.padding = EdgeInsets.zero});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: const Color(
              0xFF1E293B,
            ).withValues(alpha: 0.4), // Yarı şeffaf koyu zemin
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: child,
        ),
      ),
    );
  }
}
