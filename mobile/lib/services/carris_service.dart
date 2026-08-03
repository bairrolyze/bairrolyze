import 'package:dio/dio.dart';

import '../models/carris_models.dart';

/// Carris Metropolitana public API — no auth required.
/// Covers the Lisbon Metropolitan Area (AML).
class CarrisService {
  static const _base = 'https://api.carrismetropolitana.pt';
  static const _matchRadiusM = 120.0; // max distance to consider an OSM↔Carris match

  static final _dio = Dio(BaseOptions(
    baseUrl: _base,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 20),
  ));

  // ── Session-level caches ───────────────────────────────────────────────────

  static List<CarrisStop>? _stops;
  static Map<String, CarrisLine>? _lines;
  // In-flight fetches, shared so the several widgets that load Carris data on
  // the same screen (radar, lines section, stop cards) don't each re-download
  // the large /stops (~7.7 MB) and /lines payloads and time each other out.
  static Future<List<CarrisStop>>? _stopsInFlight;
  static Future<Map<String, CarrisLine>>? _linesInFlight;

  static Future<List<CarrisStop>> _fetchStops() {
    if (_stops != null) return Future.value(_stops!);
    return _stopsInFlight ??= _dio.get<List<dynamic>>('/stops').then((resp) {
      _stops = (resp.data ?? [])
          .cast<Map<String, dynamic>>()
          .map(CarrisStop.fromJson)
          .where((s) => s.lat != 0 && s.lon != 0)
          .toList();
      return _stops!;
    }).whenComplete(() => _stopsInFlight = null);
  }

  static Future<Map<String, CarrisLine>> _fetchLines() {
    if (_lines != null) return Future.value(_lines!);
    return _linesInFlight ??= _dio.get<List<dynamic>>('/lines').then((resp) {
      _lines = {
        for (final j in (resp.data ?? []).cast<Map<String, dynamic>>())
          j['id'] as String: CarrisLine.fromJson(j)
      };
      return _lines!;
    }).whenComplete(() => _linesInFlight = null);
  }

  // ── Public API ─────────────────────────────────────────────────────────────

  /// Find the nearest Carris stop to [lat]/[lng] within [_matchRadiusM] metres.
  /// Returns null if no match or the Carris API is unreachable.
  static Future<CarrisStop?> nearestStop(double lat, double lng) async {
    try {
      final stops = await _fetchStops();
      CarrisStop? best;
      double bestDist = _matchRadiusM;
      for (final s in stops) {
        final d = s.distanceTo(lat, lng);
        if (d < bestDist) { bestDist = d; best = s; }
      }
      return best;
    } catch (_) {
      return null;
    }
  }

  /// All Carris stops within [radiusM] metres of [lat]/[lng], nearest first.
  static Future<List<CarrisStop>> stopsWithin(
      double lat, double lng, double radiusM) async {
    try {
      final stops = await _fetchStops();
      final within = <MapEntry<CarrisStop, double>>[];
      for (final s in stops) {
        final d = s.distanceTo(lat, lng);
        if (d <= radiusM) within.add(MapEntry(s, d));
      }
      within.sort((a, b) => a.value.compareTo(b.value));
      return within.map((e) => e.key).toList();
    } catch (_) {
      return [];
    }
  }

  /// Next arrivals for a Carris stop id.  Returns [] on any error.
  static Future<List<CarrisArrival>> realtimeArrivals(String stopId) async {
    try {
      final resp = await _dio.get<List<dynamic>>('/stops/$stopId/realtime');
      return (resp.data ?? [])
          .cast<Map<String, dynamic>>()
          .map(CarrisArrival.fromJson)
          .where((a) => (a.minutesUntil ?? -1) >= 0)
          .take(12)
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Full ordered stop sequence for a line's main pattern (the whole route),
  /// for the route timeline. Returns [] on any error / non-Lisbon lines.
  static Future<List<CarrisStop>> routeStops(String lineId) async {
    try {
      final lineResp = await _dio.get<Map<String, dynamic>>('/lines/$lineId');
      final patterns =
          (lineResp.data?['patterns'] as List?)?.cast<String>() ?? [];
      if (patterns.isEmpty) return [];
      final patResp =
          await _dio.get<Map<String, dynamic>>('/patterns/${patterns.first}');
      final path = (patResp.data?['path'] as List?) ?? [];
      final stops = <CarrisStop>[];
      for (final item in path) {
        if (item is Map<String, dynamic> &&
            item['stop'] is Map<String, dynamic>) {
          stops.add(CarrisStop.fromJson(item['stop'] as Map<String, dynamic>));
        }
      }
      return stops;
    } catch (_) {
      return [];
    }
  }

  /// Line metadata (color, long name) for a given line id.
  static Future<CarrisLine?> lineInfo(String lineId) async {
    try {
      final lines = await _fetchLines();
      return lines[lineId];
    } catch (_) {
      return null;
    }
  }

  /// Line metadata map for a set of line ids.
  static Future<Map<String, CarrisLine>> lineInfoMap(List<String> lineIds) async {
    try {
      final lines = await _fetchLines();
      return { for (final id in lineIds) if (lines[id] != null) id: lines[id]! };
    } catch (_) {
      return {};
    }
  }

  static void clearCache() {
    _stops = null;
    _lines = null;
  }
}
