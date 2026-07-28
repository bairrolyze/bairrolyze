import 'package:flutter/material.dart';

const _kBg      = Color(0xFF060B14);
const _kSurface = Color(0xFF0D1625);
const _kBorder  = Color(0xFF1A2845);
const _kAccent  = Color(0xFF3B82F6);
const _kPurple  = Color(0xFF7C3AED);
const _kIndigo  = Color(0xFF4F46E5);

class TutorialScreen extends StatefulWidget {
  const TutorialScreen({super.key});

  static Future<void> show(BuildContext context) => Navigator.of(context).push(
        MaterialPageRoute(
          fullscreenDialog: true,
          builder: (_) => const TutorialScreen(),
        ),
      );

  @override
  State<TutorialScreen> createState() => _TutorialScreenState();
}

class _TutorialScreenState extends State<TutorialScreen> {
  final _controller = PageController();
  int _page = 0;

  static const _pages = [
    _PageData(
      gradient: [Color(0xFF3B82F6), Color(0xFF7C3AED)],
      emoji: '🏠',
      title: 'Welcome to HomeScope',
      subtitle: 'Your intelligent neighbourhood guide for smarter property decisions.',
      features: [
        (Icons.bolt_rounded,            'Analyse any address in seconds'),
        (Icons.bar_chart_rounded,       'Score 7 dimensions of liveability'),
        (Icons.compare_arrows_rounded,  'Compare properties side-by-side'),
        (Icons.notifications_rounded,   'Get alerts when scores change'),
      ],
    ),
    _PageData(
      gradient: [Color(0xFF3B82F6), Color(0xFF06B6D4)],
      emoji: '🔍',
      title: 'Search & Analyse',
      subtitle: 'Type any address or neighbourhood name to get a full liveability report.',
      tabLabel: 'Search tab',
      features: [
        (Icons.search_rounded,          'Type any address or area name'),
        (Icons.touch_app_rounded,       'Tap a suggestion to fill the box'),
        (Icons.insights_rounded,        'Press "Get Insights" to run analysis'),
        (Icons.history_rounded,         'Recent searches saved automatically'),
      ],
    ),
    _PageData(
      gradient: [Color(0xFF10B981), Color(0xFF3B82F6)],
      emoji: '🌍',
      title: 'Neighbourhood Report',
      subtitle: 'Deep-dive into any area across 7 scored dimensions.',
      tabLabel: 'Discover tab',
      features: [
        (Icons.speed_rounded,           'Overall score out of 100'),
        (Icons.category_rounded,        'Transport, Safety, Health & more'),
        (Icons.auto_awesome_rounded,    'AI summary of the area character'),
        (Icons.timeline_rounded,        'Historical timeline & Time Machine'),
      ],
    ),
    _PageData(
      gradient: [Color(0xFFF59E0B), Color(0xFFEF4444)],
      emoji: '🧭',
      title: 'Explore Portugal',
      subtitle: 'Browse hand-picked neighbourhoods filtered by what matters to you.',
      tabLabel: 'Explore tab',
      features: [
        (Icons.explore_rounded,         'Curated neighbourhoods across Portugal'),
        (Icons.filter_list_rounded,     'Filter by Transport, Family, Nature…'),
        (Icons.map_rounded,             'See location context at a glance'),
        (Icons.open_in_new_rounded,     'Tap any card for the full report'),
      ],
    ),
    _PageData(
      gradient: [Color(0xFF7C3AED), Color(0xFF4F46E5)],
      emoji: '⭐',
      title: 'Unlock Pro Features',
      subtitle: 'Go Pro or Premium to access the full HomeScope toolkit.',
      tabLabel: 'You tab → Upgrade',
      features: [
        (Icons.compare_arrows_rounded,  'Compare up to 10 properties (Pro)'),
        (Icons.notifications_active_rounded, '10–99 neighbourhood alerts (Pro+)'),
        (Icons.auto_awesome_rounded,    'AI investment insights (Premium)'),
        (Icons.trending_up_rounded,     'Trend forecasting (Premium)'),
      ],
    ),
  ];

