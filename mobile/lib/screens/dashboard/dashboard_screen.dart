import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/address_model.dart';
import '../../models/score_model.dart';
import '../../providers/analysis_provider.dart';
import '../../widgets/common/shimmer_card.dart';
import '../../widgets/score/category_card.dart';
import '../../widgets/score/ai_summary_card.dart';
import '../../widgets/score/overall_score_card.dart';
import '../../widgets/score/street_view_section.dart';
import '../../widgets/score/amenity_list_tile.dart';

class DashboardScreen extends ConsumerWidget {
  final AddressModel? address;

  const DashboardScreen({super.key, this.address});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final analysisState = ref.watch(analysisProvider);

    if (analysisState.isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Analyzing...')),
        body: const _LoadingSkeleton(),
      );
    }

    final result = analysisState.result;
    if (result == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Dashboard')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.search_off_rounded, size: 64),
              const SizedBox(height: 16),
              const Text('No analysis data available'),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => context.goNamed('home'),
                child: const Text('Search an Address'),
              ),
            ],
          ),
        ),
      );
    }

    final displayAddress = analysisState.address?.displayAddress ?? address?.displayAddress ?? '';
    final score = result.score;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 120,
            actions: [
              IconButton(
                icon: const Icon(Icons.map_rounded),
                onPressed: () => context.pushNamed('map', extra: analysisState.address),
                tooltip: 'View Map',
              ),
              IconButton(
                icon: const Icon(Icons.share_rounded),
                onPressed: () => _share(context, displayAddress, score),
                tooltip: 'Share',
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                displayAddress,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall,
              ),
              titlePadding: const EdgeInsets.only(left: 56, right: 100, bottom: 12),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Overall Score
                OverallScoreCard(score: score)
                    .animate()
                    .fadeIn(duration: 500.ms)
                    .slideY(begin: 0.1, end: 0),

                const SizedBox(height: 16),

                // ── Return to primary view ──────────────────────────────────
                _LivingIndexCard()
                    .animate(delay: 100.ms)
                    .fadeIn(duration: 400.ms)
                    .slideY(begin: 0.05, end: 0),

                const SizedBox(height: 20),

                // Category Scores
                Text(
                  'Category Scores',
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                ...score.categories.entries.toList().asMap().entries.map(
                      (entry) => CategoryCard(
                        categoryScore: entry.value.value,
                      )
                          .animate(delay: (100 * entry.key).ms)
                          .fadeIn(duration: 400.ms)
                          .slideX(begin: 0.05, end: 0),
                    ),

                const SizedBox(height: 20),

                // AI Summary
                if (result.aiSummary != null) ...[
                  AiSummaryCard(summary: result.aiSummary!)
                      .animate(delay: 300.ms)
                      .fadeIn(duration: 500.ms),
                  const SizedBox(height: 20),
                ],

                // Street View
                if (analysisState.address != null) ...[
                  StreetViewSection(address: analysisState.address!)
                      .animate(delay: 350.ms)
                      .fadeIn(duration: 400.ms)
                      .slideY(begin: 0.05, end: 0),
                  const SizedBox(height: 20),
                ],

                // Nearby Amenities
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Nearby Places',
                      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    TextButton.icon(
                      onPressed: () => context.pushNamed('map', extra: analysisState.address),
                      icon: const Icon(Icons.map_rounded, size: 16),
                      label: const Text('View Map'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ...result.amenities.take(10).toList().asMap().entries.map(
                      (e) => AmenityListTile(amenity: e.value)
                          .animate(delay: (50 * e.key).ms)
                          .fadeIn(duration: 300.ms),
                    ),

                if (result.amenities.length > 10) ...[
                  const SizedBox(height: 8),
                  Center(
                    child: TextButton(
                      onPressed: () => context.pushNamed('map', extra: analysisState.address),
                      child: Text('View all ${result.amenities.length} places on map'),
                    ),
                  ),
                ],

                const SizedBox(height: 32),
              ]),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.pushNamed('map', extra: analysisState.address),
        icon: const Icon(Icons.map_rounded),
        label: const Text('Open Map'),
      ),
    );
  }

  void _share(BuildContext context, String address, LocationScore score) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$address — Score: ${score.overall.round()}/100'),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(label: 'Dismiss', onPressed: () {}),
      ),
    );
  }
}


class _LivingIndexCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.pushNamed('neighborhood'),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF111827), Color(0xFF1E1B4B)],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF6C63FF).withOpacity(0.4), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6C63FF).withOpacity(0.15),
              blurRadius: 24,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6C63FF), Color(0xFF9C63FF)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Living Index',
                        style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700),
                      ),
                      Text(
                        'Your primary view — DNA, Timeline, Story & more',
                        style: TextStyle(color: Color(0xFF6C63FF), fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white38, size: 16),
              ],
            ),
            const SizedBox(height: 16),
            const Row(
              children: [
                _FeaturePill('🧬', 'DNA'),
                SizedBox(width: 8),
                _FeaturePill('🗺', 'Radius'),
                SizedBox(width: 8),
                _FeaturePill('⏱', 'Timeline'),
                SizedBox(width: 8),
                _FeaturePill('📖', 'Story'),
                SizedBox(width: 8),
                _FeaturePill('🔮', 'Future'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FeaturePill extends StatelessWidget {
  final String emoji;
  final String label;
  const _FeaturePill(this.emoji, this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFF6C63FF).withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF6C63FF).withOpacity(0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 11)),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(color: Color(0xFF9C9AFF), fontSize: 10, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _LoadingSkeleton extends StatelessWidget {
  const _LoadingSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: const [
        ShimmerCard(height: 160),
        SizedBox(height: 16),
        ShimmerCard(height: 80),
        SizedBox(height: 8),
        ShimmerCard(height: 80),
        SizedBox(height: 8),
        ShimmerCard(height: 80),
        SizedBox(height: 16),
        ShimmerCard(height: 120),
      ],
    );
  }
}
