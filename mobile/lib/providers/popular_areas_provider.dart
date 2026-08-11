import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/popular_areas.dart';
import '../services/api_service.dart';

/// Inputs for [popularAreasProvider] — the active region plus the country's
/// default city (the cold-start fallback when neither curated data nor live
/// trending exists for the region).
typedef PopularAreasArgs = ({String country, String region, String defaultCity});

/// The region label + areas to show, after blending curated data with live
/// "most searched" trending from the backend.
typedef PopularAreasResult = ({String region, List<PopularArea> areas});

/// Region-aware popular areas: curated data reordered/augmented by real
/// aggregated search counts (`GET /api/v1/popular`). Degrades gracefully — a
/// backend error or empty response just yields the curated list, and an
/// uncurated region with no data yet falls back to the default city.
final popularAreasProvider = FutureProvider.autoDispose
    .family<PopularAreasResult, PopularAreasArgs>((ref, args) async {
  final curated = popularAreasForRegion(args.region);

  List<PopularAreaStat> stats = const [];
  try {
    stats = await ref
        .read(apiServiceProvider)
        .fetchPopularAreas(country: args.country, region: args.region);
  } catch (_) {
    // Trending is a non-critical enhancement — fall through to curated.
  }

  var merged = mergePopularAreas(
    args.region,
    curated,
    [for (final s in stats) (name: s.name, count: s.count)],
  );

  // Uncurated region that no one has searched yet → show the default city so
  // the discovery rail is never empty.
  var region = args.region;
  if (merged.isEmpty) {
    merged = popularAreasForRegion(args.defaultCity);
  }
  if (merged.isNotEmpty) region = merged.first.region;

  return (region: region, areas: merged);
});
