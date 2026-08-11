import '../l10n/app_localizations.dart';

enum AmenityCategory {
  transportation,
  education,
  healthcare,
  shopping,
  safety,
  religion,
  recreation,
}

extension AmenityCategoryLabel on AmenityCategory {
  /// Localized display label for this category (map filters, stats, sheets).
  String label(AppLocalizations l) => switch (this) {
        AmenityCategory.transportation => l.amenityTransportation,
        AmenityCategory.education => l.amenityEducation,
        AmenityCategory.healthcare => l.amenityHealthcare,
        AmenityCategory.shopping => l.amenityShopping,
        AmenityCategory.safety => l.amenitySafety,
        AmenityCategory.religion => l.amenityReligion,
        AmenityCategory.recreation => l.amenityRecreation,
      };
}

class AmenityModel {
  final String id;
  final String name;
  final AmenityCategory category;
  final String type;
  final double lat;
  final double lng;
  final int? distanceMeters;
  final int? walkingMinutes;
  final int? drivingMinutes;
  final String? address;
  final Map<String, dynamic>? tags;

  const AmenityModel({
    required this.id,
    required this.name,
    required this.category,
    required this.type,
    required this.lat,
    required this.lng,
    this.distanceMeters,
    this.walkingMinutes,
    this.drivingMinutes,
    this.address,
    this.tags,
  });

  factory AmenityModel.fromJson(Map<String, dynamic> json) => AmenityModel(
        id: json['id'] as String,
        name: json['name'] as String,
        category: _parseCategory(json['category'] as String),
        type: json['type'] as String,
        lat: (json['lat'] as num).toDouble(),
        lng: (json['lng'] as num).toDouble(),
        distanceMeters: json['distance_meters'] as int?,
        walkingMinutes: json['walking_minutes'] as int?,
        drivingMinutes: json['driving_minutes'] as int?,
        address: json['address'] as String?,
        tags: json['tags'] as Map<String, dynamic>?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'category': category.name,
        'type': type,
        'lat': lat,
        'lng': lng,
        if (distanceMeters != null) 'distance_meters': distanceMeters,
        if (walkingMinutes != null) 'walking_minutes': walkingMinutes,
        if (drivingMinutes != null) 'driving_minutes': drivingMinutes,
        if (address != null) 'address': address,
        if (tags != null) 'tags': tags,
      };

  static AmenityCategory _parseCategory(String value) {
    return AmenityCategory.values.firstWhere(
      (e) => e.name == value,
      orElse: () => AmenityCategory.recreation,
    );
  }
}
