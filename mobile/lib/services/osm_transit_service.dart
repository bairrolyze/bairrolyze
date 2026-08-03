import 'package:dio/dio.dart';

import '../config/app_constants.dart';

/// One public-transport line derived from an OSM `type=route` relation.
/// Gives the line number, its two termini (start/end), travel mode and the
/// official line colour — data that stop `route_ref` tags don't carry. Works
/// globally (Lisbon city, Porto, UK, …), unlike the Lisbon-only Carris API.
class OsmRouteLine {
  final String mode; // bus, tram, subway, train, light_rail, ferry, trolleybus
  final String ref;  // "736", "24E", "Azul"
  final String from;
  final String to;
  final String colour; // raw OSM colour tag, e.g. "#4E84C4"
  final String name;

  const OsmRouteLine({
    required this.mode,
    required this.ref,
    required this.from,
    required this.to,
    required this.colour,
    required this.name,
  });

  /// Line colour as an ARGB int; falls back to a per-mode colour if the OSM
  /// `colour` tag is missing or unparseable.
  int get colorInt {
    var h = colour.trim();
    if (h.startsWith('#')) h = h.substring(1);
    if (h.length == 3) {
      h = h.split('').map((c) => '$c$c').join();
    }
    if (h.length == 6) {
      final v = int.tryParse(h, radix: 16);
      if (v != null) return 0xFF000000 | v;
    }
    return _modeColor;
  }

  /// Black or white for text on the line-colour chip, by perceived luminance.
  int get textColorInt {
    final c = colorInt;
    final r = (c >> 16) & 0xFF, g = (c >> 8) & 0xFF, b = c & 0xFF;
    final lum = (0.299 * r + 0.587 * g + 0.114 * b) / 255;
    return lum > 0.6 ? 0xFF111111 : 0xFFFFFFFF;
  }

  int get _modeColor {
    switch (mode) {
      case 'subway':
        return 0xFF8B5CF6;
      case 'train':
        return 0xFF22C55E;
      case 'tram':
      case 'light_rail':
        return 0xFFEC4899;
      case 'ferry':
        return 0xFF14B8A6;
      default:
        return 0xFF3B82F6; // bus / other
    }
  }

  /// Human mode label ("Bus", "Metro", "Train", "Tram"…).
  String get modeLabel {
    switch (mode) {
      case 'subway':
        return 'Metro';
      case 'train':
        return 'Train';
      case 'tram':
        return 'Tram';
      case 'light_rail':
        return 'Light rail';
      case 'ferry':
        return 'Ferry';
      case 'trolleybus':
        return 'Trolleybus';
      default:
        return 'Bus';
    }
  }

  /// "A ↔ B" using the two termini; falls back to the relation name.
  String get terminiText {
    if (from.isNotEmpty && to.isNotEmpty) return '$from ↔ $to';
    if (to.isNotEmpty) return to;
    if (from.isNotEmpty) return from;
    return name;
  }

  /// Sort priority: rail modes first, then buses.
  int get _modeRank {
    const order = {
      'subway': 0,
      'light_rail': 1,
      'train': 2,
      'tram': 3,
      'ferry': 4,
      'trolleybus': 5,
      'bus': 6,
    };
    return order[mode] ?? 7;
  }
}

/// Fetches public-transport lines around a point from the OSM Overpass API.
class OsmTransitService {
  static final _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 30),
  ));

  // Session cache keyed by rounded coords + radius so the radar summary and the
  // lines section share a single Overpass call.
  static final Map<String, List<OsmRouteLine>> _cache = {};
  static final Map<String, Future<List<OsmRouteLine>>> _inFlight = {};

  static String _key(double lat, double lng, double r) =>
      '${lat.toStringAsFixed(3)},${lng.toStringAsFixed(3)},${r.toInt()}';

  /// Transit lines whose route passes within [radiusM] of [lat]/[lng], deduped
  /// by (mode, ref) with both directions merged. Rail modes sorted first, then
  /// buses by number. Returns [] on any error.
  static Future<List<OsmRouteLine>> linesAround(
      double lat, double lng, double radiusM) {
    final key = _key(lat, lng, radiusM);
    final cached = _cache[key];
    if (cached != null) return Future.value(cached);
    return _inFlight[key] ??= _fetch(lat, lng, radiusM).then((lines) {
      _cache[key] = lines;
      return lines;
    }).whenComplete(() => _inFlight.remove(key));
  }

  static Future<List<OsmRouteLine>> _fetch(
      double lat, double lng, double radiusM) async {
    try {
      final query = '[out:json][timeout:25];'
          'relation(around:${radiusM.toInt()},$lat,$lng)'
          '[type=route]'
          '[route~"^(bus|tram|subway|train|light_rail|trolleybus|ferry)\$"];'
          'out tags;';
      final resp = await _dio.post<Map<String, dynamic>>(
        AppConstants.overpassApiUrl,
        data: {'data': query},
        options: Options(contentType: Headers.formUrlEncodedContentType),
      );
      final elements = (resp.data?['elements'] as List?) ?? [];

      // Merge both directions of a line into one entry keyed by (mode, ref).
      final byKey = <String, OsmRouteLine>{};
      for (final e in elements) {
        final t = (e as Map)['tags'];
        if (t is! Map) continue;
        final mode = t['route']?.toString() ?? '';
        final ref = t['ref']?.toString().trim() ?? '';
        if (mode.isEmpty || ref.isEmpty) continue;
        final key = '$mode|$ref';
        final line = OsmRouteLine(
          mode: mode,
          ref: ref,
          from: t['from']?.toString().trim() ?? '',
          to: t['to']?.toString().trim() ?? '',
          colour: t['colour']?.toString() ?? t['color']?.toString() ?? '',
          name: t['name']?.toString() ?? '',
        );
        // Keep the first one seen, but fill in from/to/colour if a later
        // direction has data the first was missing.
        final existing = byKey[key];
        if (existing == null) {
          byKey[key] = line;
        } else {
          byKey[key] = OsmRouteLine(
            mode: existing.mode,
            ref: existing.ref,
            from: existing.from.isNotEmpty ? existing.from : line.from,
            to: existing.to.isNotEmpty ? existing.to : line.to,
            colour: existing.colour.isNotEmpty ? existing.colour : line.colour,
            name: existing.name.isNotEmpty ? existing.name : line.name,
          );
        }
      }

      final lines = byKey.values.toList()
        ..sort((a, b) {
          if (a._modeRank != b._modeRank) return a._modeRank.compareTo(b._modeRank);
          final na = int.tryParse(a.ref), nb = int.tryParse(b.ref);
          if (na != null && nb != null) return na.compareTo(nb);
          if (na != null) return -1;
          if (nb != null) return 1;
          return a.ref.compareTo(b.ref);
        });
      return lines;
    } catch (_) {
      return [];
    }
  }

  /// Distinct line counts per mode label ("Bus", "Metro", …), for a summary.
  static Map<String, int> countByMode(List<OsmRouteLine> lines) {
    final counts = <String, int>{};
    for (final l in lines) {
      counts[l.modeLabel] = (counts[l.modeLabel] ?? 0) + 1;
    }
    return counts;
  }
}
