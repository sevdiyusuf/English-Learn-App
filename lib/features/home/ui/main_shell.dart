import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:yunoo/l10n/app_localizations.dart';

import '../../../core/widgets/responsive_content.dart';

class MainShell extends StatelessWidget {
  const MainShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  void _selectDestination(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final destinations = <_ShellDestination>[
      _ShellDestination(
        label: l10n.navigationHome,
        icon: Icons.grid_view_outlined,
        selectedIcon: Icons.grid_view_rounded,
      ),
      _ShellDestination(
        label: l10n.navigationSocial,
        icon: Icons.people_outline_rounded,
        selectedIcon: Icons.people_rounded,
      ),
      _ShellDestination(
        label: l10n.navigationStatistics,
        icon: Icons.analytics_outlined,
        selectedIcon: Icons.analytics_rounded,
      ),
      _ShellDestination(
        label: l10n.navigationProfile,
        icon: Icons.person_outline_rounded,
        selectedIcon: Icons.person_rounded,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final expanded =
            constraints.maxWidth >= ResponsiveContent.expandedBreakpoint;
        if (expanded) {
          return Scaffold(
            body: SafeArea(
              child: Row(
                children: [
                  NavigationRail(
                    selectedIndex: navigationShell.currentIndex,
                    onDestinationSelected: _selectDestination,
                    labelType: NavigationRailLabelType.all,
                    destinations:
                        destinations
                            .map(
                              (item) => NavigationRailDestination(
                                icon: Icon(item.icon),
                                selectedIcon: Icon(item.selectedIcon),
                                label: Text(item.label),
                              ),
                            )
                            .toList(),
                  ),
                  const VerticalDivider(width: 1),
                  Expanded(child: navigationShell),
                ],
              ),
            ),
          );
        }

        return Scaffold(
          body: navigationShell,
          bottomNavigationBar: SafeArea(
            top: false,
            child: NavigationBar(
              selectedIndex: navigationShell.currentIndex,
              onDestinationSelected: _selectDestination,
              destinations:
                  destinations
                      .map(
                        (item) => NavigationDestination(
                          icon: Icon(item.icon),
                          selectedIcon: Icon(item.selectedIcon),
                          label: item.label,
                          tooltip: item.label,
                        ),
                      )
                      .toList(),
            ),
          ),
        );
      },
    );
  }
}

class _ShellDestination {
  const _ShellDestination({
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
}
