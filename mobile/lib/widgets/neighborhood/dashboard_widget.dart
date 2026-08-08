import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../config/app_theme.dart';
import '../../config/score_format.dart';
import '../../models/address_model.dart';
import '../../models/amenity_model.dart';
import '../../models/score_model.dart';
import 'category_detail_sheet.dart';

// ── Category metadata ─────────────────────────────────────────────────────────
const _catMeta = {
  'transportation': _CatMeta(Icons.train_rounded,        Color(0xFF29B6F6)),
  'education':      _CatMeta(Icons.school_rounded,       Color(0xFF66BB6A)),
  'healthcare':     _CatMeta(Icons.local_hospital_rounded, Color(0xFFEF5350)),
  'shopping':       _CatMeta(Icons.shopping_bag_rounded, Color(0xFFFFA726)),
  'safety':         _CatMeta(Icons.shield_rounded,       Color(0xFFAB47BC)),
  'religion':       _CatMeta(Icons.church_rounded,       Color(0xFF8D6E63)),
  'recreation':     _CatMeta(Icons.park_rounded,         Color(0xFF26C6DA)),
};

const _amenityColors = {
  AmenityCategory.transportation: Color(0xFF29B6F6),
  AmenityCategory.education:      Color(0xFF66BB6A),
  AmenityCategory.healthcare:     Color(0xFFEF5350),
  AmenityCategory.shopping:       Color(0xFFFFA726),
  AmenityCategory.safety:         Color(0xFFAB47BC),
  AmenityCategory.religion:       Color(0xFF8D6E63),
  AmenityCategory.recreation:     Color(0xFF26C6DA),
};

const _amenityIcons = {
  AmenityCategory.transportation: Icons.train_rounded,
  AmenityCategory.education:      Icons.school_rounded,
  AmenityCategory.healthcare:     Icons.local_hospital_rounded,
  AmenityCategory.shopping:       Icons.shopping_bag_rounded,
  AmenityCategory.safety:         Icons.shield_rounded,
  AmenityCategory.religion:       Icons.church_rounded,
  AmenityCategory.recreation:     Icons.park_rounded,
};

class _CatMeta {
  final IconData icon;
  final Color color;
  const _CatMeta(this.icon, this.color);
}

// ── Helpers ───────────────────────────────────────────────────────────────────

// Display order for the category cards (safety-first, like the design mock).
const _catCardOrder = [
  'safety',
  'education',
  'transportation',
  'recreation',
  'shopping',
  'healthcare',
  'religion',
];

int _catOrder(String id) {
  final i = _catCardOrder.indexOf(id);
  return i < 0 ? _catCardOrder.length : i;
}

String _dist(int? m) {
  if (m == null) return '';
  return m < 1000 ? '${m}m' : '${(m / 1000).toStringAsFixed(1)}km';
}

// ── Dashboard widget ──────────────────────────────────────────────────────────

class DashboardWidget extends StatelessWidget {
  final AnalysisResult result;
  final AddressModel? address;
  final double topPadding;

  const DashboardWidget({
    super.key,
    required this.result,
    this.address,
    this.topPadding = 0,
  });

  @override
  Widget build(BuildContext context) {
    final cats    = result.score.categories.values.toList()
      ..sort((a, b) => _catOrder(a.id).compareTo(_catOrder(b.id)));
    final p       = AppPalette.of(context);

    final nearest = ([...result.amenities]
          ..sort((a, b) =>
              (a.distanceMeters ?? 99999).compareTo(b.distanceMeters ?? 99999)))
        .take(10)
        .toList();

    // If the last row of the 3-column grid would hold a single leftover card,
    // pull it out and render it full-width so nothing is left dangling alone.
    final wideCat = cats.length % 3 == 1 ? cats.last : null;
    final gridCats = wideCat != null ? cats.sublist(0, cats.length - 1) : cats;

    Widget catTile(CategoryScore cat, int i, {bool wide = false}) {
      final meta = _catMeta[cat.id];
      return GestureDetector(
        onTap: () => showCategoryDetail(
          context: context,
          cat: cat,
          allAmenities: result.amenities,
          address: address,
        ),
        child: _CategoryCard(
          cat: cat,
          color: meta?.color ?? const Color(0xFF3B82F6),
          icon: meta?.icon ?? Icons.place_rounded,
          wide: wide,
        ),
      )
          .animate(delay: (i * 45).ms)
          .fadeIn(duration: 300.ms)
          .slideY(begin: 0.06, end: 0);
    }

    return Container(
      color: p.bg,
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(0, topPadding + 20, 0, 48),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Category scores ──────────────────────────────────────────
            _SectionLabel('NEIGHBOURHOOD SCORES'),
            const SizedBox(height: 5),
            Padding(
              padding: const EdgeInsets.fromLTRB(33, 0, 24, 0),
              child: Text(
                'Tap a card to see details',
                style: TextStyle(
                  color: p.textTertiary,
                  fontSize: 11.5,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: GridView.count(
                crossAxisCount: 3,
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 0.98,
                children: [
                  for (int i = 0; i < gridCats.length; i++)
                    catTile(gridCats[i], i),
                ],
              ),
            ),
            if (wideCat != null) ...[
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: catTile(wideCat, gridCats.length, wide: true),
              ),
            ],

            const SizedBox(height: 28),

            // ── Nearest places ───────────────────────────────────────────
            _SectionLabel('NEAREST PLACES'),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                decoration: BoxDecoration(
                  color: p.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: p.border),
                ),
                child: Column(
                  children: [
                    for (int i = 0; i < nearest.length; i++) ...[
                      if (i > 0)
                        Divider(
                          height: 1,
                          color: Colors.white.withValues(alpha: 0.045),
                        ),
                      _NearestRow(amenity: nearest[i]),
                    ],
                  ],
                ),
              ),
            ).animate(delay: 380.ms).fadeIn(duration: 350.ms),

