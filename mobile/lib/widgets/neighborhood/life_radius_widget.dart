import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../models/amenity_model.dart';

class LifeRadiusWidget extends StatefulWidget {
  final List<AmenityModel> amenities;
  final double? addressLat;
  final double? addressLng;
  final double topPadding;

  const LifeRadiusWidget({
    super.key,
    required this.amenities,
    this.addressLat,
    this.addressLng,
    this.topPadding = 100,
  });

  @override
  State<LifeRadiusWidget> createState() => _LifeRadiusWidgetState();
}

class _LifeRadiusWidgetState extends State<LifeRadiusWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;
  AmenityCategory? _filter;
  AmenityModel? _tapped;

  static const _catColors = {
    AmenityCategory.transportation: Color(0xFF29B6F6),
    AmenityCategory.education: Color(0xFF66BB6A),
    AmenityCategory.healthcare: Color(0xFFEF5350),
    AmenityCategory.shopping: Color(0xFFFFA726),
    AmenityCategory.safety: Color(0xFFAB47BC),
    AmenityCategory.religion: Color(0xFF8D6E63),
    AmenityCategory.recreation: Color(0xFF26C6DA),
  };

  static const _catIcons = {
    AmenityCategory.transportation: Icons.train_rounded,
    AmenityCategory.education: Icons.school_rounded,
    AmenityCategory.healthcare: Icons.local_hospital_rounded,
    AmenityCategory.shopping: Icons.shopping_bag_rounded,
    AmenityCategory.safety: Icons.shield_rounded,
    AmenityCategory.religion: Icons.church_rounded,
    AmenityCategory.recreation: Icons.park_rounded,
  };

  static const _catLabels = {
    AmenityCategory.transportation: 'Transit',
    AmenityCategory.education: 'Schools',
    AmenityCategory.healthcare: 'Health',
    AmenityCategory.shopping: 'Shopping',
    AmenityCategory.safety: 'Safety',
    AmenityCategory.religion: 'Community',
    AmenityCategory.recreation: 'Parks',
  };

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
    Future.delayed(300.ms, () { if (mounted) _ctrl.forward(); });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  List<AmenityModel> get _visible {
    final base = widget.amenities.where((a) => a.distanceMeters != null).toList();
    return _filter == null ? base : base.where((a) => a.category == _filter).toList();
  }

  @override
  Widget build(BuildContext context) {
    // Places for the active category, sorted by distance
    final categoryList = _filter == null
        ? <AmenityModel>[]
        : (widget.amenities
            .where((a) => a.category == _filter && a.distanceMeters != null)
            .toList()
          ..sort((a, b) =>
              (a.distanceMeters ?? 99999).compareTo(b.distanceMeters ?? 99999)));

    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: widget.topPadding + 32),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'PROXIMITY',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 2.2,
                    height: 1,
                  ),
                ).animate().fadeIn(duration: 400.ms),
                const SizedBox(height: 10),
                const Text(
                  'Life Radius',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                    height: 1.05,
                  ),
                ).animate(delay: 60.ms).fadeIn(duration: 500.ms).slideY(begin: 0.15, end: 0),
                const SizedBox(height: 8),
                Text(
                  'Everything within reach, mapped around your address.',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.60),
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    height: 1.4,
                  ),
                ).animate(delay: 120.ms).fadeIn(duration: 500.ms),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // Filter chips
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                _FilterChip(
                  label: 'All',
                  icon: Icons.apps_rounded,
                  color: const Color(0xFF6C63FF),
                  selected: _filter == null,
                  onTap: () => setState(() { _filter = null; _tapped = null; }),
                ),
                ...AmenityCategory.values.map((cat) => _FilterChip(
                  label: _catLabels[cat] ?? cat.name,
                  icon: _catIcons[cat] ?? Icons.place_rounded,
                  color: _catColors[cat] ?? Colors.grey,
                  selected: _filter == cat,
                  onTap: () => setState(() { _filter = cat; _tapped = null; }),
                )),
              ],
            ),
          ).animate(delay: 150.ms).fadeIn(),

          const SizedBox(height: 12),

          // Radial map — fixed height so the list can scroll below it
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              height: 320,
              child: LayoutBuilder(
                builder: (_, constraints) {
                  final paintSize = constraints.biggest;
                  return AnimatedBuilder(
                    animation: _anim,
                    builder: (_, __) => GestureDetector(
                      onTapUp: (d) => _onTap(d.localPosition, paintSize),
                      child: CustomPaint(
                        painter: _RadialPainter(
                          amenities: _visible,
                          addressLat: widget.addressLat,
                          addressLng: widget.addressLng,
                          catColors: _catColors,
                          animValue: _anim.value,
                          tapped: _tapped,
                        ),
                        child: const SizedBox.expand(),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // Tapped-dot info bar
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: _tapped != null
                ? _AmenityInfo(
                    amenity: _tapped!,
                    color: _catColors[_tapped!.category] ?? Colors.grey)
                : Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      '${_visible.length} places in view  •  Tap a dot to explore',
                      style: const TextStyle(color: Colors.white30, fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                  ),
          ),

          // ── Category place list ──────────────────────────────────────────
          if (categoryList.isNotEmpty) ...[
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    (_catLabels[_filter!] ?? _filter!.name).toUpperCase(),
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.32),
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.8,
                    ),
                  ),
                  Text(
                    '${categoryList.length} places',
                    style: TextStyle(
                      color: (_catColors[_filter!] ?? Colors.grey).withOpacity(0.70),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF0D1625),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF1A2845)),
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: List.generate(categoryList.length, (i) {
                    final a = categoryList[i];
                    final color = _catColors[a.category] ?? Colors.grey;
                    final icon = _catIcons[a.category] ?? Icons.place_rounded;
                    final isTapped = _tapped == a;
                    return Column(
                      children: [
                        if (i > 0)
                          Divider(
                            height: 1,
                            thickness: 0.5,
                            color: Colors.white.withOpacity(0.05),
                          ),
                        InkWell(
                          onTap: () => setState(() =>
                              _tapped = isTapped ? null : a),
                          splashColor: color.withOpacity(0.08),
                          highlightColor: color.withOpacity(0.05),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            color: isTapped
                                ? color.withOpacity(0.06)
                                : Colors.transparent,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 11),
                            child: Row(children: [
                              Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  color: color.withOpacity(isTapped ? 0.20 : 0.10),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(icon, color: color, size: 15),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      a.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: isTapped
                                            ? Colors.white
                                            : Colors.white.withOpacity(0.88),
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Text(
                                      a.type.replaceAll('_', ' '),
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.35),
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    _formatDist(a.distanceMeters),
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.55),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  if (a.walkingMinutes != null)
                                    Text(
                                      '${a.walkingMinutes} min',
                                      style: TextStyle(
                                        color: color.withOpacity(0.75),
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                ],
                              ),
                            ]),
                          ),
                        ),
                      ],
                    );
                  }),
                ),
              ).animate().fadeIn(duration: 280.ms).slideY(begin: 0.06, end: 0),
            ),
          ],

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  static String _formatDist(int? m) {
    if (m == null) return '';
    return m < 1000 ? '${m}m' : '${(m / 1000).toStringAsFixed(1)}km';
  }

  void _onTap(Offset pos, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxR = (min(size.width, size.height) / 2) * 0.82;
    const maxDist = 2000.0;

    AmenityModel? nearest;
    double nearestDist = double.infinity;

    for (final a in _visible) {
      final pt = _amenityOffset(a, center, maxR, maxDist);
      if (pt == null) continue;
      final d = (pt - pos).distance;
      if (d < 24 && d < nearestDist) {
        nearestDist = d;
        nearest = a;
      }
    }

    setState(() => _tapped = nearest);
  }

  Offset? _amenityOffset(AmenityModel a, Offset center, double maxR, double maxDist) {
    final dist = a.distanceMeters?.toDouble() ?? 0;
    if (dist <= 0) return null;
    // Clamp matches _RadialPainter._offsetFor so hit positions are identical
    final r = (dist / maxDist).clamp(0.0, 1.0) * maxR;

    if (widget.addressLat != null && widget.addressLng != null && a.lat != 0 && a.lng != 0) {
      final dLat = a.lat - widget.addressLat!;
      final dLng = (a.lng - widget.addressLng!) * cos(widget.addressLat! * pi / 180);
      final angle = atan2(dLng, dLat);
      return Offset(center.dx + r * sin(angle), center.dy - r * cos(angle));
    }

    // Fallback: use _visible list (same as painter) to keep indices in sync
    final idx = _visible.indexOf(a);
    final angle = (2 * pi / _visible.length) * idx;
    return Offset(center.dx + r * cos(angle), center.dy + r * sin(angle));
  }
}

