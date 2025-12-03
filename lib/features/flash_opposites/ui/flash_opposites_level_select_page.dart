import 'dart:ui'; // Blur efekti için gerekli
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/responsive/responsive_utils.dart';
import '../../../core/theme/app_colors.dart';

class FlashOppositesLevelSelectPage extends StatelessWidget {
  const FlashOppositesLevelSelectPage({super.key});

  static const routeName = 'flashOppositesLevelSelect';

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
      backgroundColor: Colors.transparent, // Arka plan resmi görünsün
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.5), // Geri butonu belirgin
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => context.pop(),
            tooltip: 'Geri dön',
          ),
        ),
        title: const Text(
          'Flash Opposites',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            shadows: [Shadow(blurRadius: 5, color: Colors.black)],
          ),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: padding,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 20),
                  // BAŞLIK ALANI
                  Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 16,
                      horizontal: 24,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceDark.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black45,
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Text(
                      'ZORLUK SEVİYESİ',
                      style: Theme.of(
                        context,
                      ).textTheme.headlineSmall?.copyWith(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                  SizedBox(height: spacing * 2),

                  // LEVEL BUTTONS (YENİ TASARIM)
                  _LevelButton(
                    level: 'easy',
                    title: 'KOLAY',
                    description: 'Başlangıç seviyesi',
                    color: AppColors.success, // YEŞİL
                    icon: Icons.sentiment_satisfied_alt_rounded,
                    onTap: () => context.push('/flash-opposites/easy'),
                  ),
                  SizedBox(height: spacing),

                  _LevelButton(
                    level: 'medium',
                    title: 'ORTA',
                    description: 'Kelime dağarcığını geliştir',
                    color: AppColors.primary, // MAVİ
                    icon: Icons.trending_up_rounded,
                    onTap: () => context.push('/flash-opposites/medium'),
                  ),
                  SizedBox(height: spacing),

                  _LevelButton(
                    level: 'upper',
                    title: 'İLERİ',
                    description: 'Zorlu kelimeler',
                    color: AppColors.warning, // TURUNCU
                    icon: Icons.school_rounded,
                    onTap: () => context.push('/flash-opposites/upper'),
                  ),
                  SizedBox(height: spacing),

                  _LevelButton(
                    level: 'expert',
                    title: 'UZMAN',
                    description: 'Sadece ustalar için',
                    color: AppColors.error, // KIRMIZI
                    icon: Icons.flash_on_rounded,
                    onTap: () => context.push('/flash-opposites/expert'),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LevelButton extends StatelessWidget {
  const _LevelButton({
    required this.level,
    required this.title,
    required this.description,
    required this.color,
    required this.icon,
    required this.onTap,
  });

  final String level;
  final String title;
  final String description;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100,
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B), // Tamamen opak, koyu lacivert zemin
        borderRadius: BorderRadius.circular(16),
        // ÖNEMLİ: Renkli Çerçeve (User Request)
        border: Border.all(color: color, width: 2),
        // ÖNEMLİ: Renkli Parlama (Glow)
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Row(
            children: [
              // SOL ŞERİT (Renkli Vurgu)
              Container(
                width: 12,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(14),
                    bottomLeft: Radius.circular(14),
                  ),
                ),
              ),

              // İÇERİK ALANI
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    // Hafif gradyan
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        const Color(0xFF1E293B),
                        const Color(0xFF0F172A),
                      ],
                    ),
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(14),
                      bottomRight: Radius.circular(14),
                    ),
                  ),
                  child: Row(
                    children: [
                      // İKON
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(icon, color: color, size: 28),
                      ),
                      const SizedBox(width: 16),

                      // METİNLER
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ÖNEMLİ: Başlık Rengi = Kart Rengi (User Request)
                            Text(
                              title,
                              style: Theme.of(
                                context,
                              ).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: color, // Yazı rengi artık yeşil/mavi/vb.
                                letterSpacing: 1,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              description,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(color: Colors.grey[400]),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),

                      // SAĞ OK
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: color.withValues(
                          alpha: 0.5,
                        ), // Ok rengi de uyumlu
                        size: 16,
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
  }
}
