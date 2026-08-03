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
import '../../widgets/home/brand.dart';
import '../../widgets/home/recent_search_tile.dart';

// ── Brand gradient ────────────────────────────────────────────────────────────
// The premium blue→purple accent used on the primary CTA, active accents and
// section ticks. Kept in one place so the whole screen stays consistent.
const _kPrimaryBlue = Color(0xFF2F80FF);
const _kPrimaryPurple = Color(0xFF7C4DFF);
const _brandGradient = LinearGradient(
  colors: [_kPrimaryBlue, _kPrimaryPurple],
  begin: Alignment.centerLeft,
  end: Alignment.centerRight,
);

// Horizontal gutter used consistently across every section.
const _kGutter = 22.0;

// Translucent glass surface / border for dark-mode cards (Apple-style).
Color _glassFill(BuildContext c) =>
    Theme.of(c).brightness == Brightness.dark
        ? Colors.white.withValues(alpha: 0.05)
        : AppColors.surfaceLight;
Color _glassBorder(BuildContext c) =>
    Theme.of(c).brightness == Brightness.dark
        ? Colors.white.withValues(alpha: 0.08)
        : AppColors.borderLight;

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
    // Geocode the full picked address for accuracy; show the short label.
    await _runAnalysis(
      query: (_pickedFullAddress ?? _addressController.text).trim(),
      label: _addressController.text.trim(),
      countryCode: country?.code ?? 'PT',
    );
  }

  // Popular-search shortcut: skips the text field, analysing a well-known city
  // in the currently selected country.
  Future<void> _runPopularSearch(_PopularCity city) async {
    final country = ref.read(selectedCountryProvider);
    final countryName = country?.name ?? 'Portugal';
    _focusNode.unfocus();
    setState(() => _showSuggestions = false);
    await _runAnalysis(
      query: '${city.name}, $countryName',
      label: city.name,
      countryCode: country?.code ?? 'PT',
    );
  }

  Future<void> _runAnalysis({
    required String query,
    required String label,
    required String countryCode,
  }) async {
    final profile = ref.read(preferencesProvider).profile.jsonValue;
    setState(() => _analyzingAddress = label);
    await ref.read(analysisProvider.notifier).analyze(
          query,
          countryCode: countryCode,
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

    final dark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: p.bg,
      body: DecoratedBox(
        // Deep navy cinematic gradient (never pure black) with a soft blue
        // radial glow behind the hero — the atmospheric base for everything.
        decoration: BoxDecoration(
          gradient: dark
              ? const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF060B18), Color(0xFF081223), Color(0xFF050A16)],
                  stops: [0.0, 0.5, 1.0],
                )
              : null,
          color: dark ? null : p.bg,
        ),
        child: Stack(
          children: [
            if (dark)
              const Positioned(
                top: -80,
                left: 0,
                right: 0,
                child: IgnorePointer(child: _RadialGlow()),
              ),
            _buildBody(analysis),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(AnalysisState analysis) {
    final history = ref.watch(searchHistoryProvider);
    return AnimatedSwitcher(
        duration: const Duration(milliseconds: 260),
        child: analysis.isLoading
            ? AnalyzingProgressView(
                key: const ValueKey('analyzing'),
                address: _analyzingAddress,
                status: analysis.status,
                progress: analysis.progress,
              )
            : Center(
                key: const ValueKey('search'),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: SafeArea(
                    top: false,
                    bottom: false,
                    child: CustomScrollView(
                      controller: _scrollController,
                      slivers: [
                        // 1 ── City hero: skyline backdrop + logo + wordmark
                        const SliverToBoxAdapter(child: _Hero()),

                        // 2 ── Search + CTA
                        SliverToBoxAdapter(child: _buildSearchAndCta()),

                        const SliverToBoxAdapter(child: SizedBox(height: 26)),

                        // 3 ── Popular searches
                        SliverToBoxAdapter(
                          child: _PopularSearches(onTap: _runPopularSearch),
                        ),

                        const SliverToBoxAdapter(child: SizedBox(height: 26)),

                        // 4 ── Why trust it (Smart Data / AI / Score / Private)
                        const SliverToBoxAdapter(child: _FeatureGrid()),

                        // 5 ── Recent searches (only when there is history;
                        // shows the 3 most recent).
                        if (history.isNotEmpty) ...[
                          const SliverToBoxAdapter(child: SizedBox(height: 34)),
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
                        ],

                        // 6 ── What we analyse
                        const SliverToBoxAdapter(child: SizedBox(height: 40)),
                        const SliverToBoxAdapter(child: _CategoryCarousel()),

                        // 7 ── How it works
                        const SliverToBoxAdapter(child: SizedBox(height: 34)),
                        const SliverToBoxAdapter(child: _HowItWorksCard()),

                        // 8 ── Trusted-by social proof (moved to the very end)
                        const SliverToBoxAdapter(child: SizedBox(height: 40)),
                        const SliverToBoxAdapter(child: _TrustedBy()),

                        const SliverToBoxAdapter(child: SizedBox(height: 40)),
                      ],
                    ),
                  ),
                ),
              ),
    );
  }

  // ── Search field + CTA (stateful — owns controller/focus/suggestions) ───────

  Widget _buildSearchAndCta() {
    final p = AppPalette.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(_kGutter, 2, _kGutter, 0),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            // Search field — 64px dark-glass, 22px radius
            Container(
              decoration: BoxDecoration(
                color: _glassFill(context),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: _glassBorder(context)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 6),
              constraints: const BoxConstraints(minHeight: 64),
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

// ── City hero (skyline backdrop + logo mark + wordmark + subtitle) ────────────

class _Hero extends StatelessWidget {
  const _Hero();

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final topInset = MediaQuery.of(context).padding.top;
    // The painted skyline fills the full hero and reaches under the status bar;
    // content is inset from the top so it clears the notch. The skyline sits as
    // a V (tall edges, open centre) in the lower band, so the logo + wordmark
    // rest against clear sky and the buildings meet the search field below.
    const heroHeight = 404.0;

    return SizedBox(
      height: heroHeight,
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          // Skyline backdrop, full-bleed to the top edge.
          Positioned.fill(
            child: CityHeroBackdrop(height: heroHeight),
          ),
          // Centred brand lockup, floating above the skyline.
          Padding(
            padding: EdgeInsets.only(top: topInset + 30),
            child: Column(
              children: [
                const BairrolyzeLogoMark(size: 104)
                    .animate()
                    .fadeIn(duration: 500.ms)
                    .scale(
                        begin: const Offset(0.82, 0.82),
                        curve: Curves.easeOutBack),
                const SizedBox(height: 14),
                const BairrolyzeWordmark(fontSize: 44)
                    .animate(delay: 80.ms)
                    .fadeIn(duration: 500.ms)
                    .slideY(begin: 0.15, end: 0, curve: Curves.easeOut),
                const SizedBox(height: 14),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: _kGutter),
                  child: Text(
                    'AI-powered neighbourhood insights\nto help you make better decisions.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: p.textSecondary,
                      fontSize: 15.5,
                      height: 1.5,
                      letterSpacing: -0.1,
                    ),
                  ).animate(delay: 130.ms).fadeIn(duration: 500.ms),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Subtle press-scale wrapper (buttons dip to 0.98 on press) ─────────────────

class _PressableScale extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  const _PressableScale({required this.child, required this.onTap});

  @override
  State<_PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<_PressableScale> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => setState(() => _down = true),
      onTapUp: (_) => setState(() => _down = false),
      onTapCancel: () => setState(() => _down = false),
      child: AnimatedScale(
        scale: _down ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 110),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

// ── Soft blue radial glow behind the hero ─────────────────────────────────────

class _RadialGlow extends StatelessWidget {
  const _RadialGlow();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 460,
      height: 460,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            _kPrimaryBlue.withValues(alpha: 0.18),
            _kPrimaryPurple.withValues(alpha: 0.05),
            _kPrimaryBlue.withValues(alpha: 0.0),
          ],
          stops: const [0.0, 0.45, 1.0],
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
    return _PressableScale(
      onTap: onPressed,
      child: Container(
        height: 70,
        decoration: BoxDecoration(
          gradient: _brandGradient,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            // Soft ambient blue-purple glow beneath the button.
            BoxShadow(
              color: _kPrimaryPurple.withValues(alpha: 0.38),
              blurRadius: 34,
              offset: const Offset(0, 12),
              spreadRadius: -6,
            ),
            BoxShadow(
              color: _kPrimaryBlue.withValues(alpha: 0.28),
              blurRadius: 22,
              offset: const Offset(0, 6),
              spreadRadius: -8,
            ),
          ],
        ),
        child: const Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Analyse Neighbourhood',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16.5,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.2,
                ),
              ),
              SizedBox(width: 10),
              Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Popular searches ──────────────────────────────────────────────────────────

class _PopularCity {
  final String name;
  final IconData icon;
  final Color color;
  const _PopularCity(this.name, this.icon, this.color);
}

// Most-visited places per supported country. The active country (from
// `selectedCountryProvider`) decides which set is shown, so a user never sees
// another country's cities.
const _kPopularByCountry = <String, List<_PopularCity>>{
  'PT': [
    _PopularCity('Lisbon', Icons.location_city_rounded, Color(0xFF5B8CFF)),
    _PopularCity('Porto', Icons.account_balance_rounded, Color(0xFFF87171)),
    _PopularCity('Cascais', Icons.house_rounded, Color(0xFF34D399)),
    _PopularCity('Sintra', Icons.terrain_rounded, Color(0xFFFBBF24)),
  ],
  'ES': [
    _PopularCity('Madrid', Icons.location_city_rounded, Color(0xFFF87171)),
    _PopularCity('Barcelona', Icons.account_balance_rounded, Color(0xFF5B8CFF)),
    _PopularCity('Valencia', Icons.beach_access_rounded, Color(0xFF34D399)),
    _PopularCity('Seville', Icons.wb_sunny_rounded, Color(0xFFFBBF24)),
  ],
  'GB': [
    _PopularCity('London', Icons.account_balance_rounded, Color(0xFF34D399)),
    _PopularCity('Manchester', Icons.location_city_rounded, Color(0xFF5B8CFF)),
    _PopularCity('Edinburgh', Icons.castle_rounded, Color(0xFFF87171)),
    _PopularCity('Bristol', Icons.directions_boat_rounded, Color(0xFFFBBF24)),
  ],
  'FR': [
    _PopularCity('Paris', Icons.location_city_rounded, Color(0xFF5B8CFF)),
    _PopularCity('Lyon', Icons.account_balance_rounded, Color(0xFFF87171)),
    _PopularCity('Nice', Icons.beach_access_rounded, Color(0xFF34D399)),
    _PopularCity('Bordeaux', Icons.wine_bar_rounded, Color(0xFFFBBF24)),
  ],
  'DE': [
    _PopularCity('Berlin', Icons.location_city_rounded, Color(0xFFFBBF24)),
    _PopularCity('Munich', Icons.account_balance_rounded, Color(0xFF5B8CFF)),
    _PopularCity('Hamburg', Icons.directions_boat_rounded, Color(0xFF34D399)),
    _PopularCity('Cologne', Icons.church_rounded, Color(0xFFF87171)),
  ],
};

List<_PopularCity> _popularFor(String code) =>
    _kPopularByCountry[code] ?? _kPopularByCountry['PT']!;

class _PopularSearches extends ConsumerWidget {
  final ValueChanged<_PopularCity> onTap;
  const _PopularSearches({required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final country = ref.watch(selectedCountryProvider);
    final countryName = country?.name ?? 'Portugal';
    final cities = _popularFor(country?.code ?? 'PT');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          title: 'Popular Searches',
          subtitle: 'Most-visited places in $countryName',
        ),
        SizedBox(
          height: 44,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: _kGutter),
            itemCount: cities.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, i) {
              final c = cities[i];
              return _PopularChip(city: c, onTap: () => onTap(c));
            },
          ),
        ),
      ],
    ).animate(delay: 180.ms).fadeIn(duration: 460.ms);
  }
}

