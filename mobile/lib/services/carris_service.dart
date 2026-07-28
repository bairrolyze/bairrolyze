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

  static Future<List<CarrisStop>> _fetchStops() async {
    if (_stops != null) return _stops!;
    final resp = await _dio.get<List<dynamic>>('/stops');
    _stops = (resp.data ?? [])
        .cast<Map<String, dynamic>>()
        .map(CarrisStop.fromJson)
        .where((s) => s.lat != 0 && s.lon != 0)
        .toList();
    return _stops!;
  }

  static Future<Map<String, CarrisLine>> _fetchLines() async {
    if (_lines != null) return _lines!;
    final resp = await _dio.get<List<dynamic>>('/lines');
    _lines = {
      for (final j in (resp.data ?? []).cast<Map<String, dynamic>>())
        j['id'] as String: CarrisLine.fromJson(j)
    };
    return _lines!;
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

  /// Next arrivals for a Carris stop id.  Returns [] on any error.
  static Future<List<CarrisArrival>> realtimeArrivals(String stopId) async {
    try {
      final resp = await _dio.get<List<dynamic>>('/stops/$stopId/realtime');
      return (resp.data ?? [])
          .cast<Map<String, dynamic>>()
          .map(CarrisArrival.fromJson)
          .where((a) => (a.minutesUntil ?? -1) >= 0)
          .take(4)
          .toList();
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
