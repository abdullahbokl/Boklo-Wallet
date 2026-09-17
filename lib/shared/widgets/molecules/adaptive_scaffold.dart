import 'package:boklo/shared/responsive/responsive_builder.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Persistent navigation shell: bottom [NavigationBar] on phones,
/// [NavigationRail] on tablets and wider. Used by the router's
/// [StatefulShellRoute] so each tab keeps its own navigation stack.
class AdaptiveScaffold extends StatelessWidget {
  const AdaptiveScaffold({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  static const List<(String, IconData, IconData)> _destinations = [
    ('Home', Icons.home_outlined, Icons.home),
    ('Send', Icons.send_outlined, Icons.send),
    ('Requests', Icons.receipt_long_outlined, Icons.receipt_long),
    ('Contacts', Icons.people_outlined, Icons.people),
    ('Profile', Icons.person_outlined, Icons.person),
  ];

  void _goBranch(int index) {
    navigationShell.goBranch(
      index,
      // A tap on the current branch pops its stack back to the root.
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      mobile: (_, _) => Scaffold(
        body: navigationShell,
        bottomNavigationBar: NavigationBar(
          selectedIndex: navigationShell.currentIndex,
          onDestinationSelected: _goBranch,
          destinations: [
            for (final (label, outlined, filled) in _destinations)
              NavigationDestination(
                icon: Icon(outlined),
                selectedIcon: Icon(filled),
                label: label,
              ),
          ],
        ),
      ),
      tablet: (_, _) => _rail(context),
      desktop: (_, _) => _rail(context),
    );
  }

  Widget _rail(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: navigationShell.currentIndex,
            onDestinationSelected: _goBranch,
            labelType: NavigationRailLabelType.all,
            destinations: [
              for (final (label, outlined, filled) in _destinations)
                NavigationRailDestination(
                  icon: Icon(outlined),
                  selectedIcon: Icon(filled),
                  label: Text(label),
                ),
            ],
          ),
          const VerticalDivider(width: 1, thickness: 1),
          Expanded(child: navigationShell),
        ],
      ),
    );
  }
}
