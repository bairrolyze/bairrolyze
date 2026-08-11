import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/app_theme.dart';
import '../../config/score_format.dart';
import '../../l10n/app_localizations.dart';
import '../../data/popular_areas.dart';
import '../../models/user_preferences_model.dart';
import '../../providers/analysis_provider.dart';
import '../../providers/country_provider.dart';
import '../../providers/popular_areas_provider.dart';
import '../../providers/preferences_provider.dart';
import '../../providers/shell_provider.dart';
import '../../services/api_service.dart';
import '../../widgets/home/analyzing_progress_view.dart';

// ── Tag colors ─────────────────────────────────────────────────────────────────
const _kTagTransport  = Color(0xFF29B6F6);
const _kTagFamily     = Color(0xFF66BB6A);
const _kTagInvestment = Color(0xFF7C3AED);
const _kTagNature     = Color(0xFF26C6DA);
const _kTagCulture    = Color(0xFFFFA726);

// ── Data model ─────────────────────────────────────────────────────────────────

class _Neighborhood {
  final String id;
  final String name;
  final String city;
  final int score;
  final List<String> tags;
  final int transportScore;
  final int educationScore;
  final int safetyScore;

  const _Neighborhood({
    required this.id,
    required this.name,
    required this.city,
    required this.score,
    required this.tags,
    required this.transportScore,
    required this.educationScore,
    required this.safetyScore,
  });
}

// ── Curated Portugal data ──────────────────────────────────────────────────────
// Names/cities are proper nouns; the description + highlight copy is localized
// via [_nbDesc] / [_nbHighlight], keyed off the stable [id].

const _neighborhoods = <_Neighborhood>[
  _Neighborhood(
    id: 'parqueNacoes',
    name: 'Parque das Nações',
    city: 'Lisboa',
    score: 87,
    tags: ['Transport', 'Family', 'Investment'],
    transportScore: 94,
    educationScore: 78,
    safetyScore: 88,
  ),
  _Neighborhood(
    id: 'principeReal',
    name: 'Príncipe Real',
    city: 'Lisboa',
    score: 82,
    tags: ['Culture', 'Nature'],
    transportScore: 74,
    educationScore: 70,
    safetyScore: 80,
  ),
  _Neighborhood(
    id: 'cascais',
    name: 'Cascais',
    city: 'Cascais',
    score: 85,
    tags: ['Nature', 'Family', 'Investment'],
    transportScore: 72,
    educationScore: 82,
    safetyScore: 91,
  ),
  _Neighborhood(
    id: 'baixaChiado',
    name: 'Baixa-Chiado',
    city: 'Lisboa',
    score: 79,
    tags: ['Culture', 'Transport'],
    transportScore: 88,
    educationScore: 62,
    safetyScore: 71,
  ),
  _Neighborhood(
    id: 'boavista',
    name: 'Boavista',
    city: 'Porto',
    score: 81,
    tags: ['Investment', 'Transport'],
    transportScore: 83,
    educationScore: 76,
    safetyScore: 82,
  ),
  _Neighborhood(
    id: 'fozDouro',
    name: 'Foz do Douro',
    city: 'Porto',
    score: 84,
    tags: ['Nature', 'Family', 'Investment'],
    transportScore: 66,
    educationScore: 84,
    safetyScore: 89,
  ),
  _Neighborhood(
    id: 'santoAntonio',
    name: 'Santo António',
    city: 'Lisboa',
    score: 78,
    tags: ['Family', 'Culture'],
    transportScore: 80,
    educationScore: 85,
    safetyScore: 83,
  ),
  _Neighborhood(
    id: 'bragaCentro',
    name: 'Braga Centro',
    city: 'Braga',
    score: 76,
    tags: ['Family', 'Culture', 'Investment'],
    transportScore: 71,
    educationScore: 88,
    safetyScore: 84,
  ),
];

// ── Localized content helpers (keyed off _Neighborhood.id / tag keys) ──────────

String _nbDesc(AppLocalizations l, String id) => switch (id) {
      'parqueNacoes' => l.nbParqueNacoesDesc,
      'principeReal' => l.nbPrincipeRealDesc,
      'cascais' => l.nbCascaisDesc,
      'baixaChiado' => l.nbBaixaChiadoDesc,
      'boavista' => l.nbBoavistaDesc,
      'fozDouro' => l.nbFozDouroDesc,
      'santoAntonio' => l.nbSantoAntonioDesc,
      _ => l.nbBragaCentroDesc,
    };