class _PopularChip extends StatelessWidget {
  final _PopularCity city;
  final VoidCallback onTap;
  const _PopularChip({required this.city, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return _PressableScale(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18),
        decoration: BoxDecoration(
          color: _glassFill(context),
          borderRadius: BorderRadius.circular(22),
          // Glowing coloured border, tinted to the city's accent.
          border: Border.all(
              color: city.color.withValues(alpha: 0.55), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: city.color.withValues(alpha: 0.28),
              blurRadius: 14,
              spreadRadius: -3,
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(city.icon, size: 17, color: city.color),
            const SizedBox(width: 8),
            Text(
              city.name,
              style: TextStyle(
                color: p.textSecondary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Why trust it — 4-up feature grid ──────────────────────────────────────────

class _Feature {
  final IconData icon;
  final String title;
  final String desc;
  final Color color;
  const _Feature(this.icon, this.title, this.desc, this.color);
}

const _kFeatures = <_Feature>[
  _Feature(Icons.verified_user_rounded, 'Smart Data',
      'Real-time and reliable sources', Color(0xFF8B5CF6)),
  _Feature(Icons.psychology_rounded, 'AI Analysis',
      '25+ factors analysed in seconds', Color(0xFF3B82F6)),
  _Feature(Icons.track_changes_rounded, 'Accurate Score',
      'A clear score to decide with confidence', Color(0xFF22C55E)),
  _Feature(Icons.lock_rounded, 'Private & Secure',
      'Your searches and data stay protected', Color(0xFFFBBF24)),
];

class _FeatureGrid extends StatelessWidget {
  const _FeatureGrid();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: _kGutter),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 24),
        decoration: BoxDecoration(
          color: _glassFill(context),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: _glassBorder(context)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final f in _kFeatures) Expanded(child: _FeatureCell(f)),
          ],
        ),
      ),
    ).animate(delay: 200.ms).fadeIn(duration: 460.ms).slideY(
          begin: 0.06,
          end: 0,
          curve: Curves.easeOut,
        );
  }
}

