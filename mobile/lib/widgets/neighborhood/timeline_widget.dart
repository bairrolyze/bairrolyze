import 'dart:math' show pow;
import 'package:flutter/material.dart';

import '../../models/score_model.dart';

// ─── Design tokens ───────────────────────────────────────────────────────────
const _kBg       = Color(0xFF060B14);
const _kSurface  = Color(0xFF0D1625);
// ignore: unused_element
const _kSurface2 = Color(0xFF131F33);
const _kAccent   = Color(0xFF3B82F6);
const _kBorder   = Color(0xFF1A2845);

// ─── Category meta ───────────────────────────────────────────────────────────
const _catColors = {
  'transportation': Color(0xFF29B6F6),
  'education':      Color(0xFF66BB6A),
  'healthcare':     Color(0xFFEF5350),
  'shopping':       Color(0xFFFFA726),
  'safety':         Color(0xFFAB47BC),
  'recreation':     Color(0xFF26C6DA),
  'religion':       Color(0xFF8D6E63),
};

const _catIcons = {
  'transportation': Icons.train_rounded,
  'education':      Icons.school_rounded,
  'healthcare':     Icons.local_hospital_rounded,
  'shopping':       Icons.shopping_bag_rounded,
  'safety':         Icons.shield_rounded,
  'recreation':     Icons.park_rounded,
  'religion':       Icons.church_rounded,
};

// ─── Milestone event templates ────────────────────────────────────────────────
const _milestoneTemplates = <String, List<List<String>>>{
  'transportation': [
    ['New metro & bus routes added',    'Transit lines extended to serve more residents'],
    ['Transit connectivity improved',   'Journey times reduced across the network'],
  ],
  'education': [
    ['Primary school opened',           'New public school brings capacity for 400 pupils'],
    ['Educational facilities expanded', 'Libraries and study centres upgraded'],
  ],
  'healthcare': [
    ['Health centre renovation',        'GP surgery and pharmacy fully refurbished'],
    ['Medical services expanded',       'Specialist clinics added to local centre'],
  ],
  'shopping': [
    ['Commercial zone developed',       'Mixed-use retail development completed'],
    ['New retail hub opened',           'Supermarket and local shops now trading'],
  ],
  'safety': [
    ['Safety initiative launched',      'Community policing programme introduced'],
    ['Emergency services improved',     'Fire and ambulance response times cut'],
  ],
  'recreation': [
    ['Urban park opened',               'Green space with 2 km of walking paths created'],
    ['Green space expanded',            'Existing parkland extended by 3 hectares'],
  ],
  'religion': [
    ['Place of worship renovated',      'Historic building restored and reopened'],
    ['Community centre added',          'Multi-faith gathering space now open'],
  ],
};

// ─── Score simulation helpers ─────────────────────────────────────────────────

/// Generates 8 deterministic yearly scores from 2018 to 2025 (index 7 = current).
List<double> _buildYearlyScores(double overall) {
  final startScore = (overall - 14 - overall * 0.08).clamp(25.0, 72.0);
  return List.generate(8, (i) {
    final base = startScore + (overall - startScore) * pow(i / 7, 0.7);
    final noise = (i * 7 + overall.round()) % 5 - 2.5;
    return (base + noise).clamp(0.0, 100.0);
  });
}

// ─── Widget ───────────────────────────────────────────────────────────────────

class NeighborhoodTimelineWidget extends StatefulWidget {
  final LocationScore score;
  final double topPadding;

  const NeighborhoodTimelineWidget({
    super.key,
    required this.score,
    this.topPadding = 96,
  });

  @override
  State<NeighborhoodTimelineWidget> createState() =>
      _NeighborhoodTimelineWidgetState();
}

