import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';

class FlashSynonymLevelSelectPage extends StatelessWidget {
  const FlashSynonymLevelSelectPage({super.key});

  static const routeName = 'flashSynonymLevelSelect';

  @override
  Widget build(BuildContext context) {
    // Get screen height and constrain to 80% of screen
    final screenHeight = MediaQuery.of(context).size.height;
    final maxHeight = screenHeight * 0.8;

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B).withValues(alpha: 0.90),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(30),
              ),
              border: Border(
                top: BorderSide(
                  color: Colors.white.withValues(alpha: 0.15),
                  width: 1,
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.6),
                  blurRadius: 30,
                  offset: const Offset(0, -10),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Handle bar
                      Container(
                        width: 48,
                        height: 5,
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      // Title
                      Text(
                        'ZORLUK SEVİYESİ',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),

                      // Level Buttons
                      _LevelButton(
                        level: 'easy',
                        title: 'KOLAY',
                        description: 'Başlangıç seviyesi',
                        color: AppColors.success, // Yeşil
                        icon: Icons.sentiment_satisfied_alt_rounded,
                        onTap: () {
                          Navigator.of(context).pop(); // Close bottom sheet
                          context.push('/flash-synonym/easy');
                        },
                      ),
                      const SizedBox(height: 16),

                      _LevelButton(
                        level: 'medium',
                        title: 'ORTA',
                        description: 'Kelime dağarcığını geliştir',
                        color: AppColors.primary, // Mavi
                        icon: Icons.trending_up_rounded,
                        onTap: () {
                          Navigator.of(context).pop(); // Close bottom sheet
                          context.push('/flash-synonym/medium');
                        },
                      ),
                      const SizedBox(height: 16),

                      _LevelButton(
                        level: 'upper',
                        title: 'İLERİ',
                        description: 'Zorlu kelimeler',
                        color: AppColors.warning, // Turuncu
                        icon: Icons.school_rounded,
                        onTap: () {
                          Navigator.of(context).pop(); // Close bottom sheet
                          context.push('/flash-synonym/upper');
                        },
                      ),
                      const SizedBox(height: 16),

                      _LevelButton(
                        level: 'expert',
                        title: 'UZMAN',
                        description: 'Sadece ustalar için',
                        color: AppColors.error, // Kırmızı
                        icon: Icons.flash_on_rounded,
                        onTap: () {
                          Navigator.of(context).pop(); // Close bottom sheet
                          context.push('/flash-synonym/expert');
                        },
                      ),

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
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
      height: 90,
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B), // Tamamen opak, koyu lacivert zemin
        borderRadius: BorderRadius.circular(16),
        // YENİ: Renkli ve belirgin çerçeve
        border: Border.all(color: color, width: 2),
        // YENİ: Renkli parlama efekti (Glow)
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
                    topLeft: Radius.circular(
                      14,
                    ), // Çerçeve payı için biraz küçülttük
                    bottomLeft: Radius.circular(14),
                  ),
                ),
              ),

              // İÇERİK
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    // Hafif gradyan ekleyerek düz renkten kurtarıyoruz
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
                            Text(
                              title,
                              style: Theme.of(
                                context,
                              ).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color:
                                    color, // YENİ: Başlık rengi artık kart rengiyle aynı
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
                        ), // Ok rengini de uyumlu yaptık
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
