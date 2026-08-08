import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_pt.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('pt')
  ];

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get settingsTitle;

  /// No description provided for @settingsSectionProfile.
  ///
  /// In en, this message translates to:
  /// **'PROFILE'**
  String get settingsSectionProfile;

  /// No description provided for @settingsSectionCountry.
  ///
  /// In en, this message translates to:
  /// **'COUNTRY'**
  String get settingsSectionCountry;

  /// No description provided for @settingsSectionLanguage.
  ///
  /// In en, this message translates to:
  /// **'LANGUAGE'**
  String get settingsSectionLanguage;

  /// No description provided for @settingsSectionSearchRadius.
  ///
  /// In en, this message translates to:
  /// **'SEARCH RADIUS'**
  String get settingsSectionSearchRadius;

  /// No description provided for @settingsSectionAppearance.
  ///
  /// In en, this message translates to:
  /// **'APPEARANCE'**
  String get settingsSectionAppearance;

  /// No description provided for @settingsSectionAiFeatures.
  ///
  /// In en, this message translates to:
  /// **'AI FEATURES'**
  String get settingsSectionAiFeatures;

  /// No description provided for @settingsSectionHelp.
  ///
  /// In en, this message translates to:
  /// **'HELP'**
  String get settingsSectionHelp;

  /// No description provided for @profileGeneral.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get profileGeneral;

  /// No description provided for @profileFamily.
  ///
  /// In en, this message translates to:
  /// **'Family'**
  String get profileFamily;

  /// No description provided for @profileStudent.
  ///
  /// In en, this message translates to:
  /// **'Student'**
  String get profileStudent;

  /// No description provided for @profilePro.
  ///
  /// In en, this message translates to:
  /// **'Pro'**
  String get profilePro;

  /// No description provided for @profileRetired.
  ///
  /// In en, this message translates to:
  /// **'Retired'**
  String get profileRetired;

  /// No description provided for @profileInvestor.
  ///
  /// In en, this message translates to:
  /// **'Investor'**
  String get profileInvestor;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languagePortuguese.
  ///
  /// In en, this message translates to:
  /// **'Português'**
  String get languagePortuguese;

  /// No description provided for @settingsRadiusLabel.
  ///
  /// In en, this message translates to:
  /// **'{km} km radius'**
  String settingsRadiusLabel(String km);

  /// No description provided for @settingsRadiusMeters.
  ///
  /// In en, this message translates to:
  /// **'{meters}m'**
  String settingsRadiusMeters(int meters);

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @aiSummaryTitle.
  ///
  /// In en, this message translates to:
  /// **'AI Neighbourhood Summary'**
  String get aiSummaryTitle;

  /// No description provided for @aiSummarySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Powered by OpenAI'**
  String get aiSummarySubtitle;

  /// No description provided for @helpGuidesTitle.
  ///
  /// In en, this message translates to:
  /// **'Guides & Help'**
  String get helpGuidesTitle;

  /// No description provided for @helpGuidesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'8 in-depth guides for every feature'**
  String get helpGuidesSubtitle;

  /// No description provided for @helpTourTitle.
  ///
  /// In en, this message translates to:
  /// **'Quick Tour'**
  String get helpTourTitle;

  /// No description provided for @helpTourSubtitle.
  ///
  /// In en, this message translates to:
  /// **'5-screen intro to Bairrolyze'**
  String get helpTourSubtitle;

  /// No description provided for @profileProfessional.
  ///
  /// In en, this message translates to:
  /// **'Professional'**
  String get profileProfessional;

  /// No description provided for @prioritySchools.
  ///
  /// In en, this message translates to:
  /// **'Good schools'**
  String get prioritySchools;

  /// No description provided for @priorityCommute.
  ///
  /// In en, this message translates to:
  /// **'Short commute'**
  String get priorityCommute;

  /// No description provided for @prioritySocial.
  ///
  /// In en, this message translates to:
  /// **'Shops & nightlife'**
  String get prioritySocial;

  /// No description provided for @priorityHealthcare.
  ///
  /// In en, this message translates to:
  /// **'Healthcare nearby'**
  String get priorityHealthcare;

  /// No description provided for @prioritySafety.
  ///
  /// In en, this message translates to:
  /// **'Safe & quiet'**
  String get prioritySafety;

  /// No description provided for @priorityRental.
  ///
  /// In en, this message translates to:
  /// **'Rental potential'**
  String get priorityRental;

  /// No description provided for @commonContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get commonContinue;

  /// No description provided for @onboardingSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get onboardingSkip;

  /// No description provided for @onboardingWelcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Let\'s tailor your scores'**
  String get onboardingWelcomeTitle;

  /// No description provided for @onboardingWelcomeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Bairrolyze scores every address around what matters to you.'**
  String get onboardingWelcomeSubtitle;

  /// No description provided for @onboardingGetStarted.
  ///
  /// In en, this message translates to:
  /// **'Get started'**
  String get onboardingGetStarted;

  /// No description provided for @onboardingPrioritiesTitle.
  ///
  /// In en, this message translates to:
  /// **'What matters most where you\'ll live?'**
  String get onboardingPrioritiesTitle;

  /// No description provided for @onboardingPickUpTo3.
  ///
  /// In en, this message translates to:
  /// **'Pick up to 3.'**
  String get onboardingPickUpTo3;

  /// No description provided for @onboardingThatsTheMax.
  ///
  /// In en, this message translates to:
  /// **'That\'s the max'**
  String get onboardingThatsTheMax;

  /// No description provided for @onboardingConfirmPrioritize.
  ///
  /// In en, this message translates to:
  /// **'Perfect — we\'ll prioritize {profile}.'**
  String onboardingConfirmPrioritize(String profile);

  /// No description provided for @onboardingYourPriorities.
  ///
  /// In en, this message translates to:
  /// **'Your priorities'**
  String get onboardingYourPriorities;

  /// No description provided for @onboardingBalancedProfile.
  ///
  /// In en, this message translates to:
  /// **'We\'ll use a balanced, general profile — you can refine this any time in settings.'**
  String get onboardingBalancedProfile;

  /// No description provided for @onboardingStartExploring.
  ///
  /// In en, this message translates to:
  /// **'Start exploring'**
  String get onboardingStartExploring;

  /// No description provided for @commonClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get commonClear;

  /// No description provided for @homeLocationServicesOff.
  ///
  /// In en, this message translates to:
  /// **'Turn on location services to use this.'**
  String get homeLocationServicesOff;

  /// No description provided for @homeLocationPermissionNeeded.
  ///
  /// In en, this message translates to:
  /// **'Location permission is needed to detect your area.'**
  String get homeLocationPermissionNeeded;

  /// No description provided for @homeLocationFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not get your current location.'**
  String get homeLocationFailed;

  /// No description provided for @homeSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search any address, city or area'**
  String get homeSearchHint;

  /// No description provided for @homeUseMyLocation.
  ///
  /// In en, this message translates to:
  /// **'Use my current location'**
  String get homeUseMyLocation;

  /// No description provided for @homeHeroSubtitle.
  ///
  /// In en, this message translates to:
  /// **'The Smarter Way to Choose Home'**
  String get homeHeroSubtitle;

  /// No description provided for @homeCtaAnalyse.
  ///
  /// In en, this message translates to:
  /// **'Analyse Neighbourhood'**
  String get homeCtaAnalyse;

  /// No description provided for @homePopularTitle.
  ///
  /// In en, this message translates to:
  /// **'Popular Searches'**
  String get homePopularTitle;

  /// No description provided for @homePopularSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Most-visited places in {country}'**
  String homePopularSubtitle(String country);

  /// No description provided for @homePopularSeeAll.
  ///
  /// In en, this message translates to:
  /// **'See all'**
  String get homePopularSeeAll;

  /// No description provided for @homePopularTrending.
  ///
  /// In en, this message translates to:
  /// **'Trending'**
  String get homePopularTrending;

  /// No description provided for @homePopularAreasSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Popular areas people are exploring in {region}'**
  String homePopularAreasSubtitle(String region);

  /// No description provided for @homeRecentTitle.
  ///
  /// In en, this message translates to:
  /// **'Recent Searches'**
  String get homeRecentTitle;

  /// No description provided for @homeTrustedBy.
  ///
  /// In en, this message translates to:
  /// **'Trusted by thousands of users worldwide'**
  String get homeTrustedBy;

  /// No description provided for @featureSmartDataTitle.
  ///
  /// In en, this message translates to:
  /// **'Smart Data'**
  String get featureSmartDataTitle;

  /// No description provided for @featureSmartDataDesc.
  ///
  /// In en, this message translates to:
  /// **'Real-time and reliable sources'**
  String get featureSmartDataDesc;

  /// No description provided for @featureAiAnalysisTitle.
  ///
  /// In en, this message translates to:
  /// **'AI Analysis'**
  String get featureAiAnalysisTitle;

  /// No description provided for @featureAiAnalysisDesc.
  ///
  /// In en, this message translates to:
  /// **'25+ factors analysed in seconds'**
  String get featureAiAnalysisDesc;

  /// No description provided for @featureAccurateScoreTitle.
  ///
  /// In en, this message translates to:
  /// **'Accurate Score'**
  String get featureAccurateScoreTitle;

  /// No description provided for @featureAccurateScoreDesc.
  ///
  /// In en, this message translates to:
  /// **'A clear score to decide with confidence'**
  String get featureAccurateScoreDesc;

  /// No description provided for @featurePrivateSecureTitle.
  ///
  /// In en, this message translates to:
  /// **'Private & Secure'**
  String get featurePrivateSecureTitle;

  /// No description provided for @featurePrivateSecureDesc.
  ///
  /// In en, this message translates to:
  /// **'Your searches and data stay protected'**
  String get featurePrivateSecureDesc;

  /// No description provided for @homeAnalyseTitle.
  ///
  /// In en, this message translates to:
  /// **'What we analyse'**
  String get homeAnalyseTitle;

  /// No description provided for @homeAnalyseSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Seven signals we score for every address · swipe to explore'**
  String get homeAnalyseSubtitle;

  /// No description provided for @catTransportLabel.
  ///
  /// In en, this message translates to:
  /// **'Transport'**
  String get catTransportLabel;

  /// No description provided for @catTransportDesc.
  ///
  /// In en, this message translates to:
  /// **'Nearby train stations, bus routes, commute times and walkability.'**
  String get catTransportDesc;

  /// No description provided for @catEducationLabel.
  ///
  /// In en, this message translates to:
  /// **'Education'**
  String get catEducationLabel;

  /// No description provided for @catEducationDesc.
  ///
  /// In en, this message translates to:
  /// **'Schools, universities, libraries and learning options close by.'**
  String get catEducationDesc;

  /// No description provided for @catHealthLabel.
  ///
  /// In en, this message translates to:
  /// **'Health'**
  String get catHealthLabel;

  /// No description provided for @catHealthDesc.
  ///
  /// In en, this message translates to:
  /// **'Hospitals, clinics, pharmacies and everyday healthcare access.'**
  String get catHealthDesc;

  /// No description provided for @catSafetyLabel.
  ///
  /// In en, this message translates to:
  /// **'Safety'**
  String get catSafetyLabel;

  /// No description provided for @catSafetyDesc.
  ///
  /// In en, this message translates to:
  /// **'Emergency services, plus real crime stats where available.'**
  String get catSafetyDesc;

  /// No description provided for @catLifestyleLabel.
  ///
  /// In en, this message translates to:
  /// **'Lifestyle'**
  String get catLifestyleLabel;

  /// No description provided for @catLifestyleDesc.
  ///
  /// In en, this message translates to:
  /// **'Shops, markets, cafés and the daily conveniences within reach.'**
  String get catLifestyleDesc;

  /// No description provided for @catNatureLabel.
  ///
  /// In en, this message translates to:
  /// **'Nature'**
  String get catNatureLabel;

  /// No description provided for @catNatureDesc.
  ///
  /// In en, this message translates to:
  /// **'Parks, gardens and green open spaces for the outdoors.'**
  String get catNatureDesc;

  /// No description provided for @catInvestmentLabel.
  ///
  /// In en, this message translates to:
  /// **'Investment'**
  String get catInvestmentLabel;

  /// No description provided for @catInvestmentDesc.
  ///
  /// In en, this message translates to:
  /// **'Price trends, rental demand and long-term value potential.'**
  String get catInvestmentDesc;

  /// No description provided for @homeHowTitle.
  ///
  /// In en, this message translates to:
  /// **'How it works'**
  String get homeHowTitle;

  /// No description provided for @homeHowSubtitle.
  ///
  /// In en, this message translates to:
  /// **'From an address to a score in three steps'**
  String get homeHowSubtitle;

  /// No description provided for @homeHowBody.
  ///
  /// In en, this message translates to:
  /// **'We pull live data from OpenStreetMap and score every category against your profile, so the result reflects what actually matters to you.'**
  String get homeHowBody;

  /// No description provided for @homeStepLocate.
  ///
  /// In en, this message translates to:
  /// **'Locate'**
  String get homeStepLocate;

  /// No description provided for @homeStepAnalyse.
  ///
  /// In en, this message translates to:
  /// **'Analyse'**
  String get homeStepAnalyse;

  /// No description provided for @homeStepScore.
  ///
  /// In en, this message translates to:
  /// **'Score'**
  String get homeStepScore;

  /// No description provided for @commonViewMap.
  ///
  /// In en, this message translates to:
  /// **'View Map'**
  String get commonViewMap;

  /// No description provided for @commonShare.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get commonShare;

  /// No description provided for @commonDismiss.
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get commonDismiss;

  /// No description provided for @dashAnalyzing.
  ///
  /// In en, this message translates to:
  /// **'Analyzing...'**
  String get dashAnalyzing;

  /// No description provided for @dashTitle.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashTitle;

  /// No description provided for @dashNoData.
  ///
  /// In en, this message translates to:
  /// **'No analysis data available'**
  String get dashNoData;

  /// No description provided for @dashSearchAddress.
  ///
  /// In en, this message translates to:
  /// **'Search an Address'**
  String get dashSearchAddress;

  /// No description provided for @dashCategoryScores.
  ///
  /// In en, this message translates to:
  /// **'Category Scores'**
  String get dashCategoryScores;

  /// No description provided for @dashNearbyPlaces.
  ///
  /// In en, this message translates to:
  /// **'Nearby Places'**
  String get dashNearbyPlaces;

  /// No description provided for @dashViewAllPlaces.
  ///
  /// In en, this message translates to:
  /// **'View all {count} places on map'**
  String dashViewAllPlaces(int count);

  /// No description provided for @dashOpenMap.
  ///
  /// In en, this message translates to:
  /// **'Open Map'**
  String get dashOpenMap;

  /// No description provided for @dashShareMessage.
  ///
  /// In en, this message translates to:
  /// **'{address} — Score: {score}/100'**
  String dashShareMessage(String address, int score);

  /// No description provided for @dashLivingIndex.
  ///
  /// In en, this message translates to:
  /// **'Living Index'**
  String get dashLivingIndex;

  /// No description provided for @dashLivingIndexSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your primary view — DNA, Timeline, Story & more'**
  String get dashLivingIndexSubtitle;

  /// No description provided for @pillDna.
  ///
  /// In en, this message translates to:
  /// **'DNA'**
  String get pillDna;

  /// No description provided for @pillRadius.
  ///
  /// In en, this message translates to:
  /// **'Radius'**
  String get pillRadius;

  /// No description provided for @pillTimeline.
  ///
  /// In en, this message translates to:
  /// **'Timeline'**
  String get pillTimeline;

  /// No description provided for @pillStory.
  ///
  /// In en, this message translates to:
  /// **'Story'**
  String get pillStory;

  /// No description provided for @pillFuture.
  ///
  /// In en, this message translates to:
  /// **'Future'**
  String get pillFuture;

  /// No description provided for @commonCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancel;

  /// No description provided for @commonAnalyze.
  ///
  /// In en, this message translates to:
  /// **'Analyze'**
  String get commonAnalyze;

  /// No description provided for @commonClearAll.
  ///
  /// In en, this message translates to:
  /// **'Clear all'**
  String get commonClearAll;

  /// No description provided for @savedTitle.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get savedTitle;

  /// No description provided for @savedEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No saved places yet'**
  String get savedEmptyTitle;

  /// No description provided for @savedEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Tap the bookmark on any analysis to save it here for quick access.'**
  String get savedEmptyBody;

  /// No description provided for @historyTitle.
  ///
  /// In en, this message translates to:
  /// **'Search History'**
  String get historyTitle;

  /// No description provided for @historyClearTooltip.
  ///
  /// In en, this message translates to:
  /// **'Clear history'**
  String get historyClearTooltip;

  /// No description provided for @historyEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No search history yet'**
  String get historyEmptyTitle;

  /// No description provided for @historyEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Your analyzed addresses will appear here'**
  String get historyEmptyBody;

  /// No description provided for @historyClearTitle.
  ///
  /// In en, this message translates to:
  /// **'Clear History'**
  String get historyClearTitle;

  /// No description provided for @historyClearBody.
  ///
  /// In en, this message translates to:
  /// **'Remove all search history?'**
  String get historyClearBody;

  /// No description provided for @timeMinutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{minutes}m ago'**
  String timeMinutesAgo(int minutes);

  /// No description provided for @timeHoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{hours}h ago'**
  String timeHoursAgo(int hours);

  /// No description provided for @timeDaysAgo.
  ///
  /// In en, this message translates to:
  /// **'{days}d ago'**
  String timeDaysAgo(int days);

  /// No description provided for @validationRequired.
  ///
  /// In en, this message translates to:
  /// **'{field} is required'**
  String validationRequired(String field);

  /// No description provided for @validationAddressRequired.
  ///
  /// In en, this message translates to:
  /// **'Address is required'**
  String get validationAddressRequired;

  /// No description provided for @validationAddressTooShort.
  ///
  /// In en, this message translates to:
  /// **'Address is too short'**
  String get validationAddressTooShort;

  /// No description provided for @validationPostalInvalid.
  ///
  /// In en, this message translates to:
  /// **'Invalid format. Expected: {format}'**
  String validationPostalInvalid(String format);

  /// No description provided for @advTitle.
  ///
  /// In en, this message translates to:
  /// **'Advanced Search'**
  String get advTitle;

  /// No description provided for @advSectionLocation.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get advSectionLocation;

  /// No description provided for @advFailedCountries.
  ///
  /// In en, this message translates to:
  /// **'Failed to load countries'**
  String get advFailedCountries;

  /// No description provided for @advAnalyzeAddress.
  ///
  /// In en, this message translates to:
  /// **'Analyze Address'**
  String get advAnalyzeAddress;

  /// No description provided for @advHintApartment.
  ///
  /// In en, this message translates to:
  /// **'3rd floor, apt 4'**
  String get advHintApartment;

  /// No description provided for @advPostalHelp.
  ///
  /// In en, this message translates to:
  /// **'Postal code format: {format}  (e.g. {example})'**
  String advPostalHelp(String format, String example);

  /// No description provided for @fieldCountry.
  ///
  /// In en, this message translates to:
  /// **'Country'**
  String get fieldCountry;

  /// No description provided for @fieldStreet.
  ///
  /// In en, this message translates to:
  /// **'Street'**
  String get fieldStreet;

  /// No description provided for @fieldNumber.
  ///
  /// In en, this message translates to:
  /// **'No.'**
  String get fieldNumber;

  /// No description provided for @fieldApartment.
  ///
  /// In en, this message translates to:
  /// **'Apartment / Floor'**
  String get fieldApartment;

  /// No description provided for @fieldPostalCode.
  ///
  /// In en, this message translates to:
  /// **'Postal Code'**
  String get fieldPostalCode;

  /// No description provided for @fieldCity.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get fieldCity;

  /// No description provided for @fieldDistrict.
  ///
  /// In en, this message translates to:
  /// **'District / Region (optional)'**
  String get fieldDistrict;

  /// No description provided for @explorerTitle.
  ///
  /// In en, this message translates to:
  /// **'Explore'**
  String get explorerTitle;

  /// No description provided for @explorerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Find the neighbourhoods that fit how you want to live.'**
  String get explorerSubtitle;

  /// No description provided for @explorerFeatured.
  ///
  /// In en, this message translates to:
  /// **'FEATURED'**
  String get explorerFeatured;

  /// No description provided for @explorerBestFor.
  ///
  /// In en, this message translates to:
  /// **'Best for {profile}'**
  String explorerBestFor(String profile);

  /// No description provided for @explorerBestMatch.
  ///
  /// In en, this message translates to:
  /// **'Best match'**
  String get explorerBestMatch;

  /// No description provided for @explorerCityAll.
  ///
  /// In en, this message translates to:
  /// **'All areas'**
  String get explorerCityAll;

  /// No description provided for @explorerTrendingIn.
  ///
  /// In en, this message translates to:
  /// **'Trending in {region}'**
  String explorerTrendingIn(String region);

  /// No description provided for @explorerStepProfile.
  ///
  /// In en, this message translates to:
  /// **'1. Choose your profile'**
  String get explorerStepProfile;

  /// No description provided for @explorerStepArea.
  ///
  /// In en, this message translates to:
  /// **'2. Choose your area'**
  String get explorerStepArea;

  /// No description provided for @explorerSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search areas in {country}'**
  String explorerSearchHint(String country);

  /// No description provided for @explorerNoAreas.
  ///
  /// In en, this message translates to:
  /// **'No matching areas in {country}'**
  String explorerNoAreas(String country);

  /// No description provided for @explorerSearchPrompt.
  ///
  /// In en, this message translates to:
  /// **'Search for any area in {country} above to analyse it.'**
  String explorerSearchPrompt(String country);

  /// No description provided for @explorerProfileFamilyDesc.
  ///
  /// In en, this message translates to:
  /// **'Great for growth & family life'**
  String get explorerProfileFamilyDesc;

  /// No description provided for @explorerProfileStudentDesc.
  ///
  /// In en, this message translates to:
  /// **'Close to campuses & transit'**
  String get explorerProfileStudentDesc;

  /// No description provided for @explorerProfileProfessionalDesc.
  ///
  /// In en, this message translates to:
  /// **'Well connected & convenient'**
  String get explorerProfileProfessionalDesc;

  /// No description provided for @explorerProfileRetiredDesc.
  ///
  /// In en, this message translates to:
  /// **'Peaceful & quieter'**
  String get explorerProfileRetiredDesc;

  /// No description provided for @explorerProfileInvestorDesc.
  ///
  /// In en, this message translates to:
  /// **'Strong demand & upside'**
  String get explorerProfileInvestorDesc;

  /// No description provided for @filterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get filterAll;

  /// No description provided for @tagTransport.
  ///
  /// In en, this message translates to:
  /// **'Transport'**
  String get tagTransport;

  /// No description provided for @tagFamily.
  ///
  /// In en, this message translates to:
  /// **'Family'**
  String get tagFamily;

  /// No description provided for @tagInvestment.
  ///
  /// In en, this message translates to:
  /// **'Investment'**
  String get tagInvestment;

  /// No description provided for @tagNature.
  ///
  /// In en, this message translates to:
  /// **'Nature'**
  String get tagNature;

  /// No description provided for @tagCulture.
  ///
  /// In en, this message translates to:
  /// **'Culture'**
  String get tagCulture;

  /// No description provided for @statTransit.
  ///
  /// In en, this message translates to:
  /// **'Transit'**
  String get statTransit;

  /// No description provided for @statEducation.
  ///
  /// In en, this message translates to:
  /// **'Education'**
  String get statEducation;

  /// No description provided for @statSafety.
  ///
  /// In en, this message translates to:
  /// **'Safety'**
  String get statSafety;

  /// No description provided for @nbParqueNacoesDesc.
  ///
  /// In en, this message translates to:
  /// **'Modern waterfront district with excellent transit and contemporary architecture.'**
  String get nbParqueNacoesDesc;

  /// No description provided for @nbParqueNacoesHighlight.
  ///
  /// In en, this message translates to:
  /// **'Best connected in Lisbon'**
  String get nbParqueNacoesHighlight;

  /// No description provided for @nbPrincipeRealDesc.
  ///
  /// In en, this message translates to:
  /// **'Sophisticated hilltop quarter known for boutiques, galleries and vibrant café culture.'**
  String get nbPrincipeRealDesc;

  /// No description provided for @nbPrincipeRealHighlight.
  ///
  /// In en, this message translates to:
  /// **'Top walkability score'**
  String get nbPrincipeRealHighlight;

  /// No description provided for @nbCascaisDesc.
  ///
  /// In en, this message translates to:
  /// **'Prestigious seaside town with marina, beaches and an exceptional quality of life.'**
  String get nbCascaisDesc;

  /// No description provided for @nbCascaisHighlight.
  ///
  /// In en, this message translates to:
  /// **'Top coastal quality of life'**
  String get nbCascaisHighlight;

  /// No description provided for @nbBaixaChiadoDesc.
  ///
  /// In en, this message translates to:
  /// **'Lisbon\'s beating heart — historic grandeur meets a lively commercial and cultural scene.'**
  String get nbBaixaChiadoDesc;

  /// No description provided for @nbBaixaChiadoHighlight.
  ///
  /// In en, this message translates to:
  /// **'Historic centre, great transit'**
  String get nbBaixaChiadoHighlight;

  /// No description provided for @nbBoavistaDesc.
  ///
  /// In en, this message translates to:
  /// **'Porto\'s prestigious business and residential corridor with excellent urban amenities.'**
  String get nbBoavistaDesc;

  /// No description provided for @nbBoavistaHighlight.
  ///
  /// In en, this message translates to:
  /// **'Porto\'s premier investment district'**
  String get nbBoavistaHighlight;

  /// No description provided for @nbFozDouroDesc.
  ///
  /// In en, this message translates to:
  /// **'Exclusive riverside neighbourhood with ocean views, parks and upscale dining.'**
  String get nbFozDouroDesc;

  /// No description provided for @nbFozDouroHighlight.
  ///
  /// In en, this message translates to:
  /// **'Porto\'s most desirable address'**
  String get nbFozDouroHighlight;

  /// No description provided for @nbSantoAntonioDesc.
  ///
  /// In en, this message translates to:
  /// **'Central Lisbon neighbourhood with top-tier healthcare, schools and safety scores.'**
  String get nbSantoAntonioDesc;

  /// No description provided for @nbSantoAntonioHighlight.
  ///
  /// In en, this message translates to:
  /// **'Best for families in central Lisbon'**
  String get nbSantoAntonioHighlight;

  /// No description provided for @nbBragaCentroDesc.
  ///
  /// In en, this message translates to:
  /// **'Northern gem combining historic charm with a thriving university city energy.'**
  String get nbBragaCentroDesc;

  /// No description provided for @nbBragaCentroHighlight.
  ///
  /// In en, this message translates to:
  /// **'Fastest growing city centre'**
  String get nbBragaCentroHighlight;

  /// No description provided for @amenityTransportation.
  ///
  /// In en, this message translates to:
  /// **'Transport'**
  String get amenityTransportation;

  /// No description provided for @amenityEducation.
  ///
  /// In en, this message translates to:
  /// **'Schools'**
  String get amenityEducation;

  /// No description provided for @amenityHealthcare.
  ///
  /// In en, this message translates to:
  /// **'Healthcare'**
  String get amenityHealthcare;

  /// No description provided for @amenityShopping.
  ///
  /// In en, this message translates to:
  /// **'Shopping'**
  String get amenityShopping;

  /// No description provided for @amenitySafety.
  ///
  /// In en, this message translates to:
  /// **'Safety'**
  String get amenitySafety;

  /// No description provided for @amenityReligion.
  ///
  /// In en, this message translates to:
  /// **'Religion'**
  String get amenityReligion;

  /// No description provided for @amenityRecreation.
  ///
  /// In en, this message translates to:
  /// **'Parks'**
  String get amenityRecreation;

  /// No description provided for @mapTitleFallback.
  ///
  /// In en, this message translates to:
  /// **'Map'**
  String get mapTitleFallback;

  /// No description provided for @mapCenterTooltip.
  ///
  /// In en, this message translates to:
  /// **'Center map'**
  String get mapCenterTooltip;

  /// No description provided for @mapPlacesFound.
  ///
  /// In en, this message translates to:
  /// **'{total} places found'**
  String mapPlacesFound(int total);

  /// No description provided for @mapPlacesNearby.
  ///
  /// In en, this message translates to:
  /// **'{total} places nearby'**
  String mapPlacesNearby(int total);

  /// No description provided for @mapCategoryCount.
  ///
  /// In en, this message translates to:
  /// **'{total} {category}'**
  String mapCategoryCount(int total, String category);

  /// No description provided for @amenityCountLabel.
  ///
  /// In en, this message translates to:
  /// **'{label} ({count})'**
  String amenityCountLabel(String label, int count);

  /// No description provided for @amenityMinWalk.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min walk'**
  String amenityMinWalk(int minutes);

  /// No description provided for @amenityMinDrive.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min drive'**
  String amenityMinDrive(int minutes);

  /// No description provided for @paywallBadge.
  ///
  /// In en, this message translates to:
  /// **'Go Pro'**
  String get paywallBadge;

  /// No description provided for @paywallTitle.
  ///
  /// In en, this message translates to:
  /// **'Unlock the full Bairrolyze'**
  String get paywallTitle;

  /// No description provided for @paywallSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Make confident decisions with every insight at your fingertips.'**
  String get paywallSubtitle;

  /// No description provided for @paywallRestore.
  ///
  /// In en, this message translates to:
  /// **'Restore purchases'**
  String get paywallRestore;

  /// No description provided for @paywallCancelAnytime.
  ///
  /// In en, this message translates to:
  /// **'Cancel anytime. Billed monthly.'**
  String get paywallCancelAnytime;

  /// No description provided for @paywallMostPopular.
  ///
  /// In en, this message translates to:
  /// **'MOST POPULAR'**
  String get paywallMostPopular;

  /// No description provided for @paywallStartPro.
  ///
  /// In en, this message translates to:
  /// **'Start Pro — {price}/mo'**
  String paywallStartPro(String price);

  /// No description provided for @paywallTryPremium.
  ///
  /// In en, this message translates to:
  /// **'Try Premium — {price}/mo'**
  String paywallTryPremium(String price);

  /// No description provided for @paywallFreePrice.
  ///
  /// In en, this message translates to:
  /// **'€0 / forever'**
  String get paywallFreePrice;

  /// No description provided for @paywallPerMonth.
  ///
  /// In en, this message translates to:
  /// **'{price} / month'**
  String paywallPerMonth(String price);

  /// No description provided for @tierFree.
  ///
  /// In en, this message translates to:
  /// **'Free'**
  String get tierFree;

  /// No description provided for @tierPro.
  ///
  /// In en, this message translates to:
  /// **'Pro'**
  String get tierPro;

  /// No description provided for @tierPremium.
  ///
  /// In en, this message translates to:
  /// **'Premium'**
  String get tierPremium;

  /// No description provided for @featFree2Comparisons.
  ///
  /// In en, this message translates to:
  /// **'2 property comparisons'**
  String get featFree2Comparisons;

  /// No description provided for @featFree1Alert.
  ///
  /// In en, this message translates to:
  /// **'1 neighbourhood alert'**
  String get featFree1Alert;

  /// No description provided for @featFreeCoreAnalysis.
  ///
  /// In en, this message translates to:
  /// **'Core analysis & maps'**
  String get featFreeCoreAnalysis;

  /// No description provided for @featProUnlimitedComparisons.
  ///
  /// In en, this message translates to:
  /// **'Unlimited comparisons'**
  String get featProUnlimitedComparisons;

  /// No description provided for @featPro10Alerts.
  ///
  /// In en, this message translates to:
  /// **'10 neighbourhood alerts'**
  String get featPro10Alerts;

  /// No description provided for @featProPriority.
  ///
  /// In en, this message translates to:
  /// **'Priority analysis'**
  String get featProPriority;

  /// No description provided for @featProTimeline.
  ///
  /// In en, this message translates to:
  /// **'Historical timeline'**
  String get featProTimeline;

  /// No description provided for @featPremiumEverythingPro.
  ///
  /// In en, this message translates to:
  /// **'Everything in Pro'**
  String get featPremiumEverythingPro;

  /// No description provided for @featPremium99Alerts.
  ///
  /// In en, this message translates to:
  /// **'99 alerts with push notifications'**
  String get featPremium99Alerts;

  /// No description provided for @featPremiumAiInsights.
  ///
  /// In en, this message translates to:
  /// **'AI investment insights'**
  String get featPremiumAiInsights;

  /// No description provided for @featPremiumForecasting.
  ///
  /// In en, this message translates to:
  /// **'Trend forecasting'**
  String get featPremiumForecasting;

  /// No description provided for @paywallErrProductUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Product not available. Please try again.'**
  String get paywallErrProductUnavailable;

  /// No description provided for @paywallErrGeneric.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get paywallErrGeneric;

  /// No description provided for @paywallErrNoPurchases.
  ///
  /// In en, this message translates to:
  /// **'No active purchases found on this account.'**
  String get paywallErrNoPurchases;

  /// No description provided for @paywallErrPaymentPending.
  ///
  /// In en, this message translates to:
  /// **'Payment is pending. Check your payment method.'**
  String get paywallErrPaymentPending;

  /// No description provided for @paywallErrRegion.
  ///
  /// In en, this message translates to:
  /// **'Product not available in your region.'**
  String get paywallErrRegion;

  /// No description provided for @paywallErrPurchaseFailed.
  ///
  /// In en, this message translates to:
  /// **'Purchase failed. Please try again.'**
  String get paywallErrPurchaseFailed;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'pt'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'pt':
      return AppLocalizationsPt();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
