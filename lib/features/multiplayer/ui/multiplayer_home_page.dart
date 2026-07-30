import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:yunoo/l10n/app_localizations.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/gradient_background.dart';
import '../../../core/widgets/responsive_content.dart';

class MultiplayerHomePage extends StatelessWidget {
  const MultiplayerHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            tooltip: l10n.backAction,
            onPressed: () => context.canPop() ? context.pop() : context.go('/'),
          ),
          title: Text(l10n.multiplayerTitle),
        ),
        body: SafeArea(
          top: false,
          child: ResponsiveContent(
            maxWidth: 840,
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 24),
              children: [
                Semantics(
                  header: true,
                  child: Text(
                    l10n.multiplayerHeading,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.multiplayerDescription,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 24),
                _GameCard(
                  title: l10n.wordBattleTitle,
                  subtitle: l10n.wordBattleSubtitle,
                  description: l10n.wordBattleDescription,
                  icon: Icons.sports_esports_rounded,
                  color: AppColors.primary,
                  onTap: () => context.push('/lobby?from=multiplayer'),
                ),
                const SizedBox(height: 16),
                _GameCard(
                  title: l10n.grammarBattleTitle,
                  subtitle: l10n.grammarBattleSubtitle,
                  description: l10n.grammarBattleDescription,
                  icon: Icons.quiz_rounded,
                  color: AppColors.accent,
                  onTap: () => context.push('/multiplayer/grammar-arena'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GameCard extends StatelessWidget {
  const _GameCard({
    required this.title,
    required this.subtitle,
    required this.description,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final String description;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '$title. $subtitle. $description',
      excludeSemantics: true,
      child: Card(
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 120),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ExcludeSemantics(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.18),
                        shape: BoxShape.circle,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Icon(icon, color: color, size: 32),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(subtitle),
                        const SizedBox(height: 12),
                        Text(description),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  const ExcludeSemantics(child: Icon(Icons.chevron_right)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