String _nbHighlight(AppLocalizations l, String id) => switch (id) {
      'parqueNacoes' => l.nbParqueNacoesHighlight,
      'principeReal' => l.nbPrincipeRealHighlight,
      'cascais' => l.nbCascaisHighlight,
      'baixaChiado' => l.nbBaixaChiadoHighlight,
      'boavista' => l.nbBoavistaHighlight,
      'fozDouro' => l.nbFozDouroHighlight,
      'santoAntonio' => l.nbSantoAntonioHighlight,
      _ => l.nbBragaCentroHighlight,
    };

/// Display label for a tag key (the keys stay English for filter matching).
String _tagLabel(AppLocalizations l, String tag) => switch (tag) {
      'Transport' => l.tagTransport,
      'Family' => l.tagFamily,
      'Investment' => l.tagInvestment,
      'Nature' => l.tagNature,
      'Culture' => l.tagCulture,
      _ => tag,
    };

/// Localized persona label (reuses the settings/onboarding profile strings).
String _profileLabel(AppLocalizations l, UserProfile p) => switch (p) {
      UserProfile.family => l.profileFamily,
      UserProfile.student => l.profileStudent,
      UserProfile.professional => l.profileProfessional,
      UserProfile.retired => l.profileRetired,
      UserProfile.investor => l.profileInvestor,
      UserProfile.defaultProfile => l.profileGeneral,
    };

/// Short persona descriptor shown on the profile cards.
String _profileDesc(AppLocalizations l, UserProfile p) => switch (p) {
      UserProfile.family => l.explorerProfileFamilyDesc,
      UserProfile.student => l.explorerProfileStudentDesc,
      UserProfile.professional => l.explorerProfileProfessionalDesc,
      UserProfile.retired => l.explorerProfileRetiredDesc,
      UserProfile.investor => l.explorerProfileInvestorDesc,
      UserProfile.defaultProfile => '',
    };

String _flag(String code) => const {
      'PT': '🇵🇹',
      'ES': '🇪🇸',
      'GB': '🇬🇧',
      'FR': '🇫🇷',
      'DE': '🇩🇪',
    }[code] ??
    '🌍';

// The personas offered as Explore's primary "who is this for" control.
const _explorerProfiles = [
  UserProfile.family,
  UserProfile.student,
  UserProfile.professional,
  UserProfile.retired,
  UserProfile.investor,
];

/// A lightweight client-side "fit" score: reorders the curated neighbourhoods
/// for the chosen persona by weighting the signals we already have (transport /
/// education / safety / overall) plus a small bonus for matching lifestyle
/// tags. This is a browse aid only — the authoritative, profile-weighted score
/// is computed by the backend when the user taps through to Analyze.
double _fitScore(_Neighborhood n, UserProfile p) {
  final t = n.transportScore.toDouble();
  final e = n.educationScore.toDouble();
  final s = n.safetyScore.toDouble();
  final o = n.score.toDouble();
  double base;
  double bonus = 0;
  switch (p) {
    case UserProfile.family:
      base = t * 0.20 + e * 0.40 + s * 0.30 + o * 0.10;
      if (n.tags.contains('Family')) bonus += 8;
    case UserProfile.student:
      base = t * 0.45 + e * 0.10 + s * 0.15 + o * 0.30;
      if (n.tags.contains('Culture')) bonus += 6;
      if (n.tags.contains('Transport')) bonus += 4;
    case UserProfile.professional:
      base = t * 0.40 + e * 0.10 + s * 0.20 + o * 0.30;
      if (n.tags.contains('Transport')) bonus += 5;
      if (n.tags.contains('Investment')) bonus += 3;
    case UserProfile.retired:
      base = t * 0.15 + e * 0.10 + s * 0.45 + o * 0.30;
      if (n.tags.contains('Nature')) bonus += 8;
    case UserProfile.investor:
      base = t * 0.25 + e * 0.10 + s * 0.15 + o * 0.50;
      if (n.tags.contains('Investment')) bonus += 10;
    case UserProfile.defaultProfile:
      base = o;
  }
  return base + bonus;
}