            // ── AI summary ───────────────────────────────────────────────
            if (result.aiSummary != null &&
                result.aiSummary!.isNotEmpty) ...[
              const SizedBox(height: 28),
              _SectionLabel('AI SUMMARY'),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _AiSummaryCard(text: result.aiSummary!),
              ).animate(delay: 480.ms).fadeIn(duration: 350.ms),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Category card ─────────────────────────────────────────────────────────────

class _CategoryCard extends StatelessWidget {
  final CategoryScore cat;
  final Color color;
  final IconData icon;
  final bool wide;

  const _CategoryCard({
    required this.cat,
    required this.color,
    required this.icon,
    this.wide = false,
  });

  Widget _iconBadge(double size) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withValues(alpha: 0.14),
          border: Border.all(color: color.withValues(alpha: 0.45)),
        ),
        child: Icon(icon, color: color, size: size * 0.55),
      );

  Widget _bar(double score) => TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: (score / 100).clamp(0.0, 1.0)),
        duration: const Duration(milliseconds: 900),
        curve: Curves.easeOutCubic,
        builder: (_, v, __) => ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(
            value: v,
            minHeight: 4,
            backgroundColor: color.withValues(alpha: 0.14),
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final score = cat.score;
    final p = AppPalette.of(context);
    final decoration = BoxDecoration(
      // Native app surface background; keep the category-coloured border.
      color: p.surface,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: color.withValues(alpha: 0.22)),
    );

    if (wide) {
      return Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        decoration: decoration,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _iconBadge(26),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    shortCategoryLabel(cat.id, cat.label),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: p.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Text(
                  scoreLabel(score),
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  (score / 10).toStringAsFixed(1),
                  style: TextStyle(
                    color: p.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    height: 1.0,
                    letterSpacing: -0.6,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _bar(score),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(11),
      decoration: decoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Icon + label (side by side)
          Row(
            children: [
              _iconBadge(22),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  shortCategoryLabel(cat.id, cat.label),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: p.textPrimary,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
            ],
          ),
          // Big score + qualitative label, centred in the card.
          Center(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  (score / 10).toStringAsFixed(1),
                  style: TextStyle(
                    color: p.textPrimary,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    height: 1.0,
                    letterSpacing: -0.6,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  scoreLabel(score),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          // Progress bar
          _bar(score),
        ],
      ),
    );
  }
}


// ── Nearest row ───────────────────────────────────────────────────────────────

class _NearestRow extends StatelessWidget {
  final AmenityModel amenity;
  const _NearestRow({required this.amenity});

  @override
  Widget build(BuildContext context) {
    final color = _amenityColors[amenity.category] ?? const Color(0xFF3B82F6);
    final icon  = _amenityIcons[amenity.category] ?? Icons.place_rounded;
    final p = AppPalette.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, color: color, size: 15),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Text(
              amenity.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: p.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _dist(amenity.distanceMeters),
            style: TextStyle(
              color: p.textTertiary,
              fontSize: 12,
            ),
          ),
          if (amenity.walkingMinutes != null) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: p.surface2,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '${amenity.walkingMinutes}min',
                style: TextStyle(
                  color: p.textTertiary,
                  fontSize: 10.5,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── AI summary card ───────────────────────────────────────────────────────────

class _AiSummaryCard extends StatelessWidget {
  final String text;
  const _AiSummaryCard({required this.text});

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: p.border),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [p.surface, AppColors.accent2.withValues(alpha: 0.07)],
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.accent2.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.auto_awesome_rounded,
                color: AppColors.accent2, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: p.textSecondary,
                fontSize: 13.5,
                height: 1.65,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Section label ─────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 24, 0),
      child: Row(
        children: [
          // Left accent "glass" bar to anchor the section title.
          Container(
            width: 3,
            height: 13,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.accent,
                  AppColors.accent.withValues(alpha: 0.25),
                ],
              ),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            text,
            style: TextStyle(
              color: p.textSecondary,
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.8,
            ),
          ),
        ],
      ),
    );
  }
}

