import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/app_theme.dart';
import '../../providers/shell_provider.dart';
import '../explorer/explorer_screen.dart';
import '../home/home_screen.dart';
import '../neighborhood/neighborhood_screen.dart';
import '../saved/saved_screen.dart';
import '../settings/settings_screen.dart';

// IndexedStack indices. Results (index 1) is shown after an analysis rather
// than being a bottom-bar destination, so the existing `state = 1` calls that
// reveal it keep working unchanged.
class _Tab {
  static const home = 0;
  static const results = 1;
  static const explore = 2;
  static const saved = 3;
  static const profile = 4;
}

class MainShell extends ConsumerWidget {
  const MainShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tab = ref.watch(shellTabProvider);
    final p = AppPalette.of(context);

    return Scaffold(
      backgroundColor: p.bg,
      body: IndexedStack(
        index: tab,
        children: const [
          HomeScreen(),          // 0 — Home
          NeighborhoodScreen(),  // 1 — Results (post-analyse)
          ExplorerScreen(),      // 2 — Explore
          SavedScreen(),         // 3 — Saved
          SettingsScreen(),      // 4 — Profile
        ],
      ),
      bottomNavigationBar: _BottomNav(
        current: tab,
        onSelect: (i) => ref.read(shellTabProvider.notifier).state = i,
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  final int current;
  final ValueChanged<int> onSelect;

  const _BottomNav({required this.current, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final bottom = MediaQuery.of(context).padding.bottom;

    // Results (index 1) belongs to the Home/search flow, so Home stays lit.
    final homeActive = current == _Tab.home || current == _Tab.results;

    return Container(
      decoration: BoxDecoration(
        color: p.surface,
        border: Border(top: BorderSide(color: p.border, width: 1)),
      ),
      padding: EdgeInsets.only(bottom: bottom),
      child: SizedBox(
        height: 62,
        child: Row(
          children: [
            _NavItem(
              icon: Icons.home_outlined,
              activeIcon: Icons.home_rounded,
              label: 'Home',
              active: homeActive,
              onTap: () => onSelect(_Tab.home),
            ),
            _NavItem(
              icon: Icons.explore_outlined,
              activeIcon: Icons.explore_rounded,
              label: 'Explore',
              active: current == _Tab.explore,
              onTap: () => onSelect(_Tab.explore),
            ),
            // Center "+" — analyse a new property (jumps to Home search).
            _AnalyseFab(onTap: () => onSelect(_Tab.home)),
            _NavItem(
              icon: Icons.bookmark_border_rounded,
              activeIcon: Icons.bookmark_rounded,
              label: 'Saved',
              active: current == _Tab.saved,
              onTap: () => onSelect(_Tab.saved),
            ),
            _NavItem(
              icon: Icons.person_outline_rounded,
              activeIcon: Icons.person_rounded,
              label: 'Profile',
              active: current == _Tab.profile,
              onTap: () => onSelect(_Tab.profile),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final color = active ? AppColors.accent : p.textTertiary;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                active ? activeIcon : icon,
                key: ValueKey(active),
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 10.5,
                fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                letterSpacing: 0.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnalyseFab extends StatelessWidget {
  final VoidCallback onTap;
  const _AnalyseFab({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Expanded(
      child: Center(
        child: GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.accent, AppColors.accent2],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              border: Border.all(color: p.surface, width: 3),
              boxShadow: [
                BoxShadow(
                  color: AppColors.accent.withValues(alpha: 0.45),
                  blurRadius: 16,
                  spreadRadius: -2,
                ),
              ],
            ),
            child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
          ),
        ),
      ),
    );
  }
}
