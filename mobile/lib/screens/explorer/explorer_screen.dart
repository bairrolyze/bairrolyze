import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/shell_provider.dart';
import '../../providers/country_provider.dart';

// ── Design tokens ──────────────────────────────────────────────────────────────
const _kBg       = Color(0xFF060B14);
const _kSurface  = Color(0xFF0D1625);
const _kSurface2 = Color(0xFF131F33);
const _kAccent   = Color(0xFF3B82F6);
const _kBorder   = Color(0xFF1A2845);
const _kAccent2  = Color(0xFF7C3AED);

// ── Tag colors ─────────────────────────────────────────────────────────────────
const _kTagTransport  = Color(0xFF29B6F6);
const _kTagFamily     = Color(0xFF66BB6A);
const _kTagInvestment = Color(0xFF7C3AED);
const _kTagNature     = Color(0xFF26C6DA);
const _kTagCulture    = Color(0xFFFFA726);

// ── Data model ─────────────────────────────────────────────────────────────────

class _Neighborhood {
  final String name;
  final String city;
  final String description;
  final int score;
  final List<String> tags;
  final String highlight;
  final int transportScore;
  final int educationScore;
  final int safetyScore;

  const _Neighborhood({
    required this.name,
    required this.city,
    required this.description,
    required this.score,
    required this.tags,
    required this.highlight,
    required this.transportScore,
    required this.educationScore,
    required this.safetyScore,
  });
}

// ── Curated Portugal data ──────────────────────────────────────────────────────

const _neighborhoods = <_Neighborhood>[
  _Neighborhood(
    name: 'Parque das Nações',
    city: 'Lisboa',
    description:
        'Modern waterfront district with excellent transit and contemporary architecture.',
    score: 87,
    tags: ['Transport', 'Family', 'Investment'],
    highlight: 'Best connected in Lisbon',
    transportScore: 94,
    educationScore: 78,
    safetyScore: 88,
  ),
  _Neighborhood(
    name: 'Príncipe Real',
    city: 'Lisboa',
    description:
        'Sophisticated hilltop quarter known for boutiques, galleries and vibrant café culture.',
    score: 82,
    tags: ['Culture', 'Nature'],
    highlight: 'Top walkability score',
    transportScore: 74,
    educationScore: 70,
    safetyScore: 80,
  ),
  _Neighborhood(
    name: 'Cascais',
    city: 'Cascais',
    description:
        'Prestigious seaside town with marina, beaches and an exceptional quality of life.',
    score: 85,
    tags: ['Nature', 'Family', 'Investment'],
    highlight: 'Top coastal quality of life',
    transportScore: 72,
    educationScore: 82,
    safetyScore: 91,
  ),
  _Neighborhood(
    name: 'Baixa-Chiado',
    city: 'Lisboa',
    description:
        'Lisbon\'s beating heart — historic grandeur meets a lively commercial and cultural scene.',
    score: 79,
    tags: ['Culture', 'Transport'],
    highlight: 'Historic centre, great transit',
    transportScore: 88,
    educationScore: 62,
    safetyScore: 71,
  ),
  _Neighborhood(
    name: 'Boavista',
    city: 'Porto',
    description:
        'Porto\'s prestigious business and residential corridor with excellent urban amenities.',
    score: 81,
    tags: ['Investment', 'Transport'],
    highlight: 'Porto\'s premier investment district',
    transportScore: 83,
    educationScore: 76,
    safetyScore: 82,
  ),
  _Neighborhood(
    name: 'Foz do Douro',
    city: 'Porto',
    description:
        'Exclusive riverside neighbourhood with ocean views, parks and upscale dining.',
    score: 84,
    tags: ['Nature', 'Family', 'Investment'],
    highlight: 'Porto\'s most desirable address',
    transportScore: 66,
    educationScore: 84,
    safetyScore: 89,
  ),
  _Neighborhood(
    name: 'Santo António',
    city: 'Lisboa',
    description:
        'Central Lisbon neighbourhood with top-tier healthcare, schools and safety scores.',
    score: 78,
    tags: ['Family', 'Culture'],
    highlight: 'Best for families in central Lisbon',
    transportScore: 80,
    educationScore: 85,
    safetyScore: 83,
  ),
  _Neighborhood(
    name: 'Braga Centro',
    city: 'Braga',
    description:
        'Northern gem combining historic charm with a thriving university city energy.',
    score: 76,
    tags: ['Family', 'Culture', 'Investment'],
    highlight: 'Fastest growing city centre',
    transportScore: 71,
    educationScore: 88,
    safetyScore: 84,
  ),
];

// ── Screen ─────────────────────────────────────────────────────────────────────

class ExplorerScreen extends ConsumerStatefulWidget {
  const ExplorerScreen({super.key});

  @override
  ConsumerState<ExplorerScreen> createState() => _ExplorerScreenState();
}

class _ExplorerScreenState extends ConsumerState<ExplorerScreen> {
  int _filterIndex = 0;

  static const _filters = [
    'All',
    'Transport',
    'Family',
    'Investment',
    'Nature',
    'Culture',
  ];

  List<_Neighborhood> get _filtered {
    if (_filterIndex == 0) return _neighborhoods;
    final tag = _filters[_filterIndex];
    return _neighborhoods.where((n) => n.tags.contains(tag)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final country = ref.watch(selectedCountryProvider);
    final countryName = country?.name ?? 'Portugal';
    final top = MediaQuery.of(context).padding.top;
    final filtered = _filtered;

    return Container(
      color: _kBg,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── Safe area top padding ──────────────────────────────────────────
          SliverPadding(
            padding: EdgeInsets.only(top: top + 14),
            sliver: const SliverToBoxAdapter(child: SizedBox.shrink()),
          ),

          // ── Header ─────────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 0, 22, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Text(
                        'Explore',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.6,
                          height: 1,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        countryName,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.40),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Discover the neighbourhoods that match your life.',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.40),
                      fontSize: 14,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 20)),

