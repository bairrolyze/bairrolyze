import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/app_constants.dart';
import '../../providers/analysis_provider.dart';
import '../../providers/country_provider.dart';
import '../../providers/preferences_provider.dart';
import '../../providers/shell_provider.dart';
import '../../services/validation_service.dart';
import '../../widgets/common/loading_overlay.dart';
import '../../widgets/home/score_badge.dart';

// ── Design tokens ──────────────────────────────────────────────────────────────
const _kBg        = Color(0xFF060B14);
const _kSurface   = Color(0xFF0D1625);
const _kSurface2  = Color(0xFF131F33);
const _kAccent    = Color(0xFF3B82F6);
const _kBorder    = Color(0xFF1A2845);

// ── Suggestion model ──────────────────────────────────────────────────────────

class _Suggestion {
  final String display;
  final String primary;
  final String secondary;

  const _Suggestion({
    required this.display,
    required this.primary,
    required this.secondary,
  });

  factory _Suggestion.fromJson(Map<String, dynamic> json) {
    final raw = json['display_name'] as String? ?? '';
    final parts = raw.split(', ');
    return _Suggestion(
      display: raw,
      primary: parts.take(2).join(', '),
      secondary: parts.length > 2 ? parts.skip(2).take(2).join(', ') : '',
    );
  }
}

