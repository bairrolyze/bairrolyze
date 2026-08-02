import '../models/user_preferences_model.dart';

/// A single selectable priority shown during onboarding. Each priority maps to
/// the [UserProfile] it most strongly implies, so the captured selection can be
/// resolved into a scoring persona.
class OnboardingPriority {
  final String key;
  final String label;
  final String emoji;
  final UserProfile profile;

  const OnboardingPriority({
    required this.key,
    required this.label,
    required this.emoji,
    required this.profile,
  });
}

/// The canonical set of onboarding priorities. Order is meaningful: it defines
/// the tie-break order used by [profileFromPriorities].
const List<OnboardingPriority> onboardingPriorities = [
  OnboardingPriority(
    key: 'schools',
    label: 'Good schools',
    emoji: '🎓',
    profile: UserProfile.family,
  ),
  OnboardingPriority(
    key: 'commute',
    label: 'Short commute',
    emoji: '🚆',
    profile: UserProfile.professional,
  ),
  OnboardingPriority(
    key: 'social',
    label: 'Shops & nightlife',
    emoji: '🛍️',
    profile: UserProfile.student,
  ),
  OnboardingPriority(
    key: 'healthcare',
    label: 'Healthcare nearby',
    emoji: '🏥',
    profile: UserProfile.retired,
  ),
  OnboardingPriority(
    key: 'safety',
    label: 'Safe & quiet',
    emoji: '🛡️',
    profile: UserProfile.retired,
  ),
  OnboardingPriority(
    key: 'rental',
    label: 'Rental potential',
    emoji: '📈',
    profile: UserProfile.investor,
  ),
];

/// Resolves a scoring [UserProfile] from the user's selected priority keys.
///
/// Iterates [selectedKeys] in order and returns the profile of the first key
/// that matches an [onboardingPriorities] entry. Returns
/// [UserProfile.defaultProfile] if nothing matches or the list is empty.
UserProfile profileFromPriorities(List<String> selectedKeys) {
  for (final key in selectedKeys) {
    for (final priority in onboardingPriorities) {
      if (priority.key == key) return priority.profile;
    }
  }
  return UserProfile.defaultProfile;
}
