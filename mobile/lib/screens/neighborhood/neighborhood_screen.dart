import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../config/app_theme.dart';
import '../../config/score_format.dart';
import '../../models/address_model.dart';
import '../../models/score_model.dart';
import '../../models/user_preferences_model.dart';
import '../../providers/analysis_provider.dart';
import '../../providers/preferences_provider.dart';
import '../../providers/saved_provider.dart';
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

// Toggle the grouped Compare / Follow / Alerts action bar. Kept off for v1 and
// flipped on in v2 once the features have real data behind them.
const bool _kShowActionBar = false;

class NeighborhoodScreen extends ConsumerStatefulWidget {
  const NeighborhoodScreen({super.key});

  @override
  ConsumerState<NeighborhoodScreen> createState() =>
      _NeighborhoodScreenState();
}

class _NeighborhoodScreenState extends ConsumerState<NeighborhoodScreen> {
  int _tab = 0;

  // Header collapses into a compact card once any tab is scrolled past a small
  // threshold; the state is shared across tabs so it persists on switch.
  final ValueNotifier<bool> _collapsed = ValueNotifier<bool>(false);

  static const _tabs = [
    ('📊', 'Summary'),
    ('🗺', 'Map'),
    ('🧬', 'DNA'),
    ('📍', 'Radius'),
    ('⏱', 'Timeline'),
    ('✨', 'Story'),
    ('🔮', 'Future'),
  ];

  void _onScroll(ScrollNotification n) {
    if (n.metrics.axis != Axis.vertical) return;
    // Hysteresis so it doesn't flicker right at the boundary.
    final next = n.metrics.pixels > (_collapsed.value ? 24 : 48);
    if (next != _collapsed.value) _collapsed.value = next;
  }

  @override
  void dispose() {
    _collapsed.dispose();
    super.dispose();
  }

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
        ValueListenableBuilder<bool>(
          valueListenable: _collapsed,
          builder: (_, collapsed, __) => _ScoreHeader(
            score: result.score,
            address: analysis.address,
            collapsed: collapsed,
          ),
        ),
        // Compare / Follow / Alerts — hidden until v2 (needs real data behind them).
        // ignore: dead_code
        if (_kShowActionBar) _ActionBar(score: result.score, address: analysis.address),
        _TabStrip(
          current: _tab,
          tabs: _tabs,
          onSelect: (i) => setState(() => _tab = i),
        ),
        Expanded(
          child: NotificationListener<ScrollNotification>(
            onNotification: (n) {
              _onScroll(n);
              return false;
            },
            child: _buildContent(result, analysis.address),
          ),
        ),
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
          // Time Machine — fixed height so Expanded children inside resolve
          SizedBox(
            height: 520,
            child: TimeMachineWidget(score: score, topPadding: 0),
          ),

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
                  'DEVELOPMENT TIMELINE',
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

          // Historical development timeline
          NeighborhoodTimelineWidget(score: score, topPadding: 0),

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

class _ScoreHeader extends ConsumerWidget {
  final LocationScore score;
  final AddressModel? address;

  final bool collapsed;
  const _ScoreHeader({
    required this.score,
    this.address,
    this.collapsed = false,
  });

