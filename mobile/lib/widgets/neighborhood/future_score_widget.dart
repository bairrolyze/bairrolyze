import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../models/score_model.dart';

class FutureScoreWidget extends StatefulWidget {
  final LocationScore score;
  final double topPadding;
  const FutureScoreWidget({super.key, required this.score, this.topPadding = 100});

  @override
  State<FutureScoreWidget> createState() => _FutureScoreWidgetState();
}

class _FutureScoreWidgetState extends State<FutureScoreWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;
  int? _selectedMilestone;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600));
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
    Future.delayed(400.ms, () { if (mounted) _ctrl.forward(); });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  // Deterministic projection based on current category scores
  List<_Milestone> _buildMilestones() {
    final cats = widget.score.categories;
    final base = widget.score.overall;

    // Growth drivers: transit & education signal long-term appreciation
    final transit = cats['transportation']?.score ?? 50;
    final edu = cats['education']?.score ?? 50;
    final health = cats['healthcare']?.score ?? 50;
    final rec = cats['recreation']?.score ?? 50;
    final shop = cats['shopping']?.score ?? 50;

    // Growth rate influenced by category strengths (max ~3 pts/year)
    final growthPotential = ((transit * 0.3) + (edu * 0.25) + (shop * 0.2) +
                              (rec * 0.15) + (health * 0.1)) / 100;
    final yearlyGain = 1.5 + (growthPotential * 3.0);
    final confidenceBase = 0.55 + (growthPotential * 0.35);

    final y1 = (base + yearlyGain).clamp(base, 100.0);
    final y3 = (base + yearlyGain * 2.8).clamp(base, 100.0);
    final y5 = (base + yearlyGain * 4.2).clamp(base, 100.0);

    return [
      _Milestone('Today', '', base, 1.0, _buildFactors(cats, 'now')),
      _Milestone('1 Year', '${DateTime.now().year + 1}', y1, confidenceBase, _buildFactors(cats, '1y')),
      _Milestone('3 Years', '${DateTime.now().year + 3}', y3, (confidenceBase * 0.85).clamp(0, 1), _buildFactors(cats, '3y')),
      _Milestone('5 Years', '${DateTime.now().year + 5}', y5, (confidenceBase * 0.68).clamp(0, 1), _buildFactors(cats, '5y')),
    ];
  }

  List<_Factor> _buildFactors(Map<String, CategoryScore> cats, String horizon) {
    final factors = <_Factor>[];
    final transit = cats['transportation']?.score ?? 0;
    final edu = cats['education']?.score ?? 0;
    final health = cats['healthcare']?.score ?? 0;

    switch (horizon) {
      case 'now':
        if (transit >= 70) factors.add(const _Factor('Strong transit network', Icons.train_rounded, Color(0xFF29B6F6), true));
        if (edu >= 70) factors.add(const _Factor('Quality education access', Icons.school_rounded, Color(0xFF66BB6A), true));
        if (health >= 70) factors.add(const _Factor('Healthcare well covered', Icons.local_hospital_rounded, Color(0xFFEF5350), true));
        if (transit < 50) factors.add(const _Factor('Transit could improve', Icons.warning_amber_rounded, Color(0xFFFFA726), false));
      case '1y':
        factors.add(const _Factor('Infrastructure investment cycles', Icons.construction_rounded, Color(0xFF29B6F6), true));
        if (edu >= 60) factors.add(const _Factor('School catchment stability', Icons.school_rounded, Color(0xFF66BB6A), true));
        factors.add(const _Factor('Business openings increasing', Icons.store_rounded, Color(0xFFFFA726), true));
      case '3y':
        factors.add(const _Factor('Population growth trends', Icons.people_rounded, Color(0xFF6C63FF), true));
        factors.add(const _Factor('Planned transit extensions', Icons.directions_bus_rounded, Color(0xFF29B6F6), true));
        if (health >= 55) factors.add(const _Factor('Healthcare capacity growing', Icons.local_hospital_rounded, Color(0xFFEF5350), true));
      case '5y':
        factors.add(const _Factor('Urban development projects', Icons.apartment_rounded, Color(0xFF6C63FF), true));
        factors.add(const _Factor('Long-term demographic shifts', Icons.trending_up_rounded, Color(0xFF66BB6A), true));
        factors.add(const _Factor('Green infrastructure plans', Icons.park_rounded, Color(0xFF26C6DA), true));
    }

    return factors.take(3).toList();
  }

  @override
  Widget build(BuildContext context) {
    final milestones = _buildMilestones();
    final selected = _selectedMilestone != null ? milestones[_selectedMilestone!] : null;

    return SingleChildScrollView(
      padding: EdgeInsets.only(top: widget.topPadding + 32, bottom: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'FORECAST',
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
                  'Future Score',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 38,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -1.0,
                    height: 1.05,
                  ),
                ).animate(delay: 60.ms).fadeIn(duration: 500.ms).slideY(begin: 0.15, end: 0),
                const SizedBox(height: 16),
                Text(
                  'Not just where it stands —\nwhere it\'s heading.',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.72),
                    fontSize: 18,
                    fontWeight: FontWeight.w400,
                    height: 1.6,
                  ),
                ).animate(delay: 120.ms).fadeIn(duration: 500.ms),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Trajectory chart
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: AnimatedBuilder(
              animation: _anim,
              builder: (_, __) => GestureDetector(
                onTapUp: (d) => _onTapMilestone(d.localPosition, milestones),
                child: SizedBox(
                  height: 220,
                  child: CustomPaint(
                    painter: _TrajectoryPainter(
                      milestones: milestones,
                      animValue: _anim.value,
                      selectedIndex: _selectedMilestone,
                    ),
                    child: const SizedBox.expand(),
                  ),
                ),
              ),
            ),
          ).animate(delay: 200.ms).fadeIn(),

          const SizedBox(height: 20),

          // Milestone cards (horizontal scroll)
          SizedBox(
            height: 104,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: milestones.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (_, i) {
                final m = milestones[i];
                final active = _selectedMilestone == i;
                final gain = m.score - milestones[0].score;
                return GestureDetector(
                  onTap: () => setState(() => _selectedMilestone = active ? null : i),
                  child: AnimatedContainer(
                    duration: 250.ms,
                    width: 130,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: active ? const Color(0xFF6C63FF).withOpacity(0.2) : const Color(0xFF151E30),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: active ? const Color(0xFF6C63FF) : Colors.white.withOpacity(0.08),
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(m.label, style: const TextStyle(color: Colors.white60, fontSize: 11, fontWeight: FontWeight.w500)),
                        if (m.year.isNotEmpty)
                          Text(m.year, style: const TextStyle(color: Colors.white38, fontSize: 10)),
                        const Spacer(),
                        Text(
                          m.score.round().toString(),
                          style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900, height: 1),
                        ),
                        if (i > 0)
                          Text(
                            '+${gain.toStringAsFixed(1)}',
                            style: const TextStyle(color: Color(0xFF66BB6A), fontSize: 11, fontWeight: FontWeight.w600),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ).animate(delay: 300.ms).fadeIn(),

          const SizedBox(height: 20),

          // Factors panel
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: selected != null
                ? _FactorsPanel(
                    key: ValueKey(_selectedMilestone),
                    milestone: selected,
                  )
                : Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF151E30),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white.withOpacity(0.06)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.touch_app_rounded, color: Colors.white30, size: 18),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Text(
                              'Tap a milestone above to see what\'s driving the projection',
                              style: TextStyle(color: Colors.white38, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
          ),

          const SizedBox(height: 16),

          // Disclaimer
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Icon(Icons.info_outline_rounded, color: Colors.white.withOpacity(0.2), size: 13),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Projections are indicative estimates based on current amenity data. Not investment advice.',
                    style: TextStyle(color: Colors.white.withOpacity(0.22), fontSize: 11, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _onTapMilestone(Offset pos, List<_Milestone> milestones) {
    const padding = 24.0;
    final w = MediaQuery.of(context).size.width - 40;
    final sectionW = (w - padding * 2) / (milestones.length - 1);
    final x = pos.dx - padding;
    final idx = (x / sectionW).round().clamp(0, milestones.length - 1);
    setState(() => _selectedMilestone = _selectedMilestone == idx ? null : idx);
  }
}

class _Milestone {
  final String label;
  final String year;
  final double score;
  final double confidence;
  final List<_Factor> factors;
  const _Milestone(this.label, this.year, this.score, this.confidence, this.factors);
}

class _Factor {
  final String text;
  final IconData icon;
  final Color color;
  final bool positive;
  const _Factor(this.text, this.icon, this.color, this.positive);
}

// ─── Trajectory painter ──────────────────────────────────────────────────────

class _TrajectoryPainter extends CustomPainter {
  final List<_Milestone> milestones;
  final double animValue;
  final int? selectedIndex;

  const _TrajectoryPainter({
    required this.milestones,
    required this.animValue,
    this.selectedIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (milestones.isEmpty) return;

    const hPad = 24.0;
    const vPad = 20.0;
    final w = size.width - hPad * 2;
    final h = size.height - vPad * 2;

    final scores = milestones.map((m) => m.score).toList();
    final minS = scores.reduce(min) - 5;
    final maxS = min(scores.reduce(max) + 10, 100.0);
    final range = maxS - minS;

    Offset ptAt(int i) {
      final x = hPad + (w / (milestones.length - 1)) * i;
      final normalised = (scores[i] - minS) / range;
      final y = vPad + h * (1 - normalised);
      return Offset(x, y);
    }

    // Grid lines
    final gridPaint = Paint()
      ..color = Colors.white.withOpacity(0.05)
      ..strokeWidth = 1;
    for (final pct in [0.25, 0.5, 0.75, 1.0]) {
      final y = vPad + h * (1 - pct);
      canvas.drawLine(Offset(hPad, y), Offset(hPad + w, y), gridPaint);
      final tp = TextPainter(
        text: TextSpan(
          text: (minS + range * pct).round().toString(),
          style: TextStyle(color: Colors.white.withOpacity(0.2), fontSize: 9),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(0, y - 5));
    }

    // Build path (up to animValue)
    final pts = List.generate(milestones.length, ptAt);
    final totalSegs = milestones.length - 1;
    final drawn = animValue * totalSegs;

    // Confidence band (light fill below the line)
    if (animValue > 0.3) {
      final bandPath = Path();
      bandPath.moveTo(pts[0].dx, size.height);
      bandPath.lineTo(pts[0].dx, pts[0].dy);
      for (int i = 0; i < totalSegs; i++) {
        final segProgress = ((drawn - i)).clamp(0.0, 1.0);
        if (segProgress <= 0) break;
        final p1 = pts[i];
        final p2 = pts[min(i + 1, pts.length - 1)];
        final cp1 = Offset(p1.dx + (p2.dx - p1.dx) * 0.4, p1.dy);
        final cp2 = Offset(p2.dx - (p2.dx - p1.dx) * 0.4, p2.dy);
        final end = Offset.lerp(p1, p2, segProgress)!;
        // Approximate with cubic bezier clipped
        if (segProgress >= 1) {
          bandPath.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, p2.dx, p2.dy);
        } else {
          bandPath.lineTo(end.dx, end.dy);
        }
      }
      bandPath.lineTo(pts[min(drawn.floor(), totalSegs)].dx, size.height);
      bandPath.close();
      canvas.drawPath(
        bandPath,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [const Color(0xFF6C63FF).withOpacity(0.2), Colors.transparent],
          ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
      );
    }

    // Line
    final linePaint = Paint()
      ..color = const Color(0xFF6C63FF)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final linePath = Path()..moveTo(pts[0].dx, pts[0].dy);
    for (int i = 0; i < totalSegs; i++) {
      final segProgress = (drawn - i).clamp(0.0, 1.0);
      if (segProgress <= 0) break;
      final p1 = pts[i];
      final p2 = pts[i + 1];
      final cp1 = Offset(p1.dx + (p2.dx - p1.dx) * 0.4, p1.dy);
      final cp2 = Offset(p2.dx - (p2.dx - p1.dx) * 0.4, p2.dy);
      if (segProgress >= 1) {
        linePath.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, p2.dx, p2.dy);
      } else {
        linePath.lineTo(Offset.lerp(p1, p2, segProgress)!.dx,
                        Offset.lerp(p1, p2, segProgress)!.dy);
      }
    }

    // Glow
    canvas.drawPath(linePath, Paint()
      ..color = const Color(0xFF6C63FF).withOpacity(0.35)
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8));
    canvas.drawPath(linePath, linePaint);

    // Nodes
    for (int i = 0; i < milestones.length; i++) {
      if (i > drawn + 0.1) break;
      final pt = pts[i];
      final isSelected = selectedIndex == i;
      final conf = milestones[i].confidence;

      if (isSelected) {
        canvas.drawCircle(pt, 20, Paint()..color = const Color(0xFF6C63FF).withOpacity(0.2));
        canvas.drawCircle(pt, 20,
            Paint()..color = const Color(0xFF6C63FF).withOpacity(0.5)..style = PaintingStyle.stroke..strokeWidth = 1.5);
      }

      canvas.drawCircle(pt, 10,
          Paint()..color = const Color(0xFF6C63FF).withOpacity(0.3)..style = PaintingStyle.stroke..strokeWidth = 2);
      canvas.drawCircle(pt, 7, Paint()..color = isSelected ? const Color(0xFF6C63FF) : const Color(0xFF1A2235));
      canvas.drawCircle(pt, 4,
          Paint()..color = const Color(0xFF6C63FF)..style = PaintingStyle.stroke..strokeWidth = 2);

      // Score label
      final scoreTp = TextPainter(
        text: TextSpan(
          text: milestones[i].score.round().toString(),
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white70,
            fontSize: isSelected ? 14 : 12,
            fontWeight: FontWeight.w800,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      scoreTp.paint(canvas, Offset(pt.dx - scoreTp.width / 2, pt.dy - 28));

      // Confidence band (dotted outline for future nodes)
      if (i > 0) {
        final confWidth = conf * 12;
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: pt, width: confWidth, height: confWidth),
            const Radius.circular(4),
          ),
          Paint()
            ..color = Colors.white.withOpacity(0.08)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1,
        );
      }

      // Label below
      final labelTp = TextPainter(
        text: TextSpan(
          text: milestones[i].label,
          style: TextStyle(color: Colors.white.withOpacity(0.45), fontSize: 10, fontWeight: FontWeight.w500),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      labelTp.paint(canvas, Offset(pt.dx - labelTp.width / 2, size.height - vPad + 4));
    }
  }

  @override
  bool shouldRepaint(_TrajectoryPainter old) =>
      old.animValue != animValue || old.selectedIndex != selectedIndex;
}

// ─── Factors panel ───────────────────────────────────────────────────────────

class _FactorsPanel extends StatelessWidget {
  final _Milestone milestone;
  const _FactorsPanel({super.key, required this.milestone});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF151E30),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF6C63FF).withOpacity(0.3), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                milestone.label,
                style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF6C63FF).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${(milestone.confidence * 100).round()}% confidence',
                  style: const TextStyle(color: Color(0xFF6C63FF), fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...milestone.factors.asMap().entries.map((e) => Padding(
            padding: EdgeInsets.only(bottom: e.key < milestone.factors.length - 1 ? 10 : 0),
            child: Row(
              children: [
                Container(
                  width: 30, height: 30,
                  decoration: BoxDecoration(
                    color: e.value.color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(e.value.icon, color: e.value.color, size: 15),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(e.value.text,
                      style: const TextStyle(color: Colors.white70, fontSize: 13)),
                ),
                Icon(
                  e.value.positive ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                  color: e.value.positive ? const Color(0xFF66BB6A) : const Color(0xFFFFA726),
                  size: 14,
                ),
              ],
            ),
          )),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.08, end: 0);
  }
}
