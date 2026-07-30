import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../auth/logic/auth_controller.dart';
import '../../auth/ui/account_sheet.dart';
import '../../user_stats/logic/user_stats_controller.dart';
import '../../profile_settings/logic/user_settings_controller.dart';
import '../../profile_settings/models/learning_profile_presentation.dart';
import '../../profile_settings/models/user_settings.dart';
import '../../../core/providers/accent_color_provider.dart';
import '../../../core/widgets/responsive_content.dart';
import '../../../l10n/app_localizations.dart';

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
    final l10n = AppLocalizations.of(context)!;

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
            child: ResponsiveContent(
              child: ListView(
                key: const PageStorageKey<String>('home-scroll'),
                padding: const EdgeInsets.fromLTRB(4, 10, 4, 32),
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
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
                  LearningStartCard(accentColor: accentColor),
                  const SizedBox(height: 24),
                  _SectionTitle(title: l10n.homeLearningModes),
                  const SizedBox(height: 16),
                  LearningModesGrid(accentColor: accentColor),
                ],
              ),
            ),
          ),
        ],
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

String learningStartDestination(String? learningGoal) => switch (learningGoal) {
  'grammar_practice' => '/grammar',
  'mini_games' => '/mini-games',
  'multiplayer' => '/multiplayer',
  _ => '/word-match/sets',
};

class LearningStartCard extends ConsumerWidget {
  final Color accentColor;
  final UserSettings? settingsOverride;
  final ValueChanged<String>? onStart;

  const LearningStartCard({
    required this.accentColor,
    this.settingsOverride,
    this.onStart,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final settings =
        settingsOverride ??
        ref.watch(userSettingsControllerProvider).valueOrNull;
    final goal = settings?.learningGoal;
    final destination = learningStartDestination(goal);
    final profileLabel = [
      if (settings?.cefrLevel != null) l10n.cefrLabel(settings!.cefrLevel!),
      if (goal != null) l10n.learningGoalLabel(goal),
    ].join(' · ');

    return Semantics(
      button: true,
      label: l10n.startLearning,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: () {
          final callback = onStart;
          if (callback != null) {
            callback(destination);
          } else {
            context.go(destination);
          }
        },
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
                            profileLabel.isEmpty
                                ? l10n.learningProfile
                                : profileLabel,
                            style: TextStyle(
                              color: accentColor,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n.startLearning,
                          style: const TextStyle(
                            color: _primaryTextColor,
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          goal == null
                              ? l10n.wordMatchCardSubtitle
                              : l10n.learningGoalLabel(goal),
                          style: TextStyle(
                            color: _secondaryTextColor.withValues(alpha: 0.8),
                            fontSize: 14,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 5),
                      ],
                    ),
                    ConstrainedBox(
                      constraints: const BoxConstraints(
                        minHeight: 48,
                        maxWidth: 240,
                      ),
                      child: DecoratedBox(
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
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Flexible(
                                child: Text(
                                  l10n.startLearning,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(
                                Icons.play_arrow_rounded,
                                color: Colors.black,
                                size: 20,
                              ),
                            ],
                          ),
                        ),
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

class LearningModesGrid extends StatelessWidget {
  final Color accentColor;
  final ValueChanged<String>? onNavigate;

  const LearningModesGrid({
    required this.accentColor,
    this.onNavigate,
    super.key,
  });

  void _open(BuildContext context, String location) {
    final callback = onNavigate;
    if (callback != null) {
      callback(location);
    } else {
      context.go(location);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cards = [
      _EliteCard(
        icon: Icons.my_library_books_outlined,
        iconColor: accentColor,
        title: l10n.trainingCardTitle,
        subtitle: l10n.trainingCardSubtitle,
        isWide: true,
        onTap: () => _open(context, '/grammar'),
      ),
      _EliteCard(
        icon: Icons.sports_esports_outlined,
        iconColor: accentColor,
        title: l10n.miniGamesCardTitle,
        subtitle: l10n.miniGamesCardSubtitle,
        iconSize: 32,
        isWide: true,
        onTap: () => _open(context, '/mini-games'),
      ),
      _EliteCard(
        icon: Icons.groups_3_rounded,
        iconColor: accentColor,
        title: l10n.arenaTitle,
        subtitle: l10n.multiplayerSubtitle,
        isWide: true,
        onTap: () => _open(context, '/multiplayer'),
      ),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 600 ? 2 : 1;
        final width = (constraints.maxWidth - ((columns - 1) * 16)) / columns;
        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children:
              cards.map((card) => SizedBox(width: width, child: card)).toList(),
        );
      },
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

  const _EliteCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.isWide = false,
    required this.onTap,
    this.iconSize = 26,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '$title. $subtitle',
      excludeSemantics: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Container(
            constraints: const BoxConstraints(minHeight: 112),
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
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildIconBox(),
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: _secondaryTextColor.withValues(
                                  alpha: 0.2,
                                ),
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
    final l10n = AppLocalizations.of(context)!;
    final colors = [_accentColor, _accentPurple, _accentCyan, _accentRed];

    if (isCollapsed) {
      final color = colors[selectedIndex.clamp(0, colors.length - 1)];
      return Semantics(
        button: true,
        label: l10n.accentSelectorExpand,
        child: IconButton(
          onPressed: onCollapsedToggle,
          tooltip: l10n.accentSelectorExpand,
          icon: Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: color.withValues(alpha: 0.9), width: 2),
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
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...List.generate(colors.length, (index) {
          final color = colors[index];
          final isSelected = index == selectedIndex;
          return Semantics(
            selected: isSelected,
            label: l10n.accentColorOption(index + 1),
            child: IconButton(
              onPressed: () => onSelected(index),
              tooltip: l10n.accentColorOption(index + 1),
              icon: Container(
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
                child: SizedBox.square(
                  dimension: 12,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: color,
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
        IconButton(
          onPressed: onCollapsedToggle,
          tooltip: l10n.accentSelectorCollapse,
          icon: const Icon(Icons.chevron_right),
        ),
      ],
    );
  }
}