  String _article(String label) =>
      'aeiouAEIOU'.contains(label[0]) ? 'an' : 'a';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = scoreColor(score.overall);
    final p = AppPalette.of(context);
    final profile = ref.watch(preferencesProvider).profile;
    final tenth = scoreTenth(score.overall);
    final label = scoreLabel(score.overall);
    final cityLine = address?.city?.trim().isNotEmpty == true
        ? address!.city!.trim()
        : (address?.shortSecondary ?? '');

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: p.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Status + actions (share, refresh, favourite) ────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
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
                _HeaderActionButton(
                  icon: Icons.ios_share_rounded,
                  onTap: () => _share(context),
                ),
                const SizedBox(width: 8),
                _HeaderActionButton(
                  icon: Icons.refresh_rounded,
                  loading: ref.watch(analysisProvider).isLoading,
                  onTap: () => _refresh(context, ref, profile),
                ),
                if (address != null) ...[
                  const SizedBox(width: 8),
                  _SaveButton(address: address!),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
          // ── Hero: full details ⇄ compact card, driven by [collapsed] ─────
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 220),
            sizeCurve: Curves.easeInOut,
            firstCurve: Curves.easeInOut,
            secondCurve: Curves.easeInOut,
            crossFadeState:
                collapsed ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            firstChild:
                _expandedHero(context, ref, p, color, tenth, profile, cityLine),
            secondChild: _collapsedCard(context, p, color, tenth, cityLine),
          ),
          // ── Verdict — hidden when the header is collapsed ───────────────
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 220),
            sizeCurve: Curves.easeInOut,
            firstCurve: Curves.easeInOut,
            secondCurve: Curves.easeInOut,
            crossFadeState: collapsed
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            firstChild: Padding(
              padding: const EdgeInsets.fromLTRB(4, 12, 4, 0),
              child: RichText(
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
                      style:
                          TextStyle(color: color, fontWeight: FontWeight.w700),
                    ),
                    const TextSpan(text: ' neighbourhood to live in.'),
                  ],
                ),
              ),
            ),
            secondChild: const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }

  // Expanded hero: skyline backdrop behind the title + big score ring + profile.
  Widget _expandedHero(
    BuildContext context,
    WidgetRef ref,
    AppPalette p,
    Color color,
    String tenth,
    UserProfile profile,
    String cityLine,
  ) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        children: [
          // City-skyline backdrop, faded and scrimmed for legibility.
          Positioned.fill(
            child: Opacity(
              opacity: 0.45,
              child: Image.asset(
                'assets/images/city_sky.png',
                fit: BoxFit.cover,
                alignment: const Alignment(0, 0.3),
              ),
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [p.bg, p.bg.withValues(alpha: 0.35)],
                ),
              ),
            ),
          ),
          Padding(
            // Horizontal 4 aligns hero content with the status/verdict rows so
            // the title and ring share the same left/right margin.
            padding: const EdgeInsets.fromLTRB(4, 10, 4, 14),
            child: Row(
              // Top-align so Profile + title start level with the score ring
              // (no empty gap above the profile line).
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (address != null) ...[
                        _profileSelector(context, ref, p, profile),
                        const SizedBox(height: 6),
                      ],
                      Text(
                        address?.headerTitle ?? '—',
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: p.textPrimary,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.8,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 6),
                      _cityLine(context, p, cityLine),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                _ScoreRing(
                  percent: (score.overall / 100).clamp(0.0, 1.0),
                  color: color,
                  size: 72,
                  label: tenth,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Collapsed hero: compact card with a small ring + title + city.
  Widget _collapsedCard(
    BuildContext context,
    AppPalette p,
    Color color,
    String tenth,
    String cityLine,
  ) {
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: p.surface2,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: p.border),
      ),
      child: Row(
        children: [
          _ScoreRing(
            percent: (score.overall / 100).clamp(0.0, 1.0),
            color: color,
            size: 46,
            label: tenth,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  address?.headerTitle ?? '—',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: p.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 3),
                _cityLine(context, p, cityLine),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Shared "📍 city · Street View" line used by both hero states.
  Widget _cityLine(BuildContext context, AppPalette p, String cityLine) {
    return Row(
      children: [
        Icon(Icons.location_on_rounded, size: 15, color: p.textTertiary),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            cityLine,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: p.textSecondary, fontSize: 14),
          ),
        ),
        if (address?.lat != null && address?.lng != null) ...[
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => _openStreetView(address!.lat!, address!.lng!),
            behavior: HitTestBehavior.opaque,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.streetview_rounded,
                    size: 15, color: AppColors.accent2),
                SizedBox(width: 4),
                Text(
                  'Street View',
                  style: TextStyle(
                    color: AppColors.accent2,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _profileSelector(
    BuildContext context,
    WidgetRef ref,
    AppPalette p,
    UserProfile profile,
  ) {
    return GestureDetector(
      onTap: () => _openProfilePicker(context, ref, profile),
      behavior: HitTestBehavior.opaque,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Profile: ',
            style: TextStyle(
              color: p.textTertiary,
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            profile.label,
            style: const TextStyle(
              color: AppColors.accent,
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          Icon(Icons.keyboard_arrow_down_rounded,
              size: 16, color: p.textTertiary),
        ],
      ),
    );
  }

  void _refresh(BuildContext context, WidgetRef ref, UserProfile profile) {
    final addr = address;
    if (addr == null) return;
    ref.read(analysisProvider.notifier).analyze(
          addr.displayAddress,
          profile: profile.jsonValue,
          countryCode: ref.read(preferencesProvider).defaultCountry,
          forceRefresh: true,
        );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Refreshing analysis…'),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _share(BuildContext context) {
    final addr = address;
    final title = addr?.headerTitle ?? addr?.displayAddress ?? 'this location';
    final text =
        '$title scored ${scoreTenth(score.overall)}/10 on Bairrolyze';
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Summary copied to clipboard'),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _openProfilePicker(
    BuildContext context,
    WidgetRef ref,
    UserProfile current,
  ) async {
    final addr = address;
    if (addr == null) return;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _ProfilePickerSheet(
        current: current,
        onSelect: (chosen) {
          Navigator.of(context).pop();
          if (chosen == current) return;
          ref.read(preferencesProvider.notifier).setProfile(chosen);
          ref.read(analysisProvider.notifier).analyze(
                addr.displayAddress,
                profile: chosen.jsonValue,
                countryCode: ref.read(preferencesProvider).defaultCountry,
              );
        },
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

// ── Profile picker sheet ────────────────────────────────────────────────────────

class _ProfilePickerSheet extends StatelessWidget {
  final UserProfile current;
  final ValueChanged<UserProfile> onSelect;
  const _ProfilePickerSheet({required this.current, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final bottom = MediaQuery.of(context).padding.bottom;
    return Container(
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border.all(color: p.border),
      ),
      padding: EdgeInsets.fromLTRB(16, 12, 16, 16 + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: p.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Score for who?',
            style: TextStyle(
              color: p.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Re-scores this neighbourhood for your chosen lens.',
            style: TextStyle(color: p.textTertiary, fontSize: 13),
          ),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 3,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.55,
            children: UserProfile.values.map((profile) {
              final active = profile == current;
              return GestureDetector(
                onTap: () => onSelect(profile),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  decoration: BoxDecoration(
                    color: active
                        ? AppColors.accent.withValues(alpha: 0.14)
                        : p.surface2,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: active ? AppColors.accent : p.border,
                      width: active ? 1.5 : 1,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(profile.emoji,
                          style: const TextStyle(fontSize: 20)),
                      const SizedBox(height: 4),
                      Text(
                        profile.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color:
                              active ? AppColors.accent : p.textSecondary,
                          fontSize: 11.5,
                          fontWeight:
                              active ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// ── Street View pill ──────────────────────────────────────────────────────────

// Bookmark toggle — saves/removes the current analysis from the Saved tab.
// ── Header action button — rounded square (share / refresh / favourite) ──────

class _HeaderActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool loading;
  final bool active;
  final Color? activeColor;
  const _HeaderActionButton({
    required this.icon,
    required this.onTap,
    this.loading = false,
    this.active = false,
    this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final ac = activeColor ?? AppColors.accent;
    return GestureDetector(
      onTap: loading ? null : onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        // Padding only — no background box — keeps a comfortable tap target
        // without adding visual bulk to the header.
        padding: const EdgeInsets.all(6),
        child: loading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(AppColors.accent),
                ),
              )
            : Icon(icon, size: 20, color: active ? ac : p.textSecondary),
      ),
    );
  }
}

// ── Favourite (save) button — heart square that toggles the saved list ───────

class _SaveButton extends ConsumerWidget {
  final AddressModel address;
  const _SaveButton({required this.address});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final saved = ref.watch(savedProvider).any(
        (e) => SavedNotifier.keyFor(e.address) == SavedNotifier.keyFor(address));

    return _HeaderActionButton(
      icon: saved ? Icons.favorite_rounded : Icons.favorite_border_rounded,
      active: saved,
      activeColor: const Color(0xFFEF4444),
      onTap: () {
        final result = ref.read(analysisProvider).result;
        if (result == null) return;
        final nowSaved =
            ref.read(savedProvider.notifier).toggle(address, result);
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
            content:
                Text(nowSaved ? 'Saved to your list' : 'Removed from Saved'),
          ));
      },
    );
  }
}

// ── Score ring (with heart) ───────────────────────────────────────────────────

class _ScoreRing extends StatelessWidget {
  final double percent;
  final Color color;
  final double size;
  final String label; // score shown inside the ring, e.g. "8.3"
  const _ScoreRing(
      {required this.percent,
      required this.color,
      required this.size,
      required this.label});

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
          Text(
            label,
            style: TextStyle(
              color: p.textPrimary,
              fontSize: size * 0.30,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
              height: 1,
            ),
          ),
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
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                // Active: blue→purple gradient pill with a soft glow.
                // Inactive: clean, borderless text (no box).
                gradient: active
                    ? const LinearGradient(
                        colors: [AppColors.accent, AppColors.accent2],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                borderRadius: BorderRadius.circular(22),
                boxShadow: active
                    ? [
                        BoxShadow(
                          color: AppColors.accent2.withValues(alpha: 0.45),
                          blurRadius: 14,
                          spreadRadius: -3,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Opacity(
                    opacity: active ? 1 : 0.55,
                    child: Text(tab.$1, style: const TextStyle(fontSize: 13)),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    tab.$2,
                    style: TextStyle(
                      color: active ? Colors.white : p.textTertiary,
                      fontSize: 12.5,
                      fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                      letterSpacing: -0.1,
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