// ── Screen ────────────────────────────────────────────────────────────────────

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _formKey           = GlobalKey<FormState>();
  final _addressController = TextEditingController();
  final _scrollController  = ScrollController();
  final _focusNode         = FocusNode();
  final _dio               = Dio();

  Timer? _debounce;
  List<_Suggestion> _suggestions = [];
  bool _showSuggestions = false;
  bool _fetching = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _addressController.dispose();
    _scrollController.dispose();
    _focusNode
      ..removeListener(_onFocusChange)
      ..dispose();
    _dio.close();
    super.dispose();
  }

  void _onFocusChange() {
    if (!_focusNode.hasFocus) {
      Future.delayed(const Duration(milliseconds: 150), () {
        if (mounted) setState(() => _showSuggestions = false);
      });
    }
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    if (value.trim().length < 3) {
      setState(() {
        _suggestions = [];
        _showSuggestions = false;
        _fetching = false;
      });
      return;
    }
    setState(() => _fetching = true);
    _debounce = Timer(const Duration(milliseconds: 420), () => _fetchSuggestions(value));
  }

  Future<void> _fetchSuggestions(String query) async {
    final country = ref.read(selectedCountryProvider);
    final cc = (country?.code ?? 'PT').toLowerCase();
    try {
      final resp = await _dio.get<List<dynamic>>(
        '${AppConstants.nominatimBaseUrl}/search',
        queryParameters: {
          'q': query,
          'format': 'jsonv2',
          'limit': 5,
          'addressdetails': 1,
          'countrycodes': cc,
        },
        options: Options(
          headers: {'User-Agent': 'HomeScope/1.0 (mobile)'},
          receiveTimeout: const Duration(seconds: 8),
        ),
      );
      if (!mounted) return;
      final list = (resp.data ?? [])
          .whereType<Map<String, dynamic>>()
          .map(_Suggestion.fromJson)
          .toList();
      setState(() {
        _suggestions = list;
        _showSuggestions = list.isNotEmpty && _focusNode.hasFocus;
        _fetching = false;
      });
    } catch (_) {
      if (mounted) setState(() => _fetching = false);
    }
  }

  void _pickSuggestion(_Suggestion s) {
    _addressController.text = s.display;
    setState(() {
      _suggestions = [];
      _showSuggestions = false;
    });
    _focusNode.unfocus();
  }

  Future<void> _analyze() async {
    if (!_formKey.currentState!.validate()) return;
    final country = ref.read(selectedCountryProvider);
    final profile = ref.read(preferencesProvider).profile.name;
    await ref.read(analysisProvider.notifier).analyze(
          _addressController.text.trim(),
          countryCode: country?.code ?? 'PT',
          profile: profile,
        );
    if (!mounted) return;
    if (ref.read(analysisProvider).status == AnalysisStatus.done) {
      ref.read(shellTabProvider.notifier).state = 1;
    }
  }

  @override
  Widget build(BuildContext context) {
    final analysis = ref.watch(analysisProvider);
    final history  = ref.watch(searchHistoryProvider);
    final country  = ref.watch(selectedCountryProvider);
    final top      = MediaQuery.of(context).padding.top;

    ref.listen(analysisProvider, (_, next) {
      if (next.status == AnalysisStatus.error && next.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(next.error!),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ));
      }
    });

    return Theme(
      data: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: _kBg,
        colorScheme:
            const ColorScheme.dark(primary: _kAccent, surface: _kSurface),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: _kSurface2,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: _kAccent, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFEF4444)),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
          ),
          hintStyle: TextStyle(
            color: Colors.white.withOpacity(0.40),
            fontSize: 14.5,
            fontWeight: FontWeight.w400,
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        ),
      ),
      child: Scaffold(
        backgroundColor: _kBg,
        body: LoadingOverlay(
          isLoading: analysis.isLoading,
          message: analysis.statusMessage,
          child: CustomScrollView(
            controller: _scrollController,
            slivers: [

              // ── Top nav ──────────────────────────────────────────────────
              SliverPadding(
                padding: EdgeInsets.only(top: top + 8),
                sliver: SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 22),
                    child: Row(
                      children: [
                        _Logo(),
                        const SizedBox(width: 9),
                        const Text(
                          'HomeScope',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const Spacer(),
                        // Country selector
                        GestureDetector(
                          onTap: () =>
                              ref.read(shellTabProvider.notifier).state = 2,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: Colors.white.withOpacity(0.08)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(_flag(country?.code ?? 'PT'),
                                    style: const TextStyle(fontSize: 13)),
                                const SizedBox(width: 5),
                                Text(
                                  country?.code ?? 'PT',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.60),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                                const SizedBox(width: 3),
                                Icon(Icons.expand_more_rounded,
                                    size: 14,
                                    color: Colors.white.withOpacity(0.30)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // ── Hero ─────────────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(22, 20, 22, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Move smarter.',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 34,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -1.2,
                          height: 1.08,
                        ),
                      )
                          .animate()
                          .fadeIn(duration: 480.ms)
                          .slideY(begin: 0.07, end: 0),
                      ShaderMask(
                        shaderCallback: (bounds) => const LinearGradient(
                          colors: [Color(0xFF3B82F6), Color(0xFF7C3AED)],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ).createShader(bounds),
                        child: const Text(
                          'Invest wiser.',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 34,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -1.2,
                            height: 1.08,
                          ),
                        ),
                      )
                          .animate(delay: 55.ms)
                          .fadeIn(duration: 480.ms)
                          .slideY(begin: 0.07, end: 0),
                      const SizedBox(height: 10),
                      Text(
                        'Uncover safety, schools, transport & investment potential for any address.',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.50),
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          height: 1.55,
                          letterSpacing: -0.1,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ).animate(delay: 110.ms).fadeIn(duration: 420.ms),
                    ],
                  ),
                ),
              ),

              // ── Search ───────────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: _kSurface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.08)),
                      boxShadow: [
                        BoxShadow(
                          color: _kAccent.withOpacity(0.10),
                          blurRadius: 40,
                          offset: const Offset(0, 10),
                          spreadRadius: -8,
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(12),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          // Address field
                          TextFormField(
                            controller: _addressController,
                            focusNode: _focusNode,
                            style: const TextStyle(
                                color: Colors.white, fontSize: 15),
                            decoration: InputDecoration(
                              hintText:
                                  'Search an address, neighbourhood, or city...',
                              prefixIcon: _fetching
                                  ? Padding(
                                      padding: const EdgeInsets.all(14),
                                      child: SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 1.8,
                                          color:
                                              Colors.white.withOpacity(0.35),
                                        ),
                                      ),
                                    )
                                  : Icon(
                                      Icons.search_rounded,
                                      color: Colors.white.withOpacity(0.30),
                                      size: 20,
                                    ),
                              suffixIcon:
                                  _addressController.text.isNotEmpty
                                      ? IconButton(
                                          icon: Icon(
                                            Icons.clear_rounded,
                                            color:
                                                Colors.white.withOpacity(0.30),
                                            size: 17,
                                          ),
                                          onPressed: () {
                                            _addressController.clear();
                                            setState(() {
                                              _suggestions = [];
                                              _showSuggestions = false;
                                            });
                                          },
                                        )
                                      : null,
                            ),
                            textInputAction: TextInputAction.search,
                            onFieldSubmitted: (_) {
                              setState(() => _showSuggestions = false);
                              _analyze();
                            },
                            onChanged: (v) {
                              setState(() {});
                              _onChanged(v);
                            },
                            validator: ref
                                .read(validationServiceProvider)
                                .validateAddress,
                          ),

                          // Suggestion dropdown
                          AnimatedSize(
                            duration: const Duration(milliseconds: 200),
                            curve: Curves.easeOut,
                            child: _showSuggestions && _suggestions.isNotEmpty
                                ? Column(
                                    children: [
                                      const SizedBox(height: 6),
                                      Container(
                                        decoration: BoxDecoration(
                                          color: _kSurface2,
                                          borderRadius:
                                              BorderRadius.circular(14),
                                          border: Border.all(color: _kBorder),
                                        ),
                                        child: Column(
                                          children: [
                                            for (int i = 0;
                                                i < _suggestions.length;
                                                i++) ...[
                                              if (i > 0)
                                                Divider(
                                                  height: 1,
                                                  color: Colors.white
                                                      .withOpacity(0.05),
                                                ),
                                              _SuggestionTile(
                                                suggestion: _suggestions[i],
                                                onTap: () => _pickSuggestion(
                                                    _suggestions[i]),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ],
                                  )
                                : const SizedBox.shrink(),
                          ),

                          const SizedBox(height: 12),

                          // Get Insights — gradient CTA
                          _InsightsButton(
                            onPressed: () {
                              setState(() => _showSuggestions = false);
                              _analyze();
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ).animate(delay: 180.ms).fadeIn(duration: 480.ms),
              ),

              // ── What we analyze ──────────────────────────────────────────
              const SliverToBoxAdapter(child: SizedBox(height: 20)),
              const SliverToBoxAdapter(child: _DimensionRow()),

              // ── Recent searches ──────────────────────────────────────────
              if (history.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(22, 36, 22, 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'RECENT',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.32),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.8,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => ref
                              .read(searchHistoryProvider.notifier)
                              .clear(),
                          child: Text(
                            'Clear',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.32),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Column(
                    children: history.take(6).map((entry) => _HistoryTile(
                          entry: entry,
                          onTap: () async {
                            _focusNode.unfocus();
                            await ref.read(analysisProvider.notifier).loadFromHistory(entry);
                            if (mounted) ref.read(shellTabProvider.notifier).state = 1;
                          },
                          onRemove: () => ref
                              .read(searchHistoryProvider.notifier)
                              .remove(entry.id),
                        )).toList(),
                  ),
                ),
              ],

              const SliverToBoxAdapter(child: SizedBox(height: 52)),
            ],
          ),
        ),
      ),
    );
  }

  String _flag(String code) {
    const flags = {
      'PT': '🇵🇹',
      'ES': '🇪🇸',
      'GB': '🇬🇧',
      'FR': '🇫🇷',
      'DE': '🇩🇪',
    };
    return flags[code] ?? '🌍';
  }
}

