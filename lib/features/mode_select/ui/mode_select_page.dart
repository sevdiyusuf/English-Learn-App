import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../auth/logic/auth_controller.dart';
import '../../auth/ui/account_sheet.dart';
import '../../user_stats/logic/user_stats_controller.dart';
import '../../profile_settings/logic/user_settings_controller.dart';
import '../../../core/providers/accent_color_provider.dart';

// --- Renk Paleti ve Sabitler ---
const _backgroundColor = Color(
  0xFF050505,
); // Tam siyah değil, çok derin antrasit
const _accentColor = Color(0xFF2997FF); // Daha canlı, premium bir mavi
const _accentPurple = Color(0xFF9B59FF);
const _accentCyan = Color(0xFF00D1FF);
const _accentRed = Color(0xFFFF4B5C);
const _primaryTextColor = Colors.white;
const _secondaryTextColor = Color(0xFF98989F);

// Taşlı Gri Gradyan (Kartlar için)
const _stoneGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [
    Color(0xFF2C2C2E), // Işık alan köşe (Daha açık taş rengi)
    Color(0xFF1C1C1E), // Gölge tarafı (Koyu gri)
  ],
);

// Kartların etrafındaki ince "Elit" çizgi rengi
final _borderSideColor = Colors.white.withValues(alpha: 0.08);

void main() {
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: _backgroundColor,
        useMaterial3: true,
        fontFamily: 'Roboto', // Sistem fontu, iOS için San Francisco varsayılır
      ),
      home: const ModeSelectPage(),
    );
  }
}

class ModeSelectPage extends ConsumerStatefulWidget {
  const ModeSelectPage({super.key});

  static const routeName = 'modeSelect';

  @override
  ConsumerState<ModeSelectPage> createState() => _ModeSelectPageState();
}

class _ModeSelectPageState extends ConsumerState<ModeSelectPage> {
  bool _isAccentCollapsed = true;

  void _onAccentChanged(int index) {
    ref.read(accentColorProvider.notifier).setAccentIndex(index);
  }

  void _onAccentCollapsedToggle() {
    setState(() {
      _isAccentCollapsed = !_isAccentCollapsed;
    });
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);

    final authState = ref.watch(authControllerProvider);
    final user = authState.value;
    final displayName = user?.displayName;
    final username =
        displayName != null && displayName.trim().isNotEmpty
            ? displayName.trim()
            : 'User';
    final avatarInitial =
        user == null || user.isGuestMode || username.isEmpty
            ? '?'
            : username[0].toUpperCase();

    final accentIndex = ref.watch(accentColorProvider);
    final accentColor = ref.read(accentColorProvider.notifier).currentColor;

