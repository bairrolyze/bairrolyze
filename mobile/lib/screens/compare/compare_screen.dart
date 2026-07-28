import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/compare_provider.dart';
import '../../providers/pro_provider.dart';
import '../paywall/paywall_screen.dart';

const Color _kBg = Color(0xFF060B14);
const Color _kSurface = Color(0xFF0D1625);
const Color _kSurface2 = Color(0xFF131F33);
const Color _kAccent = Color(0xFF3B82F6);
const Color _kBorder = Color(0xFF1A2845);

const _catColors = <String, Color>{
  'transportation': Color(0xFF29B6F6),
  'education': Color(0xFF66BB6A),
  'healthcare': Color(0xFFEF5350),
  'shopping': Color(0xFFFFA726),
  'safety': Color(0xFFAB47BC),
  'recreation': Color(0xFF26C6DA),
  'religion': Color(0xFF8D6E63),
};

Color _colorForCategory(String id) =>
    _catColors[id] ?? _kAccent;

class CompareScreen extends ConsumerWidget {
  const CompareScreen({super.key});

  static Future<void> show(BuildContext context) {
    return Navigator.push(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => const CompareScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final compare = ref.watch(compareProvider);
    final pro = ref.watch(proProvider);

    final bool showPaywall = !pro.isPro && compare.items.length > 2;
    final List<SavedProperty> visibleItems =
        pro.isPro ? compare.items : compare.items.take(2).toList();

    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Header(
              onClear: compare.items.isEmpty
                  ? null
                  : () => ref.read(compareProvider.notifier).clear(),
            ),
            if (showPaywall) _PaywallBanner(),
            Expanded(
              child: compare.items.isEmpty
                  ? const _EmptyState(
                      icon: Icons.compare_arrows_rounded,
                      title: 'No properties saved',
                      subtitle:
                          "Analyze an address then tap 'Save to Compare' to add it here.",
                    )
                  : visibleItems.length == 1
                      ? const _EmptyState(
                          icon: Icons.compare_arrows_rounded,
                          title: 'Add another property',
                          subtitle:
                              'Save one more analysis to start comparing.',
                        )
                      : _CompareTable(items: visibleItems),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────────

class _Header extends ConsumerWidget {
  final VoidCallback? onClear;
  const _Header({this.onClear});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close, color: Colors.white, size: 22),
          ),
          const Expanded(
            child: Text(
              'Compare Properties',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (onClear != null)
            TextButton(
              onPressed: onClear,
              child: Text(
                'Clear all',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.55),
                  fontSize: 13,
                ),
              ),
            )
          else
            const SizedBox(width: 60),
        ],
      ),
    );
  }
}

// ── Paywall banner ────────────────────────────────────────────────────────────

class _PaywallBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kSurface2,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Unlock Pro to compare more than 2 properties',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF3B82F6), Color(0xFF6366F1)],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: TextButton(
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () => PaywallScreen.show(context),
              child: const Text(
                'View Pro Features',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Empty / placeholder state ─────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 48,
              color: Colors.white.withValues(alpha: 0.25),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.45),
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Main comparison table ─────────────────────────────────────────────────────

class _CompareTable extends ConsumerWidget {
  final List<SavedProperty> items;
  const _CompareTable({required this.items});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Collect categories from the first property, sorted by score desc.
    final firstCategories = items.first.score.categories;
    final sortedCatKeys = firstCategories.keys.toList()
      ..sort((a, b) => firstCategories[b]!.score.compareTo(firstCategories[a]!.score));

    // Determine winner by highest overall score.
    final winnerIndex = () {
      int idx = 0;
      double best = items[0].score.overall;
      for (int i = 1; i < items.length; i++) {
        if (items[i].score.overall > best) {
          best = items[i].score.overall;
          idx = i;
        }
      }
      return idx;
    }();

