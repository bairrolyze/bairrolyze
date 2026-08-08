// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get settingsTitle => 'You';

  @override
  String get settingsSectionProfile => 'PROFILE';

  @override
  String get settingsSectionCountry => 'COUNTRY';

  @override
  String get settingsSectionLanguage => 'LANGUAGE';

  @override
  String get settingsSectionSearchRadius => 'SEARCH RADIUS';

  @override
  String get settingsSectionAppearance => 'APPEARANCE';

  @override
  String get settingsSectionAiFeatures => 'AI FEATURES';

  @override
  String get settingsSectionHelp => 'HELP';

  @override
  String get profileGeneral => 'General';

  @override
  String get profileFamily => 'Family';

  @override
  String get profileStudent => 'Student';

  @override
  String get profilePro => 'Pro';

  @override
  String get profileRetired => 'Retired';

  @override
  String get profileInvestor => 'Investor';

  @override
  String get languageEnglish => 'English';

  @override
  String get languagePortuguese => 'Português';

  @override
  String settingsRadiusLabel(String km) {
    return '$km km radius';
  }

  @override
  String settingsRadiusMeters(int meters) {
    return '${meters}m';
  }

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get aiSummaryTitle => 'AI Neighbourhood Summary';

  @override
  String get aiSummarySubtitle => 'Powered by OpenAI';

  @override
  String get helpGuidesTitle => 'Guides & Help';

  @override
  String get helpGuidesSubtitle => '8 in-depth guides for every feature';

  @override
  String get helpTourTitle => 'Quick Tour';

  @override
  String get helpTourSubtitle => '5-screen intro to Bairrolyze';

  @override
  String get profileProfessional => 'Professional';

  @override
  String get prioritySchools => 'Good schools';

  @override
  String get priorityCommute => 'Short commute';

  @override
  String get prioritySocial => 'Shops & nightlife';

  @override
  String get priorityHealthcare => 'Healthcare nearby';

  @override
  String get prioritySafety => 'Safe & quiet';

  @override
  String get priorityRental => 'Rental potential';

  @override
  String get commonContinue => 'Continue';

  @override
  String get onboardingSkip => 'Skip';

  @override
  String get onboardingWelcomeTitle => 'Let\'s tailor your scores';

  @override
  String get onboardingWelcomeSubtitle =>
      'Bairrolyze scores every address around what matters to you.';

  @override
  String get onboardingGetStarted => 'Get started';

  @override
  String get onboardingPrioritiesTitle =>
      'What matters most where you\'ll live?';

  @override
  String get onboardingPickUpTo3 => 'Pick up to 3.';

  @override
  String get onboardingThatsTheMax => 'That\'s the max';

  @override
  String onboardingConfirmPrioritize(String profile) {
    return 'Perfect — we\'ll prioritize $profile.';
  }

  @override
  String get onboardingYourPriorities => 'Your priorities';

  @override
  String get onboardingBalancedProfile =>
      'We\'ll use a balanced, general profile — you can refine this any time in settings.';

  @override
  String get onboardingStartExploring => 'Start exploring';

  @override
  String get commonClear => 'Clear';

  @override
  String get homeLocationServicesOff =>
      'Turn on location services to use this.';

  @override
  String get homeLocationPermissionNeeded =>
      'Location permission is needed to detect your area.';

  @override
  String get homeLocationFailed => 'Could not get your current location.';

  @override
  String get homeSearchHint => 'Search any address, city or area';

  @override
  String get homeUseMyLocation => 'Use my current location';

  @override
  String get homeHeroSubtitle => 'The Smarter Way to Choose Home';

  @override
  String get homeCtaAnalyse => 'Analyse Neighbourhood';

  @override
  String get homePopularTitle => 'Popular Searches';

  @override
  String homePopularSubtitle(String country) {
    return 'Most-visited places in $country';
  }

  @override
  String get homePopularSeeAll => 'See all';

  @override
  String get homePopularTrending => 'Trending';

  @override
  String homePopularAreasSubtitle(String region) {
    return 'Popular areas people are exploring in $region';
  }

  @override
  String get homeRecentTitle => 'Recent Searches';

  @override
  String get homeTrustedBy => 'Trusted by thousands of users worldwide';

  @override
  String get featureSmartDataTitle => 'Smart Data';

  @override
  String get featureSmartDataDesc => 'Real-time and reliable sources';

  @override
  String get featureAiAnalysisTitle => 'AI Analysis';

  @override
  String get featureAiAnalysisDesc => '25+ factors analysed in seconds';

  @override
  String get featureAccurateScoreTitle => 'Accurate Score';

  @override
  String get featureAccurateScoreDesc =>
      'A clear score to decide with confidence';

  @override
  String get featurePrivateSecureTitle => 'Private & Secure';

  @override
  String get featurePrivateSecureDesc =>
      'Your searches and data stay protected';

  @override
  String get homeAnalyseTitle => 'What we analyse';

  @override
  String get homeAnalyseSubtitle =>
      'Seven signals we score for every address · swipe to explore';

  @override
  String get catTransportLabel => 'Transport';

  @override
  String get catTransportDesc =>
      'Nearby train stations, bus routes, commute times and walkability.';

  @override
  String get catEducationLabel => 'Education';

  @override
  String get catEducationDesc =>
      'Schools, universities, libraries and learning options close by.';

  @override
  String get catHealthLabel => 'Health';

  @override
  String get catHealthDesc =>
      'Hospitals, clinics, pharmacies and everyday healthcare access.';

  @override
  String get catSafetyLabel => 'Safety';

  @override
  String get catSafetyDesc =>
      'Emergency services, plus real crime stats where available.';

  @override
  String get catLifestyleLabel => 'Lifestyle';

  @override
  String get catLifestyleDesc =>
      'Shops, markets, cafés and the daily conveniences within reach.';

  @override
  String get catNatureLabel => 'Nature';

  @override
  String get catNatureDesc =>
      'Parks, gardens and green open spaces for the outdoors.';

  @override
  String get catInvestmentLabel => 'Investment';

  @override
  String get catInvestmentDesc =>
      'Price trends, rental demand and long-term value potential.';

  @override
  String get homeHowTitle => 'How it works';

  @override
  String get homeHowSubtitle => 'From an address to a score in three steps';

  @override
  String get homeHowBody =>
      'We pull live data from OpenStreetMap and score every category against your profile, so the result reflects what actually matters to you.';

  @override
  String get homeStepLocate => 'Locate';

  @override
  String get homeStepAnalyse => 'Analyse';

  @override
  String get homeStepScore => 'Score';

  @override
  String get commonViewMap => 'View Map';

  @override
  String get commonShare => 'Share';

  @override
  String get commonDismiss => 'Dismiss';

  @override
  String get dashAnalyzing => 'Analyzing...';

  @override
  String get dashTitle => 'Dashboard';

  @override
  String get dashNoData => 'No analysis data available';

  @override
  String get dashSearchAddress => 'Search an Address';

  @override
  String get dashCategoryScores => 'Category Scores';

  @override
  String get dashNearbyPlaces => 'Nearby Places';

  @override
  String dashViewAllPlaces(int count) {
    return 'View all $count places on map';
  }

  @override
  String get dashOpenMap => 'Open Map';

  @override
  String dashShareMessage(String address, int score) {
    return '$address — Score: $score/100';
  }

  @override
  String get dashLivingIndex => 'Living Index';

  @override
  String get dashLivingIndexSubtitle =>
      'Your primary view — DNA, Timeline, Story & more';

  @override
  String get pillDna => 'DNA';

  @override
  String get pillRadius => 'Radius';

  @override
  String get pillTimeline => 'Timeline';

  @override
  String get pillStory => 'Story';

  @override
  String get pillFuture => 'Future';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonAnalyze => 'Analyze';

  @override
  String get commonClearAll => 'Clear all';

  @override
  String get savedTitle => 'Saved';

  @override
  String get savedEmptyTitle => 'No saved places yet';

  @override
  String get savedEmptyBody =>
      'Tap the bookmark on any analysis to save it here for quick access.';

  @override
  String get historyTitle => 'Search History';

  @override
  String get historyClearTooltip => 'Clear history';

  @override
  String get historyEmptyTitle => 'No search history yet';

  @override
  String get historyEmptyBody => 'Your analyzed addresses will appear here';

  @override
  String get historyClearTitle => 'Clear History';

  @override
  String get historyClearBody => 'Remove all search history?';

  @override
  String timeMinutesAgo(int minutes) {
    return '${minutes}m ago';
  }

  @override
  String timeHoursAgo(int hours) {
    return '${hours}h ago';
  }

  @override
  String timeDaysAgo(int days) {
    return '${days}d ago';
  }

  @override
  String validationRequired(String field) {
    return '$field is required';
  }

  @override
  String get validationAddressRequired => 'Address is required';

  @override
  String get validationAddressTooShort => 'Address is too short';

  @override
  String validationPostalInvalid(String format) {
    return 'Invalid format. Expected: $format';
  }

  @override
  String get advTitle => 'Advanced Search';

  @override
  String get advSectionLocation => 'Location';

  @override
  String get advFailedCountries => 'Failed to load countries';

  @override
  String get advAnalyzeAddress => 'Analyze Address';

  @override
  String get advHintApartment => '3rd floor, apt 4';

  @override
  String advPostalHelp(String format, String example) {
    return 'Postal code format: $format  (e.g. $example)';
  }

  @override
  String get fieldCountry => 'Country';

  @override
  String get fieldStreet => 'Street';

  @override
  String get fieldNumber => 'No.';

  @override
  String get fieldApartment => 'Apartment / Floor';

  @override
  String get fieldPostalCode => 'Postal Code';

  @override
  String get fieldCity => 'City';

  @override
  String get fieldDistrict => 'District / Region (optional)';

  @override
  String get explorerTitle => 'Explore';

  @override
  String get explorerSubtitle =>
      'Find the neighbourhoods that fit how you want to live.';

  @override
  String get explorerFeatured => 'FEATURED';

  @override
  String explorerBestFor(String profile) {
    return 'Best for $profile';
  }

  @override
  String get explorerBestMatch => 'Best match';

  @override
  String get explorerCityAll => 'All areas';

  @override
  String explorerTrendingIn(String region) {
    return 'Trending in $region';
  }

  @override
  String get explorerStepProfile => '1. Choose your profile';

  @override
  String get explorerStepArea => '2. Choose your area';

  @override
  String explorerSearchHint(String country) {
    return 'Search areas in $country';
  }

  @override
  String explorerNoAreas(String country) {
    return 'No matching areas in $country';
  }

  @override
  String explorerSearchPrompt(String country) {
    return 'Search for any area in $country above to analyse it.';
  }

  @override
  String get explorerProfileFamilyDesc => 'Great for growth & family life';

  @override
  String get explorerProfileStudentDesc => 'Close to campuses & transit';

  @override
  String get explorerProfileProfessionalDesc => 'Well connected & convenient';

  @override
  String get explorerProfileRetiredDesc => 'Peaceful & quieter';

  @override
  String get explorerProfileInvestorDesc => 'Strong demand & upside';

  @override
  String get filterAll => 'All';

  @override
  String get tagTransport => 'Transport';

  @override
  String get tagFamily => 'Family';

  @override
  String get tagInvestment => 'Investment';

  @override
  String get tagNature => 'Nature';

  @override
  String get tagCulture => 'Culture';

  @override
  String get statTransit => 'Transit';

  @override
  String get statEducation => 'Education';

  @override
  String get statSafety => 'Safety';

  @override
  String get nbParqueNacoesDesc =>
      'Modern waterfront district with excellent transit and contemporary architecture.';

  @override
  String get nbParqueNacoesHighlight => 'Best connected in Lisbon';

  @override
  String get nbPrincipeRealDesc =>
      'Sophisticated hilltop quarter known for boutiques, galleries and vibrant café culture.';

  @override
  String get nbPrincipeRealHighlight => 'Top walkability score';

  @override
  String get nbCascaisDesc =>
      'Prestigious seaside town with marina, beaches and an exceptional quality of life.';

  @override
  String get nbCascaisHighlight => 'Top coastal quality of life';

  @override
  String get nbBaixaChiadoDesc =>
      'Lisbon\'s beating heart — historic grandeur meets a lively commercial and cultural scene.';

  @override
  String get nbBaixaChiadoHighlight => 'Historic centre, great transit';

  @override
  String get nbBoavistaDesc =>
      'Porto\'s prestigious business and residential corridor with excellent urban amenities.';

  @override
  String get nbBoavistaHighlight => 'Porto\'s premier investment district';

  @override
  String get nbFozDouroDesc =>
      'Exclusive riverside neighbourhood with ocean views, parks and upscale dining.';

  @override
  String get nbFozDouroHighlight => 'Porto\'s most desirable address';

  @override
  String get nbSantoAntonioDesc =>
      'Central Lisbon neighbourhood with top-tier healthcare, schools and safety scores.';

  @override
  String get nbSantoAntonioHighlight => 'Best for families in central Lisbon';

  @override
  String get nbBragaCentroDesc =>
      'Northern gem combining historic charm with a thriving university city energy.';

  @override
  String get nbBragaCentroHighlight => 'Fastest growing city centre';

  @override
  String get amenityTransportation => 'Transport';

  @override
  String get amenityEducation => 'Schools';

  @override
  String get amenityHealthcare => 'Healthcare';

  @override
  String get amenityShopping => 'Shopping';

  @override
  String get amenitySafety => 'Safety';

  @override
  String get amenityReligion => 'Religion';

  @override
  String get amenityRecreation => 'Parks';

  @override
  String get mapTitleFallback => 'Map';

  @override
  String get mapCenterTooltip => 'Center map';

  @override
  String mapPlacesFound(int total) {
    return '$total places found';
  }

  @override
  String mapPlacesNearby(int total) {
    return '$total places nearby';
  }

  @override
  String mapCategoryCount(int total, String category) {
    return '$total $category';
  }

  @override
  String amenityCountLabel(String label, int count) {
    return '$label ($count)';
  }

  @override
  String amenityMinWalk(int minutes) {
    return '$minutes min walk';
  }

  @override
  String amenityMinDrive(int minutes) {
    return '$minutes min drive';
  }

  @override
  String get paywallBadge => 'Go Pro';

  @override
  String get paywallTitle => 'Unlock the full Bairrolyze';

  @override
  String get paywallSubtitle =>
      'Make confident decisions with every insight at your fingertips.';

  @override
  String get paywallRestore => 'Restore purchases';

  @override
  String get paywallCancelAnytime => 'Cancel anytime. Billed monthly.';

  @override
  String get paywallMostPopular => 'MOST POPULAR';

  @override
  String paywallStartPro(String price) {
    return 'Start Pro — $price/mo';
  }

  @override
  String paywallTryPremium(String price) {
    return 'Try Premium — $price/mo';
  }

  @override
  String get paywallFreePrice => '€0 / forever';

  @override
  String paywallPerMonth(String price) {
    return '$price / month';
  }

  @override
  String get tierFree => 'Free';

  @override
  String get tierPro => 'Pro';

  @override
  String get tierPremium => 'Premium';

  @override
  String get featFree2Comparisons => '2 property comparisons';

  @override
  String get featFree1Alert => '1 neighbourhood alert';

  @override
  String get featFreeCoreAnalysis => 'Core analysis & maps';

  @override
  String get featProUnlimitedComparisons => 'Unlimited comparisons';

  @override
  String get featPro10Alerts => '10 neighbourhood alerts';

  @override
  String get featProPriority => 'Priority analysis';

  @override
  String get featProTimeline => 'Historical timeline';

  @override
  String get featPremiumEverythingPro => 'Everything in Pro';

  @override
  String get featPremium99Alerts => '99 alerts with push notifications';

  @override
  String get featPremiumAiInsights => 'AI investment insights';

  @override
  String get featPremiumForecasting => 'Trend forecasting';

  @override
  String get paywallErrProductUnavailable =>
      'Product not available. Please try again.';

  @override
  String get paywallErrGeneric => 'Something went wrong. Please try again.';

  @override
  String get paywallErrNoPurchases =>
      'No active purchases found on this account.';

  @override
  String get paywallErrPaymentPending =>
      'Payment is pending. Check your payment method.';

  @override
  String get paywallErrRegion => 'Product not available in your region.';

  @override
  String get paywallErrPurchaseFailed => 'Purchase failed. Please try again.';
}
