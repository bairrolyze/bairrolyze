// Unit tests for AnalysisNotifier's progressive-state consumption of the
// job-based analyze pipeline (POST /analyze -> SSE stream), replacing the
// old single blocking call. These fake ApiService/CacheService rather than
// hitting the network or Hive, so they run as plain Dart tests (no device /
// widget pump required).
//
// Note: tests/widget/test_home_screen.dart already fails against this repo
// pre-existing this change (verified via `git stash` — identical failures
// on main), an unrelated Flutter widget-test-infra issue. Not addressed
// here per scope.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homescope/providers/analysis_provider.dart';
import 'package:homescope/services/api_service.dart';
import 'package:homescope/services/cache_service.dart';

class FakeCacheService extends CacheService {
  final Map<String, dynamic> _store = {};

  @override
  T? get<T>(String key) => _store[key] as T?;

  @override
  Future<void> set(String key, dynamic value, {Duration? ttl}) async {
    _store[key] = value;
  }
}

class FakeApiService extends ApiService {
  FakeApiService(this._events, {this.throwOnCreate});

  final List<SseEvent> _events;
  final Object? throwOnCreate;
  bool jobCreated = false;

  @override
  Future<String> createAnalysisJob({
    required String address,
    required String countryCode,
    required String profile,
    required double radius,
  }) async {
    jobCreated = true;
    if (throwOnCreate != null) throw throwOnCreate!;
    return 'job-1';
  }

  @override
  Stream<SseEvent> streamAnalysis(String analysisId) => Stream.fromIterable(_events);
}

Map<String, dynamic> _finalPayload({String id = 'job-1'}) => {
      'id': id,
      'analyzed_at': '2024-01-01T00:00:00Z',
      'address': {
        'lat': 38.7169,
        'lng': -9.1399,
        'display_name': 'Rua Augusta, Lisboa',
        'country': 'Portugal',
        'city': 'Lisboa',
        'confidence': 1.0,
      },
      'score': {
        'overall': 75.0,
        'categories': <String, dynamic>{},
        'profile': 'default',
        'calculated_at': '2024-01-01T00:00:00Z',
      },
      'amenities': <dynamic>[],
      'ai_summary': 'Great place to live.',
      'profile': 'default',
    };

List<SseEvent> _happyPathEvents() => [
      const SseEvent('stage', {'stage': 'address_found', 'status': 'running', 'progress': 0}),
      const SseEvent('stage', {'stage': 'address_found', 'status': 'done', 'progress': 10}),
      const SseEvent('stage', {'stage': 'map_ready', 'status': 'running', 'progress': 10}),
      const SseEvent('stage', {'stage': 'map_ready', 'status': 'done', 'progress': 25}),
      const SseEvent('stage', {'stage': 'amenities_ready', 'status': 'running', 'progress': 25}),
      const SseEvent('stage', {'stage': 'amenities_ready', 'status': 'done', 'progress': 50}),
      const SseEvent('stage', {'stage': 'crime_ready', 'status': 'running', 'progress': 50}),
      const SseEvent('stage', {'stage': 'crime_ready', 'status': 'done', 'progress': 62}),
      const SseEvent('stage', {'stage': 'score_ready', 'status': 'running', 'progress': 62}),
      const SseEvent('stage', {'stage': 'score_ready', 'status': 'done', 'progress': 78}),
      const SseEvent('stage', {'stage': 'summary_ready', 'status': 'running', 'progress': 78}),
      const SseEvent('stage', {'stage': 'summary_ready', 'status': 'done', 'progress': 90}),
      SseEvent('complete', {
        'status': 'done',
        'progress': 100,
        'partial_failure': false,
        'final': _finalPayload(),
      }),
    ];

