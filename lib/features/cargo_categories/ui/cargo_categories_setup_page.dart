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
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Colors.transparent,
            body: Center(child: CircularProgressIndicator(color: Colors.white)),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            backgroundColor: Colors.transparent,
            appBar: _buildAppBar(context),
            body: Center(
              child: _GlassContainer(
                padding: const EdgeInsets.all(24),
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
                      style: const TextStyle(color: Colors.white, fontSize: 16),
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

        final padding = ResponsiveUtils.responsivePadding(context);
        final spacing = ResponsiveUtils.responsiveSpacing(context);
        final maxWidth = ResponsiveUtils.responsive<double>(
          context: context,
          mobile: double.infinity,
          tablet: 600,
          desktop: 700,
        );

        return Scaffold(
          backgroundColor: const Color.fromARGB(0, 0, 0, 0),
          extendBodyBehindAppBar: true,
          appBar: _buildAppBar(context),
          body: Stack(
            children: [
              const SizedBox.expand(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment.topCenter,
                      radius: 1.5,
                      colors: [
                        Color.fromARGB(
                          255,
                          38,
                          91,
                          101,
                        ), // Biraz daha mavimsi gri
                        Color(0xFF000000),
                      ],
                      stops: [0.0, 1.0],
                    ),
                  ),
                ),
              ),
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

                            // --- BİLGİLENDİRME KARTI ---
                            _buildInfoCard(context),
                            SizedBox(height: spacing * 2),

                            // --- 1. HIZ SEÇENEĞİ ---
                            _buildSectionHeader(
                              context,
                              'HIZ',
                              'assets/icons/speed.svg',
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: _SpeedButton(
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
                                  child: _SpeedButton(
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

                            SizedBox(height: spacing * 2),

                            // --- 2. ZORLUK SEVİYESİ ---
                            _buildSectionHeader(
                              context,
                              'ZORLUK SEVİYESİ',
                              'assets/icons/local_shipping.svg',
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: _GameLevelButton(
                                    level: GameLevel.beginner,
                                    isSelected:
                                        state.selectedGameLevel ==
                                        GameLevel.beginner,
                                    onTap: () {
                                      ref
                                          .read(
                                            cargoCategoriesControllerProvider
                                                .notifier,
                                          )
                                          .selectGameLevel(GameLevel.beginner);
                                    },
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _GameLevelButton(
                                    level: GameLevel.normal,
                                    isSelected:
                                        state.selectedGameLevel ==
                                        GameLevel.normal,
                                    onTap: () {
                                      ref
                                          .read(
                                            cargoCategoriesControllerProvider
                                                .notifier,
                                          )
                                          .selectGameLevel(GameLevel.normal);
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: _GameLevelButton(
                                    level: GameLevel.advanced,
                                    isSelected:
                                        state.selectedGameLevel ==
                                        GameLevel.advanced,
                                    onTap: () {
                                      ref
                                          .read(
                                            cargoCategoriesControllerProvider
                                                .notifier,
                                          )
                                          .selectGameLevel(GameLevel.advanced);
                                    },
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _GameLevelButton(
                                    level: GameLevel.expert,
                                    isSelected:
                                        state.selectedGameLevel ==
                                        GameLevel.expert,
                                    onTap: () {
                                      ref
                                          .read(
                                            cargoCategoriesControllerProvider
                                                .notifier,
                                          )
                                          .selectGameLevel(GameLevel.expert);
                                    },
                                  ),
                                ),
                              ],
                            ),

                            SizedBox(height: spacing * 3),

                            // --- BAŞLAT BUTONU ---
                            AnimatedOpacity(
                              duration: const Duration(milliseconds: 300),
                              opacity: state.canStartGame ? 1.0 : 0.5,
                              child: Container(
                                width: double.infinity,
                                height: 56,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow:
                                      state.canStartGame
                                          ? [
                                            BoxShadow(
                                              color: AppColors.primary
                                                  .withValues(alpha: 0.5),
                                              blurRadius: 20,
                                              offset: const Offset(0, 4),
                                            ),
                                          ]
                                          : [],
                                ),
                                child: FilledButton(
                                  onPressed:
                                      state.canStartGame
                                          ? () {
                                            ref
                                                .read(
                                                  cargoCategoriesControllerProvider
                                                      .notifier,
                                                )
                                                .startGame();
                                            WidgetsBinding.instance
                                                .addPostFrameCallback((_) {
                                                  if (mounted &&
                                                      context.mounted) {
                                                    context.go(
                                                      '/cargo-categories/game',
                                                    );
                                                  }
                                                });
                                          }
                                          : null,
                                  style: FilledButton.styleFrom(
                                    backgroundColor:
                                        state.canStartGame
                                            ? const Color.fromARGB(
                                              255,
                                              65,
                                              126,
                                              138,
                                            )
                                            : Colors.grey.withValues(
                                              alpha: 0.3,
                                            ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
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
                                        ).textTheme.titleMedium?.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 1.2,
                                          fontSize: 16,
                                        ),
                                      ),
                                      if (state.canStartGame) ...[
                                        const SizedBox(width: 8),
                                        const Icon(
                                          Icons.play_arrow_rounded,
                                          size: 26,
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            ),

                            SizedBox(height: spacing * 3),

                            _buildSectionHeader(
                              context,
                              'KATEGORİLER',
                              'assets/icons/local_shipping.svg',
                            ),
                            const SizedBox(height: 12),
                            _buildCategoriesGrid(),
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

  // Bilgilendirme Kartı
  Widget _buildInfoCard(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B).withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Sol: Info ikonu
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: SvgPicture.asset(
                  'assets/icons/info.svg',
                  width: 20,
                  height: 20,
                  colorFilter: ColorFilter.mode(
                    const Color.fromARGB(
                      255,
                      116,
                      194,
                      209,
                    ).withValues(alpha: 0.9),
                    BlendMode.srcIn,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Sağ: Bilgilendirme metni
              Expanded(
                child: Text(
                  'Banttan gelen paketleri yakın anlamlarına göre 3 kategoriye gruplandırın.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 14,
                    height: 1.4,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Estetik Başlık Widget'ı - MERKEZ HİZALAMA
  Widget _buildSectionHeader(
    BuildContext context,
    String title,
    String svgPath,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center, // Merkeze hizalama
      children: [
        SvgPicture.asset(
          svgPath,
          width: 20,
          height: 20,
          colorFilter: ColorFilter.mode(
            const Color.fromARGB(255, 116, 194, 209).withValues(alpha: 0.9),
            BlendMode.srcIn,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.9),
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
            fontSize: 16,
            shadows: [
              Shadow(
                blurRadius: 8,
                color: AppColors.primary.withValues(alpha: 0.5),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCategoriesGrid() {
    final allCategories = CargoService.instance.getCategories();
    final categoryIds = [
      'clothes',
      'family',
      'daily_routine',
      'technology',
      'health',
      'environment',
      'science',
      'business',
      'culture',
      'travel',
      'feelings',
      'nature',
      'jobs',
      'city',
      'free_time',
      'food',
      'house',
      'school',
    ];

    final categories =
        categoryIds
            .map(
              (id) => allCategories.firstWhere(
                (cat) => cat.id == id,
                orElse: () => allCategories.first,
              ),
            )
            .where((cat) => categoryIds.contains(cat.id))
            .toList();

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 2.2,
      ),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        return _CategoryCard(category: categories[index]);
      },
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    // Toplam AppBar alanı için yükseklik (SafeArea + Margin + İçerik)
    const double toolbarHeight = 80.0;

    return PreferredSize(
      preferredSize: const Size.fromHeight(toolbarHeight),
      child: SafeArea(
        child: Container(
          height: 64, // Floating panelin kendi yüksekliği
          margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            // Hafif transparan siyah arka plan (Glassmorphism için temel)
            color: const Color.fromARGB(
              255,
              102,
              135,
              155,
            ).withValues(alpha: 0.5),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.15),
              width: 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          // Blur efektini sınırların içinde tutmak için ClipRRect
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: NavigationToolbar(
                  leading: IconButton(
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                    onPressed: () {
                      final state = ref.read(cargoCategoriesControllerProvider);
                      if (state.isRunning) {
                        ref
                            .read(cargoCategoriesControllerProvider.notifier)
                            .reset();
                      }
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go('/mode-select');
                      }
                    },
                  ),
                  middle: Text(
                    'OYUN AYARLARI',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.5,
                      fontSize: 19,
                      shadows: [
                        Shadow(
                          blurRadius: 10,
                          color: AppColors.primary.withValues(alpha: 0.5),
                        ),
                      ],
                    ),
                  ),
                  centerMiddle: true,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GameLevelButton extends StatelessWidget {
  const _GameLevelButton({
    required this.level,
    required this.isSelected,
    required this.onTap,
  });

  final GameLevel level;
  final bool isSelected;
  final VoidCallback onTap;

  Color get _color {
    switch (level) {
      case GameLevel.beginner:
        return AppColors.success;
      case GameLevel.normal:
        return AppColors.primary;
      case GameLevel.advanced:
        return Colors.orange;
      case GameLevel.expert:
        return AppColors.error;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color:
              isSelected
                  ? _color.withValues(alpha: 0.2)
                  : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? _color : Colors.white.withValues(alpha: 0.1),
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow:
              isSelected
                  ? [
                    BoxShadow(
                      color: _color.withValues(alpha: 0.3),
                      blurRadius: 8,
                      spreadRadius: 0,
                    ),
                  ]
                  : [],
        ),
        child: Center(
          child: Text(
            level.displayName,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.white70,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              fontSize: 15,
            ),
          ),
        ),
      ),
    );
  }
}

class _SpeedButton extends StatelessWidget {
  const _SpeedButton({
    required this.difficulty,
    required this.isSelected,
    required this.onTap,
  });

  final Difficulty difficulty;
  final bool isSelected;
  final VoidCallback onTap;

  Color get _color {
    switch (difficulty) {
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
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          gradient:
              isSelected
                  ? LinearGradient(
                    colors: [
                      _color.withValues(alpha: 0.3),
                      _color.withValues(alpha: 0.1),
                    ],
                  )
                  : null,
          color: isSelected ? null : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? _color : Colors.white.withValues(alpha: 0.1),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(
              difficulty == Difficulty.fast
                  ? 'assets/icons/speed.svg'
                  : 'assets/icons/timer.svg',
              width: 20,
              height: 20,
              colorFilter: ColorFilter.mode(
                isSelected ? Colors.white : Colors.white60,
                BlendMode.srcIn,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              difficulty.displayName,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white70,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({required this.category});

  final Category category;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(30), // Tam oval şekil
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Container(
          decoration: BoxDecoration(
            color: const Color.fromARGB(
              255,
              68,
              4,
              4,
            ).withValues(alpha: 0.4), // Koyu mor
            borderRadius: BorderRadius.circular(30), // Tam oval
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.5),
              width: 1,
            ),
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  SvgPicture.asset(
                    'assets/icons/package.svg',
                    width: 16,
                    height: 16,
                    colorFilter: ColorFilter.mode(
                      Colors.white.withValues(alpha: 0.9),
                      BlendMode.srcIn,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      category.name,
                      textAlign: TextAlign.center,
                      maxLines: 1, // Yatay olduğu için tek satır daha iyi
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13, // Yazı büyütüldü (11 -> 13)
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

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
            color: const Color(0xFF1E293B).withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: child,
        ),
      ),
    );
  }
}
