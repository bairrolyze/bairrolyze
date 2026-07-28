import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/shell_provider.dart';
import '../explorer/explorer_screen.dart';
import '../home/home_screen.dart';
import '../neighborhood/neighborhood_screen.dart';
import '../settings/settings_screen.dart';

const kShellBg      = Color(0xFF060B14);
const kShellSurface = Color(0xFF0D1625);
const kShellBorder  = Color(0xFF1A2845);
const kShellAccent  = Color(0xFF3B82F6);

class MainShell extends ConsumerWidget {
  const MainShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tab = ref.watch(shellTabProvider);

    return Scaffold(
      backgroundColor: kShellBg,
      body: IndexedStack(
        index: tab,
        children: const [
          HomeScreen(),
          NeighborhoodScreen(),
          ExplorerScreen(),
          SettingsScreen(),
        ],
      ),
      bottomNavigationBar: _BottomNav(
        current: tab,
        onTap: (i) => ref.read(shellTabProvider.notifier).state = i,
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  final int current;
  final ValueChanged<int> onTap;

  const _BottomNav({required this.current, required this.onTap});

  static const _items = [
    (Icons.search_rounded,         Icons.search_rounded,         'Search'),
    (Icons.explore_outlined,       Icons.explore_rounded,        'Explore'),
    (Icons.travel_explore_rounded, Icons.travel_explore_rounded, 'Discover'),
    (Icons.person_outline_rounded, Icons.person_rounded,         'You'),
  ];

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;
    return Container(
      decoration: const BoxDecoration(
        color: kShellSurface,
        border: Border(top: BorderSide(color: kShellBorder, width: 1)),
      ),
      padding: EdgeInsets.only(bottom: bottom),
      child: Row(
        children: List.generate(_items.length, (i) {
          final active = i == current;
          final item = _items[i];
          return Expanded(
            child: GestureDetector(
              onTap: () => onTap(i),
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        active ? item.$2 : item.$1,
                        key: ValueKey(active),
                        color: active
                            ? kShellAccent
                            : Colors.white.withValues(alpha: 0.32),
                        size: 23,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.$3,
                      style: TextStyle(
                        color: active
                            ? kShellAccent
                            : Colors.white.withValues(alpha: 0.32),
                        fontSize: 10.5,
                        fontWeight:
                            active ? FontWeight.w600 : FontWeight.w400,
                        letterSpacing: 0.1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
