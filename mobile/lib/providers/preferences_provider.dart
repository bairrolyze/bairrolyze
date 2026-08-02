import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user_preferences_model.dart';

final preferencesProvider =
    StateNotifierProvider<PreferencesNotifier, UserPreferences>(
  (ref) => PreferencesNotifier(),
);

class PreferencesNotifier extends StateNotifier<UserPreferences> {
  static const _key = 'user_preferences';

  PreferencesNotifier() : super(const UserPreferences()) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw != null) {
      try {
        state = UserPreferences.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      } catch (_) {
        // Keep defaults if parse fails
      }
    }
    state = state.copyWith(initialized: true);
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(state.toJson()));
  }

  Future<void> setProfile(UserProfile profile) async {
    state = state.copyWith(profile: profile);
    await _save();
  }

  Future<void> setDefaultCountry(String code) async {
    state = state.copyWith(defaultCountry: code);
    await _save();
  }

  Future<void> setSearchRadius(double radius) async {
    state = state.copyWith(searchRadius: radius);
    await _save();
  }

  Future<void> setShowAiSummary(bool show) async {
    state = state.copyWith(showAiSummary: show);
    await _save();
  }

  Future<void> setOnboardingComplete(bool value) async {
    state = state.copyWith(onboardingComplete: value);
    await _save();
  }

  Future<void> setPriorities(List<String> priorities) async {
    state = state.copyWith(priorities: priorities);
    await _save();
  }
}