  void _next() {
    if (_page < _pages.length - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;
    final top    = MediaQuery.of(context).padding.top;
    final isLast = _page == _pages.length - 1;

    return Scaffold(
      backgroundColor: _kBg,
      body: Column(
        children: [
          // ── Top bar ───────────────────────────────────────────────────────
          SizedBox(
            height: top + 56,
            child: Align(
              alignment: Alignment.bottomRight,
              child: Padding(
                padding: const EdgeInsets.only(right: 20, bottom: 10),
                child: isLast
                    ? const SizedBox.shrink()
                    : GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: Text(
                          'Skip',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.38),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
              ),
            ),
          ),

          // ── Pages ─────────────────────────────────────────────────────────
          Expanded(
            child: PageView.builder(
              controller: _controller,
              itemCount: _pages.length,
              onPageChanged: (i) => setState(() => _page = i),
              itemBuilder: (_, i) => _TutorialPage(data: _pages[i]),
            ),
          ),

          // ── Dots ──────────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.only(bottom: 28, top: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_pages.length, (i) {
                final active = i == _page;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: active ? 22 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: active
                        ? _kAccent
                        : Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(3),
                  ),
                );
              }),
            ),
          ),

          // ── CTA button ────────────────────────────────────────────────────
          Padding(
            padding: EdgeInsets.fromLTRB(20, 0, 20, bottom + 24),
            child: GestureDetector(
              onTap: _next,
              child: Container(
                height: 54,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: _pages[_page].gradient,
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: _kAccent.withValues(alpha: 0.30),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: Text(
                  isLast ? 'Get Started' : 'Next',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Page content ──────────────────────────────────────────────────────────────

class _PageData {
  final List<Color> gradient;
  final String emoji;
  final String title;
  final String subtitle;
  final String? tabLabel;
  final List<(IconData, String)> features;

  const _PageData({
    required this.gradient,
    required this.emoji,
    required this.title,
    required this.subtitle,
    this.tabLabel,
    required this.features,
  });
}

class _TutorialPage extends StatelessWidget {
  final _PageData data;
  const _TutorialPage({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Emoji icon in gradient circle ─────────────────────────────────
          Center(
            child: Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: data.gradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: data.gradient.first.withValues(alpha: 0.35),
                    blurRadius: 28,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Center(
                child: Text(data.emoji,
                    style: const TextStyle(fontSize: 40)),
              ),
            ),
          ),
          const SizedBox(height: 32),

          // ── Tab badge ─────────────────────────────────────────────────────
          if (data.tabLabel != null) ...[
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: data.gradient),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                data.tabLabel!,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  letterSpacing: 0.2,
                ),
              ),
            ),
            const SizedBox(height: 14),
          ] else
            const SizedBox(height: 0),

          // ── Title ─────────────────────────────────────────────────────────
          Text(
            data.title,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -0.8,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 10),

          // ── Subtitle ──────────────────────────────────────────────────────
          Text(
            data.subtitle,
            style: TextStyle(
              fontSize: 15,
              color: Colors.white.withValues(alpha: 0.52),
              height: 1.55,
            ),
          ),
          const SizedBox(height: 28),

          // ── Feature list ──────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _kSurface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: _kBorder),
            ),
            child: Column(
              children: data.features
                  .map((f) => _FeatureRow(
                        icon: f.$1,
                        label: f.$2,
                        color: data.gradient.first,
                      ))
                  .toList(),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _FeatureRow({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(icon, color: color, size: 16),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13.5,
                  color: Colors.white.withValues(alpha: 0.82),
                  fontWeight: FontWeight.w500,
                  height: 1.3,
                ),
              ),
            ),
          ],
        ),
      );
}
