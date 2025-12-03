import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
// import 'dart:math' as math; // Transform rotate için gerekli

import '../../../core/responsive/responsive_utils.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/svg_icon.dart';

class MiniGamesPage extends StatelessWidget {
  const MiniGamesPage({super.key});

  static const routeName = 'miniGames';

  @override
  Widget build(BuildContext context) {
    final padding = ResponsiveUtils.responsivePadding(context);
    final spacing = ResponsiveUtils.responsiveSpacing(context);
    final maxWidth = ResponsiveUtils.responsive<double>(
      context: context,
      mobile: double.infinity,
      tablet: 500,
      desktop: 600,
    );

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceDark.withValues(alpha: 0.9),
        elevation: 0,
        centerTitle: true,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.5),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () {
              if (Navigator.of(context).canPop()) {
                context.pop();
              } else {
                context.go('/mode-select');
              }
            },
            tooltip: 'Geri dön',
          ),
        ),
        title: const Text(
          'Mini Games',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            shadows: [Shadow(blurRadius: 5, color: Colors.black)],
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: padding,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(height: spacing),

                  // OFFLINE GAMES Header
                  _SectionHeader(title: 'OFFLINE GAMES'),

                  SizedBox(height: spacing),

                  _GameButton(
                    title: 'Flash Opposites',
                    subtitle: 'Zıt anlamlı kelime seçme oyunu',
                    icon: Icons.flash_on,
                    svgAsset: 'assets/icons/flash_on.svg',
                    color: const Color.fromARGB(255, 175, 63, 192), // Mor
                    onTap: () => context.push('/flash-opposites'),
                  ),
                  SizedBox(height: spacing),

                  _GameButton(
                    title: 'Flash Synonym',
                    subtitle: 'Eş/yakın anlamlı kelimeleri seçin',
                    icon: Icons.compare_arrows,
                    svgAsset: 'assets/icons/compare_arrows.svg',
                    color: const Color.fromARGB(255, 63, 192, 175), // Turkuaz
                    onTap: () => context.push('/flash-synonym'),
                  ),
                  SizedBox(height: spacing),

                  _GameButton(
                    title: 'Cargo Categories',
                    subtitle: 'Kelimeleri kategorilere ayır',
                    icon: Icons.local_shipping,
                    svgAsset: 'assets/icons/local_shipping.svg',
                    color: const Color.fromARGB(255, 244, 162, 97), // Turuncu
                    onTap: () => context.push('/cargo-categories/setup'),
                  ),
                  SizedBox(height: spacing),

                  _GameButton(
                    title: 'Word Echo',
                    subtitle: 'Kelimeyi hatırla ve doğru yeri seç',
                    icon: Icons.memory,
                    svgAsset: 'assets/icons/memory.svg',
                    color: const Color.fromARGB(255, 99, 102, 241), // İndigo
                    onTap: () => context.push('/word-echo'),
                  ),

                  SizedBox(height: spacing * 2),

                  // ONLINE GAMES Header
                  _SectionHeader(title: 'ONLINE GAMES'),

                  SizedBox(height: spacing),

                  _GameButton(
                    title: 'Word Battle',
                    subtitle: 'Çevrim içi kelime savaşı',
                    icon: Icons.people,
                    svgAsset: 'assets/icons/people.svg',
                    color: AppColors.primary, // Mavi
                    onTap: () => context.go('/'),
                  ),

                  SizedBox(height: spacing * 2),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
        boxShadow: const [
          BoxShadow(color: Colors.black45, blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontSize: ResponsiveUtils.responsiveFontSize(
            context,
            mobile: 16,
            desktop: 18,
          ),
          fontWeight: FontWeight.w900,
          color: Colors.white,
          letterSpacing: 2.0,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

class _GameButton extends StatelessWidget {
  const _GameButton({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
    this.svgAsset,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final String? svgAsset;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        splashColor: color.withValues(alpha: 0.1),
        highlightColor: color.withValues(alpha: 0.05),
        child: Ink(
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(20)),
          child: Container(
            width: double.infinity,
            constraints: const BoxConstraints(
              minHeight: 120,
            ), // Yüksekliği korudum
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: AppColors.surfaceDark,
              border: Border.all(color: color, width: 2),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias, // Watermark taşmasını engeller
            child: Stack(
              alignment: Alignment.center,
              children: [
                // 1. ARKA PLAN WATERMARK (Silik İkon)
                Positioned(
                  right: -20,
                  bottom: -20,
                  child: Transform.rotate(
                    angle: -0.2,
                    child:
                        svgAsset != null
                            ? SvgIcon(
                              svgAsset: svgAsset!,
                              fallbackIcon: icon,
                              size: 120, // Büyük boyut
                              color: color.withValues(alpha: 0.1), // Silik renk
                            )
                            : Icon(
                              icon,
                              size: 120,
                              color: color.withValues(alpha: 0.1),
                            ),
                  ),
                ),

                // 2. MERKEZİ İÇERİK (Padding ile korundu)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      svgAsset != null
                          ? SvgIcon(
                            svgAsset: svgAsset!,
                            fallbackIcon: icon,
                            color: color,
                            size: 28, // Normal boyut
                          )
                          : Icon(icon, color: color, size: 28),
                      const SizedBox(height: 8),
                      Text(
                        title,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
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
}
