import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../config/app_constants.dart';
import '../../config/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../../models/address_model.dart';
import '../../models/user_preferences_model.dart';
import '../../providers/country_provider.dart';
import '../../providers/locale_provider.dart';
import '../../providers/preferences_provider.dart';
import '../../providers/theme_provider.dart';
import '../docs/docs_screen.dart';
import '../tutorial/tutorial_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs           = ref.watch(preferencesProvider);
    final themeMode       = ref.watch(themeModeProvider);
    final locale          = ref.watch(localeProvider);
    final countriesAsync  = ref.watch(countriesProvider);
    final selectedCountry = ref.watch(selectedCountryProvider);
    final top             = MediaQuery.of(context).padding.top;
    final p                = AppPalette.of(context);
    final l                = AppLocalizations.of(context);

    return Container(
      color: p.bg,
      child: ListView(
          padding: EdgeInsets.fromLTRB(0, top + 20, 0, 60),
          children: [
            // ── Title ───────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
              child: Text(
                l.settingsTitle,
                style: TextStyle(
                  color: p.textPrimary,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.8,
                ),
              ),
            ),

            // ── Profile ──────────────────────────────────────────────────
            _SectionHeader(l.settingsSectionProfile),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _ProfileGrid(
                selected: prefs.profile,
                onSelect: (profile) =>
                    ref.read(preferencesProvider.notifier).setProfile(profile),
              ),
            ),

            // ── Language ─────────────────────────────────────────────────
            _SectionHeader(l.settingsSectionLanguage),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _DarkCard(
                child: Row(
                  children: [
                    _LanguageChip(
                      label: l.languagePortuguese,
                      flag: '🇵🇹',
                      active: locale.languageCode == 'pt',
                      onTap: () => ref
                          .read(localeProvider.notifier)
                          .setLocale(const Locale('pt')),
                    ),
                    const SizedBox(width: 8),
                    _LanguageChip(
                      label: l.languageEnglish,
                      flag: '🇬🇧',
                      active: locale.languageCode == 'en',
                      onTap: () => ref
                          .read(localeProvider.notifier)
                          .setLocale(const Locale('en')),
                    ),
                  ],
                ),
              ),
            ),

            // ── Country ──────────────────────────────────────────────────
            _SectionHeader(l.settingsSectionCountry),
            countriesAsync.when(
              data: (countries) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _DarkCard(
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<CountryConfig>(
                      value: selectedCountry,
                      isExpanded: true,
                      dropdownColor: p.surface2,
                      icon: Icon(Icons.expand_more_rounded,
                          color: p.textTertiary, size: 18),
                      style: TextStyle(
                          color: p.textPrimary, fontSize: 14),
                      items: countries
                          .map((c) => DropdownMenuItem(
                                value: c,
                                child: Row(
                                  children: [
                                    Text(_flag(c.code),
                                        style:
                                            const TextStyle(fontSize: 16)),
                                    const SizedBox(width: 10),
                                    Text(c.name,
                                        style: TextStyle(
                                            color: p.textPrimary,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500)),
                                  ],
                                ),
                              ))
                          .toList(),
                      onChanged: (c) {
                        if (c != null) {
                          ref
                              .read(selectedCountryProvider.notifier)
                              .select(c);
                        }
                      },
                    ),
                  ),
                ),
              ),
              loading: () => const LinearProgressIndicator(color: AppColors.accent),
              error: (_, __) => const SizedBox(),
            ),

            // ── Search radius ─────────────────────────────────────────────
            _SectionHeader(l.settingsSectionSearchRadius),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _DarkCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          l.settingsRadiusLabel(
                              (prefs.searchRadius / 1000).toStringAsFixed(1)),
                          style: TextStyle(
                            color: p.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          l.settingsRadiusMeters(prefs.searchRadius.round()),
                          style: TextStyle(
                            color: p.textTertiary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    SliderTheme(
                      data: SliderThemeData(
                        activeTrackColor: AppColors.accent,
                        thumbColor: AppColors.accent,
                        overlayColor: AppColors.accent.withValues(alpha: 0.12),
                        inactiveTrackColor: p.border,
                        trackHeight: 3,
                        thumbShape: const RoundSliderThumbShape(
                            enabledThumbRadius: 7),
                      ),
                      child: Slider(
                        value: prefs.searchRadius,
                        min: 500,
                        max: 5000,
                        divisions: 9,
                        onChanged: (v) => ref
                            .read(preferencesProvider.notifier)
                            .setSearchRadius(v),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('500m',
                            style: TextStyle(
                                color: p.textTertiary,
                                fontSize: 11)),
                        Text('5km',
                            style: TextStyle(
                                color: p.textTertiary,
                                fontSize: 11)),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // ── Appearance ───────────────────────────────────────────────
            _SectionHeader(l.settingsSectionAppearance),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _DarkCard(
                child: Row(
                  children: [
                    _ThemeChip(
                      icon: Icons.brightness_auto_rounded,
                      label: l.themeSystem,
                      active: themeMode == ThemeMode.system,
                      onTap: () => ref
                          .read(themeModeProvider.notifier)
                          .setTheme(ThemeMode.system),
                    ),
                    const SizedBox(width: 8),
                    _ThemeChip(
                      icon: Icons.light_mode_rounded,
                      label: l.themeLight,
                      active: themeMode == ThemeMode.light,
                      onTap: () => ref
                          .read(themeModeProvider.notifier)
                          .setTheme(ThemeMode.light),
                    ),
                    const SizedBox(width: 8),
                    _ThemeChip(
                      icon: Icons.dark_mode_rounded,
                      label: l.themeDark,
                      active: themeMode == ThemeMode.dark,
                      onTap: () => ref
                          .read(themeModeProvider.notifier)
                          .setTheme(ThemeMode.dark),
                    ),
                  ],
                ),
              ),
            ),

            // ── AI Summary ───────────────────────────────────────────────
            _SectionHeader(l.settingsSectionAiFeatures),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _DarkCard(
                child: Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: AppColors.accent2.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.auto_awesome_rounded,
                          color: AppColors.accent2, size: 17),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l.aiSummaryTitle,
                            style: TextStyle(
                              color: p.textPrimary,
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            l.aiSummarySubtitle,
                            style: TextStyle(
                              color: p.textTertiary,
                              fontSize: 11.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: prefs.showAiSummary,
                      activeThumbColor: AppColors.accent2,
                      onChanged: (v) => ref
                          .read(preferencesProvider.notifier)
                          .setShowAiSummary(v),
                    ),
                  ],
                ),
              ),
            ),

            // ── Help ─────────────────────────────────────────────────────
            _SectionHeader(l.settingsSectionHelp),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _DarkCard(
                child: Column(
                  children: [
                    // Guides & docs
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => DocsScreen.show(context),
                      child: Row(
                        children: [
                          Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: AppColors.accent.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.library_books_rounded,
                                color: AppColors.accent, size: 17),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l.helpGuidesTitle,
                                  style: TextStyle(
                                    color: p.textPrimary,
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  l.helpGuidesSubtitle,
                                  style: TextStyle(
                                    color: p.textTertiary,
                                    fontSize: 11.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(Icons.chevron_right_rounded,
                              color: p.textTertiary, size: 20),
                        ],
                      ),
                    ),
                    Divider(height: 24, color: p.border),
                    // Quick tour
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => TutorialScreen.show(context),
                      child: Row(
                        children: [
                          Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: AppColors.accent2.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.play_circle_outline_rounded,
                                color: AppColors.accent2, size: 17),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l.helpTourTitle,
                                  style: TextStyle(
                                    color: p.textPrimary,
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  l.helpTourSubtitle,
                                  style: TextStyle(
                                    color: p.textTertiary,
                                    fontSize: 11.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(Icons.chevron_right_rounded,
                              color: p.textTertiary, size: 20),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Legal ────────────────────────────────────────────────────
            _SectionHeader('LEGAL'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _DarkCard(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () async {
                    final uri = Uri.parse(AppConstants.privacyPolicyUrl);
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  },
                  child: Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: AppColors.accent.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.privacy_tip_outlined,
                            color: AppColors.accent, size: 17),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Privacy Policy',
                          style: TextStyle(
                            color: p.textPrimary,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Icon(Icons.open_in_new_rounded,
                          color: p.textTertiary, size: 18),
                    ],
                  ),
                ),
              ),
            ),

            // ── Version footer ───────────────────────────────────────────
            const SizedBox(height: 32),
            Center(
              child: Text(
                'Bairrolyze v2.0 · OSM · OpenAI',
                style: TextStyle(
                  color: p.textTertiary,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
    );
  }

  String _flag(String code) {
    const flags = {
      'PT': '🇵🇹',
      'ES': '🇪🇸',
      'GB': '🇬🇧',
      'FR': '🇫🇷',
      'DE': '🇩🇪',
    };
    return flags[code] ?? '🌍';
  }
}

// ── Profile grid ──────────────────────────────────────────────────────────────

class _ProfileGrid extends StatelessWidget {
  final UserProfile selected;
  final ValueChanged<UserProfile> onSelect;
  const _ProfileGrid({required this.selected, required this.onSelect});

  static const _profiles = [
    (UserProfile.defaultProfile, '🏠'),
    (UserProfile.family,         '👨‍👩‍👧'),
    (UserProfile.student,        '🎓'),
    (UserProfile.professional,   '💼'),
    (UserProfile.retired,        '🌿'),
    (UserProfile.investor,       '📈'),
  ];

  static String _label(AppLocalizations l, UserProfile profile) =>
      switch (profile) {
        UserProfile.defaultProfile => l.profileGeneral,
        UserProfile.family => l.profileFamily,
        UserProfile.student => l.profileStudent,
        UserProfile.professional => l.profilePro,
        UserProfile.retired => l.profileRetired,
        UserProfile.investor => l.profileInvestor,
      };

  @override
  Widget build(BuildContext context) {
    final pal = AppPalette.of(context);
    final l = AppLocalizations.of(context);
    return GridView.count(
      crossAxisCount: 3,
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.55,
      children: _profiles.map((profile) {
        final active = selected == profile.$1;
        return GestureDetector(
          onTap: () => onSelect(profile.$1),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            decoration: BoxDecoration(
              color: active
                  ? AppColors.accent.withValues(alpha: 0.14)
                  : pal.surface2,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: active ? AppColors.accent : pal.border,
                width: active ? 1.5 : 1,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(profile.$2, style: const TextStyle(fontSize: 20)),
                const SizedBox(height: 4),
                Text(
                  _label(l, profile.$1),
                  style: TextStyle(
                    color: active ? AppColors.accent : pal.textSecondary,
                    fontSize: 11.5,
                    fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ── Theme chip ────────────────────────────────────────────────────────────────

class _ThemeChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _ThemeChip({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final pal = AppPalette.of(context);
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: active ? AppColors.accent.withValues(alpha: 0.14) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: active ? AppColors.accent : pal.border,
              width: 1.5,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon,
                  size: 16,
                  color:
                      active ? AppColors.accent : pal.textTertiary),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color:
                      active ? AppColors.accent : pal.textTertiary,
                  fontSize: 11,
                  fontWeight:
                      active ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Language chip ─────────────────────────────────────────────────────────────

class _LanguageChip extends StatelessWidget {
  final String label;
  final String flag;
  final bool active;
  final VoidCallback onTap;
  const _LanguageChip({
    required this.label,
    required this.flag,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final pal = AppPalette.of(context);
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            color: active ? AppColors.accent.withValues(alpha: 0.14) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: active ? AppColors.accent : pal.border,
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(flag, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: active ? AppColors.accent : pal.textSecondary,
                  fontSize: 13,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Section header ────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    final pal = AppPalette.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 10),
      child: Text(
        title,
        style: TextStyle(
          color: pal.textTertiary,
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.8,
        ),
      ),
    );
  }
}

// ── Dark card wrapper ─────────────────────────────────────────────────────────

class _DarkCard extends StatelessWidget {
  final Widget child;
  const _DarkCard({required this.child});

  @override
  Widget build(BuildContext context) {
    final pal = AppPalette.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: pal.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: pal.border),
      ),
      child: child,
    );
  }
}