// ─── Radial painter ──────────────────────────────────────────────────────────

class _RadialPainter extends CustomPainter {
  final List<AmenityModel> amenities;
  final double? addressLat;
  final double? addressLng;
  final Map<AmenityCategory, Color> catColors;
  final double animValue;
  final AmenityModel? tapped;

  const _RadialPainter({
    required this.amenities,
    required this.catColors,
    required this.animValue,
    this.addressLat,
    this.addressLng,
    this.tapped,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxR = (min(size.width, size.height) / 2) * 0.82;
    const maxDist = 2000.0;

    // Background circle
    canvas.drawCircle(center, maxR + 10, Paint()..color = const Color(0xFF0D1525));

    // Rings (5, 10, 15, 20 min = ~400, 800, 1200, 2000m)
    final ringDistances = [400.0, 800.0, 1200.0, 2000.0];
    final ringLabels = ['5 min', '10 min', '15 min', '20 min'];
    for (int i = 0; i < ringDistances.length; i++) {
      final r = (ringDistances[i] / maxDist) * maxR;
      canvas.drawCircle(
        center, r,
        Paint()
          ..color = Colors.white.withOpacity(i == ringDistances.length - 1 ? 0.10 : 0.06)
          ..style = PaintingStyle.stroke
          ..strokeWidth = i == ringDistances.length - 1 ? 1.5 : 1,
      );
      // Ring label
      final tp = TextPainter(
        text: TextSpan(
          text: ringLabels[i],
          style: TextStyle(color: Colors.white.withOpacity(0.25), fontSize: 9),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(center.dx + 4, center.dy - r - 11));
    }

    // Compass directions
    final compassPaint = TextPainter(textDirection: TextDirection.ltr);
    for (final (label, dx, dy) in [
      ('N', 0.0, -1.0), ('S', 0.0, 1.0), ('E', 1.0, 0.0), ('W', -1.0, 0.0),
    ]) {
      compassPaint
        ..text = TextSpan(
            text: label,
            style: TextStyle(color: Colors.white.withOpacity(0.15), fontSize: 10, fontWeight: FontWeight.w700))
        ..layout();
      compassPaint.paint(
        canvas,
        Offset(center.dx + (maxR + 14) * dx - compassPaint.width / 2,
               center.dy + (maxR + 14) * dy - compassPaint.height / 2),
      );
    }

    if (animValue <= 0.01) return;

    // Amenity dots
    for (final a in amenities) {
      final pt = _offsetFor(a, center, maxR, maxDist);
      if (pt == null) continue;

      // Animate from center
      final animPt = Offset.lerp(center, pt, animValue * animValue)!;
      final color = catColors[a.category] ?? Colors.grey;
      final isTapped = tapped == a;

      if (isTapped) {
        // Highlight ring
        canvas.drawCircle(animPt, 14, Paint()..color = color.withOpacity(0.2));
        canvas.drawCircle(animPt, 14,
            Paint()..color = color.withOpacity(0.6)..style = PaintingStyle.stroke..strokeWidth = 1.5);
      }

      // Dot
      canvas.drawCircle(animPt, isTapped ? 7 : 5, Paint()..color = color);
      canvas.drawCircle(animPt, isTapped ? 3.5 : 2, Paint()..color = Colors.white.withOpacity(0.9));
    }

    // Center home indicator
    canvas.drawCircle(center, 14, Paint()..color = const Color(0xFF6C63FF).withOpacity(0.25));
    canvas.drawCircle(center, 14,
        Paint()..color = const Color(0xFF6C63FF)..style = PaintingStyle.stroke..strokeWidth = 2);
    canvas.drawCircle(center, 6, Paint()..color = const Color(0xFF6C63FF));
    canvas.drawCircle(center, 3, Paint()..color = Colors.white);
  }

  Offset? _offsetFor(AmenityModel a, Offset center, double maxR, double maxDist) {
    final dist = a.distanceMeters?.toDouble() ?? 0;
    if (dist <= 0) return null;
    final r = (dist / maxDist).clamp(0.0, 1.0) * maxR;

    if (addressLat != null && addressLng != null && (a.lat != 0 || a.lng != 0)) {
      final dLat = a.lat - addressLat!;
      final dLng = (a.lng - addressLng!) * cos(addressLat! * pi / 180);
      final angle = atan2(dLng, dLat);
      return Offset(center.dx + r * sin(angle), center.dy - r * cos(angle));
    }

    final idx = amenities.indexOf(a);
    final angle = (2 * pi / amenities.length) * idx;
    return Offset(center.dx + r * cos(angle), center.dy + r * sin(angle));
  }

  @override
  bool shouldRepaint(_RadialPainter old) =>
      old.animValue != animValue || old.tapped != tapped || old.amenities != amenities;
}

// ─── Filter chip ─────────────────────────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({required this.label, required this.icon, required this.color, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: 200.ms,
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? color : color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withOpacity(selected ? 0 : 0.3), width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: selected ? Colors.white : color),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : color,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Amenity info bar ────────────────────────────────────────────────────────

class _AmenityInfo extends StatelessWidget {
  final AmenityModel amenity;
  final Color color;

  const _AmenityInfo({required this.amenity, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      key: ValueKey(amenity.id),
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF151E30),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(color: color.withOpacity(0.15), shape: BoxShape.circle),
            child: Icon(Icons.place_rounded, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(amenity.name,
                    style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(amenity.type.replaceAll('_', ' '),
                    style: const TextStyle(color: Colors.white54, fontSize: 11)),
              ],
            ),
          ),
          if (amenity.walkingMinutes != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${amenity.walkingMinutes} min',
                style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700),
              ),
            ),
        ],
      ),
    ).animate().fadeIn(duration: 200.ms).slideY(begin: 0.1, end: 0);
  }
}