    const double labelColWidth = 100;

    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: IntrinsicWidth(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Property header row ──────────────────────────────────────
              _PropertyHeaderRow(
                items: items,
                winnerIndex: winnerIndex,
                labelColWidth: labelColWidth,
                onRemove: (id) =>
                    ref.read(compareProvider.notifier).remove(id),
              ),

              // Divider
              Divider(
                height: 1,
                thickness: 1,
                color: Colors.white.withValues(alpha: 0.05),
              ),

              // ── Category rows ────────────────────────────────────────────
              ...sortedCatKeys.map((catKey) {
                return _CategoryRow(
                  catKey: catKey,
                  items: items,
                  labelColWidth: labelColWidth,
                );
              }),

              // Divider before winner row
              Divider(
                height: 1,
                thickness: 1,
                color: Colors.white.withValues(alpha: 0.05),
              ),

              // ── Best-overall winner row ──────────────────────────────────
              _WinnerRow(
                items: items,
                winnerIndex: winnerIndex,
                labelColWidth: labelColWidth,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Property header row ───────────────────────────────────────────────────────

class _PropertyHeaderRow extends StatelessWidget {
  final List<SavedProperty> items;
  final int winnerIndex;
  final double labelColWidth;
  final void Function(String id) onRemove;

  const _PropertyHeaderRow({
    required this.items,
    required this.winnerIndex,
    required this.labelColWidth,
    required this.onRemove,
  });

  Color _scoreColor(double score) {
    if (score >= 80) return const Color(0xFF66BB6A);
    if (score >= 60) return const Color(0xFFFFA726);
    return const Color(0xFFEF5350);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: labelColWidth),
          ...items.map(
            (prop) => Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Column(
                  children: [
                    // Score ring
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _scoreColor(prop.score.overall)
                            .withValues(alpha: 0.15),
                        border: Border.all(
                          color: _scoreColor(prop.score.overall),
                          width: 2,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        prop.score.overall.round().toString(),
                        style: TextStyle(
                          color: _scoreColor(prop.score.overall),
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Address
                    Text(
                      prop.address.displayAddress,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Remove button
                    GestureDetector(
                      onTap: () => onRemove(prop.id),
                      child: Icon(
                        Icons.close,
                        size: 16,
                        color: Colors.white.withValues(alpha: 0.35),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Category row ──────────────────────────────────────────────────────────────

class _CategoryRow extends StatelessWidget {
  final String catKey;
  final List<SavedProperty> items;
  final double labelColWidth;

  const _CategoryRow({
    required this.catKey,
    required this.items,
    required this.labelColWidth,
  });

  @override
  Widget build(BuildContext context) {
    // Get label from first property that has this category.
    final label = items
            .map((p) => p.score.categories[catKey]?.label)
            .firstWhere((l) => l != null, orElse: () => catKey) ??
        catKey;

    final catColor = _colorForCategory(catKey);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Category label column
              SizedBox(
                width: labelColWidth,
                child: Padding(
                  padding: const EdgeInsets.only(left: 18),
                  child: Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              // Score cells
              ...items.map((prop) {
                final catScore = prop.score.categories[catKey];
                final scoreVal = catScore?.score ?? 0.0;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          scoreVal.round().toString(),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final fraction = (scoreVal / 100).clamp(0.0, 1.0);
                            return Stack(
                              children: [
                                // Track
                                Container(
                                  height: 4,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.06),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                                // Fill
                                FractionallySizedBox(
                                  widthFactor: fraction,
                                  child: Container(
                                    height: 4,
                                    decoration: BoxDecoration(
                                      color: catColor,
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
        Divider(
          height: 1,
          thickness: 1,
          color: Colors.white.withValues(alpha: 0.05),
        ),
      ],
    );
  }
}

// ── Winner row ────────────────────────────────────────────────────────────────

class _WinnerRow extends StatelessWidget {
  final List<SavedProperty> items;
  final int winnerIndex;
  final double labelColWidth;

  const _WinnerRow({
    required this.items,
    required this.winnerIndex,
    required this.labelColWidth,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _kSurface,
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: labelColWidth,
            child: Padding(
              padding: const EdgeInsets.only(left: 18),
              child: Text(
                'Best overall',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          ...List.generate(items.length, (i) {
            final isWinner = i == winnerIndex;
            return Expanded(
              child: Center(
                child: isWinner
                    ? Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: Color(0xFF166534),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check,
                          color: Color(0xFF4ADE80),
                          size: 16,
                        ),
                      )
                    : const SizedBox(height: 28),
              ),
            );
          }),
        ],
      ),
    );
  }
}
