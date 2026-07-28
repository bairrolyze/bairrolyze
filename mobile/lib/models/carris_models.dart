import 'dart:math';

class CarrisStop {
  final String id;
  final String name;
  final double lat;
  final double lon;
  final List<String> lines;
  final String? wheelchairBoarding;
  final List<String> facilities;

  const CarrisStop({
    required this.id,
    required this.name,
    required this.lat,
    required this.lon,
    required this.lines,
    this.wheelchairBoarding,
    this.facilities = const [],
  });

  factory CarrisStop.fromJson(Map<String, dynamic> j) => CarrisStop(
        id: j['id'] as String,
        name: j['name'] as String? ?? j['short_name'] as String? ?? '',
        lat: double.tryParse(j['lat']?.toString() ?? '') ?? 0,
        lon: double.tryParse(j['lon']?.toString() ?? '') ?? 0,
        lines: List<String>.from(j['lines'] as List? ?? []),
        wheelchairBoarding: j['wheelchair_boarding']?.toString(),
        facilities: List<String>.from(j['facilities'] as List? ?? []),
      );

  // Haversine distance in metres to another lat/lng
  double distanceTo(double toLat, double toLon) {
    const r = 6371000.0;
    final dLat = (toLat - lat) * pi / 180;
    final dLon = (toLon - lon) * pi / 180;
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat * pi / 180) * cos(toLat * pi / 180) * sin(dLon / 2) * sin(dLon / 2);
    return r * 2 * atan2(sqrt(a), sqrt(1 - a));
  }

  bool get isWheelchairAccessible => wheelchairBoarding == '1' || wheelchairBoarding == '2';
}

class CarrisLine {
  final String id;
  final String shortName;
  final String longName;
  final String color;
  final String textColor;

  const CarrisLine({
    required this.id,
    required this.shortName,
    required this.longName,
    required this.color,
    required this.textColor,
  });

  factory CarrisLine.fromJson(Map<String, dynamic> j) => CarrisLine(
        id: j['id'] as String,
        shortName: j['short_name'] as String? ?? j['id'] as String,
        longName: j['long_name'] as String? ?? '',
        color: j['color'] as String? ?? '#3D85C6',
        textColor: j['text_color'] as String? ?? '#FFFFFF',
      );

  // Parse hex color like "#3D85C6" to Flutter Color
  static int _hexToInt(String hex) {
    final h = hex.replaceAll('#', '').padLeft(6, '0');
    return int.parse('FF$h', radix: 16);
  }

  int get colorInt => _hexToInt(color);
  int get textColorInt => _hexToInt(textColor);
}

class CarrisArrival {
  final String lineId;
  final String headsign;
  final DateTime? estimatedArrival;
  final DateTime? scheduledArrival;

  const CarrisArrival({
    required this.lineId,
    required this.headsign,
    this.estimatedArrival,
    this.scheduledArrival,
  });

  factory CarrisArrival.fromJson(Map<String, dynamic> j) {
    DateTime? parseUnix(dynamic v) {
      if (v == null) return null;
      final ms = (v as num).toInt();
      return DateTime.fromMillisecondsSinceEpoch(ms * 1000);
    }

    return CarrisArrival(
      lineId: j['line_id']?.toString() ?? '',
      headsign: j['headsign']?.toString() ?? '',
      estimatedArrival: parseUnix(j['estimated_arrival_unix']),
      scheduledArrival: parseUnix(j['scheduled_arrival_unix']),
    );
  }

  // Minutes until arrival from now (null if in the past or unknown)
  int? get minutesUntil {
    final t = estimatedArrival ?? scheduledArrival;
    if (t == null) return null;
    final diff = t.difference(DateTime.now()).inMinutes;
    return diff >= 0 ? diff : null;
  }
}
