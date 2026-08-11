// Unit tests for the pure region-aware popular-areas blending logic
// (data/popular_areas.dart) — no Flutter/device dependencies.

import 'package:flutter_test/flutter_test.dart';
import 'package:homescope/data/popular_areas.dart';

void main() {
  group('resolvePopularAreas', () {
    test('prefers the last-search region when it is curated', () {
      final r = resolvePopularAreas(lastSearchCity: 'Porto', defaultCity: 'Lisboa');
      expect(r.region, 'Porto');
      expect(r.areas, isNotEmpty);
      expect(r.areas.every((a) => a.region == 'Porto'), isTrue);
    });

    test('falls back to the default city when the region is uncurated', () {
      final r = resolvePopularAreas(
          lastSearchCity: 'Nowheresville', defaultCity: 'Lisboa');
      expect(r.region, 'Lisboa');
      expect(r.areas, isNotEmpty);
    });

    test('falls back to the default city when there is no last search', () {
      final r = resolvePopularAreas(lastSearchCity: null, defaultCity: 'Madrid');
      expect(r.region, 'Madrid');
      expect(r.areas.first.region, 'Madrid');
    });
  });

  group('mergePopularAreas', () {
    final curated = popularAreasForRegion('Lisboa');

    test('empty stats returns curated order unchanged', () {
      final merged = mergePopularAreas('Lisboa', curated, const []);
      expect(merged, curated);
    });

    test('trending curated areas float to top and are flagged', () {
      // Chiado sits below Parque das Nações in curated order; make it #1.
      final merged = mergePopularAreas('Lisboa', curated, const [
        (name: 'Chiado', count: 50),
      ]);
      expect(merged.first.name, 'Chiado');
      expect(merged.first.isTrending, isTrue);
      expect(merged.first.searchCount, 50);
      // Keeps its curated metadata (score + tags).
      expect(merged.first.score, greaterThan(0));
      expect(merged.first.tags, isNotEmpty);
      // Nothing is dropped.
      expect(merged.length, curated.length);
    });

    test('backend-only areas appear as lightweight trending cards', () {
      final merged = mergePopularAreas('Lisboa', curated, const [
        (name: 'Marvila', count: 30),
      ]);
      final marvila = merged.firstWhere((a) => a.name == 'Marvila');
      expect(marvila.isTrending, isTrue);
      expect(marvila.searchCount, 30);
      expect(marvila.score, 0);
      expect(marvila.tags, isEmpty);
      expect(marvila.region, 'Lisboa');
      // Curated areas are still present after it.
      expect(merged.length, curated.length + 1);
    });

    test('ordering follows stat order and dedupes case-insensitively', () {
      final merged = mergePopularAreas('Lisboa', curated, const [
        (name: 'alfama', count: 10),
        (name: 'Alfama', count: 9),
      ]);
      expect(merged.first.name.toLowerCase(), 'alfama');
      // The duplicate does not create a second Alfama entry.
      expect(
        merged.where((a) => a.name.toLowerCase() == 'alfama').length,
        1,
      );
    });
  });
}