// ── Gradient CTA button ───────────────────────────────────────────────────────

class _InsightsButton extends StatelessWidget {
  final VoidCallback onPressed;
  const _InsightsButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2563EB), Color(0xFF7C3AED)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3B82F6).withOpacity(0.38),
            blurRadius: 22,
            offset: const Offset(0, 7),
            spreadRadius: -4,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(14),
          splashColor: Colors.white.withOpacity(0.10),
          highlightColor: Colors.white.withOpacity(0.05),
          child: const Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.insights_rounded, color: Colors.white, size: 18),
                SizedBox(width: 9),
                Text(
                  'Get Insights',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.2,
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

// ── Suggestion tile ───────────────────────────────────────────────────────────

class _SuggestionTile extends StatelessWidget {
  final _Suggestion suggestion;
  final VoidCallback onTap;

  const _SuggestionTile({required this.suggestion, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 1),
              child: Icon(
                Icons.location_on_rounded,
                size: 15,
                color: _kAccent.withOpacity(0.65),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    suggestion.primary,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (suggestion.secondary.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      suggestion.secondary,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.38),
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Mini logo ─────────────────────────────────────────────────────────────────

class _Logo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const size = 26.0;
    const colors = [
      Color(0xFF29B6F6),
      Color(0xFF66BB6A),
      Color(0xFFEF5350),
      Color(0xFFFFA726),
      Color(0xFFAB47BC),
      Color(0xFF8D6E63),
      Color(0xFF26C6DA),
    ];
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _DonutPainter(colors)),
    );
  }
}

class _DonutPainter extends CustomPainter {
  final List<Color> colors;
  _DonutPainter(this.colors);

