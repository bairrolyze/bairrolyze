import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/app_localizations.dart';
import '../../providers/analysis_provider.dart';
import '../../widgets/home/score_badge.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);
    final history = ref.watch(searchHistoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l.historyTitle),
        actions: [
          if (history.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_rounded),
              onPressed: () => _confirmClear(context, ref),
              tooltip: l.historyClearTooltip,
            ),
        ],
      ),
      body: history.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.history_rounded,
                    size: 72,
                    color: theme.colorScheme.outlineVariant,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l.historyEmptyTitle,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l.historyEmptyBody,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: history.length,
              itemBuilder: (context, index) {
                final entry = history[index];
                return Dismissible(
                  key: Key(entry.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    color: theme.colorScheme.errorContainer,
                    child: Icon(Icons.delete_rounded, color: theme.colorScheme.onErrorContainer),
                  ),
                  onDismissed: (_) => ref.read(searchHistoryProvider.notifier).remove(entry.id),
                  child: Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: ScoreBadge(score: entry.score.overall.round(), size: 48),
                      title: Text(
                        entry.address.displayAddress,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                      ),
                      subtitle: Text(
                        _formatDate(l, entry.timestamp),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () {
                        ref.read(analysisProvider.notifier).analyze(
                              entry.address.displayAddress,
                              countryCode: entry.address.countryCode,
                            );
                        context.pushNamed('dashboard', extra: entry.address);
                      },
                    ),
                  ),
                );
              },
            ),
    );
  }

  String _formatDate(AppLocalizations l, DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 60) return l.timeMinutesAgo(diff.inMinutes);
    if (diff.inHours < 24) return l.timeHoursAgo(diff.inHours);
    if (diff.inDays < 7) return l.timeDaysAgo(diff.inDays);
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  void _confirmClear(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.historyClearTitle),
        content: Text(l.historyClearBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l.commonCancel),
          ),
          FilledButton(
            onPressed: () {
              ref.read(searchHistoryProvider.notifier).clear();
              Navigator.pop(ctx);
            },
            child: Text(l.commonClear),
          ),
        ],
      ),
    );
  }
}