class _FeatureCell extends StatelessWidget {
  final _Feature f;
  const _FeatureCell(this.f);

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: f.color.withValues(alpha: 0.14),
              boxShadow: [
                BoxShadow(
                  color: f.color.withValues(alpha: 0.22),
                  blurRadius: 16,
                  spreadRadius: -4,
                ),
              ],
            ),
            child: Icon(f.icon, color: f.color, size: 22),
          ),
          const SizedBox(height: 11),
          Text(
            f.title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: p.textPrimary,
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            f.desc,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: p.textTertiary,
              fontSize: 10.5,
              height: 1.3,
              letterSpacing: -0.1,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Trusted-by social proof ───────────────────────────────────────────────────

class _TrustedBy extends StatelessWidget {
  const _TrustedBy();

  // Deterministic gradient pairs for the faux avatar stack.
  static const _avatarColors = <List<Color>>[
    [Color(0xFF6366F1), Color(0xFF8B5CF6)],
    [Color(0xFF0EA5E9), Color(0xFF22D3EE)],
    [Color(0xFFF472B6), Color(0xFFFB7185)],
    [Color(0xFF34D399), Color(0xFF10B981)],
    [Color(0xFFF59E0B), Color(0xFFF97316)],
  ];

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: _kGutter),
      child: Row(
        children: [
          // Shield badge.
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.accent.withValues(alpha: 0.12),
              border:
                  Border.all(color: AppColors.accent.withValues(alpha: 0.30)),
            ),
            child: const Icon(Icons.verified_user_rounded,
                color: AppColors.accent, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Trusted by thousands of users worldwide',
                  style: TextStyle(
                    color: p.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.1,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    // Overlapping avatar stack.
                    SizedBox(
                      width: 26.0 * _avatarColors.length - (18.0 * (_avatarColors.length - 1)) + 4,
                      height: 30,
                      child: Stack(
                        children: [
                          for (int i = 0; i < _avatarColors.length; i++)
                            Positioned(
                              left: i * 18.0,
                              child: _Avatar(
                                colors: _avatarColors[i],
                                ringColor: p.bg,
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        '+2.5K',
                        style: TextStyle(
                          color: AppColors.accent,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
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
    ).animate(delay: 220.ms).fadeIn(duration: 460.ms);
  }
}

class _Avatar extends StatelessWidget {
  final List<Color> colors;
  final Color ringColor;
  const _Avatar({required this.colors, required this.ringColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: ringColor, width: 2),
      ),
      child: Icon(
        Icons.person_rounded,
        size: 16,
        color: Colors.white.withValues(alpha: 0.92),
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