class _NeighborhoodTimelineWidgetState
    extends State<NeighborhoodTimelineWidget> {
  late final List<double> _yearlyScores;
  late final List<_MilestoneEvent> _milestones;
  late final List<MapEntry<String, CategoryScore>> _topCats;

  static const _years = [2018, 2019, 2020, 2021, 2022, 2023, 2024, 2025];

  @override
  void initState() {
    super.initState();
    _yearlyScores = _buildYearlyScores(widget.score.overall);
    _topCats = _buildTopCats();
    _milestones = _buildMilestones();
  }

  // Top 5 categories sorted by score descending
  List<MapEntry<String, CategoryScore>> _buildTopCats() {
    final entries = widget.score.categories.entries.toList()
      ..sort((a, b) => b.value.score.compareTo(a.value.score));
    return entries.take(5).toList();
  }

  // Generate 6-8 milestone events deterministically
  List<_MilestoneEvent> _buildMilestones() {
    final events = <_MilestoneEvent>[];

    widget.score.categories.forEach((id, cat) {
      final templates = _milestoneTemplates[id];
      if (templates == null) return;

      // How many events this category contributes (1 or 2)
      final count = cat.score >= 55 ? 2 : 1;

      for (var t = 0; t < count; t++) {
        final tpl = templates[t % templates.length];
        // Derive year from score: higher score → more recent event
        final yearOffset = ((cat.score / 100) * 5).round();
        final rawYear = 2019 + yearOffset + t;
        final year = rawYear.clamp(2018, 2025);

        events.add(_MilestoneEvent(
          year: year,
          title: tpl[0],
          subtitle: tpl[1],
          categoryId: id,
        ));
      }
    });

    // Sort by year ascending, stable
    events.sort((a, b) => a.year.compareTo(b.year));

    // Clamp to 8 events max
    return events.take(8).toList();
  }

  @override
  Widget build(BuildContext context) {
    final gainPts = (_yearlyScores.last - _yearlyScores.first).round();

    return Container(
      color: _kBg,
      padding: EdgeInsets.only(top: widget.topPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Section 1: Score Journey ──────────────────────────────────
          _SectionLabel('SCORE JOURNEY'),
          _ScoreJourneyCard(
            yearlyScores: _yearlyScores,
            years: _years,
            gainPts: gainPts,
          ),

          const SizedBox(height: 28),

          // ── Section 2: Category Evolution ─────────────────────────────
          _SectionLabel('CATEGORY EVOLUTION'),
          _CategoryEvolutionCard(topCats: _topCats),

          const SizedBox(height: 28),

          // ── Section 3: Key Milestones ─────────────────────────────────
          _SectionLabel('KEY MILESTONES'),
          _MilestonesCard(milestones: _milestones),

          const SizedBox(height: 28),
        ],
      ),
    );
  }
}

// ─── Section label ────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
      child: Text(
        text,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.28),
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.6,
        ),
      ),
    );
  }
}

// ─── Score Journey card ───────────────────────────────────────────────────────

class _ScoreJourneyCard extends StatelessWidget {
  final List<double> yearlyScores;
  final List<int> years;
  final int gainPts;

  const _ScoreJourneyCard({
    required this.yearlyScores,
    required this.years,
    required this.gainPts,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: _kSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _kBorder),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header text
            Text(
              'How this neighbourhood evolved',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Simulated 8-year development trajectory',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.45),
                fontSize: 12,
              ),
            ),

            const SizedBox(height: 20),

            // Chart
            SizedBox(
              height: 100,
              child: CustomPaint(
                painter: _ScoreJourneyPainter(
                  scores: yearlyScores,
                  color: _kAccent,
                ),
                child: const SizedBox.expand(),
              ),
            ),

            const SizedBox(height: 8),

            // X-axis year labels
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text('2018', style: _xAxisStyle),
                Text('2020', style: _xAxisStyle),
                Text('2022', style: _xAxisStyle),
                Text('2024', style: _xAxisStyle),
                Text('2026', style: _xAxisStyle),
              ],
            ),

            const SizedBox(height: 16),

            // Summary stat
            Row(
              children: [
                const Icon(Icons.trending_up_rounded,
                    color: Color(0xFF4ADE80), size: 16),
                const SizedBox(width: 6),
                Text(
                  '+$gainPts pts since 2018 · Growing steadily',
                  style: const TextStyle(
                    color: Color(0xFF4ADE80),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
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

const _xAxisStyle = TextStyle(
  color: Color(0xFF4A6080),
  fontSize: 10,
  fontWeight: FontWeight.w500,
);

// ─── CustomPainter: Score Journey line chart ──────────────────────────────────

class _ScoreJourneyPainter extends CustomPainter {
  final List<double> scores;
  final Color color;

  const _ScoreJourneyPainter({required this.scores, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (scores.isEmpty) return;

    final minScore = scores.reduce((a, b) => a < b ? a : b);
    final maxScore = scores.reduce((a, b) => a > b ? a : b);
    final range = (maxScore - minScore).clamp(1.0, 100.0);

    // Leave bottom margin for labels (handled outside), add top padding
    const vPad = 10.0;
    final h = size.height - vPad;

    Offset toPoint(int i) {
      final x = (i / (scores.length - 1)) * size.width;
      final y = vPad + (1.0 - (scores[i] - minScore) / range) * h;
      return Offset(x, y);
    }

    final points = List.generate(scores.length, toPoint);

    // Build bezier path
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 0; i < points.length - 1; i++) {
      final cp1 = Offset(
        points[i].dx + (points[i + 1].dx - points[i].dx) * 0.5,
        points[i].dy,
      );
      final cp2 = Offset(
        points[i].dx + (points[i + 1].dx - points[i].dx) * 0.5,
        points[i + 1].dy,
      );
      path.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy,
          points[i + 1].dx, points[i + 1].dy);
    }

    // Filled area
    final fillPath = Path.from(path)
      ..lineTo(points.last.dx, size.height)
      ..lineTo(points.first.dx, size.height)
      ..close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          color.withValues(alpha: 0.25),
          color.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawPath(fillPath, fillPaint);

    // Stroke line
    final strokePaint = Paint()
      ..color = color
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(path, strokePaint);

    // Small dots at each point
    final dotPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    for (var i = 0; i < points.length - 1; i++) {
      canvas.drawCircle(points[i], 3.5, dotPaint);
    }

    // Last point (current score): larger dot with glow ring
    final last = points.last;

    // Glow ring
    final glowPaint = Paint()
      ..color = color.withValues(alpha: 0.22)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(last, 14, glowPaint);

    // Outer ring
    final ringPaint = Paint()
      ..color = color.withValues(alpha: 0.55)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(last, 10, ringPaint);

    // Filled centre
    canvas.drawCircle(last, 6, dotPaint);

    // Score label above current dot
    final label = scores.last.round().toString();
    final tp = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    tp.paint(canvas,
        Offset(last.dx - tp.width / 2, last.dy - 22));
  }

  @override
  bool shouldRepaint(_ScoreJourneyPainter old) =>
      old.scores != scores || old.color != color;
}

// ─── Category Evolution card ──────────────────────────────────────────────────

class _CategoryEvolutionCard extends StatelessWidget {
  final List<MapEntry<String, CategoryScore>> topCats;

  const _CategoryEvolutionCard({required this.topCats});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: _kSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _kBorder),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Legend row
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _LegendDot(color: Colors.white.withValues(alpha: 0.3),
                    label: '2018'),
                const SizedBox(width: 14),
                _LegendDot(color: _kAccent, label: '2026'),
              ],
            ),
            const SizedBox(height: 14),

            // Bar rows
            ...topCats.map((entry) {
              final cat = entry.value;
              final score2026 = cat.score;
              final score2018 =
                  (cat.score * 0.72 + cat.score * 0.05).clamp(0.0, 100.0);
              final delta = (score2026 - score2018).round();
              final color =
                  _catColors[entry.key] ?? _kAccent;

              return Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: _EvolutionRow(
                  label: cat.label,
                  score2018: score2018,
                  score2026: score2026,
                  delta: delta,
                  color: color,
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label,
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.45), fontSize: 10)),
      ],
    );
  }
}

