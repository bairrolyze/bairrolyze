import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../config/app_theme.dart';
import '../../providers/analysis_provider.dart';

// The backend streams 6 real stages (address_found → map_ready →
// amenities_ready → crime_ready → score_ready → summary_ready). Five of the
// six checklist rows below map 1:1 to a real event — including "Checking crime
// statistics" (real UK Police API data for GB addresses; an OSM-based fallback
// elsewhere). Only "Evaluating transport links" is cosmetic: it rides the
// score event. Every row's state and the ring percentage come from real
// backend job state.

class _Stage {
  final AnalysisStatus at; // status at which this row becomes active
  final IconData icon;
  final String label;
  const _Stage(this.at, this.icon, this.label);
}

const _kStages = [
  _Stage(AnalysisStatus.addressFound,      Icons.search_rounded,             'Verifying location'),
  _Stage(AnalysisStatus.mapReady,          Icons.layers_rounded,             'Collecting neighbourhood data'),
  _Stage(AnalysisStatus.fetchingAmenities, Icons.school_rounded,             'Analysing schools'),
  _Stage(AnalysisStatus.checkingCrime,     Icons.shield_rounded,             'Checking crime statistics'),
  _Stage(AnalysisStatus.scoring,           Icons.directions_transit_rounded, 'Evaluating transport links'),
  _Stage(AnalysisStatus.generatingSummary, Icons.auto_awesome_rounded,       'Generating AI insights'),
];

const _kTips = [
  'Areas with good public transport can see up to 12% higher property value on average.',
  'Homes near well-rated schools tend to hold their value better over time.',
  'Walkable neighbourhoods with amenities nearby are consistently in higher demand.',
];

int _ord(AnalysisStatus s) => switch (s) {
  AnalysisStatus.idle => 0,
  AnalysisStatus.addressFound => 1,
  AnalysisStatus.mapReady => 2,
  AnalysisStatus.fetchingAmenities => 3,
  AnalysisStatus.checkingCrime => 4,
  AnalysisStatus.scoring => 5,
  AnalysisStatus.generatingSummary => 6,
  AnalysisStatus.done => 7,
  AnalysisStatus.error => 0,
};

/// Full-screen replacement for the home screen while an analysis job is
/// running. Driven by the real SSE pipeline via
/// [AnalysisState.status]/[AnalysisState.progress] — every checkmark and the
/// percentage reflect real backend state, not a fixed timer.
class AnalyzingProgressView extends StatelessWidget {
  final String address;
  final AnalysisStatus status;
  final int progress; // 0-100, straight from the backend job's `progress`

  const AnalyzingProgressView({
    super.key,
    required this.address,
    required this.status,
    required this.progress,
  });

  double get _percent => (progress / 100.0).clamp(0.0, 1.0);

  // Rough index into the tips, advancing as the pipeline progresses.
  int get _tipIndex => (_ord(status)).clamp(0, _kStages.length);