// ── Screen ─────────────────────────────────────────────────────────────────────

class ExplorerScreen extends ConsumerStatefulWidget {
  const ExplorerScreen({super.key});

  @override
  ConsumerState<ExplorerScreen> createState() => _ExplorerScreenState();
}

// The country the curated `_neighborhoods` (with rich stats) belong to. Other
// countries are still fully searchable via the country-scoped area search.
const _kCuratedCountry = 'PT';

class _ExplorerScreenState extends ConsumerState<ExplorerScreen> {
  UserProfile _profile = UserProfile.family;
  String? _cityFilter; // null = all cities
  String? _analyzingLabel;

  final _searchController = TextEditingController();
  final _searchFocus = FocusNode();
  String _query = '';
  Timer? _debounce;
  bool _searching = false;
  List<AreaSuggestion> _osmResults = const [];

  @override
  void initState() {
    super.initState();
    // Default to the user's saved persona; a neutral/general profile falls
    // back to Family so the fit ranking is meaningful on first open.
    final saved = ref.read(preferencesProvider).profile;
    if (saved != UserProfile.defaultProfile) _profile = saved;
    // Focusing the empty search box reveals trending suggestions.
    _searchFocus.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchFocus.removeListener(_onFocusChange);
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  // Whether the curated fit-ranked cards apply to the selected country.
  bool get _curatedActive =>
      (ref.read(selectedCountryProvider)?.code ?? 'PT') == _kCuratedCountry;

  // Distinct cities present in the curated set, for the area chips.
  List<String> get _cities {
    if (!_curatedActive) return const [];
    final seen = <String>[];
    for (final n in _neighborhoods) {
      if (!seen.contains(n.city)) seen.add(n.city);
    }
    return seen;
  }

  // Neighbourhoods for the chosen city, ranked best-fit-first for the persona.
  List<_Neighborhood> get _ranked {
    if (!_curatedActive) return const [];
    final list = _neighborhoods
        .where((n) => _cityFilter == null || n.city == _cityFilter)
        .toList()
      ..sort((a, b) => _fitScore(b, _profile).compareTo(_fitScore(a, _profile)));
    return list;
  }

  // ── Area search (tier 1 curated + tier 3 country-scoped OSM) ───────────────

  void _onQueryChanged(String value) {
    setState(() => _query = value);
    _debounce?.cancel();
    final q = value.trim();
    if (q.length < 2) {
      setState(() {
        _osmResults = const [];
        _searching = false;
      });
      return;
    }
    setState(() => _searching = true);
    _debounce = Timer(const Duration(milliseconds: 350), () => _runOsmSearch(q));
  }

  Future<void> _runOsmSearch(String q) async {
    final country = ref.read(selectedCountryProvider);
    try {
      final results = await ref.read(apiServiceProvider).searchAreas(
            query: q,
            country: country?.code ?? 'PT',
          );
      if (!mounted || q != _query.trim()) return;
      setState(() {
        _osmResults = results;
        _searching = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _searching = false);
    }
  }

  // Curated areas (instant, offline) whose name/city matches the query.
  List<AreaSuggestion> _curatedMatches(String q) {
    if (!_curatedActive) return const [];
    final n = q.trim().toLowerCase();
    if (n.isEmpty) return const [];
    return _neighborhoods
        .where((x) =>
            x.name.toLowerCase().contains(n) || x.city.toLowerCase().contains(n))
        .map((x) => AreaSuggestion(
              name: x.name,
              region: x.city,
              lat: 0,
              lng: 0,
              type: 'curated',
            ))
        .toList();
  }

  // Merge curated + OSM, curated first, deduped by name+region.
  List<AreaSuggestion> get _searchResults {
    final out = <AreaSuggestion>[];
    final seen = <String>{};
    for (final s in [..._curatedMatches(_query), ..._osmResults]) {
      final key = '${s.name.toLowerCase()}|${s.region.toLowerCase()}';
      if (seen.add(key)) out.add(s);
    }
    return out;
  }

  void _clearSearch() {
    _debounce?.cancel();
    _searchController.clear();
    _searchFocus.unfocus();
    setState(() {
      _query = '';
      _osmResults = const [];
      _searching = false;
    });
  }

  Future<void> _openCountryPicker() async {
    _searchFocus.unfocus();
    final countries = await ref.read(countriesProvider.future);
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppPalette.of(context).surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final p = AppPalette.of(ctx);
        final selected = ref.read(selectedCountryProvider)?.code;
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: p.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 8),
              for (final c in countries)
                ListTile(
                  leading: Text(_flag(c.code),
                      style: const TextStyle(fontSize: 22)),
                  title: Text(c.name,
                      style: TextStyle(
                          color: p.textPrimary, fontWeight: FontWeight.w600)),
                  trailing: c.code == selected
                      ? const Icon(Icons.check_circle_rounded,
                          color: AppColors.accent)
                      : null,
                  onTap: () {
                    ref.read(selectedCountryProvider.notifier).select(c);
                    Navigator.of(ctx).pop();
                    _clearSearch();
                    setState(() => _cityFilter = null);
                  },
                ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  // Run a real analysis for the tapped neighbourhood, then jump to results.
  Future<void> _analyze(_Neighborhood n) => _analyzeArea(n.name, n.city);

  // Analyse an arbitrary area (curated card or search result) and jump to
  // results — the same geocode→score→AI flow the rest of the app uses.
  Future<void> _analyzeArea(String name, String region) async {
    _searchFocus.unfocus();
    final country = ref.read(selectedCountryProvider);
    final countryName = country?.name ?? 'Portugal';
    final profile = ref.read(preferencesProvider).profile.jsonValue;
    final label = region.isEmpty || region == name ? name : '$name, $region';
    setState(() => _analyzingLabel = label);
    await ref.read(analysisProvider.notifier).analyze(
          '$label, $countryName',
          countryCode: country?.code ?? 'PT',
          profile: profile,
        );
    if (!mounted) return;
    if (ref.read(analysisProvider).status == AnalysisStatus.done) {
      ref.read(shellTabProvider.notifier).state = 1;
    }
  }

  // Shared pill styling for the persona + city selectors.
  Widget _selectorChip({
    required String label,
    required bool active,
    required VoidCallback onTap,
    bool small = false,
  }) {
    final p = AppPalette.of(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: EdgeInsets.symmetric(horizontal: small ? 14 : 16),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active ? AppColors.accent.withValues(alpha: 0.12) : p.surface2,
          borderRadius: BorderRadius.circular(22),
          border: active
              ? Border.all(color: AppColors.accent.withValues(alpha: 0.70), width: 1.5)
              : Border.all(color: p.border, width: 1),
          gradient: active
              ? LinearGradient(colors: [
                  AppColors.accent.withValues(alpha: 0.10),
                  const Color(0xFF7C3AED).withValues(alpha: 0.10),
                ])
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? AppColors.accent : p.textTertiary,
            fontSize: small ? 12 : 12.5,
            fontWeight: active ? FontWeight.w700 : FontWeight.w500,
            letterSpacing: 0.1,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final country = ref.watch(selectedCountryProvider);
    final countryName = country?.name ?? 'Portugal';
    final top = MediaQuery.of(context).padding.top;
    final ranked = _ranked;
    final p = AppPalette.of(context);
    final l = AppLocalizations.of(context);

    // While an analysis (started here) runs, show the shared progress view.
    final analysis = ref.watch(analysisProvider);
    if (analysis.isLoading) {
      return AnalyzingProgressView(
        address: _analyzingLabel ?? '',
        status: analysis.status,
        progress: analysis.progress,
      );
    }

    final searching = _query.trim().isNotEmpty;
    // Focused + empty box → trending suggestions (reuses Phase-2 /popular).
    final showSuggestions = _searchFocus.hasFocus && !searching;

    return Container(
      color: p.bg,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        slivers: [
          SliverPadding(
            padding: EdgeInsets.only(top: top + 14),
            sliver: const SliverToBoxAdapter(child: SizedBox.shrink()),
          ),

          // ── Header: title + subtitle, with the country picker pill ─────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 0, 22, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          l.explorerTitle,
                          style: TextStyle(
                            color: p.textPrimary,
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.6,
                            height: 1,
                          ),
                        ),
                      ),
                      _CountryPill(
                        flag: _flag(country?.code ?? 'PT'),
                        name: countryName,
                        onTap: _openCountryPicker,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l.explorerSubtitle,
                    style: TextStyle(
                      color: p.textTertiary,
                      fontSize: 14.5,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 26)),

          // ── Step 1: profile ────────────────────────────────────────────────
          SliverToBoxAdapter(child: _stepHeading(p, l.explorerStepProfile)),
          const SliverToBoxAdapter(child: SizedBox(height: 14)),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 148,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 22),
                physics: const BouncingScrollPhysics(),
                itemCount: _explorerProfiles.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, i) {
                  final profile = _explorerProfiles[i];
                  return _ProfileCard(
                    emoji: profile.emoji,
                    title: _profileLabel(l, profile),
                    desc: _profileDesc(l, profile),
                    selected: profile == _profile,
                    onTap: () => setState(() => _profile = profile),
                  );
                },
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 26)),

          // ── Step 2: area ───────────────────────────────────────────────────
          SliverToBoxAdapter(child: _stepHeading(p, l.explorerStepArea)),
          const SliverToBoxAdapter(child: SizedBox(height: 12)),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              child: _searchField(p, l, countryName),
            ),
          ),

          if (searching) ...[
            // Live area search results (curated + country-scoped OSM).
            const SliverToBoxAdapter(child: SizedBox(height: 6)),
            _buildSearchResults(p, l, countryName),
          ] else if (showSuggestions) ...[
            // Trending suggestions for the country's headline region.
            const SliverToBoxAdapter(child: SizedBox(height: 8)),
            _buildTrendingSuggestions(p, l, country?.defaultCity ?? 'Lisboa',
                country?.code ?? 'PT'),
          ] else ...[
            // Default: city chips + fit-ranked featured cards (or a prompt for
            // countries we don't curate yet).
            const SliverToBoxAdapter(child: SizedBox(height: 12)),
            if (_cities.isNotEmpty)
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 36,
                  child: Builder(builder: (context) {
                    final items = <String?>[null, ..._cities];
                    return ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 22),
                      physics: const BouncingScrollPhysics(),
                      itemCount: items.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, i) {
                        final city = items[i];
                        return _selectorChip(
                          label: city ?? l.explorerCityAll,
                          active: city == _cityFilter,
                          small: true,
                          onTap: () => setState(() => _cityFilter = city),
                        );
                      },
                    );
                  }),
                ),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 22)),
            if (ranked.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(22, 0, 22, 12),
                  child: Text(
                    l.explorerBestFor(_profileLabel(l, _profile)).toUpperCase(),
                    style: TextStyle(
                      color: p.textTertiary,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.6,
                    ),
                  ),
                ),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    if (index >= ranked.length) return null;
                    return _NeighborhoodCard(
                      neighborhood: ranked[index],
                      isTopMatch: index == 0,
                      onAnalyze: () => _analyze(ranked[index]),
                    );
                  },
                  childCount: ranked.length,
                ),
              ),
            ] else
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(22, 28, 22, 0),
                  child: Text(
                    l.explorerSearchPrompt(countryName),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: p.textTertiary, fontSize: 13.5, height: 1.5),
                  ),
                ),
              ),
          ],

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  Widget _stepHeading(AppPalette p, String text) => Padding(
        padding: const EdgeInsets.fromLTRB(22, 0, 22, 0),
        child: Text(
          text,
          style: TextStyle(
            color: p.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
        ),
      );

  Widget _searchField(AppPalette p, AppLocalizations l, String countryName) {
    return Container(
      decoration: BoxDecoration(
        color: p.surface2,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: p.border),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        children: [
          Icon(Icons.search_rounded, size: 20, color: p.textTertiary),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocus,
              onChanged: _onQueryChanged,
              textInputAction: TextInputAction.search,
              style: TextStyle(color: p.textPrimary, fontSize: 15),
              decoration: InputDecoration(
                isCollapsed: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 16),
                border: InputBorder.none,
                hintText: l.explorerSearchHint(countryName),
                hintStyle: TextStyle(color: p.textTertiary, fontSize: 15),
              ),
            ),
          ),
          if (_searching)
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else if (_query.isNotEmpty)
            GestureDetector(
              onTap: _clearSearch,
              child: Icon(Icons.close_rounded, size: 18, color: p.textTertiary),
            ),
        ],
      ),
    );
  }

  Widget _buildSearchResults(AppPalette p, AppLocalizations l, String countryName) {
    final results = _searchResults;
    if (results.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 24, 22, 0),
          child: Text(
            _searching ? '…' : l.explorerNoAreas(countryName),
            textAlign: TextAlign.center,
            style: TextStyle(color: p.textTertiary, fontSize: 13.5),
          ),
        ),
      );
    }
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          if (index >= results.length) return null;
          final r = results[index];
          final curated = r.type == 'curated';
          return _areaTile(
            p,
            icon: curated ? Icons.star_rounded : Icons.place_rounded,
            iconColor: curated ? AppColors.accent : p.textTertiary,
            name: r.name,
            region: r.region,
            onTap: () => _analyzeArea(r.name, r.region),
          );
        },
        childCount: results.length,
      ),
    );
  }

  // Trending suggestions shown when the search box is focused but empty —
  // reuses the Phase-2 popularity data for the country's headline region.
  Widget _buildTrendingSuggestions(
      AppPalette p, AppLocalizations l, String region, String countryCode) {
    final resolved = ref
        .watch(popularAreasProvider(
          (country: countryCode, region: region, defaultCity: region),
        ))
        .asData
        ?.value;
    final areas = (resolved?.areas ?? popularAreasForRegion(region)).take(6).toList();
    final label = resolved?.region ?? region;
    if (areas.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());

    return SliverList(
      delegate: SliverChildListDelegate([
        Padding(
          padding: const EdgeInsets.fromLTRB(22, 10, 22, 8),
          child: Text(
            l.explorerTrendingIn(label).toUpperCase(),
            style: TextStyle(
              color: p.textTertiary,
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.4,
            ),
          ),
        ),
        for (final a in areas)
          _areaTile(
            p,
            icon: Icons.place_rounded,
            iconColor: p.textTertiary,
            name: a.name,
            region: a.region,
            onTap: () => _analyzeArea(a.name, a.region),
          ),
      ]),
    );
  }

  Widget _areaTile(
    AppPalette p, {
    required IconData icon,
    required Color iconColor,
    required String name,
    required String region,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, size: 20, color: iconColor),
      title: Text(name,
          style: TextStyle(color: p.textPrimary, fontWeight: FontWeight.w600)),
      subtitle: region.isEmpty || region == name
          ? null
          : Text(region, style: TextStyle(color: p.textTertiary, fontSize: 12)),
      trailing:
          Icon(Icons.chevron_right_rounded, size: 20, color: p.textTertiary),
    );
  }
}