void main() {
  group('AnalysisNotifier.analyze (job-based pipeline)', () {
    test('walks through real stage transitions and resolves done with the final payload', () async {
      final fakeApi = FakeApiService(_happyPathEvents());
      final container = ProviderContainer(overrides: [
        apiServiceProvider.overrideWithValue(fakeApi),
        cacheServiceProvider.overrideWithValue(FakeCacheService()),
      ]);
      addTearDown(container.dispose);

      final seenStatuses = <AnalysisStatus>[];
      container.listen<AnalysisState>(
        analysisProvider,
        (previous, next) => seenStatuses.add(next.status),
        fireImmediately: true,
      );

      await container.read(analysisProvider.notifier).analyze('Rua Augusta 150, Lisboa');

      expect(fakeApi.jobCreated, isTrue);

      final finalState = container.read(analysisProvider);
      expect(finalState.status, AnalysisStatus.done);
      expect(finalState.result, isNotNull);
      expect(finalState.result!.score.overall, 75.0);
      expect(finalState.address?.displayAddress, 'Rua Augusta, Lisboa');
      expect(finalState.progress, 100);

      // Real backend stage events drove the enum through every in-progress
      // state, in order, not a cosmetic client-side guess.
      expect(seenStatuses, containsAllInOrder([
        AnalysisStatus.addressFound,
        AnalysisStatus.mapReady,
        AnalysisStatus.fetchingAmenities,
        AnalysisStatus.checkingCrime,
        AnalysisStatus.scoring,
        AnalysisStatus.generatingSummary,
        AnalysisStatus.done,
      ]));

      // searchHistoryProvider is updated once the job completes.
      expect(container.read(searchHistoryProvider), hasLength(1));
    });

    test('cache hit short-circuits without creating a job', () async {
      final fakeApi = FakeApiService(_happyPathEvents());
      final fakeCache = FakeCacheService();
      await fakeCache.set('analysis_Rua Augusta 150, Lisboa_default', _finalPayload());

      final container = ProviderContainer(overrides: [
        apiServiceProvider.overrideWithValue(fakeApi),
        cacheServiceProvider.overrideWithValue(fakeCache),
      ]);
      addTearDown(container.dispose);

      await container.read(analysisProvider.notifier).analyze('Rua Augusta 150, Lisboa');

      expect(fakeApi.jobCreated, isFalse);
      expect(container.read(analysisProvider).status, AnalysisStatus.done);
    });

    test('a mid-pipeline stage failure resolves to a friendly error, not a hang', () async {
      final events = [
        const SseEvent('stage', {'stage': 'address_found', 'status': 'running', 'progress': 0}),
        const SseEvent('stage', {'stage': 'address_found', 'status': 'done', 'progress': 10}),
        const SseEvent('stage', {'stage': 'map_ready', 'status': 'running', 'progress': 10}),
        const SseEvent('stage', {'stage': 'map_ready', 'status': 'done', 'progress': 25}),
        const SseEvent('stage', {'stage': 'amenities_ready', 'status': 'running', 'progress': 25}),
        const SseEvent('stage', {
          'stage': 'amenities_ready',
          'status': 'error',
          'error': 'amenity_fetch_failed: overpass down',
        }),
        const SseEvent('complete', {'status': 'done', 'partial_failure': true, 'final': null}),
      ];
      final fakeApi = FakeApiService(events);
      final container = ProviderContainer(overrides: [
        apiServiceProvider.overrideWithValue(fakeApi),
        cacheServiceProvider.overrideWithValue(FakeCacheService()),
      ]);
      addTearDown(container.dispose);

      await container.read(analysisProvider.notifier).analyze('Rua Augusta 150, Lisboa');

      final state = container.read(analysisProvider);
      expect(state.status, AnalysisStatus.error);
      expect(state.error, isNotNull);
      expect(state.result, isNull);
    });

    test('address-not-found stage error maps through the existing friendly-error copy', () async {
      final events = [
        const SseEvent('stage', {'stage': 'address_found', 'status': 'running', 'progress': 0}),
        const SseEvent('stage', {
          'stage': 'address_found',
          'status': 'error',
          'error': 'not_found: Address not found: nowhere',
        }),
        const SseEvent('complete', {'status': 'done', 'partial_failure': true, 'final': null}),
      ];
      final fakeApi = FakeApiService(events);
      final container = ProviderContainer(overrides: [
        apiServiceProvider.overrideWithValue(fakeApi),
        cacheServiceProvider.overrideWithValue(FakeCacheService()),
      ]);
      addTearDown(container.dispose);

      await container.read(analysisProvider.notifier).analyze('nowhere');

      final state = container.read(analysisProvider);
      expect(state.status, AnalysisStatus.error);
      expect(state.error, 'Address not found. Please check and try again.');
    });
  });
}
