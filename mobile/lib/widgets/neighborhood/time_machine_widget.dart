import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../models/score_model.dart';

class TimeMachineWidget extends StatefulWidget {
  final LocationScore score;
  final double topPadding;

  const TimeMachineWidget({super.key, required this.score, this.topPadding = 96});

  @override
  State<TimeMachineWidget> createState() => _TimeMachineWidgetState();
}

class _TimeMachineWidgetState extends State<TimeMachineWidget> {
  double _hour = 9.0;

  // Time-of-day activity multipliers per category (0.0–1.0)
  // These shape how each category's activity level changes across the day
  static const _profiles = <String, List<double>>{
    'transportation': [0.1, 0.2, 0.5, 0.9, 0.8, 0.7, 0.7, 0.8, 0.9, 0.8, 0.7, 0.7,
                       0.7, 0.6, 0.6, 0.7, 0.8, 1.0, 0.9, 0.7, 0.5, 0.4, 0.3, 0.1],
    'education':     [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.3, 0.8, 1.0, 1.0, 1.0, 1.0,
                       0.9, 0.9, 0.9, 0.5, 0.2, 0.1, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0],
    'healthcare':    [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.4, 0.9, 1.0, 1.0, 0.9,
                       0.8, 0.9, 0.9, 0.8, 0.7, 0.3, 0.2, 0.1, 0.0, 0.0, 0.0, 0.0],
    'shopping':      [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.2, 0.5, 0.7, 0.9, 1.0,
                       1.0, 1.0, 0.9, 0.8, 0.7, 0.6, 0.5, 0.4, 0.2, 0.1, 0.0, 0.0],
    'safety':        [0.7, 0.6, 0.5, 0.5, 0.4, 0.4, 0.5, 0.6, 0.8, 0.9, 0.9, 0.9,
                       0.9, 0.9, 0.9, 0.8, 0.7, 0.7, 0.6, 0.6, 0.6, 0.6, 0.7, 0.7],
    'recreation':    [0.0, 0.0, 0.0, 0.0, 0.0, 0.2, 0.4, 0.6, 0.7, 0.7, 0.7, 0.6,
                       0.5, 0.5, 0.6, 0.7, 0.7, 0.8, 0.9, 1.0, 0.9, 0.7, 0.3, 0.1],
    'religion':      [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.5, 0.8, 0.9, 0.7, 0.3, 0.1,
                       0.1, 0.1, 0.1, 0.1, 0.1, 0.1, 0.3, 0.4, 0.3, 0.1, 0.0, 0.0],
  };

  static const _catColors = {
    'transportation': Color(0xFF29B6F6),
    'education': Color(0xFF66BB6A),
    'healthcare': Color(0xFFEF5350),
    'shopping': Color(0xFFFFA726),
    'safety': Color(0xFFAB47BC),
    'religion': Color(0xFF8D6E63),
    'recreation': Color(0xFF26C6DA),
  };

  static const _catIcons = {
    'transportation': Icons.train_rounded,
    'education': Icons.school_rounded,
    'healthcare': Icons.local_hospital_rounded,
    'shopping': Icons.shopping_bag_rounded,
    'safety': Icons.shield_rounded,
    'religion': Icons.church_rounded,
    'recreation': Icons.park_rounded,
  };

  // Sky gradient based on hour
  List<Color> get _skyColors {
    final h = _hour;
    if (h < 5 || h >= 23) return [const Color(0xFF020818), const Color(0xFF0D1B40)];
    if (h < 7)  return [const Color(0xFF1A0A2E), const Color(0xFF3D1A5C), const Color(0xFFFF6B35)];
    if (h < 9)  return [const Color(0xFFFF8C42), const Color(0xFFFFD166), const Color(0xFF5BBCFF)];
    if (h < 17) return [const Color(0xFF1A73E8), const Color(0xFF5BBCFF), const Color(0xFF8DD7F7)];
    if (h < 19) return [const Color(0xFFFF8C42), const Color(0xFFFF5F57), const Color(0xFF3D1A5C)];
    if (h < 21) return [const Color(0xFF3D1A5C), const Color(0xFF1A0A2E), const Color(0xFF0D1B40)];
    return [const Color(0xFF080E1A), const Color(0xFF0D1B40)];
  }

  String get _timeLabel {
    final h = _hour.floor();
    final m = ((_hour - h) * 60).round();
    final mm = m.toString().padLeft(2, '0');
    final period = h < 12 ? 'AM' : 'PM';
    final h12 = h == 0 ? 12 : (h > 12 ? h - 12 : h);
    return '${h12.toString().padLeft(2, '0')}:$mm $period';
  }

