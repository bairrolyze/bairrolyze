enum UserProfile {
  defaultProfile,
  family,
  student,
  professional,
  retired,
  investor,
}

extension UserProfileJson on UserProfile {
  String get jsonValue => switch (this) {
        UserProfile.defaultProfile => 'default',
        UserProfile.family => 'family',
        UserProfile.student => 'student',
        UserProfile.professional => 'professional',
        UserProfile.retired => 'retired',
        UserProfile.investor => 'investor',
      };

  static UserProfile fromJson(String value) => switch (value) {
        'family' => UserProfile.family,
        'student' => UserProfile.student,
        'professional' => UserProfile.professional,
        'retired' => UserProfile.retired,
        'investor' => UserProfile.investor,
        _ => UserProfile.defaultProfile,
      };
}

extension UserProfileDisplay on UserProfile {
  String get emoji => switch (this) {
        UserProfile.defaultProfile => '🏠',
        UserProfile.family => '👨‍👩‍👧',
        UserProfile.student => '🎓',
        UserProfile.professional => '💼',
        UserProfile.retired => '🌿',
        UserProfile.investor => '📈',
      };

  String get label => switch (this) {
        UserProfile.defaultProfile => 'General',
        UserProfile.family => 'Family',
        UserProfile.student => 'Student',
        UserProfile.professional => 'Professional',
        UserProfile.retired => 'Retired',
        UserProfile.investor => 'Investor',
      };
}

class UserPreferences {
  final UserProfile profile;
  final String defaultCountry;
  final bool useDarkMode;
  final bool useSystemTheme;
  final bool showAiSummary;
  final double searchRadius;
  final bool onboardingComplete;
  final List<String> priorities;

  /// Runtime-only flag set by the provider once SharedPreferences has finished
  /// loading. Never persisted (not in toJson / fromJson); used to avoid
  /// flashing onboarding before prefs are ready.
  final bool initialized;

  const UserPreferences({
    this.profile = UserProfile.defaultProfile,
    this.defaultCountry = 'PT',
    this.useDarkMode = false,
    this.useSystemTheme = true,
    this.showAiSummary = true,
    this.searchRadius = 2000.0,
    this.onboardingComplete = false,
    this.priorities = const [],
    this.initialized = false,
  });

  UserPreferences copyWith({
    UserProfile? profile,
    String? defaultCountry,
    bool? useDarkMode,
    bool? useSystemTheme,
    bool? showAiSummary,
    double? searchRadius,
    bool? onboardingComplete,
    List<String>? priorities,
    bool? initialized,
  }) =>
      UserPreferences(
        profile: profile ?? this.profile,
        defaultCountry: defaultCountry ?? this.defaultCountry,
        useDarkMode: useDarkMode ?? this.useDarkMode,
        useSystemTheme: useSystemTheme ?? this.useSystemTheme,
        showAiSummary: showAiSummary ?? this.showAiSummary,
        searchRadius: searchRadius ?? this.searchRadius,
        onboardingComplete: onboardingComplete ?? this.onboardingComplete,
        priorities: priorities ?? this.priorities,
        initialized: initialized ?? this.initialized,
      );

  factory UserPreferences.fromJson(Map<String, dynamic> json) => UserPreferences(
        profile: UserProfileJson.fromJson(json['profile'] as String? ?? 'default'),
        defaultCountry: json['default_country'] as String? ?? 'PT',
        useDarkMode: json['use_dark_mode'] as bool? ?? false,
        useSystemTheme: json['use_system_theme'] as bool? ?? true,
        showAiSummary: json['show_ai_summary'] as bool? ?? true,
        searchRadius: (json['search_radius'] as num?)?.toDouble() ?? 2000.0,
        onboardingComplete: json['onboarding_complete'] as bool? ?? false,
        priorities: (json['priorities'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            const [],
      );

  Map<String, dynamic> toJson() => {
        'profile': profile.jsonValue,
        'default_country': defaultCountry,
        'use_dark_mode': useDarkMode,
        'use_system_theme': useSystemTheme,
        'show_ai_summary': showAiSummary,
        'search_radius': searchRadius,
        'onboarding_complete': onboardingComplete,
        'priorities': priorities,
      };
}
