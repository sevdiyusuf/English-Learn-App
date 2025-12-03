import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'dart:ui'; // Blur efekti için gerekli

import '../../../core/widgets/svg_icon.dart';

class AppColors {
  static const Color background = Color(0xFF0F172A);
  static const Color surface = Color(0xFF1E293B);
  static const Color accentPurple = Color(0xFF6366F1);
  static const Color accentPink = Color(0xFFEC4899);
  static const Color accentOrange = Color(0xFFF59E0B);
  static const Color accentTeal = Color(0xFF14B8A6);
}

class ModeSelectPage extends StatefulWidget {
  const ModeSelectPage({super.key});

  static const routeName = 'modeSelect';

  @override
  State<ModeSelectPage> createState() => _ModeSelectPageState();
}

class _ModeSelectPageState extends State<ModeSelectPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // 1. KATMAN: Arka plan dekoratif ışıklar
          Positioned(
            top: -100,
            left: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                color: AppColors.accentPurple.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            right: -50,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                color: AppColors.accentTeal.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
            ),
          ),
          // Blur filtresi
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
            child: const SizedBox.expand(),
          ),

          // 2. KATMAN: İçerik
          SafeArea(
            child: Center(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final maxWidth =
                      constraints.maxWidth > 600 ? 600.0 : constraints.maxWidth;

                  return SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24.0,
                        vertical: 16.0,
                      ),
                      child: SizedBox(
                        width: maxWidth,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const SizedBox(height: 20),

                            // Başlık Kısmı
                            _buildHeader(context),

                            const SizedBox(height: 40),

                            // Mini Games Bölümü
                            _SectionTitle(title: 'Eğlence Zamanı 🎮'),
                            const SizedBox(height: 16),
                            _GameCard(
                              title: 'Mini Games',
                              subtitle: 'Kelime bilginizi oyunlarla test edin',
                              icon: Icons.gamepad_outlined,
                              svgAsset: 'assets/icons/gamepad.svg',
                              primaryColor:
                                  AppColors.accentPurple, // Ana vurgu rengi
                              gradientColors: const [
                                AppColors.accentPurple,
                                AppColors.accentPink,
                              ],
                              onTap: () => context.go('/mini-games'),
                            ),

                            const SizedBox(height: 32),

                            // Word Match Bölümü
                            _SectionTitle(title: 'Kelime Pratiği 📚'),
                            const SizedBox(height: 16),
                            _GameCard(
                              title: 'Word Match',
                              subtitle: 'Kendi kartlarınızla eşleştirme yapın',
                              icon: Icons.style_outlined,
                              svgAsset: 'assets/icons/style.svg',
                              primaryColor:
                                  AppColors.accentTeal, // Ana vurgu rengi
                              gradientColors: const [
                                AppColors.accentTeal,
                                Color(0xFF0EA5E9),
                              ],
                              onTap: () => context.go('/word-match/sets'),
                            ),

                            const SizedBox(height: 40),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surface.withValues(alpha: 0.8),
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.accentOrange.withValues(alpha: 0.5),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.accentOrange.withValues(alpha: 0.2),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: const SvgIcon(
            svgAsset: 'assets/icons/smile.svg',
            fallbackIcon: Icons.emoji_objects_outlined,
            size: 40,
            color: AppColors.accentOrange,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Hoş Geldiniz!',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w900,
            color: Colors.white,
            letterSpacing: 1.2,
            shadows: [
              Shadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 10,
              ),
            ],
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Text(
            'Dikkat süresi üç saniye olanlar için:\nOyunlarla İngilizce kelimeler öğrenin.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Colors.grey.shade300,
              height: 1.5,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4.0),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.white.withValues(alpha: 0.7),
          letterSpacing: 2,
        ),
      ),
    );
  }
}

class _GameCard extends StatelessWidget {
  const _GameCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.primaryColor,
    required this.gradientColors,
    required this.onTap,
    this.svgAsset,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color primaryColor; // Çerçeve ve şerit rengi
  final List<Color> gradientColors; // İkon veya detaylar için kullanılabilir
  final VoidCallback onTap;
  final String? svgAsset;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 130, // Kart yüksekliği
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B), // Tok Koyu Lacivert Zemin
        borderRadius: BorderRadius.circular(24),
        // RENKLİ ÇERÇEVE
        border: Border.all(
          color: primaryColor.withValues(alpha: 0.8),
          width: 2,
        ),
        // RENKLİ PARLAMA (GLOW)
        boxShadow: [
          BoxShadow(
            color: primaryColor.withValues(alpha: 0.25),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          splashColor: primaryColor.withValues(alpha: 0.1),
          highlightColor: primaryColor.withValues(alpha: 0.05),
          child: Stack(
            children: [
              // 1. SOL ŞERİT (Renkli Vurgu)
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                child: Container(
                  width: 12,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: gradientColors,
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(22), // Çerçeve payı
                      bottomLeft: Radius.circular(22),
                    ),
                  ),
                ),
              ),

              // 2. ARKA PLAN DEKORATİF İKON (Watermark)
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
                            size: 140,
                            color: primaryColor.withValues(alpha: 0.1),
                          )
                          : Icon(
                            icon,
                            size: 140,
                            color: primaryColor.withValues(alpha: 0.1),
                          ),
                ),
              ),

              // 3. İÇERİK
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  36,
                  20,
                  20,
                  20,
                ), // Soldan şerit için ekstra boşluk
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              color: primaryColor, // Başlık artık tema renginde
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            subtitle,
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 14,
                              height: 1.2,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),

                    // Sağ Ok Butonu
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: primaryColor.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: primaryColor.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Icon(
                        Icons.arrow_forward_rounded,
                        color: primaryColor,
                        size: 24,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
