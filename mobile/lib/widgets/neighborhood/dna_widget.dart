import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../models/address_model.dart';
import '../../models/score_model.dart';

class DNAWidget extends StatefulWidget {
  final LocationScore score;
  final AddressModel? address;
  final double topPadding;
  const DNAWidget({super.key, required this.score, this.address, this.topPadding = 100});

  @override
  State<DNAWidget> createState() => _DNAWidgetState();
}

class _DNAWidgetState extends State<DNAWidget> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;
  int? _selected;

  static const _colors = {
    'transportation': Color(0xFF29B6F6),
    'education': Color(0xFF66BB6A),
    'healthcare': Color(0xFFEF5350),
    'shopping': Color(0xFFFFA726),
    'safety': Color(0xFFAB47BC),
    'religion': Color(0xFF8D6E63),
    'recreation': Color(0xFF26C6DA),
  };

  static const _icons = {
    'transportation': Icons.train_rounded,
    'education': Icons.school_rounded,
    'healthcare': Icons.local_hospital_rounded,
    'shopping': Icons.shopping_bag_rounded,
    'safety': Icons.shield_rounded,
    'religion': Icons.church_rounded,
    'recreation': Icons.park_rounded,
  };

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500));
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut);
    Future.delayed(400.ms, () { if (mounted) _ctrl.forward(); });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cats = widget.score.categories.values.toList();

    return SingleChildScrollView(
      child: Column(
        children: [
          SizedBox(height: widget.topPadding + 32),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Section label
                const Text(
                  'ANALYTICS',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 2.2,
                    height: 1,
                  ),
                ).animate().fadeIn(duration: 400.ms),
                const SizedBox(height: 10),
                // Title
                const Text(
                  'Area DNA',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                    height: 1.05,
                  ),
                ).animate(delay: 60.ms).fadeIn(duration: 500.ms).slideY(begin: 0.15, end: 0),
                const SizedBox(height: 8),
                // Subtitle
                Text(
                  'Visual fingerprint of what makes this area unique.',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.60),
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    height: 1.4,
                  ),
                ).animate(delay: 120.ms).fadeIn(duration: 500.ms),
                if (_locationMeta(widget.address) != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _locationMeta(widget.address)!,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.45),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.1,
                    ),
                  ).animate(delay: 180.ms).fadeIn(duration: 400.ms),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          // DNA Canvas
          LayoutBuilder(builder: (context, constraints) {
            final sz = (constraints.maxWidth * 0.88).clamp(240.0, 380.0);
            return SizedBox(
              width: sz,
              height: sz,
              child: AnimatedBuilder(
                animation: _anim,
                builder: (_, __) => Stack(
                  children: [
                    GestureDetector(
                      onTapUp: (d) => _onTap(d.localPosition, cats, sz),
                      child: CustomPaint(
                        size: Size(sz, sz),
                        painter: _DNAPainter(
                          categories: cats,
                          animValue: _anim.value,
                          selectedIndex: _selected,
                          colors: _colors,
                        ),
                      ),
                    ),
                    ..._categoryIcons(cats, sz),
                  ],
                ),
              ),
            );
          }).animate(delay: 200.ms).fadeIn(duration: 600.ms),

          const SizedBox(height: 20),

          // Detail card
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 280),
            transitionBuilder: (child, anim) => FadeTransition(
              opacity: anim,
              child: SlideTransition(
                position: Tween(begin: const Offset(0, 0.08), end: Offset.zero).animate(anim),
                child: child,
              ),
            ),
            child: _selected != null
                ? _DetailCard(
                    key: ValueKey(_selected),
                    cat: cats[_selected!],
                    color: _colors[cats[_selected!].id] ?? Colors.blue,
                    icon: _icons[cats[_selected!].id] ?? Icons.place_rounded,
                    overallScore: widget.score.overall,
                  )
                : const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    child: Text(
                      'Tap any ring or icon to explore that category',
                      style: TextStyle(color: Colors.white30, fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                  ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  List<Widget> _categoryIcons(List<CategoryScore> cats, double sz) {
    final center = sz / 2;
    final maxR = center * 0.70;
    return cats.asMap().entries.map((e) {
      final angle = (2 * pi / cats.length) * e.key - pi / 2;
      final r = maxR + 34;
      final x = center + r * cos(angle) - 18;
      final y = center + r * sin(angle) - 18;
      final color = _colors[e.value.id] ?? Colors.white;
      final active = _selected == e.key;
      return Positioned(
        left: x,
        top: y,
        child: GestureDetector(
          onTap: () => setState(() => _selected = active ? null : e.key),
          child: AnimatedContainer(
            duration: 200.ms,
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: active ? color : color.withOpacity(0.15),
              shape: BoxShape.circle,
              border: Border.all(color: color.withOpacity(active ? 1 : 0.4), width: 1.5),
              boxShadow: active ? [BoxShadow(color: color.withOpacity(0.5), blurRadius: 12)] : [],
            ),
            child: Icon(_icons[e.value.id] ?? Icons.place_rounded,
                color: active ? Colors.white : color, size: 16),
          ),
        ),
      );
    }).toList();
  }

  String? _locationMeta(AddressModel? address) {
    if (address == null) return null;
    final parts = [
      if (address.district != null && address.district!.isNotEmpty) address.district!,
      if (address.city != null && address.city!.isNotEmpty) address.city!,
      if (address.postalCode != null && address.postalCode!.isNotEmpty) address.postalCode!,
    ];
    return parts.isEmpty ? null : parts.join(' · ');
  }

  void _onTap(Offset pos, List<CategoryScore> cats, double sz) {
    final center = sz / 2;
    final dx = pos.dx - center;
    final dy = pos.dy - center;
    final angle = atan2(dy, dx) + pi / 2;
    final normalised = angle < 0 ? angle + 2 * pi : angle;
    final idx = (normalised / (2 * pi / cats.length)).floor() % cats.length;
    setState(() => _selected = _selected == idx ? null : idx);
  }
}

