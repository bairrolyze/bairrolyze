import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../config/app_constants.dart';
import '../../config/app_theme.dart';
import '../../models/user_preferences_model.dart';
import '../../providers/analysis_provider.dart';
import '../../providers/country_provider.dart';
import '../../providers/preferences_provider.dart';
import '../../providers/shell_provider.dart';
import '../../services/validation_service.dart';
import '../../widgets/home/analyzing_progress_view.dart';
import '../../widgets/home/recent_search_tile.dart';

// ── Brand gradient ────────────────────────────────────────────────────────────
// Single source for the blue→violet accent used on the hero icon and CTA.
// Built from theme tokens so it stays correct in light and dark mode.
const _brandGradient = LinearGradient(
  colors: [AppColors.accent, AppColors.accent2],
  begin: Alignment.centerLeft,
  end: Alignment.centerRight,
);

// Horizontal gutter used consistently across every section.
const _kGutter = 22.0;

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
  bool _locating = false;
  String _analyzingAddress = '';
  // The full Nominatim string for a picked suggestion — sent for accurate
  // geocoding while the field shows only the short label. Cleared when the
  // user edits the field.
  String? _pickedFullAddress;

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
    _pickedFullAddress = null; // manual edit invalidates a prior selection
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
    // Show the concise label the user actually picked…
    _addressController.text = s.primary;
    _addressController.selection =
        TextSelection.collapsed(offset: s.primary.length);
    // …but keep the full string so geocoding stays precise.
    _pickedFullAddress = s.display;
    setState(() {
      _suggestions = [];
      _showSuggestions = false;
    });
    _focusNode.unfocus();
  }

  Future<void> _analyze() async {
    if (!_formKey.currentState!.validate()) return;
    final country = ref.read(selectedCountryProvider);
    final profile = ref.read(preferencesProvider).profile.jsonValue;
    // Geocode the full picked address for accuracy; show the short label.
    final query =
        (_pickedFullAddress ?? _addressController.text).trim();
    setState(() => _analyzingAddress = _addressController.text.trim());
    await ref.read(analysisProvider.notifier).analyze(
          query,
          countryCode: country?.code ?? 'PT',
          profile: profile,
        );
    if (!mounted) return;
    if (ref.read(analysisProvider).status == AnalysisStatus.done) {
      ref.read(shellTabProvider.notifier).state = 1;
    }
  }

  Future<void> _openHistory(SearchHistoryEntry entry) async {
    _focusNode.unfocus();
    setState(() => _analyzingAddress = entry.address.displayAddress);
    await ref.read(analysisProvider.notifier).loadFromHistory(entry);
    if (mounted) {
      ref.read(shellTabProvider.notifier).state = 1;
    }
  }

  // Resolve the device's current location into the search field (map-style).
  Future<void> _useCurrentLocation() async {
    if (_locating) return;
    _focusNode.unfocus();
    setState(() => _locating = true);
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        _locationError('Turn on location services to use this.');
        return;
      }
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        _locationError('Location permission is needed to detect your area.');
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.high),
      );
      final address = await _reverseGeocode(pos.latitude, pos.longitude);
      if (!mounted) return;
      _addressController.text = address;
      _pickedFullAddress = null; // the field itself now holds the full address
      setState(() => _showSuggestions = false);
    } catch (_) {
      _locationError('Could not get your current location.');
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  // Reverse-geocode via the same Nominatim service used for search.
  Future<String> _reverseGeocode(double lat, double lng) async {
    final resp = await _dio.get<Map<String, dynamic>>(
      '${AppConstants.nominatimBaseUrl}/reverse',
      queryParameters: {'lat': lat, 'lon': lng, 'format': 'jsonv2'},
      options: Options(
        headers: {'User-Agent': 'HomeScope/1.0 (mobile)'},
        receiveTimeout: const Duration(seconds: 8),
      ),
    );
    return resp.data?['display_name'] as String? ??
        '${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}';
  }

  void _locationError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      behavior: SnackBarBehavior.floating,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final analysis = ref.watch(analysisProvider);
    final history  = ref.watch(searchHistoryProvider);
    final p        = AppPalette.of(context);

    ref.listen(analysisProvider, (_, next) {
      if (next.status == AnalysisStatus.error && next.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(next.error!),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ));
      }
    });

    return Scaffold(
      backgroundColor: p.bg,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 260),
        child: analysis.isLoading
            ? AnalyzingProgressView(
                key: const ValueKey('analyzing'),
                address: _analyzingAddress,
                status: analysis.status,
                progress: analysis.progress,
              )
            : Stack(
                key: const ValueKey('search'),
                children: [
                  // Soft brand glow behind the hero for depth.
                  const Positioned(
                      top: -60, left: 0, right: 0, child: Center(child: _GlowBlob())),
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 560),
                      child: SafeArea(
                        bottom: false,
                        child: CustomScrollView(
                          controller: _scrollController,
                          slivers: [
                            // 1 ── Branding hero (centred)
                            const SliverToBoxAdapter(child: _Hero()),

                            // 2 ── Search + CTA
                            SliverToBoxAdapter(child: _buildSearchAndCta()),

                            const SliverToBoxAdapter(child: SizedBox(height: 30)),

                            // 3 ── Recent searches (only when there is history;
                            // shows the 3 most recent).
                            if (history.isNotEmpty) ...[
                              SliverToBoxAdapter(
                                child: _RecentHeader(
                                  onClear: () => ref
                                      .read(searchHistoryProvider.notifier)
                                      .clear(),
                                ),
                              ),
                              SliverToBoxAdapter(
                                child: Column(
                                  children: [
                                    for (final entry in history.take(3))
                                      RecentSearchTile(
                                        entry: entry,
                                        onTap: () => _openHistory(entry),
                                        onRemove: () => ref
                                            .read(searchHistoryProvider.notifier)
                                            .remove(entry.id),
                                      ),
                                  ],
                                ),
                              ),
                              const SliverToBoxAdapter(child: SizedBox(height: 30)),
                            ],

                            // 4 ── What we analyse
                            const SliverToBoxAdapter(child: _CategoryCarousel()),

                            // 5 ── How it works
                            const SliverToBoxAdapter(child: SizedBox(height: 34)),
                            const SliverToBoxAdapter(child: _HowItWorksCard()),

                            const SliverToBoxAdapter(child: SizedBox(height: 40)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  // ── Search field + CTA (stateful — owns controller/focus/suggestions) ───────

  Widget _buildSearchAndCta() {
    final p = AppPalette.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(_kGutter, 8, _kGutter, 0),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            // Search field
            Container(
              decoration: BoxDecoration(
                color: p.surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: p.border),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 12, right: 4),
                    child: _fetching
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 1.8,
                              color: p.textTertiary,
                            ),
                          )
                        : Icon(Icons.search_rounded,
                            color: p.textTertiary, size: 22),
                  ),
                  Expanded(
                    child: TextFormField(
                      controller: _addressController,
                      focusNode: _focusNode,
                      style: TextStyle(
                          color: p.textPrimary,
                          fontSize: 15.5,
                          letterSpacing: -0.1),
                      decoration: InputDecoration(
                        hintText: 'Search any address, city or area',
                        hintStyle:
                            TextStyle(color: p.textTertiary, fontSize: 15),
                        isDense: true,
                        filled: false,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        errorBorder: InputBorder.none,
                        focusedErrorBorder: InputBorder.none,
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 16),
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
                      validator:
                          ref.read(validationServiceProvider).validateAddress,
                    ),
                  ),
                  // Clear (only when text present) then "use my location".
                  if (_addressController.text.isNotEmpty)
                    IconButton(
                      icon: Icon(Icons.clear_rounded,
                          color: p.textTertiary, size: 18),
                      onPressed: () {
                        _addressController.clear();
                        _pickedFullAddress = null;
                        setState(() {
                          _suggestions = [];
                          _showSuggestions = false;
                        });
                      },
                    ),
                  IconButton(
                    icon: _locating
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 1.8,
                              color: AppColors.accent,
                            ),
                          )
                        : const Icon(Icons.my_location_rounded,
                            color: AppColors.accent, size: 20),
                    tooltip: 'Use my current location',
                    onPressed: _locating ? null : _useCurrentLocation,
                  ),
                ],
              ),
            ),

            // Suggestion dropdown
            AnimatedSize(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              child: _showSuggestions && _suggestions.isNotEmpty
                  ? Column(
                      children: [
                        const SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            color: p.surface2,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: p.border),
                          ),
                          child: Column(
                            children: [
                              for (int i = 0; i < _suggestions.length; i++) ...[
                                if (i > 0) Divider(height: 1, color: p.border),
                                _SuggestionTile(
                                  suggestion: _suggestions[i],
                                  onTap: () => _pickSuggestion(_suggestions[i]),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    )
                  : const SizedBox.shrink(),
            ),

            const SizedBox(height: 16),

            // Primary CTA
            _CtaButton(
              onPressed: () {
                setState(() => _showSuggestions = false);
                _analyze();
              },
            ),
          ],
        ),
      ),
    ).animate(delay: 140.ms).fadeIn(duration: 460.ms).slideY(begin: 0.05, end: 0);
  }
}