  ({String primary, String secondary}) get _addressLines {
    final parts = address
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    if (parts.isEmpty) return (primary: address, secondary: '');
    return (
      primary: parts.take(2).join(', '),
      secondary: parts.skip(2).take(2).join(', '),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final lines = _addressLines;
    final tip = _kTips[_tipIndex % _kTips.length];
    final cur = _ord(status);

    return Container(
      color: p.bg,
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 8),

              // ── Title ──────────────────────────────────────────────────────
              Text(
                'Analysing…',
                style: TextStyle(
                  color: p.textPrimary,
                  fontSize: 27,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.6,
                ),
              ),
              const SizedBox(height: 10),

              // ── Address (two lines) ────────────────────────────────────────
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.location_on_rounded,
                      size: 16, color: AppColors.accent),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      lines.primary,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.accent,
                        fontSize: 16.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                ],
              ),
              if (lines.secondary.isNotEmpty) ...[
                const SizedBox(height: 3),
                Text(
                  lines.secondary,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: p.textTertiary, fontSize: 13),
                ),
              ],

              const SizedBox(height: 30),

              // ── Progress ring ──────────────────────────────────────────────
              SizedBox(
                width: 172,
                height: 172,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 172,
                      height: 172,
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: _percent),
                        duration: const Duration(milliseconds: 600),
                        curve: Curves.easeOutCubic,
                        builder: (context, value, _) => CustomPaint(
                          painter: _RingPainter(value, p.border),
                        ),
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${(_percent * 100).round()}%',
                          style: TextStyle(
                            color: p.textPrimary,
                            fontSize: 36,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -1.2,
                          ),
                        ),
                        Text(
                          'Complete',
                          style: TextStyle(
                            color: p.textTertiary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 22),
              Text(
                'This usually takes 15–20 seconds',
                style: TextStyle(color: p.textTertiary, fontSize: 12.5),
              ),
              const SizedBox(height: 26),

              // ── Checklist ──────────────────────────────────────────────────
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
                decoration: BoxDecoration(
                  color: p.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: p.border),
                ),
                child: Column(
                  children: [
                    for (int i = 0; i < _kStages.length; i++) ...[
                      if (i > 0) const SizedBox(height: 17),
                      _StageRow(
                        stage: _kStages[i],
                        state: () {
                          final th = _ord(_kStages[i].at);
                          if (cur > th) return _StageState.done;
                          if (cur == th) return _StageState.active;
                          return _StageState.pending;
                        }(),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ── Tip card ───────────────────────────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(18),
                  border:
                      Border.all(color: AppColors.accent.withValues(alpha: 0.14)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.accent, AppColors.accent2],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.auto_awesome_rounded,
                          color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        tip,
                        key: ValueKey(tip),
                        style: TextStyle(
                          color: p.textSecondary,
                          fontSize: 12.5,
                          height: 1.45,
                        ),
                      ).animate().fadeIn(duration: 300.ms),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _StageState { done, active, pending }

class _StageRow extends StatelessWidget {
  final _Stage stage;
  final _StageState state;

  const _StageRow({required this.stage, required this.state});

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final dim = state == _StageState.pending;
    final iconColor = state == _StageState.pending
        ? p.textTertiary
        : state == _StageState.active
            ? AppColors.accent
            : AppColors.success;

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 250),
      opacity: dim ? 0.45 : 1.0,
      child: Row(
        children: [
          Icon(stage.icon, size: 19, color: iconColor),
          const SizedBox(width: 13),
          Expanded(
            child: Text(
              stage.label,
              style: TextStyle(
                color:
                    state == _StageState.pending ? p.textTertiary : p.textPrimary,
                fontSize: 14.5,
                fontWeight: state == _StageState.active
                    ? FontWeight.w700
                    : FontWeight.w500,
              ),
            ),
          ),
          SizedBox(
            width: 20,
            height: 20,
            child: switch (state) {
              _StageState.done => const Icon(Icons.check_circle_rounded,
                  size: 20, color: AppColors.success),
              _StageState.active => const CircularProgressIndicator(
                  strokeWidth: 2, color: AppColors.accent),
              _StageState.pending => Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: p.border, width: 1.5),
                  ),
                ),
            },
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double percent;
  final Color trackColor;
  _RingPainter(this.percent, this.trackColor);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 12) / 2;

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = trackColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 11,
    );

    if (percent <= 0) return;
    final sweep = 2 * 3.14159265358979 * percent;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final gradient = SweepGradient(
      startAngle: -1.5707963267948966,
      endAngle: -1.5707963267948966 + sweep,
      colors: const [AppColors.accent, AppColors.accent2],
      transform: const GradientRotation(-1.5707963267948966),
    );

    canvas.drawArc(
      rect,
      -1.5707963267948966,
      sweep,
      false,
      Paint()
        ..shader = gradient.createShader(rect)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 11
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) =>
      oldDelegate.percent != percent || oldDelegate.trackColor != trackColor;
}
