// Curated "popular areas" per region.
//
// Phase 1 of the region-aware Popular Searches feature: instead of a flat list
// of city chips, we show the well-known neighbourhoods/areas *within* the
// region the user is currently looking at (their last search, or the country's
// default city). Tapping an area runs a real analysis and jumps to the summary,
// exactly like the Explorer cards.
//
// This is a curated, static fallback. Phase 2 will replace it (or blend it)
// with real aggregated "most searched" data once search logging exists on the
// backend — the widget layer will not need to change, only the resolver below.

/// A single popular area within a region (a neighbourhood, parish or town).
///
/// [name] and [region] are proper nouns and stay un-localized; [tags] use the
/// same English keys as the Explorer filters so their labels/colours are shared
/// (`Transport`, `Family`, `Investment`, `Nature`, `Culture`).
///
/// [score] is 0 for areas that come purely from live backend trending data
/// (no curated metadata) — the card renders those without a score ring.
/// [isTrending] marks areas surfaced by real aggregated search data (Phase 2).
class PopularArea {
  final String name;
  final String region;
  final int score;
  final List<String> tags;
  final bool isTrending;

  /// Aggregated search count backing [isTrending] (0 for curated-only areas).
  /// The card only surfaces the number once it clears a meaningful threshold,
  /// so sparse early data reads as a plain "Trending" label rather than "1".
  final int searchCount;

  const PopularArea(
    this.name,
    this.region,
    this.score,
    this.tags, {
    this.isTrending = false,
    this.searchCount = 0,
  });

  PopularArea copyWith({bool? isTrending, int? searchCount}) => PopularArea(
        name,
        region,
        score,
        tags,
        isTrending: isTrending ?? this.isTrending,
        searchCount: searchCount ?? this.searchCount,
      );
}

String _normName(String s) => s.trim().toLowerCase();

/// Blends curated areas with live "most searched" data from the backend.
///
/// [stats] are `(name, count)` pairs, already ordered most-popular-first. The
/// result puts genuinely-trending areas up top (curated ones keep their rich
/// score/tags; unknown ones become lightweight trending cards), then appends
/// the remaining curated areas so the list is never bare. Falls back to plain
/// curated order when [stats] is empty.
List<PopularArea> mergePopularAreas(
  String region,
  List<PopularArea> curated,
  List<({String name, int count})> stats,
) {
  if (stats.isEmpty) return curated;

  final byName = {for (final a in curated) _normName(a.name): a};
  final result = <PopularArea>[];
  final used = <String>{};

  for (final s in stats) {
    final key = _normName(s.name);
    if (key.isEmpty || used.contains(key)) continue;
    final match = byName[key];
    if (match != null) {
      result.add(match.copyWith(isTrending: true, searchCount: s.count));
    } else {
      // Backend-only trending area: no curated score/tags.
      result.add(PopularArea(s.name, region, 0, const [],
          isTrending: true, searchCount: s.count));
    }
    used.add(key);
  }

  for (final a in curated) {
    if (used.add(_normName(a.name))) result.add(a);
  }
  return result;
}