// ── Branding hero (centred icon + name + subtitle) ────────────────────────────

class _Hero extends StatelessWidget {
  const _Hero();

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(_kGutter, 20, _kGutter, 30),
      child: Column(
        children: [
          // Home icon badge
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              color: p.surface,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: AppColors.accent.withValues(alpha: 0.30)),
              boxShadow: [
                BoxShadow(
                  color: AppColors.accent.withValues(alpha: 0.35),
                  blurRadius: 28,
                  spreadRadius: -6,
                ),
              ],
            ),
            alignment: Alignment.center,
            child: const Icon(Icons.home_rounded,
                color: AppColors.accent, size: 38),
          )
              .animate()
              .fadeIn(duration: 460.ms)
              .scale(begin: const Offset(0.85, 0.85), curve: Curves.easeOutBack),

          const SizedBox(height: 18),

          // App name
          Text(
            'HomeScope',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: p.textPrimary,
              fontSize: 33,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.8,
            ),
          ).animate(delay: 60.ms).fadeIn(duration: 460.ms),

          const SizedBox(height: 12),

          // Subtitle
          Text(
            'Neighbourhood insights to help you\nmake better decisions.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: p.textSecondary,
              fontSize: 15.5,
              height: 1.5,
              letterSpacing: -0.1,
            ),
          ).animate(delay: 110.ms).fadeIn(duration: 460.ms),
        ],
      ),
    );
  }
}