// ─── Painter ─────────────────────────────────────────────────────────────────

class _DNAPainter extends CustomPainter {
  final List<CategoryScore> categories;
  final double animValue;
  final int? selectedIndex;
  final Map<String, Color> colors;

  const _DNAPainter({
    required this.categories,
    required this.animValue,
    required this.colors,
    this.selectedIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final maxR = size.width / 2 * 0.70;
    final n = categories.length;

    // Dark circle background
    canvas.drawCircle(c, size.width / 2 * 0.88,
        Paint()..color = const Color(0xFF0D1525));

    // Reference rings
    final gridPaint = Paint()
      ..color = Colors.white.withOpacity(0.06)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;
    for (final pct in [0.25, 0.5, 0.75, 1.0]) {
      canvas.drawCircle(c, maxR * pct, gridPaint);
    }

    // Spoke lines
    final spokePaint = Paint()
      ..color = Colors.white.withOpacity(0.05)
      ..strokeWidth = 0.8;
    for (int i = 0; i < n; i++) {
      final a = (2 * pi / n) * i - pi / 2;
      canvas.drawLine(c, Offset(c.dx + maxR * cos(a), c.dy + maxR * sin(a)), spokePaint);
    }

    if (animValue <= 0.01) return;

    // Score points
    final pts = <Offset>[];
    for (int i = 0; i < n; i++) {
      final a = (2 * pi / n) * i - pi / 2;
      final r = maxR * (categories[i].score.clamp(0.0, 100.0) / 100.0) * animValue;
      pts.add(Offset(c.dx + r * cos(a), c.dy + r * sin(a)));
    }

    final catColors = categories.map((cat) => colors[cat.id] ?? Colors.blue).toList();
    final sweepColors = [...catColors, catColors.first];
    final shapeRect = Rect.fromCircle(center: c, radius: maxR);

    final sweepShader = SweepGradient(
      colors: sweepColors,
      center: Alignment.center,
      startAngle: -pi / 2,
      endAngle: 3 * pi / 2,
    ).createShader(shapeRect);

    final shapePath = _smoothPath(pts);

    // Outer glow
    canvas.drawPath(
      shapePath,
      Paint()
        ..shader = sweepShader
        ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 20)
        ..style = PaintingStyle.fill,
    );

    // Filled shape
    canvas.saveLayer(Rect.fromLTWH(0, 0, size.width, size.height), Paint());
    canvas.drawPath(shapePath, Paint()..shader = sweepShader..style = PaintingStyle.fill);
    canvas.drawPath(shapePath, Paint()..color = const Color(0xFF080E1A).withOpacity(0.45));
    canvas.restore();

    // Stroke
    canvas.drawPath(
      shapePath,
      Paint()
        ..shader = sweepShader
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round,
    );

    // Score dots
    for (int i = 0; i < n; i++) {
      final color = catColors[i];
      final isActive = selectedIndex == i;
      if (isActive) {
        canvas.drawCircle(pts[i], 14,
            Paint()..color = color.withOpacity(0.2)..style = PaintingStyle.fill);
        canvas.drawCircle(pts[i], 14,
            Paint()..color = color.withOpacity(0.5)..style = PaintingStyle.stroke..strokeWidth = 1.5);
      }
      canvas.drawCircle(pts[i], isActive ? 6.5 : 4.5, Paint()..color = color);
      canvas.drawCircle(pts[i], isActive ? 3 : 2, Paint()..color = Colors.white);
    }

    // Center dot
    canvas.drawCircle(c, 5, Paint()..color = Colors.white.withOpacity(0.3));
    canvas.drawCircle(c, 2.5, Paint()..color = Colors.white.withOpacity(0.7));
  }