class _EvolutionRow extends StatelessWidget {
  final String label;
  final double score2018;
  final double score2026;
  final int delta;
  final Color color;

  const _EvolutionRow({
    required this.label,
    required this.score2018,
    required this.score2026,
    required this.delta,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w500),
              ),
            ),
            Text(
              '+$delta',
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        // 2018 bar (grey)
        _Bar(
          fraction: score2018 / 100,
          color: Colors.white.withValues(alpha: 0.18),
          height: 5,
        ),
        const SizedBox(height: 4),
        // 2026 bar (accent)
        _Bar(
          fraction: score2026 / 100,
          color: color,
          height: 7,
        ),
      ],
    );
  }
}

class _Bar extends StatelessWidget {
  final double fraction;
  final Color color;
  final double height;

  const _Bar(
      {required this.fraction, required this.color, required this.height});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      return Stack(
        children: [
          Container(
            height: height,
            width: constraints.maxWidth,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(height),
            ),
          ),
          Container(
            height: height,
            width: constraints.maxWidth * fraction.clamp(0.0, 1.0),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(height),
            ),
          ),
        ],
      );
    });
  }
}

// ─── Key Milestones card ──────────────────────────────────────────────────────

class _MilestoneEvent {
  final int year;
  final String title;
  final String subtitle;
  final String categoryId;

  const _MilestoneEvent({
    required this.year,
    required this.title,
    required this.subtitle,
    required this.categoryId,
  });
}

class _MilestonesCard extends StatelessWidget {
  final List<_MilestoneEvent> milestones;

  const _MilestonesCard({required this.milestones});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: _kSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _kBorder),
        ),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
        child: Column(
          children: List.generate(milestones.length, (i) {
            final event = milestones[i];
            final isLast = i == milestones.length - 1;
            final color =
                _catColors[event.categoryId] ?? _kAccent;
            final icon =
                _catIcons[event.categoryId] ?? Icons.place_rounded;

            return _MilestoneItem(
              event: event,
              color: color,
              icon: icon,
              isLast: isLast,
            );
          }),
        ),
      ),
    );
  }
}

class _MilestoneItem extends StatelessWidget {
  final _MilestoneEvent event;
  final Color color;
  final IconData icon;
  final bool isLast;

  const _MilestoneItem({
    required this.event,
    required this.color,
    required this.icon,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    const dotSize = 28.0;
    const lineWidth = 2.0;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Left column: line + dot
          SizedBox(
            width: dotSize,
            child: Column(
              children: [
                // Dot
                Container(
                  width: dotSize,
                  height: dotSize,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                    border: Border.all(color: color.withValues(alpha: 0.6)),
                  ),
                  child: Icon(icon, color: color, size: 14),
                ),
                // Vertical line below dot (except last item)
                if (!isLast)
                  Expanded(
                    child: Center(
                      child: Container(
                        width: lineWidth,
                        color: _kBorder,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(width: 14),

          // Right column: content
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 20, top: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.year.toString(),
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.38),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    event.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    event.subtitle,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.45),
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
