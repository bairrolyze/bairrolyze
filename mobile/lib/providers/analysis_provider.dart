import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../models/address_model.dart';
import '../models/score_model.dart';
import '../models/amenity_model.dart';
import '../services/api_service.dart';
import '../services/cache_service.dart';

enum AnalysisStatus {
  idle,
  addressFound,
  mapReady,
  fetchingAmenities,
  checkingCrime,
  scoring,
  generatingSummary,
  done,
  error,
}

class AnalysisState {
  final AnalysisStatus status;
  final AddressModel? address;
  final AnalysisResult? result;
  final String? error;
  final String statusMessage;
  final int progress; // 0-100, real backend value from job.progress

  const AnalysisState({
    this.status = AnalysisStatus.idle,
    this.address,
    this.result,
    this.error,
    this.statusMessage = '',
    this.progress = 0,
  });

  AnalysisState copyWith({
    AnalysisStatus? status,
    AddressModel? address,
    AnalysisResult? result,
    String? error,
    String? statusMessage,
    int? progress,
  }) =>
      AnalysisState(
        status: status ?? this.status,
        address: address ?? this.address,
        result: result ?? this.result,
        error: error ?? this.error,
        statusMessage: statusMessage ?? this.statusMessage,
        progress: progress ?? this.progress,
      );

  bool get isLoading => [
        AnalysisStatus.addressFound,
        AnalysisStatus.mapReady,
        AnalysisStatus.fetchingAmenities,
        AnalysisStatus.checkingCrime,
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
      status: AnalysisStatus.addressFound,
      statusMessage: 'Locating address...',
      error: null,
      progress: 0,
    );

    try {
      final api = _ref.read(apiServiceProvider);
      final cache = _ref.read(cacheServiceProvider);

      final cacheKey = 'analysis_${rawAddress}_$profile';
      final cached = cache.get<Map<String, dynamic>>(cacheKey);
      if (cached != null) {
        final result = AnalysisResult.fromJson(cached);
        final addr = _addressFromPayload(cached, rawAddress, countryCode);
        state = state.copyWith(
          status: AnalysisStatus.done,
          result: result,
          address: addr,
        );
        return;
      }

      // Kick off the background job pipeline (returns immediately with an
      // analysis_id; the 4 real stages — geocode -> amenities -> score ->
      // AI summary — run server-side and are streamed back below).
      final analysisId = await api.createAnalysisJob(
        address: rawAddress,
        countryCode: countryCode,
        profile: profile,
        radius: 2000,
      );

      Map<String, dynamic>? finalPayload;
      String? firstStageError;

      await for (final event in api.streamAnalysis(analysisId)) {
        switch (event.event) {
          case 'stage':
            final stage = event.data['stage'] as String?;
            final status = event.data['status'] as String?;
            final progress = (event.data['progress'] as num?)?.toInt();
            if (status == 'running') {
              state = state.copyWith(
                status: _stageToStatus(stage),
                statusMessage: _stageToMessage(stage),
                progress: progress,
              );
            } else if (status == 'done' && progress != null) {
              // Bump progress on completion too, so the bar advances even
              // if the UI missed the "running" tick for a very fast stage.
              state = state.copyWith(progress: progress);
            } else if (status == 'error') {
              firstStageError ??= event.data['error'] as String?;
            }
            break;
          case 'complete':
            finalPayload = event.data['final'] as Map<String, dynamic>?;
            final progress = (event.data['progress'] as num?)?.toInt();
            if (progress != null) state = state.copyWith(progress: progress);
            break;
          case 'error':
            firstStageError ??= event.data['message'] as String? ?? 'job not found or expired';
            break;
          case 'timeout':
            firstStageError ??= 'timeout: analysis is taking too long';
            break;
        }
      }

      if (finalPayload == null) {
        throw Exception(firstStageError ?? 'Analysis failed');
      }

      final data = finalPayload;
      final result = AnalysisResult.fromJson(data);
      final address = _addressFromPayload(data, rawAddress, countryCode);

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

  /// Builds a full [AddressModel] from an analysis payload's `address` block,
  /// preserving coordinates (needed for Street View) and the geocoded
  /// display name / city. Used by both the cached and freshly-fetched paths so
  /// cached results keep their lat/lng and full address just like new ones.
  AddressModel _addressFromPayload(
    Map<String, dynamic> data,
    String rawAddress,
    String countryCode,
  ) {
    final geoData = data['address'] as Map<String, dynamic>?;
    if (geoData == null) {
      return AddressModel(
        displayAddress: rawAddress,
        countryCode: countryCode,
      );
    }
    return AddressModel(
      displayAddress: geoData['display_name'] as String? ?? rawAddress,
      street: geoData['street'] as String? ?? geoData['road'] as String?,
      number: geoData['number'] as String? ??
          geoData['house_number'] as String?,
      district:
          geoData['district'] as String? ?? geoData['suburb'] as String?,
      postalCode:
          geoData['postcode'] as String? ?? geoData['postal_code'] as String?,
      city: geoData['city'] as String?,
      country: geoData['country'] as String? ?? 'Portugal',
      countryCode: countryCode,
      lat: (geoData['lat'] as num?)?.toDouble(),
      lng: (geoData['lng'] as num?)?.toDouble(),
      id: _uuid.v4(),
    );
  }

  /// Maps a backend pipeline stage name to the existing (already-real, no
  /// longer cosmetic) [AnalysisStatus] value driven by SSE "stage" events.
  AnalysisStatus _stageToStatus(String? stage) {
    switch (stage) {
      case 'address_found':
        return AnalysisStatus.addressFound;
      case 'map_ready':
        return AnalysisStatus.mapReady;
      case 'amenities_ready':
        return AnalysisStatus.fetchingAmenities;
      case 'crime_ready':
        return AnalysisStatus.checkingCrime;
      case 'score_ready':
        return AnalysisStatus.scoring;
      case 'summary_ready':
        return AnalysisStatus.generatingSummary;
      default:
        return state.status;
    }
  }

  String _stageToMessage(String? stage) {
    switch (stage) {
      case 'address_found':
        return 'Locating address...';
      case 'map_ready':
        return 'Preparing the map...';
      case 'amenities_ready':
        return 'Finding nearby amenities...';
      case 'crime_ready':
        return 'Checking crime statistics...';
      case 'score_ready':
        return 'Calculating location score...';
      case 'summary_ready':
        return 'Generating AI summary...';
      default:
        return state.statusMessage;
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