// Keyed by a normalised region name (see [_norm]); the canonical display label
// comes from each area's [region] field so casing/accents stay correct.
const _kAreasByRegion = <String, List<PopularArea>>{
  // ── Portugal ──────────────────────────────────────────────────────────────
  'lisboa': [
    PopularArea('Parque das Nações', 'Lisboa', 87, ['Transport', 'Family', 'Investment']),
    PopularArea('Chiado', 'Lisboa', 84, ['Culture', 'Transport']),
    PopularArea('Príncipe Real', 'Lisboa', 83, ['Culture', 'Nature']),
    PopularArea('Alfama', 'Lisboa', 82, ['Culture', 'Transport']),
    PopularArea('Belém', 'Lisboa', 81, ['Culture', 'Nature', 'Family']),
    PopularArea('Baixa', 'Lisboa', 80, ['Transport', 'Culture']),
    PopularArea('Estrela', 'Lisboa', 80, ['Family', 'Nature']),
    PopularArea('Alvalade', 'Lisboa', 79, ['Family', 'Transport']),
  ],
  'porto': [
    PopularArea('Foz do Douro', 'Porto', 84, ['Nature', 'Family', 'Investment']),
    PopularArea('Cedofeita', 'Porto', 84, ['Culture', 'Transport']),
    PopularArea('Ribeira', 'Porto', 81, ['Culture', 'Transport']),
    PopularArea('Boavista', 'Porto', 81, ['Investment', 'Transport']),
    PopularArea('Bonfim', 'Porto', 77, ['Investment', 'Culture']),
  ],
  'cascais': [
    PopularArea('Cascais Centro', 'Cascais', 85, ['Nature', 'Family']),
    PopularArea('Estoril', 'Cascais', 83, ['Nature', 'Investment']),
    PopularArea('Carcavelos', 'Cascais', 80, ['Nature', 'Family', 'Transport']),
  ],
  'braga': [
    PopularArea('Braga Centro', 'Braga', 76, ['Family', 'Culture', 'Investment']),
    PopularArea('São Vítor', 'Braga', 74, ['Family', 'Transport']),
  ],
  'sintra': [
    PopularArea('Sintra Vila', 'Sintra', 79, ['Nature', 'Culture']),
    PopularArea('Algueirão', 'Sintra', 72, ['Family', 'Transport']),
  ],

  // ── Spain ─────────────────────────────────────────────────────────────────
  'madrid': [
    PopularArea('Salamanca', 'Madrid', 85, ['Investment', 'Culture']),
    PopularArea('Retiro', 'Madrid', 84, ['Nature', 'Family']),
    PopularArea('Chamberí', 'Madrid', 83, ['Family', 'Culture']),
    PopularArea('Chamartín', 'Madrid', 81, ['Family', 'Transport']),
    PopularArea('Malasaña', 'Madrid', 80, ['Culture', 'Transport']),
  ],
  'barcelona': [
    PopularArea('Eixample', 'Barcelona', 84, ['Transport', 'Culture']),
    PopularArea('Sarrià', 'Barcelona', 83, ['Family', 'Nature']),
    PopularArea('Gràcia', 'Barcelona', 82, ['Culture', 'Family']),
    PopularArea('Ciutat Vella', 'Barcelona', 79, ['Culture', 'Transport']),
  ],

  // ── United Kingdom ──────────────────────────────────────────────────────────
  'london': [
    PopularArea('Kensington', 'London', 86, ['Investment', 'Culture']),
    PopularArea('Richmond', 'London', 84, ['Nature', 'Family']),
    PopularArea('Islington', 'London', 82, ['Culture', 'Transport']),
    PopularArea('Greenwich', 'London', 81, ['Nature', 'Family']),
    PopularArea('Shoreditch', 'London', 80, ['Culture', 'Transport']),
    PopularArea('Camden', 'London', 79, ['Culture', 'Transport']),
  ],
  'manchester': [
    PopularArea('Didsbury', 'Manchester', 81, ['Family', 'Nature']),
    PopularArea('City Centre', 'Manchester', 79, ['Transport', 'Culture']),
    PopularArea('Chorlton', 'Manchester', 78, ['Family', 'Culture']),
  ],

  // ── France ────────────────────────────────────────────────────────────────
  'paris': [
    PopularArea('Saint-Germain-des-Prés', 'Paris', 85, ['Culture', 'Investment']),
    PopularArea('Le Marais', 'Paris', 84, ['Culture', 'Transport']),
    PopularArea('Batignolles', 'Paris', 81, ['Family', 'Nature']),
    PopularArea('Montmartre', 'Paris', 80, ['Culture', 'Nature']),
    PopularArea('Bastille', 'Paris', 79, ['Culture', 'Transport']),
  ],
  'lyon': [
    PopularArea('Presqu\'île', 'Lyon', 82, ['Culture', 'Transport']),
    PopularArea('Croix-Rousse', 'Lyon', 80, ['Culture', 'Family']),
  ],

  // ── Germany ───────────────────────────────────────────────────────────────
  'berlin': [
    PopularArea('Prenzlauer Berg', 'Berlin', 84, ['Family', 'Culture']),
    PopularArea('Mitte', 'Berlin', 83, ['Culture', 'Transport']),
    PopularArea('Charlottenburg', 'Berlin', 82, ['Family', 'Investment']),
    PopularArea('Kreuzberg', 'Berlin', 80, ['Culture', 'Transport']),
    PopularArea('Friedrichshain', 'Berlin', 79, ['Culture', 'Transport']),
  ],
  'munich': [
    PopularArea('Schwabing', 'Munich', 84, ['Family', 'Culture']),
    PopularArea('Maxvorstadt', 'Munich', 82, ['Culture', 'Transport']),
  ],
};

String _norm(String s) => s.trim().toLowerCase();

/// The curated popular areas for [region], or an empty list if we have none.
List<PopularArea> popularAreasForRegion(String region) =>
    _kAreasByRegion[_norm(region)] ?? const [];

/// Resolves the region to show and its popular areas.
///
/// Prefers the user's [lastSearchCity]; if we have no curated data for it (or
/// it is blank), falls back to the country's [defaultCity]. Returns the
/// canonical region label (matching the areas) alongside the list so headers
/// read correctly even when the input casing differs.
({String region, List<PopularArea> areas}) resolvePopularAreas({
  String? lastSearchCity,
  required String defaultCity,
}) {
  if (lastSearchCity != null && lastSearchCity.trim().isNotEmpty) {
    final areas = popularAreasForRegion(lastSearchCity);
    if (areas.isNotEmpty) {
      return (region: areas.first.region, areas: areas);
    }
  }
  final fallback = popularAreasForRegion(defaultCity);
  final label = fallback.isNotEmpty ? fallback.first.region : defaultCity;
  return (region: label, areas: fallback);
}
