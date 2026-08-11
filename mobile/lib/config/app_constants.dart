class AppConstants {
  static const String appName = 'Bairrolyze';
  static const String appTagline = 'Know your neighborhood before you move.';

  // Legal — hosted free on GitHub Pages (see landing/privacy.html)
  static const String privacyPolicyUrl =
      'https://rajesharyain.github.io/bairrolyze/privacy.html';

 // API - override with env vars in production
  // static const String backendBaseUrl = String.fromEnvironment(
  //   'BACKEND_URL',
  //   defaultValue: 'http://localhost:8001',
  // );

  static const String backendBaseUrl = String.fromEnvironment(
    'BACKEND_URL',
    defaultValue: 'https://api-home-scope.wonderfulplant-e443a025.eastus.azurecontainerapps.io/',
  );

  static const String nominatimBaseUrl = 'https://nominatim.openstreetmap.org';
  static const String overpassApiUrl = 'https://overpass-api.de/api/interpreter';
  static const String openRouteServiceBaseUrl = 'https://api.openrouteservice.org';

  // Scoring
  static const double searchRadiusMeters = 2000;
  static const int maxAmenityResults = 50;

  // Cache
  static const Duration cacheTtl = Duration(hours: 24);
  static const int maxHistoryItems = 20;
  static const int maxFavorites = 50;

  // Map
  static const double defaultZoom = 15.0;
  static const double markerZoom = 16.0;

  // Animation
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration normalAnimation = Duration(milliseconds: 350);
  static const Duration longAnimation = Duration(milliseconds: 500);

  // Score thresholds
  static const int scoreExcellent = 80;
  static const int scoreGood = 60;
  static const int scoreFair = 40;
}
