import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../config/app_theme.dart';
import '../../models/address_model.dart';
import '../../models/score_model.dart';
import '../../providers/analysis_provider.dart';
import '../../providers/alerts_provider.dart';
import '../../providers/compare_provider.dart';
import '../../providers/pro_provider.dart';
import '../../widgets/neighborhood/dashboard_widget.dart';
import '../../widgets/neighborhood/dna_widget.dart';
import '../../widgets/neighborhood/life_radius_widget.dart';
import '../../widgets/neighborhood/time_machine_widget.dart';
import '../../widgets/neighborhood/timeline_widget.dart';
import '../../widgets/neighborhood/ai_story_widget.dart';
import '../../widgets/neighborhood/future_score_widget.dart';
import '../../widgets/map/map_tab_body.dart';
import '../alerts/alerts_screen.dart';
import '../compare/compare_screen.dart';
import '../paywall/paywall_screen.dart';

class NeighborhoodScreen extends ConsumerStatefulWidget {
  const NeighborhoodScreen({super.key});

  @override
  ConsumerState<NeighborhoodScreen> createState() =>
      _NeighborhoodScreenState();
}

class _NeighborhoodScreenState extends ConsumerState<NeighborhoodScreen> {
  int _tab = 0;

  static const _tabs = [
    ('📊', 'Summary'),
    ('🗺', 'Map'),
    ('🧬', 'DNA'),
    ('📍', 'Radius'),
    ('⏱', 'Timeline'),
    ('✨', 'Story'),
    ('🔮', 'Future'),
  ];

  @override
  Widget build(BuildContext context) {
    final analysis = ref.watch(analysisProvider);
    final result   = analysis.result;
    final top      = MediaQuery.of(context).padding.top;

    if (result == null) {
      return _EmptyExplore(top: top);
    }

    return Column(
      children: [
        SizedBox(height: top),
        _ScoreHeader(score: result.score, address: analysis.address),
        _ActionBar(score: result.score, address: analysis.address),
        _TabStrip(
          current: _tab,
          tabs: _tabs,
          onSelect: (i) => setState(() => _tab = i),
        ),
        Expanded(child: _buildContent(result, analysis.address)),
      ],
    );
  }

  Widget _buildContent(AnalysisResult result, AddressModel? address) {
    switch (_tab) {
      case 0:
        return DashboardWidget(result: result, address: address, topPadding: 0);
      case 1:
        return const MapTabBody();
      case 2:
        return DNAWidget(score: result.score, address: address, topPadding: 0);
      case 3:
        return LifeRadiusWidget(
          amenities: result.amenities,
          addressLat: address?.lat,
          addressLng: address?.lng,
          topPadding: 0,
        );
      case 4:
        return _TimelineTab(score: result.score);
      case 5:
        return AIStoryWidget(result: result, topPadding: 0);
      case 6:
        return FutureScoreWidget(score: result.score, topPadding: 0);
      default:
        return const SizedBox();
    }
  }
}

// ── Action bar — Compare + Follow ─────────────────────────────────────────────

class _ActionBar extends ConsumerWidget {
  final LocationScore score;
  final AddressModel? address;
  const _ActionBar({required this.score, this.address});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (address == null) return const SizedBox.shrink();