// ── Decorative brand glow ─────────────────────────────────────────────────────

class _GlowBlob extends StatelessWidget {
  const _GlowBlob();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: 340,
        height: 340,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              AppColors.accent.withValues(alpha: 0.16),
              AppColors.accent.withValues(alpha: 0.0),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Primary gradient CTA ──────────────────────────────────────────────────────

class _CtaButton extends StatelessWidget {
  final VoidCallback onPressed;
  const _CtaButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 58,
      decoration: BoxDecoration(
        gradient: _brandGradient,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.accent.withValues(alpha: 0.40),
            blurRadius: 26,
            offset: const Offset(0, 9),
            spreadRadius: -4,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(18),
          splashColor: Colors.white.withValues(alpha: 0.10),
          highlightColor: Colors.white.withValues(alpha: 0.05),
          child: const Center(
            child: Text(
              'Analyse Neighbourhood',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
              ),
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
    final p = AppPalette.of(context);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 1),
              child: Icon(
                Icons.location_on_rounded,
                size: 16,
                color: AppColors.accent.withValues(alpha: 0.65),
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
                    style: TextStyle(
                      color: p.textPrimary,
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
                      style: TextStyle(color: p.textTertiary, fontSize: 11.5),
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

// ── Recent searches: header ───────────────────────────────────────────────────

class _RecentHeader extends StatelessWidget {
  final VoidCallback onClear;
  const _RecentHeader({required this.onClear});

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(_kGutter, 0, _kGutter, 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Recent Searches',
            style: TextStyle(
              color: p.textPrimary,
              fontSize: 21,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
            ),
          ),
          GestureDetector(
            onTap: onClear,
            behavior: HitTestBehavior.opaque,
            child: Text(
              'Clear',
              style: TextStyle(
                color: p.textTertiary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── What we analyse — swipeable glass carousel ────────────────────────────────

class _Cat {
  final IconData icon;
  final String label;
  final String desc;
  final Color color;
  const _Cat(this.icon, this.label, this.desc, this.color);
}

const _kCats = <_Cat>[
  _Cat(Icons.directions_transit_rounded, 'Transport',
      'Nearby train stations, bus routes, commute times and walkability.',
      Color(0xFF29B6F6)),
  _Cat(Icons.school_rounded, 'Education',
      'Schools, universities, libraries and learning options close by.',
      Color(0xFF66BB6A)),
  _Cat(Icons.local_hospital_rounded, 'Health',
      'Hospitals, clinics, pharmacies and everyday healthcare access.',
      Color(0xFFEF5350)),
  _Cat(Icons.shield_rounded, 'Safety',
      'Emergency services, plus real crime stats where available.',
      Color(0xFFAB47BC)),
  _Cat(Icons.shopping_bag_rounded, 'Lifestyle',
      'Shops, markets, cafés and the daily conveniences within reach.',
      Color(0xFFFFA726)),
  _Cat(Icons.park_rounded, 'Nature',
      'Parks, gardens and green open spaces for the outdoors.',
      Color(0xFF26C6DA)),
  _Cat(Icons.trending_up_rounded, 'Investment',
      'Price trends, rental demand and long-term value potential.',
      Color(0xFF8D6E63)),
];

class _CategoryCarousel extends StatefulWidget {
  const _CategoryCarousel();

  @override
  State<_CategoryCarousel> createState() => _CategoryCarouselState();
}

class _CategoryCarouselState extends State<_CategoryCarousel> {
  late final PageController _pc;
  double _page = 0;

  @override
  void initState() {
    super.initState();
    _pc = PageController(viewportFraction: 0.83);
    _pc.addListener(_onScroll);
    // Guard against the PageView restoring a non-zero page on launch — always
    // start focused on the first category.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _pc.hasClients) _pc.jumpToPage(0);
    });
  }

  void _onScroll() {
    final pg = _pc.page ?? 0;
    if (pg != _page) setState(() => _page = pg);
  }

  @override
  void dispose() {
    _pc.removeListener(_onScroll);
    _pc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final active = _page.round().clamp(0, _kCats.length - 1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(
          title: 'What we analyse',
          subtitle: 'Seven signals we score for every address · swipe to explore',
        ),
        SizedBox(
          height: 188,
          child: PageView.builder(
            controller: _pc,
            physics: const BouncingScrollPhysics(),
            itemCount: _kCats.length,
            itemBuilder: (context, i) {
              // delta: signed distance from the centred page (0 = focused).
              final delta = _page - i;
              final t = delta.abs().clamp(0.0, 1.0);
              return _GlassCategoryCard(cat: _kCats[i], t: t, delta: delta);
            },
          ),
        ),
        const SizedBox(height: 20),
        // Animated page indicators — active dot stretches and takes the
        // active category's colour (the glow "follows" the card).
        Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(_kCats.length, (i) {
              final on = i == active;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: on ? 22 : 7,
                height: 7,
                decoration: BoxDecoration(
                  color: on ? _kCats[active].color : p.border,
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}

class _GlassCategoryCard extends StatelessWidget {
  final _Cat cat;
  final double t; // 0 when focused (centred), 1 when a full page away
  final double delta; // signed distance from centre (for parallax direction)

  const _GlassCategoryCard(
      {required this.cat, required this.t, required this.delta});

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final focus = 1 - t; // 1 at centre → 0 at the edges

    // Micro-interactions.
    final scale = 0.92 + 0.08 * focus;      // focused card sits larger
    final lift = -10.0 * focus;              // …and lifts up
    final iconScale = 0.88 + 0.12 * focus;   // icon gently scales on focus
    final parallax = delta * 16.0;           // content drifts against the drag

    return Transform.translate(
      offset: Offset(0, lift),
      child: Transform.scale(
        scale: scale,
        child: Padding(
          // Extra vertical room so the focused (scaled + lifted) card and its
          // glow are never clipped at the top of the PageView.
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 16),
          child: Container(
            // Transparent card — just a tinted border + soft category glow.
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: cat.color.withValues(alpha: 0.22)),
              boxShadow: [
                BoxShadow(
                  color: cat.color.withValues(alpha: 0.06 + 0.18 * focus),
                  blurRadius: 30,
                  spreadRadius: -8,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            padding: const EdgeInsets.all(20),
            child: Transform.translate(
              offset: Offset(parallax, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Transform.scale(
                        scale: iconScale,
                        child: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: cat.color.withValues(alpha: 0.16),
                            border: Border.all(
                                color: cat.color.withValues(alpha: 0.35)),
                            boxShadow: [
                              BoxShadow(
                                color: cat.color.withValues(alpha: 0.32 * focus),
                                blurRadius: 20,
                                spreadRadius: -4,
                              ),
                            ],
                          ),
                          child: Icon(cat.icon, color: cat.color, size: 25),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          cat.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: p.textPrimary,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    cat.desc,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: p.textSecondary,
                      fontSize: 13.5,
                      height: 1.45,
                      letterSpacing: -0.1,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Reusable section header (gradient tick + title + subtitle) ────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  const _SectionHeader({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(_kGutter, 0, _kGutter, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Gradient accent tick that anchors every section header.
              Container(
                width: 4,
                height: 20,
                decoration: BoxDecoration(
                  gradient: _brandGradient,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: TextStyle(
                  color: p.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.6,
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          Padding(
            padding: const EdgeInsets.only(left: 14),
            child: Text(
              subtitle,
              style: TextStyle(
                color: p.textTertiary,
                fontSize: 12.5,
                letterSpacing: -0.1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── How it works ──────────────────────────────────────────────────────────────

class _HowItWorksCard extends StatelessWidget {
  const _HowItWorksCard();

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(
          title: 'How it works',
          subtitle: 'From an address to a score in three steps',
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: _kGutter),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(24),
              border:
                  Border.all(color: AppColors.accent.withValues(alpha: 0.14)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'We pull live data from OpenStreetMap and score every category against your profile, so the result reflects what actually matters to you.',
                  style: TextStyle(
                    color: p.textSecondary,
                    fontSize: 13.5,
                    height: 1.55,
                    letterSpacing: -0.1,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    const _StepChip(
                        icon: Icons.location_searching_rounded, label: 'Locate'),
                    _StepArrow(color: p.textTertiary),
                    const _StepChip(
                        icon: Icons.travel_explore_rounded, label: 'Analyse'),
                    _StepArrow(color: p.textTertiary),
                    const _StepChip(
                        icon: Icons.insights_rounded, label: 'Score'),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _StepArrow extends StatelessWidget {
  final Color color;
  const _StepArrow({required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Icon(Icons.arrow_forward_rounded, size: 15, color: color),
    );
  }
}

class _StepChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _StepChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Expanded(
      child: Column(
        children: [
          // Circular accent icon badge — mirrors the category-card icons.
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.accent.withValues(alpha: 0.14),
              border:
                  Border.all(color: AppColors.accent.withValues(alpha: 0.28)),
            ),
            child: Icon(icon, size: 21, color: AppColors.accent),
          ),
          const SizedBox(height: 9),
          Text(
            label,
            style: TextStyle(
              color: p.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.1,
            ),
          ),
        ],
      ),
    );
  }
}