  String get _timeDescription {
    final h = _hour;
    if (h < 5)  return 'Deep night — the city sleeps';
    if (h < 7)  return 'Early morning — the day stirs';
    if (h < 9)  return 'Morning rush — energy builds';
    if (h < 12) return 'Late morning — fully awake';
    if (h < 14) return 'Lunch hour — streets fill';
    if (h < 17) return 'Afternoon — steady rhythm';
    if (h < 19) return 'Evening rush — peak activity';
    if (h < 21) return 'Evening — restaurants & parks';
    if (h < 23) return 'Late night — winding down';
    return 'Midnight — quiet streets';
  }

  double _activityAt(String catId, double hour) {
    final profile = _profiles[catId];
    if (profile == null) return 0.5;
    final h = hour.floor().clamp(0, 23);
    final next = (h + 1) % 24;
    final frac = hour - hour.floor();
    return profile[h] * (1 - frac) + profile[next] * frac;
  }

  @override
  Widget build(BuildContext context) {
    final cats = widget.score.categories.values.toList();

    return Column(
      children: [
        // Sky gradient header
        Expanded(
          flex: 3,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeInOut,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: _skyColors,
              ),
            ),
            child: Stack(
              children: [
                // Stars (night only)
                if (_hour < 6 || _hour > 21)
                  ...List.generate(20, (i) {
                    final r = Random(i);
                    return Positioned(
                      left: r.nextDouble() * MediaQuery.of(context).size.width,
                      top: r.nextDouble() * 160,
                      child: Container(
                        width: r.nextDouble() * 2 + 1,
                        height: r.nextDouble() * 2 + 1,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(r.nextDouble() * 0.6 + 0.4),
                          shape: BoxShape.circle,
                        ),
                      ),
                    );
                  }),
                // Content
                Padding(
                  padding: EdgeInsets.fromLTRB(24, widget.topPadding + 20, 24, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'ACTIVITY',
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
                        'Time Machine',
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
                        'See how your neighbourhood\nchanges throughout the day.',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.72),
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          height: 1.6,
                        ),
                      ).animate(delay: 120.ms).fadeIn(duration: 500.ms),
                      const Spacer(),
                      // Time display
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            _timeLabel,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 42,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -2,
                              height: 1,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: AnimatedSwitcher(
                              duration: 400.ms,
                              child: Text(
                                _timeDescription,
                                key: ValueKey(_timeDescription),
                                style: const TextStyle(color: Colors.white60, fontSize: 13, height: 1.3),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // Activity bars
        Expanded(
          flex: 4,
          child: Container(
            color: const Color(0xFF080E1A),
            child: Column(
              children: [
                // Slider
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Column(
                    children: [
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight: 4,
                          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
                          overlayShape: const RoundSliderOverlayShape(overlayRadius: 18),
                          activeTrackColor: const Color(0xFF6C63FF),
                          inactiveTrackColor: Colors.white.withOpacity(0.1),
                          thumbColor: const Color(0xFF6C63FF),
                          overlayColor: const Color(0xFF6C63FF).withOpacity(0.2),
                        ),
                        child: Slider(
                          value: _hour,
                          min: 0,
                          max: 23.99,
                          onChanged: (v) => setState(() => _hour = v),
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: ['12am', '6am', '12pm', '6pm', '11pm'].map((t) =>
                          Text(t, style: const TextStyle(color: Colors.white30, fontSize: 10)),
                        ).toList(),
                      ),
                    ],
                  ),
                ),

                // Category activity rows
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                    children: cats.map((cat) {
                      final activity = _activityAt(cat.id, _hour);
                      final color = _catColors[cat.id] ?? Colors.grey;
                      final icon = _catIcons[cat.id] ?? Icons.place_rounded;
                      final effectiveScore = (cat.score / 100) * activity;
                      return _ActivityRow(
                        label: cat.label,
                        icon: icon,
                        color: color,
                        activity: activity,
                        effectiveScore: effectiveScore,
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ActivityRow extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final double activity;
  final double effectiveScore;

  const _ActivityRow({
    required this.label,
    required this.icon,
    required this.color,
    required this.activity,
    required this.effectiveScore,
  });

  String get _activityLabel {
    if (activity < 0.2) return 'Quiet';
    if (activity < 0.5) return 'Low';
    if (activity < 0.75) return 'Active';
    if (activity < 0.9) return 'Busy';
    return 'Peak';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: Text(label,
                style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500)),
          ),
          Expanded(
            flex: 5,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: effectiveScore),
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeOutCubic,
                builder: (_, v, __) => LinearProgressIndicator(
                  value: v.clamp(0.0, 1.0),
                  minHeight: 6,
                  backgroundColor: color.withOpacity(0.12),
                  valueColor: AlwaysStoppedAnimation(color),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 36,
            child: Text(
              _activityLabel,
              style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w600),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}
