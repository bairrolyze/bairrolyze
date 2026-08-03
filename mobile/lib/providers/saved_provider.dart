import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/address_model.dart';
import '../models/score_model.dart';
import 'analysis_provider.dart' show SearchHistoryEntry;

/// Explicitly bookmarked analyses, persisted to Hive so they survive restarts.
/// This is distinct from the in-memory recent-search history: entries only
/// appear here when the user taps the bookmark on a result.
final savedProvider =
    StateNotifierProvider<SavedNotifier, List<SearchHistoryEntry>>(
  (ref) => SavedNotifier(),
);

class SavedNotifier extends StateNotifier<List<SearchHistoryEntry>> {
  SavedNotifier() : super(const []) {
    _load();
  }

  static const _boxName = 'saved_analyses';
  static const _key = 'entries';

  Box get _box => Hive.box(_boxName);

  /// Stable identity for a place — its display address, normalised.
  static String keyFor(AddressModel a) => a.displayAddress.trim().toLowerCase();

  bool isSaved(AddressModel address) {
    final k = keyFor(address);
    return state.any((e) => keyFor(e.address) == k);
  }

  /// Toggle the saved state for the current analysis. Returns the new state
  /// (true = now saved).
  bool toggle(AddressModel address, AnalysisResult result) {
    if (isSaved(address)) {
      remove(keyFor(address));
      return false;
    }
    final entry = SearchHistoryEntry(
      id: keyFor(address),
      address: address,
      score: result.score,
      result: result,
      timestamp: DateTime.now(),
    );
    state = [entry, ...state];
    _persist();
    return true;
  }

  void remove(String id) {
    state = state.where((e) => e.id != id).toList();
    _persist();
  }

  void clear() {
    state = const [];
    _persist();
  }

  // ── Persistence ─────────────────────────────────────────────────────────
  void _load() {
    try {
      final raw = _box.get(_key) as String?;
      if (raw == null || raw.isEmpty) return;
      final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
      state = list
          .map(_fromJson)
          .whereType<SearchHistoryEntry>()
          .toList(growable: false);
    } catch (_) {
      // Corrupt/legacy data — start clean rather than crash.
      state = const [];
    }
  }

  void _persist() {
    _box.put(_key, jsonEncode(state.map(_toJson).toList()));
  }

  Map<String, dynamic> _toJson(SearchHistoryEntry e) => {
        'id': e.id,
        'address': e.address.toJson(),
        'result': e.result?.toJson(),
        'timestamp': e.timestamp.toIso8601String(),
      };

  SearchHistoryEntry? _fromJson(Map<String, dynamic> j) {
    final resultMap = j['result'];
    if (resultMap == null) return null; // only full analyses are restorable
    final result =
        AnalysisResult.fromJson((resultMap as Map).cast<String, dynamic>());
    final address =
        AddressModel.fromJson((j['address'] as Map).cast<String, dynamic>());
    return SearchHistoryEntry(
      id: j['id'] as String? ?? keyFor(address),
      address: address,
      score: result.score,
      result: result,
      timestamp:
          DateTime.tryParse(j['timestamp'] as String? ?? '') ?? DateTime.now(),
    );
  }
}