          // ── Filter chips ────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: SizedBox(
              height: 44,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 22),
                physics: const BouncingScrollPhysics(),
                itemCount: _filters.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final active = i == _filterIndex;
                  return GestureDetector(
                    onTap: () => setState(() => _filterIndex = i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeInOut,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 0),
                      decoration: BoxDecoration(
                        color: active
                            ? _kAccent.withValues(alpha: 0.12)
                            : _kSurface2,
                        borderRadius: BorderRadius.circular(22),
                        border: active
                            ? Border.all(
                                color: _kAccent.withValues(alpha: 0.70),
                                width: 1.5,
                              )
                            : Border.all(
                                color: _kBorder,
                                width: 1,
                              ),
                        gradient: active
                            ? LinearGradient(
                                colors: [
                                  _kAccent.withValues(alpha: 0.10),
                                  _kAccent2.withValues(alpha: 0.10),
                                ],
                              )
                            : null,
                      ),
                      child: Center(
                        child: Text(
                          _filters[i],
                          style: TextStyle(
                            color: active
                                ? _kAccent
                                : Colors.white.withValues(alpha: 0.45),
                            fontSize: 12.5,
                            fontWeight: active
                                ? FontWeight.w700
                                : FontWeight.w500,
                            letterSpacing: 0.1,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 24)),

          // ── Section label ──────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 0, 22, 12),
              child: Text(
                'FEATURED',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.28),
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.6,
                ),
              ),
            ),
          ),

          // ── Neighborhood cards ─────────────────────────────────────────────
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                if (index >= filtered.length) return null;
                return _NeighborhoodCard(
                  neighborhood: filtered[index],
                  onAnalyze: () {
                    ref.read(shellTabProvider.notifier).state = 0;
                  },
                );
              },
              childCount: filtered.length,
            ),
          ),

          // ── Bottom padding (nav bar clearance) ────────────────────────────
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }
}

// ── Neighborhood card ──────────────────────────────────────────────────────────

class _NeighborhoodCard extends StatelessWidget {
  final _Neighborhood neighborhood;
  final VoidCallback onAnalyze;

  const _NeighborhoodCard({
    required this.neighborhood,
    required this.onAnalyze,
  });

  Color _scoreColor(int score) {
    if (score >= 80) return const Color(0xFF22C55E);
    if (score >= 65) return const Color(0xFF3B82F6);
    return const Color(0xFFF59E0B);
  }

  Color _tagColor(String tag) {
    switch (tag) {
      case 'Transport':
        return _kTagTransport;
      case 'Family':
        return _kTagFamily;
      case 'Investment':
        return _kTagInvestment;
      case 'Nature':
        return _kTagNature;
      case 'Culture':
        return _kTagCulture;
      default:
        return _kAccent;
    }
  }

  @override
  Widget build(BuildContext context) {
    final n = neighborhood;
    final scoreColor = _scoreColor(n.score);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _kBorder, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Top row: score ring + name/city + highlight badge ────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Score ring
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: scoreColor, width: 2.5),
                    color: scoreColor.withValues(alpha: 0.10),
                  ),
                  child: Center(
                    child: Text(
                      n.score.toString(),
                      style: TextStyle(
                        color: scoreColor,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Name + city
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 2),
                      Text(
                        n.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.3,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        n.city,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.40),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                // Highlight badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: _kAccent.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(20),
                    border:
                        Border.all(color: _kAccent.withValues(alpha: 0.28)),
                  ),
                  child: Text(
                    n.highlight,
                    style: TextStyle(
                      color: _kAccent.withValues(alpha: 0.90),
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.1,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // ── Description ──────────────────────────────────────────────────
            Text(
              n.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.42),
                fontSize: 13,
                height: 1.5,
              ),
            ),

            const SizedBox(height: 14),

            // ── Stat pills row ───────────────────────────────────────────────
            Row(
              children: [
                _StatPill(
                  icon: Icons.directions_transit_filled_rounded,
                  label: 'Transit',
                  value: n.transportScore,
                  color: _kTagTransport,
                ),
                const SizedBox(width: 8),
                _StatPill(
                  icon: Icons.school_rounded,
                  label: 'Education',
                  value: n.educationScore,
                  color: _kTagFamily,
                ),
                const SizedBox(width: 8),
                _StatPill(
                  icon: Icons.shield_rounded,
                  label: 'Safety',
                  value: n.safetyScore,
                  color: const Color(0xFF22C55E),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // ── Tags + Analyze button ────────────────────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Tags
                Expanded(
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: n.tags.map((tag) {
                      final color = _tagColor(tag);
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: color.withValues(alpha: 0.28)),
                        ),
                        child: Text(
                          tag,
                          style: TextStyle(
                            color: color.withValues(alpha: 0.90),
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.1,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(width: 10),
                // Analyze button
                GestureDetector(
                  onTap: onAnalyze,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [_kAccent, Color(0xFF2563EB)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.analytics_rounded,
                          color: Colors.white,
                          size: 13,
                        ),
                        SizedBox(width: 5),
                        Text(
                          'Analyze',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Stat pill ──────────────────────────────────────────────────────────────────

class _StatPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final int value;
  final Color color;

  const _StatPill({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: _kSurface2,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _kBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            '$value',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.38),
              fontSize: 10.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