  @override
  void paint(Canvas canvas, Size size) {
    const segments = 7;
    const gapRad = 0.08;
    const sweepRad = (2 * 3.14159265 / segments) - gapRad;
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    for (int i = 0; i < segments; i++) {
      final start =
          -1.5707963 + i * (2 * 3.14159265 / segments) + gapRad / 2;
      canvas.drawArc(
        rect.deflate(3.5),
        start,
        sweepRad,
        false,
        Paint()
          ..color = colors[i]
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.5
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

// ── History tile ──────────────────────────────────────────────────────────────

class _HistoryTile extends StatelessWidget {
  final SearchHistoryEntry entry;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const _HistoryTile({
    required this.entry,
    required this.onTap,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final score = entry.score.overall.round();
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.fromLTRB(18, 0, 18, 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: _kSurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withOpacity(0.06)),
        ),
        child: Row(
          children: [
            ScoreBadge(score: score, size: 36),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.address.displayAddress,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _timeAgo(entry.timestamp),
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.32),
                      fontSize: 11.5,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(Icons.close_rounded,
                  size: 14, color: Colors.white.withOpacity(0.22)),
              onPressed: onRemove,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            ),
          ],
        ),
      ),
    );
  }

  String _timeAgo(DateTime t) {
    final d = DateTime.now().difference(t);
    if (d.inMinutes < 60) return '${d.inMinutes}m ago';
    if (d.inHours < 24) return '${d.inHours}h ago';
    return '${d.inDays}d ago';
  }
}

// ── What we analyze — pixel-perfect grid ──────────────────────────────────────

class _DimensionRow extends StatelessWidget {
  const _DimensionRow();

  static const _dims = [
    (emoji: '🚇', label: 'Transport',  color: Color(0xFF29B6F6)),
    (emoji: '🎓', label: 'Education',  color: Color(0xFF66BB6A)),
    (emoji: '🏥', label: 'Health',     color: Color(0xFFEF5350)),
    (emoji: '🛡', label: 'Safety',     color: Color(0xFFAB47BC)),
    (emoji: '🛍', label: 'Lifestyle',  color: Color(0xFFFFA726)),
    (emoji: '🌳', label: 'Nature',     color: Color(0xFF26C6DA)),
    (emoji: '💼', label: 'Investment', color: Color(0xFF8D6E63)),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(22, 0, 22, 12),
          child: Text(
            'WHAT WE ANALYZE',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.38),
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.6,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: LayoutBuilder(
            builder: (_, constraints) {
              const gap = 9.0;
              final cardW = (constraints.maxWidth - gap * 3) / 4;
              final cardH = cardW / 0.82;
              Widget card(int i) => SizedBox(
                    width: cardW,
                    height: cardH,
                    child: _DimCard(d: _dims[i]),
                  );
              return Column(
                children: [
                  // Row 1 — 4 cards
                  Row(children: [
                    for (int i = 0; i < 4; i++) ...[
                      if (i > 0) const SizedBox(width: gap),
                      card(i),
                    ],
                  ]),
                  const SizedBox(height: gap),
                  // Row 2 — 3 cards centred
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    for (int i = 4; i < 7; i++) ...[
                      if (i > 4) const SizedBox(width: gap),
                      card(i),
                    ],
                  ]),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

class _DimCard extends StatefulWidget {
  final ({String emoji, String label, Color color}) d;
  const _DimCard({required this.d});

  @override
  State<_DimCard> createState() => _DimCardState();
}

class _DimCardState extends State<_DimCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final c = widget.d.color;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        clipBehavior: Clip.antiAlias,
        transform: Matrix4.translationValues(0, _hovered ? -4 : 0, 0),
        decoration: BoxDecoration(
          color: c.withValues(alpha: _hovered ? 0.12 : 0.07),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: c.withValues(alpha: _hovered ? 0.28 : 0.14)),
          boxShadow: _hovered
              ? [BoxShadow(color: c.withValues(alpha: 0.24), blurRadius: 14, offset: const Offset(0, 6))]
              : [],
        ),
        child: Stack(
          children: [
            // Content: icon top, label bottom
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(4, 16, 4, 10),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(widget.d.emoji,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 24)),
                    Text(
                      widget.d.label,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: c.withValues(alpha: 0.90),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.1,
                        height: 1.1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Top accent bar — identical 3 px on every card
            Positioned(
              top: 0, left: 0, right: 0,
              child: Container(height: 3, color: c.withValues(alpha: 0.70)),
            ),
          ],
        ),
      ),
    );
  }
}
