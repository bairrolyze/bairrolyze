import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../models/address_model.dart';
import '../models/score_model.dart';
import '../models/amenity_model.dart';
import '../services/api_service.dart';
import '../services/cache_service.dart';

enum AnalysisStatus { idle, geocoding, fetchingAmenities, scoring, generatingSummary, done, error }

class AnalysisState {
  final AnalysisStatus status;
  final AddressModel? address;
  final AnalysisResult? result;
  final String? error;
  final String statusMessage;

  const AnalysisState({
    this.status = AnalysisStatus.idle,
    this.address,
    this.result,
    this.error,
    this.statusMessage = '',
  });

  AnalysisState copyWith({
    AnalysisStatus? status,
    AddressModel? address,
    AnalysisResult? result,
    String? error,
    String? statusMessage,
  }) =>
      AnalysisState(
        status: status ?? this.status,
        address: address ?? this.address,
        result: result ?? this.result,
        error: error ?? this.error,
        statusMessage: statusMessage ?? this.statusMessage,
      );

  bool get isLoading => [
        AnalysisStatus.geocoding,
        AnalysisStatus.fetchingAmenities,
        AnalysisStatus.scoring,
        AnalysisStatus.generatingSummary,
      ].contains(status);
}

final analysisProvider =
    StateNotifierProvider<AnalysisNotifier, AnalysisState>(
  (ref) => AnalysisNotifier(ref),
);

class AnalysisNotifier extends StateNotifier<AnalysisState> {
  final Ref _ref;
  static const _uuid = Uuid();

  AnalysisNotifier(this._ref) : super(const AnalysisState());

  Future<void> analyze(
    String rawAddress, {
    String countryCode = 'PT',
    String profile = 'default',
  }) async {
    state = state.copyWith(
      status: AnalysisStatus.geocoding,
      statusMessage: 'Locating address...',
      error: null,
    );

    try {
      final api = _ref.read(apiServiceProvider);
      final cache = _ref.read(cacheServiceProvider);

      final cacheKey = 'analysis_${rawAddress}_$profile';
      final cached = cache.get<Map<String, dynamic>>(cacheKey);
      if (cached != null) {
        final result = AnalysisResult.fromJson(cached);
        final addr = AddressModel(
          displayAddress: rawAddress,
          countryCode: countryCode,
        );
        state = state.copyWith(
          status: AnalysisStatus.done,
          result: result,
          address: addr,
        );
        return;
      }

      // Call the single /analyze endpoint which handles the full pipeline
      state = state.copyWith(
        status: AnalysisStatus.fetchingAmenities,
        statusMessage: 'Analyzing neighborhood...',
      );

      final data = await api.analyzeAddress(
        address: rawAddress,
        countryCode: countryCode,
        profile: profile,
        radius: 2000,
      );

      final result = AnalysisResult.fromJson(data);
      final geoData = data['address'] as Map<String, dynamic>;
      final address = AddressModel(
        displayAddress: geoData['display_name'] as String? ?? rawAddress,
        city: geoData['city'] as String?,
        country: geoData['country'] as String? ?? 'Portugal',
        countryCode: countryCode,
        lat: (geoData['lat'] as num?)?.toDouble(),
        lng: (geoData['lng'] as num?)?.toDouble(),
        id: _uuid.v4(),
      );

      cache.set(cacheKey, data);
      await _ref.read(searchHistoryProvider.notifier).add(address, result);

      state = state.copyWith(
        status: AnalysisStatus.done,
        result: result,
        address: address,
      );
    } catch (e) {
      state = state.copyWith(
        status: AnalysisStatus.error,
        error: _friendlyError(e.toString()),
        statusMessage: '',
      );
    }
  }

  String _friendlyError(String raw) {
    if (raw.contains('404') || raw.contains('not found')) {
      return 'Address not found. Please check and try again.';
    }
    if (raw.contains('Connection refused') || raw.contains('SocketException')) {
      return 'Cannot connect to server. Make sure the backend is running.';
    }
    if (raw.contains('timeout') || raw.contains('TimeoutException')) {
      return 'Request timed out. Please try again.';
    }
    return 'Analysis failed. Please try again.';
  }

  Future<void> loadFromHistory(SearchHistoryEntry entry) async {
    final result = entry.result;
    if (result != null) {
      state = state.copyWith(
        status: AnalysisStatus.done,
        result: result,
        address: entry.address,
        error: null,
        statusMessage: '',
      );
    } else {
      await analyze(entry.address.displayAddress);
    }
  }

  void reset() => state = const AnalysisState();
}

// ── Search history ──────────────────────────────────────────────────────────

final searchHistoryProvider =
    StateNotifierProvider<SearchHistoryNotifier, List<SearchHistoryEntry>>(
  (ref) => SearchHistoryNotifier(),
);

class SearchHistoryEntry {
  final String id;
  final AddressModel address;
  final LocationScore score;
  final AnalysisResult? result;
  final DateTime timestamp;

  const SearchHistoryEntry({
    required this.id,
    required this.address,
    required this.score,
    this.result,
    required this.timestamp,
  });
}

class SearchHistoryNotifier extends StateNotifier<List<SearchHistoryEntry>> {
  SearchHistoryNotifier() : super([]);

  Future<void> add(AddressModel address, AnalysisResult result) async {
    final entry = SearchHistoryEntry(
      id: const Uuid().v4(),
      address: address,
      score: result.score,
      result: result,
      timestamp: DateTime.now(),
    );
    state = [entry, ...state.take(19)];
  }

  void remove(String id) {
    state = state.where((e) => e.id != id).toList();
  }

  void clear() => state = [];
}

// ── Map filter ───────────────────────────────────────────────────────────────

final mapFilterProvider = StateProvider<AmenityCategory?>((ref) => null);

final filteredAmenitiesProvider = Provider<List<AmenityModel>>((ref) {
  final analysis = ref.watch(analysisProvider);
  final filter = ref.watch(mapFilterProvider);
  final amenities = analysis.result?.amenities ?? [];
  if (filter == null) return amenities;
  return amenities.where((a) => a.category == filter).toList();
});
