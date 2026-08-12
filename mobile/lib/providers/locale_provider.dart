import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Languages the app ships with. English is the default; users can switch to
/// Portuguese in Settings (the choice is persisted).
const List<Locale> kSupportedLocales = [
  Locale('en'),
  Locale('pt'),
];

const Locale kDefaultLocale = Locale('en');

/// Drives [MaterialApp.router]'s `locale`. Persisted so the choice survives
/// restarts. Mirrors the pattern in [themeModeProvider].
final localeProvider =
    StateNotifierProvider<LocaleNotifier, Locale>((ref) => LocaleNotifier());

class LocaleNotifier extends StateNotifier<Locale> {
  static const _key = 'app_locale';

  LocaleNotifier() : super(kDefaultLocale) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_key);
    if (code != null) {
      state = _fromCode(code);
    }
  }

  Future<void> setLocale(Locale locale) async {
    if (!_isSupported(locale)) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, locale.languageCode);
    state = locale;
  }

  bool _isSupported(Locale locale) =>
      kSupportedLocales.any((l) => l.languageCode == locale.languageCode);

  Locale _fromCode(String code) => kSupportedLocales.firstWhere(
        (l) => l.languageCode == code,
        orElse: () => kDefaultLocale,
      );
}