    return Scaffold(
      extendBody: true,
      backgroundColor: _backgroundColor,
      body: Stack(
        children: [
          Positioned(
            top: -100,
            right: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accentColor.withValues(alpha: 0.05),
                boxShadow: [
                  BoxShadow(
                    color: accentColor.withValues(alpha: 0.05),
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
            bottom: false,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 120),
              physics: const BouncingScrollPhysics(),
              children: [
                _HomeHeader(
                  username: username,
                  avatarInitial: avatarInitial,
                  accentColor: accentColor,
                  accentIndex: accentIndex,
                  onAccentChanged: _onAccentChanged,
                  isAccentCollapsed: _isAccentCollapsed,
                  onAccentCollapsedToggle: _onAccentCollapsedToggle,
                ),
                const SizedBox(height: 32),
                _WordMatchHeroCard(accentColor: accentColor),
                const SizedBox(height: 24),
                const _SectionTitle(title: 'Özellikler'),
                const SizedBox(height: 16),
                _FeatureGrid(accentColor: accentColor),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _GlassBottomNavBar(
        selectedIndex: 0,
        accentColor: accentColor,
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: _secondaryTextColor.withValues(alpha: 0.6),
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.5,
        ),
      ),
    );
  }
}

class _HomeHeader extends ConsumerWidget {
  final String username;
  final String avatarInitial;
  final Color accentColor;
  final int accentIndex;
  final ValueChanged<int> onAccentChanged;
  final bool isAccentCollapsed;
  final VoidCallback onAccentCollapsedToggle;

  const _HomeHeader({
    required this.username,
    required this.avatarInitial,
    required this.accentColor,
    required this.accentIndex,
    required this.onAccentChanged,
    required this.isAccentCollapsed,
    required this.onAccentCollapsedToggle,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(userStatsControllerProvider);
    final settingsAsync = ref.watch(userSettingsControllerProvider);

    final currentStreak = statsAsync.valueOrNull?.currentStreakDays ?? 1;
    final streakGoal = settingsAsync.valueOrNull?.streakGoal ?? 10;

    return Row(
      children: [
        GestureDetector(
          onTap: () => showAccountSheet(context),
          child: Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: accentColor.withValues(alpha: 0.5),
                width: 1.5,
              ),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                const CircleAvatar(
                  radius: 24,
                  backgroundImage: NetworkImage(
                    'https://i.pravatar.cc/150?img=11',
                  ),
                  backgroundColor: Color(0xFF2C2C2E),
                ),
                Text(
                  avatarInitial,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
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
                  Expanded(
                    child: Text(
                      'Merhaba $username',
                      style: const TextStyle(
                        color: _primaryTextColor,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 6),
                  _AccentSelector(
                    selectedIndex: accentIndex,
                    onSelected: onAccentChanged,
                    isCollapsed: isAccentCollapsed,
                    onCollapsedToggle: onAccentCollapsedToggle,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _SegmentedProgressBar(
                      totalSegments: streakGoal,
                      filledSegments:
                          currentStreak > streakGoal
                              ? streakGoal
                              : currentStreak,
                      accentColor: accentColor,
                    ),
                  ),
                  const SizedBox(width: 8),

                  Text(
                    '$currentStreak / $streakGoal',
                    style: const TextStyle(
                      color: _secondaryTextColor,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '🔥 $currentStreak Günlük Seri',
                    style: TextStyle(
                      color: Colors.orangeAccent.shade200,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SegmentedProgressBar extends StatelessWidget {
  final int totalSegments;
  final int filledSegments;
  final Color accentColor;

  const _SegmentedProgressBar({
    required this.totalSegments,
    required this.filledSegments,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(totalSegments, (index) {
        final isFilled = index < filledSegments;
        return Expanded(
          child: Container(
            height: 5,
            margin: EdgeInsets.only(right: index == totalSegments - 1 ? 0 : 3),
            decoration: BoxDecoration(
              gradient:
                  isFilled
                      ? LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          accentColor.withValues(alpha: 0.95),
                          accentColor.withValues(alpha: 0.6),
                        ],
                      )
                      : const LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [Color(0xFF2C2C2E), Color(0xFF1C1C1E)],
                      ),
              borderRadius: BorderRadius.circular(999),
              boxShadow:
                  isFilled
                      ? [
                        BoxShadow(
                          color: accentColor.withValues(alpha: 0.7),
                          blurRadius: 10,
                          spreadRadius: 0.5,
                          offset: const Offset(0, 0),
                        ),
                      ]
                      : [],
            ),
          ),
        );
      }),
    );
  }
}

class _WordMatchHeroCard extends StatelessWidget {
  final Color accentColor;

  const _WordMatchHeroCard({required this.accentColor});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.go('/word-match/sets'),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF2C2C2E), Color(0xFF0A0A0C)],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.05),
            width: 1,
          ),
        ),
        child: Stack(
          children: [
            // Arka plan dekoratif ikon (Büyük, silik ve hafif eğimli)
            Positioned(
              right: -20,
              bottom: -20,
              child: Transform.rotate(
                angle: -0.25,
                child: Icon(
                  Icons.grid_view_rounded,
                  size: 180,
                  color: accentColor.withValues(alpha: 0.18),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: accentColor.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'GÜNÜN EGZERSİZİ',
                          style: TextStyle(
                            color: accentColor,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Word Practice',
                        style: TextStyle(
                          color: _primaryTextColor,
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Kelime dağarcığını geliştirmenin\nen pratik yolu.',
                        style: TextStyle(
                          color: _secondaryTextColor.withValues(alpha: 0.8),
                          fontSize: 14,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 5),
                    ],
                  ),
                  Container(
                    height: 35,
                    width: 160,
                    decoration: BoxDecoration(
                      color: _primaryTextColor,
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.white.withValues(alpha: 0.2),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Text(
                          'Başla',
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(
                          Icons.play_arrow_rounded,
                          color: Colors.black,
                          size: 20,
                        ),
                      ],
                    ),
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

class _FeatureGrid extends StatelessWidget {
  final Color accentColor;

  const _FeatureGrid({required this.accentColor});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _EliteCard(
                icon: Icons.my_library_books_outlined,
                iconColor: accentColor,
                title: 'Grammar',
                subtitle: 'Dil Bilgisi',
                contentOffset: 6,
                onTap: () => context.go('/grammar'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _EliteCard(
                icon: Icons.sports_esports_outlined,
                iconColor: accentColor,
                title: 'Mini Games',
                subtitle: 'Eğlence',
                iconSize: 32,
                contentOffset: 6,
                onTap: () => context.go('/mini-games'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _EliteCard(
          icon: Icons.groups_3_rounded,
          iconColor: accentColor,
          title: 'Multiplayer',
          subtitle: 'Arkadaşlarınla gerçek zamanlı yarış',
          isWide: true,
          onTap: () => context.go('/multiplayer'),
        ),
      ],
    );
  }
}

class _EliteCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool isWide;
  final VoidCallback onTap;
  final double iconSize;
  final double contentOffset;

  const _EliteCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.isWide = false,
    required this.onTap,
    this.iconSize = 26,
    this.contentOffset = 0,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: isWide ? null : 160,
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
        child: Stack(
          children: [
            isWide
                ? Row(
                  children: [
                    _buildIconBox(),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              color: _primaryTextColor,
                              fontWeight: FontWeight.w700,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            subtitle,
                            style: TextStyle(
                              color: _secondaryTextColor,
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: _borderSideColor.withValues(alpha: 0.3),
                    ),
                  ],
                )
                : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (contentOffset > 0) SizedBox(height: contentOffset),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildIconBox(),
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: _secondaryTextColor.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      title,
                      style: const TextStyle(
                        color: _primaryTextColor,
                        fontWeight: FontWeight.w800,
                        fontSize: 23,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: _secondaryTextColor,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
          ],
        ),
      ),
    );
  }

  Widget _buildIconBox() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: iconColor.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(icon, color: iconColor, size: iconSize),
    );
  }
}

class _AccentSelector extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final bool isCollapsed;
  final VoidCallback onCollapsedToggle;

  const _AccentSelector({
    required this.selectedIndex,
    required this.onSelected,
    required this.isCollapsed,
    required this.onCollapsedToggle,
  });

  @override
  Widget build(BuildContext context) {
    final colors = [_accentColor, _accentPurple, _accentCyan, _accentRed];

    if (isCollapsed) {
      final color = colors[selectedIndex.clamp(0, colors.length - 1)];
      return GestureDetector(
        onDoubleTap: onCollapsedToggle,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: onCollapsedToggle,
              child: Icon(
                Icons.chevron_left,
                size: 14,
                color: Colors.white.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: color.withValues(alpha: 0.9),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.4),
                    blurRadius: 8,
                    spreadRadius: 0.5,
                  ),
                ],
              ),
              child: Container(
                width: 13,
                height: 13,
                decoration: BoxDecoration(shape: BoxShape.circle, color: color),
              ),
            ),
          ],
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...List.generate(colors.length, (index) {
          final color = colors[index];
          final isSelected = index == selectedIndex;
          return GestureDetector(
            onTap: () => onSelected(index),
            onDoubleTap: isSelected ? onCollapsedToggle : null,
            child: Container(
              margin: EdgeInsets.only(
                right: index == colors.length - 1 ? 0 : 8,
              ),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color:
                      isSelected
                          ? color.withValues(alpha: 0.9)
                          : Colors.white.withValues(alpha: 0.25),
                  width: isSelected ? 2 : 1,
                ),
                boxShadow:
                    isSelected
                        ? [
                          BoxShadow(
                            color: color.withValues(alpha: 0.4),
                            blurRadius: 8,
                            spreadRadius: 0.5,
                          ),
                        ]
                        : [],
              ),
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(shape: BoxShape.circle, color: color),
              ),
            ),
          );
        }),
        const SizedBox(width: 4),
        GestureDetector(
          onTap: onCollapsedToggle,
          child: Icon(
            Icons.chevron_right,
            size: 14,
            color: Colors.white.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }
}

class _GlassBottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final Color accentColor;

  const _GlassBottomNavBar({
    required this.selectedIndex,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10), // Buzlu Cam efekti
        child: Container(
          decoration: BoxDecoration(
            color: _backgroundColor.withValues(alpha: 0.85),
            border: Border(
              top: BorderSide(
                color: Colors.white.withValues(alpha: 0.05),
                width: 0.5,
              ),
            ),
          ),
          child: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.transparent, // Konteyner rengini kullan
            elevation: 0,
            currentIndex: selectedIndex,
            onTap: (_) {},
            selectedItemColor: accentColor,
            unselectedItemColor: _secondaryTextColor.withValues(alpha: 0.6),
            selectedIconTheme: IconThemeData(color: accentColor),
            selectedLabelStyle: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              height: 2,
              color: accentColor,
            ),
            unselectedLabelStyle: const TextStyle(fontSize: 10, height: 2),
            showUnselectedLabels: true,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_filled),
                label: 'Ana Sayfa',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.explore_outlined),
                label: 'Keşfet',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.insert_chart_outlined_rounded),
                label: 'Analiz',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_outline_rounded),
                label: 'Profil',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