  Path _smoothPath(List<Offset> pts) {
    final n = pts.length;
    final path = Path()..moveTo(pts[0].dx, pts[0].dy);
    for (int i = 0; i < n; i++) {
      final p0 = pts[(i - 1 + n) % n];
      final p1 = pts[i];
      final p2 = pts[(i + 1) % n];
      final p3 = pts[(i + 2) % n];
      final cp1x = p1.dx + (p2.dx - p0.dx) / 6;
      final cp1y = p1.dy + (p2.dy - p0.dy) / 6;
      final cp2x = p2.dx - (p3.dx - p1.dx) / 6;
      final cp2y = p2.dy - (p3.dy - p1.dy) / 6;
      path.cubicTo(cp1x, cp1y, cp2x, cp2y, p2.dx, p2.dy);
    }
    return path..close();
  }

  @override
  bool shouldRepaint(_DNAPainter old) =>
      old.animValue != animValue || old.selectedIndex != selectedIndex;
}

// ─── Detail card ─────────────────────────────────────────────────────────────

class _DetailCard extends StatelessWidget {
  final CategoryScore cat;
  final Color color;
  final IconData icon;
  final double overallScore;

  const _DetailCard({
    super.key,
    required this.cat,
    required this.color,
    required this.icon,
    required this.overallScore,
  });

  @override
  Widget build(BuildContext context) {
    final diff = cat.score - overallScore;
    final diffLabel = '${diff >= 0 ? '+' : ''}${diff.round()} vs avg';
    final diffColor = diff >= 0 ? const Color(0xFF66BB6A) : const Color(0xFFEF5350);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF151E30),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.35), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(cat.label,
                        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
                    Text('${cat.count} places found',
                        style: const TextStyle(color: Colors.white54, fontSize: 12)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('${cat.score.round()}',
                      style: TextStyle(color: color, fontSize: 30, fontWeight: FontWeight.w900, height: 1)),
                  Text(diffLabel,
                      style: TextStyle(color: diffColor, fontSize: 11, fontWeight: FontWeight.w600)),
                ],
              ),
            ],
          ),
          if (cat.closest != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.near_me_rounded, color: Colors.white38, size: 14),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text('Closest: ${cat.closest!.name}',
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                        overflow: TextOverflow.ellipsis),
                  ),
                  if (cat.closest!.walkingMinutes != null)
                    Text('${cat.closest!.walkingMinutes} min',
                        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
