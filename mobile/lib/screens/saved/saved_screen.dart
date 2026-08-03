import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/app_theme.dart';
import '../../providers/analysis_provider.dart';
import '../../providers/saved_provider.dart';
import '../../providers/shell_provider.dart';
import '../../widgets/home/recent_search_tile.dart';

/// Saved / recent searches tab. Lists every analysed address as a premium
/// card; tapping re-opens the saved analysis, swiping removes it.
class SavedScreen extends ConsumerWidget {
  const SavedScreen({super.key});

  Future<void> _open(WidgetRef ref, SearchHistoryEntry entry) async {
    await ref.read(analysisProvider.notifier).loadFromHistory(entry);
    ref.read(shellTabProvider.notifier).state = 1;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(savedProvider);
    final p = AppPalette.of(context);

    return Scaffold(
      backgroundColor: p.bg,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            // Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(22, 18, 22, 18),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Saved',
                      style: TextStyle(
                        color: p.textPrimary,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.8,
                      ),
                    ),
                    if (history.isNotEmpty)
                      GestureDetector(
                        onTap: () =>
                            ref.read(savedProvider.notifier).clear(),
                        behavior: HitTestBehavior.opaque,
                        child: Text(
                          'Clear all',
                          style: TextStyle(
                            color: p.textTertiary,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            if (history.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _Empty(),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, i) {
                    final entry = history[i];
                    return RecentSearchTile(
                      entry: entry,
                      onTap: () => _open(ref, entry),
                      onRemove: () => ref
                          .read(savedProvider.notifier)
                          .remove(entry.id),
                    );
                  },
                  childCount: history.length,
                ),
              ),

            const SliverToBoxAdapter(child: SizedBox(height: 40)),
          ],
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Icon(Icons.bookmark_border_rounded,
                  color: AppColors.accent, size: 34),
            ),
            const SizedBox(height: 18),
            Text(
              'No saved places yet',
              style: TextStyle(
                color: p.textPrimary,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Tap the bookmark on any analysis to\nsave it here for quick access.',
              textAlign: TextAlign.center,
              style: TextStyle(color: p.textTertiary, fontSize: 13.5, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}
