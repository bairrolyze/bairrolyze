class AddressModel {
  final String displayAddress;
  final String? street;
  final String? number;
  final String? apartment;
  final String? postalCode;
  final String? city;
  final String? district;
  final String country;
  final String countryCode;
  final double? lat;
  final double? lng;
  final String? id;

  const AddressModel({
    required this.displayAddress,
    this.street,
    this.number,
    this.apartment,
    this.postalCode,
    this.city,
    this.district,
    this.country = 'Portugal',
    this.countryCode = 'PT',
    this.lat,
    this.lng,
    this.id,
  });

  List<String> get _segments => displayAddress
      .split(',')
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty)
      .toList();

  static String? _extractPostcode(String s) {
    final pt = RegExp(r'\b\d{4}-\d{3}\b').firstMatch(s); // PT (e.g. 2800-123)
    if (pt != null) return pt.group(0);
    final uk = RegExp(r'\b[A-Z]{1,2}\d[A-Z\d]?\b').firstMatch(s); // UK (SW3, E14)
    return uk?.group(0);
  }

  /// Short, clean primary label — the specific place only, never the full
  /// display string. A street address keeps its number + street
  /// ("26, Avenida da República"); an area keeps "Area, City"
  /// ("Chelsea, London").
  String get shortPrimary {
    final segs = _segments;
    if (segs.isEmpty) {
      return city?.trim().isNotEmpty == true ? city!.trim() : 'Location';
    }
    final first = segs.first;
    // House-number first segment → pair it with the street (2nd segment).
    if (RegExp(r'^\d+[A-Za-z]?$').hasMatch(first) && segs.length >= 2) {
      return '$first, ${segs[1]}';
    }
    final c = city?.trim();
    if (c != null && c.isNotEmpty && c.toLowerCase() != first.toLowerCase()) {
      return '$first, $c';
    }
    return first;
  }

  /// Fuller primary label for the results header: the leading street/place
  /// segments (up to two) before the city/region/postcode, so a specific
  /// address like "Oriente, Praça do Oriente" isn't collapsed to just
  /// "Oriente". Falls back to [shortPrimary] when nothing better is available.
  String get headerTitle {
    final segs = _segments;
    if (segs.isEmpty) return shortPrimary;
    final stops = <String>{
      city?.trim().toLowerCase() ?? '',
      district?.trim().toLowerCase() ?? '',
      country.trim().toLowerCase(),
    }..removeWhere((e) => e.isEmpty);
    final kept = <String>[];
    for (final s in segs) {
      if (stops.contains(s.toLowerCase())) break;
      if (_extractPostcode(s) == s) break; // pure postcode segment
      kept.add(s);
      if (kept.length == 2) break;
    }
    return kept.isEmpty ? shortPrimary : kept.join(', ');
  }

  /// Short secondary label — the human-readable context not already in the
  /// primary: "City, Country" ("Amadora, Portugal"), else "Postcode, Country"
  /// ("SW3, United Kingdom"), else "Region, Country".
  String get shortSecondary {
    final ctry = country.trim();
    final primaryLower = shortPrimary.toLowerCase();

    String withCountry(String s) => ctry.isEmpty ? s : '$s, $ctry';
    bool notInPrimary(String s) => !primaryLower.contains(s.toLowerCase());

    final c = city?.trim();
    if (c != null && c.isNotEmpty && notInPrimary(c)) return withCountry(c);

    final pc = _extractPostcode(displayAddress) ??
        (postalCode?.trim().isNotEmpty == true ? postalCode!.trim() : null);
    if (pc != null && pc.isNotEmpty && notInPrimary(pc)) return withCountry(pc);

    final reg = district?.trim();
    if (reg != null && reg.isNotEmpty && notInPrimary(reg)) return withCountry(reg);

    return ctry.isEmpty ? displayAddress : ctry;
  }

  AddressModel copyWith({
    String? displayAddress,
    String? street,
    String? number,
    String? apartment,
    String? postalCode,
    String? city,
    String? district,
    String? country,
    String? countryCode,
    double? lat,
    double? lng,
    String? id,
  }) =>
      AddressModel(
        displayAddress: displayAddress ?? this.displayAddress,
        street: street ?? this.street,
        number: number ?? this.number,
        apartment: apartment ?? this.apartment,
        postalCode: postalCode ?? this.postalCode,
        city: city ?? this.city,
        district: district ?? this.district,
        country: country ?? this.country,
        countryCode: countryCode ?? this.countryCode,
        lat: lat ?? this.lat,
        lng: lng ?? this.lng,
        id: id ?? this.id,
      );

  factory AddressModel.fromJson(Map<String, dynamic> json) => AddressModel(
        displayAddress: json['display_address'] as String? ?? json['displayAddress'] as String? ?? '',
        street: json['street'] as String?,
        number: json['number'] as String?,
        apartment: json['apartment'] as String?,
        postalCode: json['postal_code'] as String?,
        city: json['city'] as String?,
        district: json['district'] as String?,
        country: json['country'] as String? ?? 'Portugal',
        countryCode: json['country_code'] as String? ?? 'PT',
        lat: (json['lat'] as num?)?.toDouble(),
        lng: (json['lng'] as num?)?.toDouble(),
        id: json['id'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'display_address': displayAddress,
        if (street != null) 'street': street,
        if (number != null) 'number': number,
        if (apartment != null) 'apartment': apartment,
        if (postalCode != null) 'postal_code': postalCode,
        if (city != null) 'city': city,
        if (district != null) 'district': district,
        'country': country,
        'country_code': countryCode,
        if (lat != null) 'lat': lat,
        if (lng != null) 'lng': lng,
        if (id != null) 'id': id,
      };
}

class CountryConfig {
  final String code;
  final String name;
  final String language;
  final String currency;
  final String postalPattern;
  final String postalFormat;
  final String postalExample;
  final String nominatimCountry;
  final String defaultCity;
  final LatLngModel center;
  final double defaultZoom;

  const CountryConfig({
    required this.code,
    required this.name,
    required this.language,
    required this.currency,
    required this.postalPattern,
    required this.postalFormat,
    required this.postalExample,
    required this.nominatimCountry,
    required this.defaultCity,
    required this.center,
    required this.defaultZoom,
  });

  factory CountryConfig.fromJson(Map<String, dynamic> json) => CountryConfig(
        code: json['code'] as String,
        name: json['name'] as String,
        language: json['language'] as String,
        currency: json['currency'] as String,
        postalPattern: json['postalPattern'] as String,
        postalFormat: json['postalFormat'] as String,
        postalExample: json['postalExample'] as String,
        nominatimCountry: json['nominatimCountry'] as String,
        defaultCity: json['defaultCity'] as String,
        center: LatLngModel.fromJson(json['center'] as Map<String, dynamic>),
        defaultZoom: (json['defaultZoom'] as num).toDouble(),
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is CountryConfig && code == other.code;

  @override
  int get hashCode => code.hashCode;
}

class LatLngModel {
  final double lat;
  final double lng;

  const LatLngModel({required this.lat, required this.lng});

  factory LatLngModel.fromJson(Map<String, dynamic> json) => LatLngModel(
        lat: (json['lat'] as num).toDouble(),
        lng: (json['lng'] as num).toDouble(),
      );
}
