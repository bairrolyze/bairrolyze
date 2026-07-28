import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../models/address_model.dart';
import '../../models/amenity_model.dart';
import '../../models/score_model.dart';
import 'category_detail_sheet.dart';

// ── Design tokens ──────────────────────────────────────────────────────────────
const _kBg      = Color(0xFF060B14);
const _kSurface = Color(0xFF0D1625);
const _kSurface2= Color(0xFF131F33);
const _kBorder  = Color(0xFF1A2845);
const _kAccent2 = Color(0xFF6C63FF);

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

Color _scoreColor(double s) {
  if (s >= 80) return const Color(0xFF22C55E);
  if (s >= 60) return const Color(0xFF3B82F6);
  if (s >= 40) return const Color(0xFFF59E0B);
  return const Color(0xFFEF4444);
}

String _scoreLabel(double s) {
  if (s >= 80) return 'Excellent';
  if (s >= 60) return 'Good';
  if (s >= 40) return 'Fair';
  return 'Poor';
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
    final overall = result.score.overall;
    final color   = _scoreColor(overall);
    final cats    = result.score.categories.values.toList();

    final nearest = ([...result.amenities]
          ..sort((a, b) =>
              (a.distanceMeters ?? 99999).compareTo(b.distanceMeters ?? 99999)))
        .take(10)
        .toList();

    return Container(
      color: _kBg,
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(0, topPadding + 20, 0, 48),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Score hero ───────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _ScoreHero(
                overall: overall,
                color: color,
                label: _scoreLabel(overall),
                profile: result.score.profile,
                catCount: cats.length,
              ),
            ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.06, end: 0),

            const SizedBox(height: 28),

            // ── Category scores ──────────────────────────────────────────
            _SectionLabel('SCORES BY CATEGORY'),
            const SizedBox(height: 10),
            ...List.generate(cats.length, (i) {
              final cat  = cats[i];
              final meta = _catMeta[cat.id];
              return Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: GestureDetector(
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
                  ),
                ),
              )
                  .animate(delay: (i * 55).ms)
                  .fadeIn(duration: 300.ms)
                  .slideX(begin: 0.05, end: 0);
            }),

            const SizedBox(height: 28),

            // ── Nearest places ───────────────────────────────────────────
            _SectionLabel('NEAREST PLACES'),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                decoration: BoxDecoration(
                  color: _kSurface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _kBorder),
                ),
                child: Column(
                  children: [
                    for (int i = 0; i < nearest.length; i++) ...[
                      if (i > 0)
                        Divider(
                          height: 1,
                          color: Colors.white.withOpacity(0.045),
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

// ── Score hero ────────────────────────────────────────────────────────────────

class _ScoreHero extends StatelessWidget {
  final double overall;
  final Color color;
  final String label;
  final String profile;
  final int catCount;

  const _ScoreHero({
    required this.overall,
    required this.color,
    required this.label,
    required this.profile,
    required this.catCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _kBorder),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.08),
            blurRadius: 32,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          // Animated score ring
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: overall / 100),
            duration: const Duration(milliseconds: 1100),
            curve: Curves.easeOutCubic,
            builder: (_, progress, __) => SizedBox(
              width: 88,
              height: 88,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CustomPaint(
                    size: const Size(88, 88),
                    painter: _RingPainter(
                        progress: 1, color: _kBorder, strokeWidth: 5.5),
                  ),
                  CustomPaint(
                    size: const Size(88, 88),
                    painter: _RingPainter(
                        progress: progress, color: color, strokeWidth: 5.5),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        (overall * progress).round().toString(),
                        style: TextStyle(
                          color: color,
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -1,
                          height: 1,
                        ),
                      ),
                      Text(
                        'of 100',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.28),
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 18),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Label badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.14),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    label,
                    style: TextStyle(
                      color: color,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
                const SizedBox(height: 9),
                Text(
                  '$catCount dimensions scored',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.42),
                    fontSize: 12.5,
                  ),
                ),
                const SizedBox(height: 6),
                // Profile chip
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                        color: Colors.white.withOpacity(0.08)),
                  ),
                  child: Text(
                    profile.toUpperCase(),
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.4),
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.9,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Category card ─────────────────────────────────────────────────────────────

class _CategoryCard extends StatelessWidget {
  final CategoryScore cat;
  final Color color;
  final IconData icon;

  const _CategoryCard({
    required this.cat,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final score = cat.score;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kBorder),
      ),
      child: Row(
        children: [
          // Icon badge
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: color, size: 19),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      cat.label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      score.round().toString(),
                      style: TextStyle(
                        color: color,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 7),
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: score / 100),
                  duration: const Duration(milliseconds: 900),
                  curve: Curves.easeOutCubic,
                  builder: (_, v, __) => ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: v,
                      minHeight: 4,
                      backgroundColor: _kBorder,
                      valueColor: AlwaysStoppedAnimation(color),
                    ),
                  ),
                ),
                if (cat.closest != null) ...[
                  const SizedBox(height: 7),
                  Row(
                    children: [
                      Icon(Icons.location_on_rounded,
                          size: 11,
                          color: Colors.white.withOpacity(0.28)),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          cat.closest!.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.38),
                            fontSize: 11.5,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _dist(cat.closest!.distanceMeters),
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.28),
                          fontSize: 11,
                        ),
                      ),
                      if (cat.closest!.walkingMinutes != null) ...[
                        const SizedBox(width: 4),
                        Text(
                          '· ${cat.closest!.walkingMinutes}min',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.22),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ],
            ),
          ),
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

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
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
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _dist(amenity.distanceMeters),
            style: TextStyle(
              color: Colors.white.withOpacity(0.38),
              fontSize: 12,
            ),
          ),
          if (amenity.walkingMinutes != null) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: _kSurface2,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '${amenity.walkingMinutes}min',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.32),
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kBorder),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_kSurface, _kAccent2.withOpacity(0.07)],
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _kAccent2.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.auto_awesome_rounded,
                color: _kAccent2, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Colors.white.withOpacity(0.72),
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
      child: Text(
        text,
        style: TextStyle(
          color: Colors.white.withOpacity(0.32),
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.8,
        ),
      ),
    );
  }
}

// ── Ring painter ──────────────────────────────────────────────────────────────

class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double strokeWidth;
  const _RingPainter(
      {required this.progress,
      required this.color,
      required this.strokeWidth});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final inset = strokeWidth / 2;
    final rect =
        Rect.fromLTWH(inset, inset, size.width - inset * 2, size.height - inset * 2);

    canvas.drawArc(rect, -pi / 2, 2 * pi * progress, false, paint);
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress || old.color != color;
}
