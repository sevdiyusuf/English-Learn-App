import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../core/responsive/responsive_utils.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/storage_service.dart';

class LobbyHomePage extends StatefulWidget {
  const LobbyHomePage({super.key});

  static const routeName = 'home';

  @override
  State<LobbyHomePage> createState() => _LobbyHomePageState();
}

class _LobbyHomePageState extends State<LobbyHomePage> {
  String? _savedRoomPath;

  @override
  void initState() {
    super.initState();
    _loadSavedRoom();
  }

  void _loadSavedRoom() {
    if (!kIsWeb) {
      return;
    }
    try {
      final roomId = StorageService.getRoomId();
      final roomCode = StorageService.getRoomCode();
      String? path;
      if (roomId != null && roomId.trim().isNotEmpty) {
        path = '/room/${roomId.trim()}';
      } else if (roomCode != null && roomCode.trim().isNotEmpty) {
        path = '/room/${roomCode.trim()}';
      }
      if (mounted) {
        setState(() {
          _savedRoomPath = path;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _savedRoomPath = null;
        });
      }
    }
  }

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
      appBar: AppBar(
        backgroundColor: Colors.transparent,
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
            onPressed: () => context.go('/mini-games'),
            tooltip: 'Mini Games\'e dön',
          ),
        ),
        title: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.surfaceDark.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Text(
            'Word Battle',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              shadows: [Shadow(blurRadius: 5, color: Colors.black)],
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: padding,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // --- KAYDEDİLEN ODA (VARSA) ---
                    if (_savedRoomPath != null) ...[
                      Align(
                        alignment: Alignment.center,
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => context.go(_savedRoomPath!),
                            borderRadius: BorderRadius.circular(30),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.success.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(30),
                                border: Border.all(
                                  color: AppColors.success.withValues(
                                    alpha: 0.5,
                                  ),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.success.withValues(
                                      alpha: 0.1,
                                    ),
                                    blurRadius: 10,
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.history,
                                    color: AppColors.success,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Önceki Odaya Dön',
                                    style: TextStyle(
                                      color: AppColors.success,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(
                                    Icons.arrow_forward_ios,
                                    color: AppColors.success,
                                    size: 12,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // --- BAŞLIK ---
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceDark.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'KELİME SAVAŞI',
                        style: Theme.of(
                          context,
                        ).textTheme.headlineMedium?.copyWith(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 2,
                          shadows: [
                            Shadow(
                              blurRadius: 15,
                              color: AppColors.primary.withValues(alpha: 0.5),
                            ),
                          ],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),

                    const SizedBox(height: 32),

                    // --- BİLGİ KARTI ---
                    const _GameInfoWidget(),

                    SizedBox(height: spacing * 2),

                    // --- ODA OLUŞTUR BUTONU ---
                    _MenuButton(
                      title: 'Oda Oluştur',
                      subtitle: 'Yeni bir oyun kur ve arkadaşını davet et',
                      icon: Icons.add_circle_outline,
                      color: AppColors.primary, // Mavi tema
                      onTap: () => context.push('/create'),
                    ),

                    SizedBox(height: spacing),

                    // --- ODA KATIL BUTONU ---
                    _MenuButton(
                      title: 'Odaya Katıl',
                      subtitle: 'Var olan bir odaya kod ile giriş yap',
                      icon: Icons.login_rounded, // Daha modern ikon
                      color: const Color(0xFFEC4899), // Pembe/Mor tema
                      onTap: () => context.push('/join'),
                    ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// --- ŞIK MENÜ BUTONU ---
class _MenuButton extends StatelessWidget {
  const _MenuButton({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 110,
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B), // Tok Koyu Zemin
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color, width: 2),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.25),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          splashColor: color.withValues(alpha: 0.1),
          highlightColor: color.withValues(alpha: 0.05),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                // Sol İkon
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                    border: Border.all(color: color.withValues(alpha: 0.3)),
                  ),
                  child: Icon(icon, color: color, size: 32),
                ),
                const SizedBox(width: 20),

                // Metinler
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: color,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                // Sağ Ok
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: color.withValues(alpha: 0.5),
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// --- BİLGİ KARTI ---
class _GameInfoWidget extends StatelessWidget {
  const _GameInfoWidget();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A).withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.1),
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
                const Text(
                  'NASIL OYNANIR?',
                  style: TextStyle(
                    color: Colors.amber,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Bu modda oyuncular sırayla 1 fiil ve 1 sıfat yazar. Süresi dolan oyuncu eli kaybeder.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