// ── Country picker pill ────────────────────────────────────────────────────────

class _CountryPill extends StatelessWidget {
  final String flag;
  final String name;
  final VoidCallback onTap;

  const _CountryPill(
      {required this.flag, required this.name, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: p.surface2,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: p.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(flag, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 6),
            Text(
              name,
              style: TextStyle(
                color: p.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            Icon(Icons.keyboard_arrow_down_rounded,
                size: 18, color: p.textTertiary),
          ],
        ),
      ),
    );
  }
}

// ── Profile card ───────────────────────────────────────────────────────────────

class _ProfileCard extends StatelessWidget {
  final String emoji;
  final String title;
  final String desc;
  final bool selected;
  final VoidCallback onTap;

  const _ProfileCard({
    required this.emoji,
    required this.title,
    required this.desc,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 150,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.accent.withValues(alpha: 0.10)
              : p.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected
                ? AppColors.accent.withValues(alpha: 0.70)
                : p.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(emoji, style: const TextStyle(fontSize: 26)),
                const Spacer(),
                Text(
                  title,
                  style: TextStyle(
                    color: p.textPrimary,
                    fontSize: 15.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  desc,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: p.textTertiary,
                    fontSize: 12,
                    height: 1.3,
                  ),
                ),
              ],
            ),
            if (selected)
              const Align(
                alignment: Alignment.topRight,
                child: Icon(Icons.check_circle_rounded,
                    size: 20, color: AppColors.accent),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Neighborhood card ──────────────────────────────────────────────────────────

class _NeighborhoodCard extends StatelessWidget {
  final _Neighborhood neighborhood;
  final bool isTopMatch;
  final VoidCallback onAnalyze;

  const _NeighborhoodCard({
    required this.neighborhood,
    required this.onAnalyze,
    this.isTopMatch = false,
  });

  Color _tagColor(String tag) {
    switch (tag) {
      case 'Transport':
        return _kTagTransport;
      case 'Family':
        return _kTagFamily;
      case 'Investment':
        return _kTagInvestment;
      case 'Nature':
        return _kTagNature;
      case 'Culture':
        return _kTagCulture;
      default:
        return AppColors.accent;
    }
  }

  @override
  Widget build(BuildContext context) {
    final n = neighborhood;
    final ring = scoreColor(n.score.toDouble());
    final p = AppPalette.of(context);
    final l = AppLocalizations.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isTopMatch
              ? AppColors.accent.withValues(alpha: 0.55)
              : p.border,
          width: isTopMatch ? 1.5 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Top row: score ring + name/city + highlight badge ────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Score ring
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: ring, width: 2.5),
                    color: ring.withValues(alpha: 0.10),
                  ),
                  child: Center(
                    // Same /10 scale as the main score (score_format.dart).
                    child: Text(
                      scoreTenth(n.score.toDouble()),
                      style: TextStyle(
                        color: ring,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Name + city
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 2),
                      Text(
                        n.name,
                        style: TextStyle(
                          color: p.textPrimary,
                          fontSize: 15.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.3,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        n.city,
                        style: TextStyle(
                          color: p.textTertiary,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                // Badge: "Best match" for the #1 ranked card, else the
                // neighbourhood's editorial highlight.
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.accent
                        .withValues(alpha: isTopMatch ? 0.16 : 0.10),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: AppColors.accent
                            .withValues(alpha: isTopMatch ? 0.45 : 0.28)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isTopMatch) ...[
                        const Icon(Icons.star_rounded,
                            size: 11, color: AppColors.accent),
                        const SizedBox(width: 3),
                      ],
                      Text(
                        isTopMatch ? l.explorerBestMatch : _nbHighlight(l, n.id),
                        style: TextStyle(
                          color: AppColors.accent.withValues(alpha: 0.90),
                          fontSize: 10,
                          fontWeight:
                              isTopMatch ? FontWeight.w700 : FontWeight.w600,
                          letterSpacing: 0.1,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // ── Description ──────────────────────────────────────────────────
            Text(
              _nbDesc(l, n.id),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: p.textTertiary,
                fontSize: 13,
                height: 1.5,
              ),
            ),

            const SizedBox(height: 14),

            // ── Stat pills row ───────────────────────────────────────────────
            Row(
              children: [
                _StatPill(
                  icon: Icons.directions_transit_filled_rounded,
                  label: l.statTransit,
                  value: n.transportScore,
                  color: _kTagTransport,
                ),
                const SizedBox(width: 8),
                _StatPill(
                  icon: Icons.school_rounded,
                  label: l.statEducation,
                  value: n.educationScore,
                  color: _kTagFamily,
                ),
                const SizedBox(width: 8),
                _StatPill(
                  icon: Icons.shield_rounded,
                  label: l.statSafety,
                  value: n.safetyScore,
                  color: const Color(0xFF22C55E),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // ── Tags + Analyze button ────────────────────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Tags
                Expanded(
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: n.tags.map((tag) {
                      final color = _tagColor(tag);
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: color.withValues(alpha: 0.28)),
                        ),
                        child: Text(
                          _tagLabel(l, tag),
                          style: TextStyle(
                            color: color.withValues(alpha: 0.90),
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.1,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(width: 10),
                // Analyze button
                GestureDetector(
                  onTap: onAnalyze,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.accent, Color(0xFF2563EB)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.analytics_rounded,
                          color: Colors.white,
                          size: 13,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          l.commonAnalyze,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),
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

// ── Stat pill ──────────────────────────────────────────────────────────────────

class _StatPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final int value;
  final Color color;

  const _StatPill({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: p.surface2,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: p.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            scoreTenth(value.toDouble()),
            style: TextStyle(
              color: p.textPrimary,
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: p.textTertiary,
              fontSize: 10.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
