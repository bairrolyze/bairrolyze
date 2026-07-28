import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/app_theme.dart';
import '../../models/address_model.dart';
import '../../models/user_preferences_model.dart';
import '../../providers/country_provider.dart';
import '../../providers/preferences_provider.dart';
import '../../providers/theme_provider.dart';
import '../docs/docs_screen.dart';
import '../tutorial/tutorial_screen.dart';

// ── Design tokens ──────────────────────────────────────────────────────────────
const _kBg       = Color(0xFF060B14);
const _kSurface  = Color(0xFF0D1625);
const _kSurface2 = Color(0xFF131F33);
const _kBorder   = Color(0xFF1A2845);
const _kAccent   = Color(0xFF3B82F6);
const _kAccent2  = Color(0xFF6C63FF);

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs           = ref.watch(preferencesProvider);
    final themeMode       = ref.watch(themeModeProvider);
    final countriesAsync  = ref.watch(countriesProvider);
    final selectedCountry = ref.watch(selectedCountryProvider);
    final top             = MediaQuery.of(context).padding.top;

    return Theme(
      data: AppTheme.dark(),
      child: Container(
        color: _kBg,
        child: ListView(
          padding: EdgeInsets.fromLTRB(0, top + 20, 0, 60),
          children: [
            // ── Title ───────────────────────────────────────────────────
            const Padding(
              padding: EdgeInsets.fromLTRB(24, 4, 24, 24),
              child: Text(
                'You',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.8,
                ),
              ),
            ),

            // ── Profile ──────────────────────────────────────────────────
            _SectionHeader('PROFILE'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _ProfileGrid(
                selected: prefs.profile,
                onSelect: (p) =>
                    ref.read(preferencesProvider.notifier).setProfile(p),
              ),
            ),

            // ── Country ──────────────────────────────────────────────────
            _SectionHeader('COUNTRY'),
            countriesAsync.when(
              data: (countries) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _DarkCard(
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<CountryConfig>(
                      value: selectedCountry,
                      isExpanded: true,
                      dropdownColor: _kSurface2,
                      icon: Icon(Icons.expand_more_rounded,
                          color: Colors.white.withOpacity(0.4), size: 18),
                      style: const TextStyle(
                          color: Colors.white, fontSize: 14),
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
                                        style: const TextStyle(
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
              loading: () => const LinearProgressIndicator(color: _kAccent),
              error: (_, __) => const SizedBox(),
            ),

            // ── Search radius ─────────────────────────────────────────────
            _SectionHeader('SEARCH RADIUS'),
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
                          '${(prefs.searchRadius / 1000).toStringAsFixed(1)} km radius',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '${(prefs.searchRadius).round()}m',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.4),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    SliderTheme(
                      data: SliderThemeData(
                        activeTrackColor: _kAccent,
                        thumbColor: _kAccent,
                        overlayColor: _kAccent.withOpacity(0.12),
                        inactiveTrackColor: _kBorder,
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
                                color: Colors.white.withOpacity(0.35),
                                fontSize: 11)),
                        Text('5km',
                            style: TextStyle(
                                color: Colors.white.withOpacity(0.35),
                                fontSize: 11)),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // ── Appearance ───────────────────────────────────────────────
            _SectionHeader('APPEARANCE'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _DarkCard(
                child: Row(
                  children: [
                    _ThemeChip(
                      icon: Icons.brightness_auto_rounded,
                      label: 'System',
                      active: themeMode == ThemeMode.system,
                      onTap: () => ref
                          .read(themeModeProvider.notifier)
                          .setTheme(ThemeMode.system),
                    ),
                    const SizedBox(width: 8),
                    _ThemeChip(
                      icon: Icons.light_mode_rounded,
                      label: 'Light',
                      active: themeMode == ThemeMode.light,
                      onTap: () => ref
                          .read(themeModeProvider.notifier)
                          .setTheme(ThemeMode.light),
                    ),
                    const SizedBox(width: 8),
                    _ThemeChip(
                      icon: Icons.dark_mode_rounded,
                      label: 'Dark',
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
            _SectionHeader('AI FEATURES'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _DarkCard(
                child: Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: _kAccent2.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.auto_awesome_rounded,
                          color: _kAccent2, size: 17),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'AI Neighbourhood Summary',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Powered by OpenAI',
                            style: TextStyle(
                              color: Colors.white38,
                              fontSize: 11.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: prefs.showAiSummary,
                      activeColor: _kAccent2,
                      onChanged: (v) => ref
                          .read(preferencesProvider.notifier)
                          .setShowAiSummary(v),
                    ),
                  ],
                ),
              ),
            ),

            // ── Help ─────────────────────────────────────────────────────
            _SectionHeader('HELP'),
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
                              color: _kAccent.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.library_books_rounded,
                                color: _kAccent, size: 17),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Guides & Help',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  '8 in-depth guides for every feature',
                                  style: TextStyle(
                                    color: Colors.white38,
                                    fontSize: 11.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(Icons.chevron_right_rounded,
                              color: Colors.white.withOpacity(0.25), size: 20),
                        ],
                      ),
                    ),
                    Divider(height: 24, color: Colors.white.withOpacity(0.06)),
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
                              color: _kAccent2.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.play_circle_outline_rounded,
                                color: _kAccent2, size: 17),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Quick Tour',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  '5-screen intro to HomeScope',
                                  style: TextStyle(
                                    color: Colors.white38,
                                    fontSize: 11.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(Icons.chevron_right_rounded,
                              color: Colors.white.withOpacity(0.25), size: 20),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Version footer ───────────────────────────────────────────
            const SizedBox(height: 32),
            Center(
              child: Text(
                'HomeScope v2.0 · OSM · OpenAI',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.2),
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
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
    (UserProfile.defaultProfile, '🏠', 'General'),
    (UserProfile.family,         '👨‍👩‍👧', 'Family'),
    (UserProfile.student,        '🎓', 'Student'),
    (UserProfile.professional,   '💼', 'Pro'),
    (UserProfile.retired,        '🌿', 'Retired'),
    (UserProfile.investor,       '📈', 'Investor'),
  ];

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 3,
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.55,
      children: _profiles.map((p) {
        final active = selected == p.$1;
        return GestureDetector(
          onTap: () => onSelect(p.$1),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            decoration: BoxDecoration(
              color: active
                  ? _kAccent.withOpacity(0.14)
                  : _kSurface2,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: active ? _kAccent : Colors.white.withOpacity(0.07),
                width: active ? 1.5 : 1,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(p.$2, style: const TextStyle(fontSize: 20)),
                const SizedBox(height: 4),
                Text(
                  p.$3,
                  style: TextStyle(
                    color: active ? _kAccent : Colors.white.withOpacity(0.6),
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
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: active ? _kAccent.withOpacity(0.14) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: active ? _kAccent : Colors.white.withOpacity(0.08),
              width: 1.5,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon,
                  size: 16,
                  color:
                      active ? _kAccent : Colors.white.withOpacity(0.4)),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color:
                      active ? _kAccent : Colors.white.withOpacity(0.4),
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

// ── Section header ────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 10),
      child: Text(
        title,
        style: TextStyle(
          color: Colors.white.withOpacity(0.32),
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kBorder),
      ),
      child: child,
    );
  }
}