    final compare  = ref.watch(compareProvider);
    final alerts   = ref.watch(alertsProvider);
    final pro      = ref.watch(proProvider);
    final isSaved  = compare.contains(CompareNotifier.idFor(address!));
    final isFollowing = alerts.isFollowing(address!);
    final p = AppPalette.of(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 7, 14, 7),
      decoration: BoxDecoration(
        color: p.surface,
        border: Border(bottom: BorderSide(color: p.border)),
      ),
      child: Row(
        children: [
          // Compare button
          _ActionChip(
            icon: isSaved
                ? Icons.compare_arrows_rounded
                : Icons.add_chart_rounded,
            label: isSaved ? 'Comparing' : 'Compare',
            active: isSaved,
            color: AppColors.accent,
            onTap: () {
              if (isSaved) {
                CompareScreen.show(context);
                return;
              }
              // Free users can save up to maxCompare
              if (!pro.isPro &&
                  compare.items.length >= pro.maxCompare) {
                PaywallScreen.show(context);
                return;
              }
              ref
                  .read(compareProvider.notifier)
                  .add(address!, score);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Added to comparison'),
                  behavior: SnackBarBehavior.floating,
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
          const SizedBox(width: 8),
          // View comparison (only when saved)
          if (isSaved) ...[
            _ActionChip(
              icon: Icons.open_in_new_rounded,
              label: 'View Compare',
              active: false,
              color: AppColors.accent2,
              onTap: () => CompareScreen.show(context),
            ),
            const SizedBox(width: 8),
          ],
          // Follow / Alerts button
          _ActionChip(
            icon: isFollowing
                ? Icons.notifications_active_rounded
                : Icons.notifications_none_rounded,
            label: isFollowing ? 'Following' : 'Follow',
            active: isFollowing,
            color: const Color(0xFF22C55E),
            onTap: () {
              if (!pro.isPro) {
                PaywallScreen.show(context);
                return;
              }
              if (isFollowing) {
                AlertsScreen.show(context);
                return;
              }
              ref.read(alertsProvider.notifier).follow(
                    address!,
                    score.overall,
                  );
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Now following this neighbourhood'),
                  behavior: SnackBarBehavior.floating,
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
          const SizedBox(width: 8),
          // Alerts shortcut
          GestureDetector(
            onTap: () => AlertsScreen.show(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: p.surface2,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: p.border),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.notifications_outlined,
                      size: 14,
                      color: p.textSecondary),
                  const SizedBox(width: 5),
                  Text(
                    'Alerts',
                    style: TextStyle(
                      color: p.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
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

class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final Color color;
  final VoidCallback onTap;

  const _ActionChip({
    required this.icon,
    required this.label,
    required this.active,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: active ? color.withValues(alpha: 0.12) : p.surface2,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: active ? color.withValues(alpha: 0.5) : p.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 13,
                color: active ? color : p.textSecondary),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                color: active ? color : p.textSecondary,
                fontSize: 12,
                fontWeight: active ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Combined Timeline + Time Machine tab ──────────────────────────────────────

class _TimelineTab extends StatelessWidget {
  final LocationScore score;
  const _TimelineTab({required this.score});

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Historical development timeline
          NeighborhoodTimelineWidget(score: score, topPadding: 0),

          // ── Divider ─────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 4, 18, 16),
            child: Row(
              children: [
                Expanded(child: Divider(color: p.border)),
                const SizedBox(width: 12),
                Icon(Icons.access_time_rounded,
                    size: 12, color: p.textTertiary),
                const SizedBox(width: 6),
                Text(
                  'DAILY ACTIVITY RADAR',
                  style: TextStyle(
                    color: p.textTertiary,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.6,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(child: Divider(color: p.border)),
              ],
            ),
          ),

          // Time Machine — fixed height so Expanded children inside resolve
          SizedBox(
            height: 520,
            child: TimeMachineWidget(score: score, topPadding: 0),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyExplore extends StatelessWidget {
  final double top;
  const _EmptyExplore({required this.top});

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Container(
      color: p.bg,
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: p.surface,
                    shape: BoxShape.circle,
                    border: Border.all(color: p.border),
                  ),
                  child: const Icon(Icons.explore_rounded,
                      color: AppColors.accent, size: 32),
                ),
                const SizedBox(height: 20),
                Text(
                  'No analysis yet',
                  style: TextStyle(
                    color: p.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Search an address in the Search tab\nto explore its full neighbourhood profile.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: p.textTertiary,
                    fontSize: 14,
                    height: 1.55,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Score header ──────────────────────────────────────────────────────────────

class _ScoreHeader extends StatelessWidget {
  final LocationScore score;
  final AddressModel? address;
  const _ScoreHeader({required this.score, this.address});

  Color _scoreColor() {
    final s = score.overall;
    if (s >= 80) return const Color(0xFF22C55E);
    if (s >= 60) return const Color(0xFF3B82F6);
    if (s >= 40) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }

  String _scoreLabel() {
    final s = score.overall;
    if (s >= 80) return 'Excellent';
    if (s >= 60) return 'Good';
    if (s >= 40) return 'Fair';
    return 'Poor';
  }

  String _article(String label) =>
      'aeiouAEIOU'.contains(label[0]) ? 'an' : 'a';

  @override
  Widget build(BuildContext context) {
    final color = _scoreColor();
    final p = AppPalette.of(context);
    final tenth = (score.overall / 10).toStringAsFixed(1);
    final label = _scoreLabel();
    final cityLine = address?.city?.trim().isNotEmpty == true
        ? address!.city!.trim()
        : (address?.shortSecondary ?? '');

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
      decoration: BoxDecoration(
        color: p.surface,
        border: Border(bottom: BorderSide(color: p.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Status row ──────────────────────────────────────────────────
          Row(
            children: [
              const Icon(Icons.verified_user_rounded,
                  size: 15, color: AppColors.success),
              const SizedBox(width: 6),
              const Text(
                'Analysis Complete',
                style: TextStyle(
                  color: AppColors.success,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.1,
                ),
              ),
              const Spacer(),
              if (address?.lat != null && address?.lng != null)
                _StreetViewButton(
                  onTap: () => _openStreetView(address!.lat!, address!.lng!),
                ),
            ],
          ),
          const SizedBox(height: 10),
          // ── Address + score + ring ──────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      address?.headerTitle ?? '—',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: p.textPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.8,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        Icon(Icons.location_on_rounded,
                            size: 15, color: p.textTertiary),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            cityLine,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                color: p.textSecondary, fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          tenth,
                          style: TextStyle(
                            color: p.textPrimary,
                            fontSize: 46,
                            fontWeight: FontWeight.w800,
                            height: 1,
                            letterSpacing: -1.8,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6, left: 3),
                          child: Text(
                            '/10',
                            style: TextStyle(
                              color: p.textTertiary,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 9),
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 9, vertical: 4),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                  color: color.withValues(alpha: 0.35)),
                            ),
                            child: Text(
                              label.toUpperCase(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: color,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              _ScoreRing(
                percent: (score.overall / 100).clamp(0.0, 1.0),
                color: color,
                size: 92,
              ),
            ],
          ),
          const SizedBox(height: 8),
          // ── Verdict ─────────────────────────────────────────────────────
          RichText(
            text: TextSpan(
              style: TextStyle(
                color: p.textSecondary,
                fontSize: 13,
                height: 1.35,
                letterSpacing: -0.1,
              ),
              children: [
                TextSpan(text: 'This is ${_article(label)} '),
                TextSpan(
                  text: label.toLowerCase(),
                  style: TextStyle(color: color, fontWeight: FontWeight.w700),
                ),
                const TextSpan(text: ' neighbourhood to live in.'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Future<void> _openStreetView(double lat, double lng) async {
    final url = Uri.parse(
      'https://www.google.com/maps/@?api=1&map_action=pano'
      '&viewpoint=${lat.toStringAsFixed(6)},${lng.toStringAsFixed(6)}',
    );
    await launchUrl(url, mode: LaunchMode.externalApplication);
  }
}

// ── Street View pill ──────────────────────────────────────────────────────────

class _StreetViewButton extends StatelessWidget {
  final VoidCallback onTap;
  const _StreetViewButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: p.surface2,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.accent2.withValues(alpha: 0.35)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.map_rounded, size: 15, color: AppColors.accent2),
            SizedBox(width: 6),
            Text(
              'Street View',
              style: TextStyle(
                color: AppColors.accent2,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Score ring (with heart) ───────────────────────────────────────────────────

class _ScoreRing extends StatelessWidget {
  final double percent;
  final Color color;
  final double size;
  const _ScoreRing(
      {required this.percent, required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.32),
            blurRadius: 28,
            spreadRadius: -6,
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: percent),
            duration: const Duration(milliseconds: 900),
            curve: Curves.easeOutCubic,
            builder: (_, v, __) => CustomPaint(
              size: Size(size, size),
              painter: _ScoreRingPainter(v, color, p.border),
            ),
          ),
          Icon(Icons.favorite_rounded, color: color, size: size * 0.3),
        ],
      ),
    );
  }
}

class _ScoreRingPainter extends CustomPainter {
  final double percent;
  final Color color;
  final Color track;
  _ScoreRingPainter(this.percent, this.color, this.track);

  static const _twoPi = 6.28318530718;
  static const _start = -1.5707963268; // -90°, start at 12 o'clock

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    const stroke = 9.0;
    final radius = (size.width - stroke) / 2;

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = track
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke,
    );

    if (percent <= 0) return;
    final sweep = _twoPi * percent;
    final rect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawArc(
      rect,
      _start,
      sweep,
      false,
      Paint()
        ..shader = SweepGradient(
          startAngle: _start,
          endAngle: _start + sweep,
          colors: [color.withValues(alpha: 0.55), color],
          transform: const GradientRotation(_start),
        ).createShader(rect)
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _ScoreRingPainter old) =>
      old.percent != percent || old.color != color || old.track != track;
}

// ── Horizontal tab strip ──────────────────────────────────────────────────────

class _TabStrip extends StatelessWidget {
  final int current;
  final List<(String, String)> tabs;
  final ValueChanged<int> onSelect;

  const _TabStrip({
    required this.current,
    required this.tabs,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: p.surface,
        border: Border(bottom: BorderSide(color: p.border)),
      ),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount: tabs.length,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (_, i) {
          final active = i == current;
          final tab = tabs[i];
          return GestureDetector(
            onTap: () => onSelect(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeInOut,
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
              decoration: BoxDecoration(
                color: active
                    ? AppColors.accent.withValues(alpha: 0.14)
                    : p.surface2,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: active
                      ? AppColors.accent
                      : p.border,
                  width: 1.5,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(tab.$1, style: const TextStyle(fontSize: 13)),
                  const SizedBox(width: 5),
                  Text(
                    tab.$2,
                    style: TextStyle(
                      color: active
                          ? AppColors.accent
                          : p.textSecondary,
                      fontSize: 12,
                      fontWeight:
                          active ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
