import 'package:flutter/material.dart';

import '../config/app_config.dart';
import 'home/create_post_screen.dart';
import 'home/home_screen.dart';
import 'market/market_screen.dart';
import 'music/music_screen.dart';
import 'profile/profile_screen.dart';
import 'squads_screen.dart';

class RootShell extends StatefulWidget {
  const RootShell({super.key});

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  int _selectedIndex = 0;

  static const List<Widget> _pages = [
    HomeScreen(),
    SquadsScreen(),
    MusicScreen(),
    MarketScreen(),
    ProfileScreen(),
  ];

  static const _destinations = <_Destination>[
    _Destination(
      icon: Icons.home_outlined,
      selectedIcon: Icons.home_rounded,
      label: 'الرئيسية',
    ),
    _Destination(
      icon: Icons.groups_outlined,
      selectedIcon: Icons.groups_rounded,
      label: 'الفرق',
    ),
    _Destination(
      icon: Icons.music_note_outlined,
      selectedIcon: Icons.music_note_rounded,
      label: 'الأناشيد',
    ),
    _Destination(
      icon: Icons.storefront_outlined,
      selectedIcon: Icons.storefront_rounded,
      label: 'المتجر',
    ),
    _Destination(
      icon: Icons.person_outline,
      selectedIcon: Icons.person_rounded,
      label: 'حسابي',
    ),
  ];

  void _openCreatePost() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const CreatePostScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isDesktop = width >= 900;

    return Scaffold(
      body: SafeArea(
        child: isDesktop
            ? Row(
                children: [
                  _buildRail(context),
                  const VerticalDivider(width: 1),
                  Expanded(child: IndexedStack(index: _selectedIndex, children: _pages)),
                ],
              )
            : IndexedStack(index: _selectedIndex, children: _pages),
      ),
      bottomNavigationBar: isDesktop
          ? null
          : NavigationBar(
              selectedIndex: _selectedIndex,
              onDestinationSelected: (index) =>
                  setState(() => _selectedIndex = index),
              destinations: _destinations
                  .map(
                    (d) => NavigationDestination(
                      icon: Icon(d.icon),
                      selectedIcon: Icon(d.selectedIcon),
                      label: d.label,
                    ),
                  )
                  .toList(),
            ),
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton.extended(
              onPressed: _openCreatePost,
              icon: const Icon(Icons.edit_rounded),
              label: const Text('منشور جديد'),
            )
          : null,
    );
  }

  Widget _buildRail(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return NavigationRail(
      selectedIndex: _selectedIndex,
      onDestinationSelected: (index) => setState(() => _selectedIndex = index),
      labelType: NavigationRailLabelType.all,
      minExtendedWidth: 210,
      leading: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [colorScheme.primary, colorScheme.tertiary],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.explore_rounded,
                color: colorScheme.onPrimary,
                size: 22,
              ),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    AppConfig.appNameAr,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  Text(
                    AppConfig.appName,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      destinations: _destinations
          .map(
            (d) => NavigationRailDestination(
              icon: Icon(d.icon),
              selectedIcon: Icon(d.selectedIcon),
              label: Text(d.label),
            ),
          )
          .toList(),
    );
  }
}

class _Destination {
  final IconData icon;
  final IconData selectedIcon;
  final String label;

  const _Destination({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });
}