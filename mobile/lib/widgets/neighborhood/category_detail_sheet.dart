import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../config/app_theme.dart';
import '../../config/score_format.dart';
import '../../models/address_model.dart';
import '../../models/amenity_model.dart';
import '../../models/carris_models.dart';
import '../../models/score_model.dart';
import '../../services/carris_service.dart';
import '../../services/osm_transit_service.dart';

// ── Entry point ───────────────────────────────────────────────────────────────

void showCategoryDetail({
  required BuildContext context,
  required CategoryScore cat,
  required List<AmenityModel> allAmenities,
  required AddressModel? address,
}) {
  final amenities = (allAmenities.where((a) => a.category.name == cat.id).toList()
        ..sort((a, b) => (a.distanceMeters ?? 99999).compareTo(b.distanceMeters ?? 99999)));

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    useSafeArea: false,
    builder: (_) => CategoryDetailSheet(
      cat: cat,
      amenities: amenities,
      address: address,
    ),
  );
}

// ── Static lookup tables ──────────────────────────────────────────────────────

const _catEmoji = {
  'transportation': '🚇',
  'education':      '🎓',
  'healthcare':     '🏥',
  'shopping':       '🛍',
  'safety':         '🛡',
  'religion':       '⛪',
  'recreation':     '🌳',
};

const _catColor = {
  'transportation': Color(0xFF29B6F6),
  'education':      Color(0xFF66BB6A),
  'healthcare':     Color(0xFFEF5350),
  'shopping':       Color(0xFFFFA726),
  'safety':         Color(0xFFAB47BC),
  'religion':       Color(0xFF8D6E63),
  'recreation':     Color(0xFF26C6DA),
};

const _catIcon = {
  'transportation': Icons.train_rounded,
  'education':      Icons.school_rounded,
  'healthcare':     Icons.local_hospital_rounded,
  'shopping':       Icons.shopping_bag_rounded,
  'safety':         Icons.shield_rounded,
  'religion':       Icons.church_rounded,
  'recreation':     Icons.park_rounded,
};

const _subTypeLabel = <String, String>{
  // Transportation
  'bus_stop': 'Bus Stops', 'station': 'Train Stations',
  'subway_entrance': 'Metro Stations', 'taxi': 'Taxi Stands',
  'bicycle_rental': 'Bike Sharing', 'parking': 'Parking Areas',
  'ferry_terminal': 'Ferry Terminals', 'tram_stop': 'Tram Stops',
  // Education
  'school': 'Schools', 'university': 'Universities',
  'college': 'Colleges', 'library': 'Libraries',
  'kindergarten': 'Kindergartens', 'language_school': 'Language Schools',
  // Healthcare
  'hospital': 'Hospitals', 'clinic': 'Clinics',
  'pharmacy': 'Pharmacies', 'doctors': 'Surgeries',
  'dentist': 'Dentists', 'veterinary': 'Veterinary',
  // Shopping
  'supermarket': 'Supermarkets', 'mall': 'Shopping Centres',
  'convenience': 'Convenience Stores', 'market': 'Markets',
  'bakery': 'Bakeries', 'butcher': 'Butchers',
  'clothes': 'Clothing Stores', 'electronics': 'Electronics',
  // Safety
  'police': 'Police Stations', 'fire_station': 'Fire Stations',
  'ambulance_station': 'Ambulance Stations',
  // Recreation
  'park': 'Parks', 'garden': 'Gardens',
  'sports_centre': 'Sports Centres', 'gym': 'Gyms',
  'playground': 'Playgrounds', 'pitch': 'Sports Pitches',
  'swimming_pool': 'Swimming Pools',
  // Religion
  'church': 'Churches', 'mosque': 'Mosques',
  'temple': 'Temples', 'synagogue': 'Synagogues',
  'place_of_worship': 'Places of Worship',
};

// Per-sub-type accent colours for the transit radar
const _kTransportColors = <String, Color>{
  'subway_entrance': Color(0xFF8B5CF6),
  'bus_stop':        Color(0xFF3B82F6),
  'station':         Color(0xFF22C55E),
  'taxi':            Color(0xFFF59E0B),
  'bicycle_rental':  Color(0xFF06B6D4),
  'tram_stop':       Color(0xFFEC4899),
  'ferry_terminal':  Color(0xFF14B8A6),
  'parking':         Color(0xFF64748B),
};

const _subTypeIcon = <String, IconData>{
  'bus_stop': Icons.directions_bus_rounded,
  'station': Icons.train_rounded,
  'subway_entrance': Icons.subway_rounded,
  'tram_stop': Icons.tram_rounded,
  'taxi': Icons.local_taxi_rounded,
  'bicycle_rental': Icons.pedal_bike_rounded,
  'parking': Icons.local_parking_rounded,
  'ferry_terminal': Icons.directions_boat_rounded,
  'school': Icons.school_rounded,
  'university': Icons.account_balance_rounded,
  'college': Icons.account_balance_rounded,
  'library': Icons.menu_book_rounded,
  'kindergarten': Icons.child_care_rounded,
  'hospital': Icons.local_hospital_rounded,
  'clinic': Icons.medical_services_rounded,
  'pharmacy': Icons.local_pharmacy_rounded,
  'doctors': Icons.medical_services_rounded,
  'dentist': Icons.medical_services_rounded,
  'supermarket': Icons.shopping_cart_rounded,
  'mall': Icons.store_mall_directory_rounded,
  'convenience': Icons.storefront_rounded,
  'market': Icons.storefront_rounded,
  'police': Icons.local_police_rounded,
  'fire_station': Icons.local_fire_department_rounded,
  'park': Icons.park_rounded,
  'garden': Icons.yard_rounded,
  'sports_centre': Icons.sports_rounded,
  'gym': Icons.fitness_center_rounded,
  'playground': Icons.child_friendly_rounded,
  'swimming_pool': Icons.pool_rounded,
  'church': Icons.church_rounded,
  'mosque': Icons.mosque_rounded,
  'place_of_worship': Icons.church_rounded,
};

const _lifestyleTags = <String, List<String>>{
  'transportation': [
    '✅ No car required',
    '✅ Great for daily commuters',
    '✅ Student-friendly transit',
    '✅ Easy city-centre access',
  ],
  'education': [
    '✅ Family-friendly area',
    '✅ Strong school access',
    '✅ University nearby',
    '✅ Great for students',
  ],
  'healthcare': [
    '✅ Pharmacy within walking distance',
    '✅ Emergency care reachable',
    '✅ Regular healthcare access',
  ],
  'shopping': [
    '✅ Daily needs covered on foot',
    '✅ No car needed for errands',
    '✅ Convenient lifestyle',
    '✅ Variety of options nearby',
  ],
  'safety': [
    '✅ Emergency services nearby',
    '✅ Well-monitored area',
    '✅ Peace of mind',
  ],
  'recreation': [
    '✅ Active lifestyle supported',
    '✅ Green spaces within reach',
    '✅ Outdoor activities available',
    '✅ Good for mental wellbeing',
  ],
  'religion': [
    '✅ Diverse spiritual community',
    '✅ Cultural richness nearby',
    '✅ Community spaces accessible',
  ],
};

// ── Helpers ───────────────────────────────────────────────────────────────────

String _dist(int? m) {
  if (m == null) return '—';
  return m < 1000 ? '${m}m' : '${(m / 1000).toStringAsFixed(1)}km';
}

String _percentile(double score) {
  if (score >= 95) return 'Top 5%';
  if (score >= 90) return 'Top 10%';
  if (score >= 85) return 'Top 15%';
  if (score >= 80) return 'Top 20%';
  if (score >= 75) return 'Top 25%';
  if (score >= 70) return 'Top 30%';
  if (score >= 60) return 'Top 40%';
  return 'Average';
}

String _recommendation(String catId, double score) {
  switch (catId) {
    case 'transportation':
      return score >= 80
          ? 'If transportation is a priority, this property is an excellent choice. Daily commuting is comfortable without depending on a private vehicle. Public transit, cycling, and walking are all practical options.'
          : score >= 60
          ? 'This property offers reasonable transit connections. Most destinations are reachable but you may want to plan commute routes in advance for less frequent services.'
          : 'Transportation access is a potential concern here. Factor in commute times and the cost of private transport when evaluating this property.';
    case 'education':
      return score >= 80
          ? 'For families or students, this is a strong location. Multiple schools and learning institutions are within easy reach, reducing daily commute time significantly.'
          : score >= 60
          ? 'Educational access is adequate. Families should verify specific school catchment areas and proximity to preferred institutions.'
          : 'Limited nearby educational facilities may be a consideration for families. Research transport options to schools further afield.';
    case 'healthcare':
      return score >= 80
          ? 'Healthcare access is a genuine strength of this property. From pharmacies to hospitals, medical needs at any urgency level are well catered for nearby.'
          : score >= 60
          ? 'Routine healthcare needs are reasonably met. Verify the location of your preferred GP, pharmacy, and any specialist services you regularly use.'
          : 'Healthcare access is limited here. Ensure you are comfortable with travel distances to hospitals and clinics before committing.';
    case 'shopping':
      return score >= 80
          ? 'Day-to-day living is very convenient here. Groceries, retail, and dining options are all within easy reach — a real quality-of-life advantage.'
          : score >= 60
          ? 'Shopping needs are reasonably covered. Major weekly shops may require a short journey but everyday essentials should be accessible on foot.'
          : 'Shopping convenience is limited. Budget extra time and potentially transport costs for regular grocery and retail needs.';
    case 'safety':
      return score >= 80
          ? 'Emergency services are well positioned relative to this property. This is reassuring both for daily peace of mind and for insurance considerations.'
          : 'Emergency service coverage is adequate for the area. As with any location, it is worth checking local crime statistics independently.';
    case 'recreation':
      return score >= 80
          ? 'For an active lifestyle, this property scores highly. Parks, sports facilities, and green spaces nearby support both physical and mental wellbeing.'
          : score >= 60
          ? 'Recreation options are available within a reasonable distance. Consider your preferred activities and verify specific facility access before deciding.'
          : 'Green space and leisure facilities are limited nearby. If outdoor activity is important to you, factor this into your decision.';
    default:
      return score >= 80
          ? 'This category is a genuine asset of the property — well above average for the area.'
          : score >= 60
          ? 'This category meets typical expectations for the area with some room for improvement.'
          : 'This category is below average and worth considering as part of your overall assessment.';
  }
}

// ── Sub-type model ────────────────────────────────────────────────────────────

class _SubType {
  final String type;
  final int count;
  final double score;
  final int closestM;
  const _SubType({
    required this.type,
    required this.count,
    required this.score,
    required this.closestM,
  });
}

// ── Sheet widget ──────────────────────────────────────────────────────────────

class CategoryDetailSheet extends StatefulWidget {
  final CategoryScore cat;
  final List<AmenityModel> amenities;
  final AddressModel? address;

  const CategoryDetailSheet({
    super.key,
    required this.cat,
    required this.amenities,
    this.address,
  });

  @override
  State<CategoryDetailSheet> createState() => _CategoryDetailSheetState();
}

class _CategoryDetailSheetState extends State<CategoryDetailSheet> {
  late final Color _color;
  late final List<_SubType> _subtypes;
  // Amenities grouped by sub-type, each list sorted nearest-first, groups
  // ordered by count (then proximity). Powers the collapsible nearby section.
  late final List<MapEntry<String, List<AmenityModel>>> _groups;
  final Set<String> _expandedTypes = {};

  @override
  void initState() {
    super.initState();
    _color = _catColor[widget.cat.id] ?? const Color(0xFF3B82F6);
    _subtypes = _computeSubtypes();
    _groups = _computeGroups();
    // All groups start collapsed — the user taps a row to reveal its places.
  }

  List<MapEntry<String, List<AmenityModel>>> _computeGroups() {
    final groups = <String, List<AmenityModel>>{};
    for (final a in widget.amenities) {
      groups.putIfAbsent(a.type, () => []).add(a);
    }
    for (final l in groups.values) {
      l.sort((a, b) =>
          (a.distanceMeters ?? 99999).compareTo(b.distanceMeters ?? 99999));
    }
    return groups.entries.toList()
      ..sort((a, b) {
        final byCount = b.value.length.compareTo(a.value.length);
        if (byCount != 0) return byCount;
        return (a.value.first.distanceMeters ?? 99999)
            .compareTo(b.value.first.distanceMeters ?? 99999);
      });
  }

  /// Cumulative counts of places reachable within each distance band.
  List<(String, int)> _reachBands() {
    const bands = [(200.0, '200 m'), (500.0, '500 m'), (1000.0, '1 km'), (2000.0, '2 km')];
    return bands
        .map((b) => (
              b.$2,
              widget.amenities
                  .where((a) => (a.distanceMeters ?? 99999) <= b.$1)
                  .length,
            ))
        .toList();
  }

  List<_SubType> _computeSubtypes() {
    final groups = <String, List<AmenityModel>>{};
    for (final a in widget.amenities) {
      groups.putIfAbsent(a.type, () => []).add(a);
    }
    if (groups.isEmpty) return [];
    final maxCount = groups.values.map((l) => l.length).reduce(max);
    final base = widget.cat.score;
    return (groups.entries.map((e) {
      final list = e.value..sort((a, b) =>
          (a.distanceMeters ?? 99999).compareTo(b.distanceMeters ?? 99999));
      final count = list.length;
      final closest = list.first.distanceMeters ?? 99999;
      final countFactor = 0.7 + (count / maxCount) * 0.3;
      final distFactor = closest < 200 ? 1.06 : closest < 500 ? 1.0 : closest < 1000 ? 0.95 : 0.88;
      final score = (base * countFactor * distFactor).clamp(0.0, 100.0);
      return _SubType(type: e.key, count: count, score: score, closestM: closest);
    }).toList()
      ..sort((a, b) => b.score.compareTo(a.score)));
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;
    final p = AppPalette.of(context);
    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      minChildSize: 0.5,
      maxChildSize: 0.96,
      builder: (ctx, ctrl) => Container(
        decoration: BoxDecoration(
          color: p.bg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
        ),
        child: CustomScrollView(
          controller: ctrl,
          slivers: [
            SliverToBoxAdapter(child: _buildHandle()),
            SliverToBoxAdapter(child: _buildHeader()),
            // Transport gets the radar + lines instead of the generic reach bars.
            if (widget.cat.id != 'transportation')
              SliverToBoxAdapter(child: _buildScoreOverview()),
            if (widget.cat.id == 'transportation')
              SliverToBoxAdapter(child: _buildTransportDNA()),
            if (widget.cat.id == 'transportation' &&
                widget.address?.lat != null &&
                widget.address?.lng != null)
              SliverToBoxAdapter(
                child: _TransitLinesSection(
                  lat: widget.address!.lat!,
                  lng: widget.address!.lng!,
                  color: _color,
                  amenities: widget.amenities,
                ),
              ),
            // Lines + radar cover transport; the grouped stop list is only for
            // the other categories.
            if (widget.cat.id != 'transportation')
              SliverToBoxAdapter(child: _buildNearbyGrouped()),
            if (widget.address?.lat != null && widget.address?.lng != null)
              SliverToBoxAdapter(child: _buildMiniMap()),
            SliverToBoxAdapter(child: _buildWhatMakes()),
            SliverToBoxAdapter(child: _buildLifestyle()),
            SliverToBoxAdapter(child: _buildRecommendation()),
            SliverToBoxAdapter(child: SizedBox(height: 32 + bottom)),
          ],
        ),
      ),
    );
  }

  // ── Drag handle ─────────────────────────────────────────────────────────────

  Widget _buildHandle() => Padding(
    padding: const EdgeInsets.only(top: 12, bottom: 4),
    child: Center(
      child: Container(
        width: 40, height: 4,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    ),
  );

  // ── Header ──────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    final score = widget.cat.score;
    final color = _color;
    final label = scoreLabel(score);
    final p = AppPalette.of(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: p.border)),
      ),
      child: Row(
        children: [
          // Animated ring
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: score / 100),
            duration: const Duration(milliseconds: 900),
            curve: Curves.easeOutCubic,
            builder: (_, v, __) => SizedBox(
              width: 80, height: 80,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CustomPaint(
                    size: const Size(80, 80),
                    painter: _RingPainter(progress: 1, color: p.border, stroke: 5),
                  ),
                  CustomPaint(
                    size: const Size(80, 80),
                    painter: _RingPainter(progress: v, color: color, stroke: 5),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        scoreTenth(score),
                        style: TextStyle(
                          color: color, fontSize: 22,
                          fontWeight: FontWeight.w800, height: 1,
                        ),
                      ),
                      Text('/ 10', style: TextStyle(
                        color: p.textTertiary, fontSize: 9.5,
                      )),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      _catEmoji[widget.cat.id] ?? '📍',
                      style: const TextStyle(fontSize: 20),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      shortCategoryLabel(widget.cat.id, widget.cat.label),
                      style: TextStyle(
                        color: p.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                      decoration: BoxDecoration(
                        color: scoreColor(score).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: Text(
                        label,
                        style: TextStyle(
                          color: scoreColor(score),
                          fontSize: 11.5, fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(7),
                        border: Border.all(color: color.withValues(alpha: 0.25)),
                      ),
                      child: Text(
                        _percentile(score),
                        style: TextStyle(
                          color: color,
                          fontSize: 11, fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  widget.cat.id == 'transportation'
                      ? '${widget.cat.count} transit stops within 2km'
                      : '${widget.cat.count} places found within 2km',
                  style: TextStyle(
                    color: p.textTertiary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  // ── Places within reach (real distance-band counts) ──────────────────────────

  Widget _buildScoreOverview() {
    final color = _color;
    final p = AppPalette.of(context);
    final bands = _reachBands();
    final maxCount = bands.map((b) => b.$2).fold<int>(0, max);

    if (maxCount == 0) {
      return _Section(
        title: 'PLACES WITHIN REACH',
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 22),
          decoration: BoxDecoration(
            color: p.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: p.border),
          ),
          child: Text(
            'No places found nearby.',
            textAlign: TextAlign.center,
            style: TextStyle(color: p.textTertiary, fontSize: 12.5),
          ),
        ),
      ).animate(delay: 80.ms).fadeIn(duration: 350.ms);
    }

    return _Section(
      title: 'PLACES WITHIN REACH',
      child: Column(
        children: [
          for (final band in bands)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  SizedBox(
                    width: 42,
                    child: Text(
                      band.$1,
                      style: TextStyle(
                        color: p.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: band.$2 / maxCount),
                      duration: const Duration(milliseconds: 800),
                      curve: Curves.easeOutCubic,
                      builder: (_, v, __) => ClipRRect(
                        borderRadius: BorderRadius.circular(5),
                        child: LinearProgressIndicator(
                          value: v,
                          minHeight: 9,
                          backgroundColor: color.withValues(alpha: 0.12),
                          valueColor: AlwaysStoppedAnimation(color),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 30,
                    child: Text(
                      '${band.$2}',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        color: p.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    ).animate(delay: 80.ms).fadeIn(duration: 350.ms);
  }

  // ── Transit radar (transportation only) ──────────────────────────────────────

  Widget _buildTransportDNA() {
    if (widget.amenities.isEmpty) return const SizedBox.shrink();
    // The section renders its own "NEAREST STOP" + "AROUND YOU" blocks.
    return _TransitRadarSection(
      amenities: widget.amenities,
      address: widget.address,
      color: _color,
      subtypes: _subtypes,
    ).animate(delay: 80.ms).fadeIn(duration: 300.ms);
  }

  // ── What's nearby (grouped by type, collapsible) ─────────────────────────────

  Widget _buildNearbyGrouped() {
    if (_groups.isEmpty) return const SizedBox.shrink();
    final isTransport = widget.cat.id == 'transportation';
    final p = AppPalette.of(context);

    return _Section(
      title: isTransport ? 'NEARBY TRANSIT' : "WHAT'S NEARBY",
      child: Container(
        decoration: BoxDecoration(
          color: p.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: p.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            for (int i = 0; i < _groups.length; i++) ...[
              if (i > 0)
                Divider(height: 1, color: Colors.white.withValues(alpha: 0.05)),
              _buildGroup(_groups[i], isTransport),
            ],
          ],
        ),
      ),
    ).animate(delay: 120.ms).fadeIn(duration: 350.ms);
  }

  Widget _buildGroup(
    MapEntry<String, List<AmenityModel>> group,
    bool isTransport,
  ) {
    final color = _color;
    final p = AppPalette.of(context);
    final type = group.key;
    final places = group.value;
    final expanded = _expandedTypes.contains(type);
    final label = _subTypeLabel[type] ?? _prettify(type);
    final icon =
        _subTypeIcon[type] ?? _catIcon[widget.cat.id] ?? Icons.place_rounded;

    return Column(
      children: [
        // Header row — tap to expand/collapse
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => setState(() {
            expanded ? _expandedTypes.remove(type) : _expandedTypes.add(type);
          }),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            child: Row(
              children: [
                Container(
                  width: 34, height: 34,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 16),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: p.textPrimary,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${places.length}',
                    style: TextStyle(
                      color: color,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                AnimatedRotation(
                  turns: expanded ? 0.25 : 0.0,
                  duration: const Duration(milliseconds: 180),
                  child: Icon(Icons.chevron_right_rounded,
                      size: 20, color: p.textTertiary),
                ),
              ],
            ),
          ),
        ),
        // Expanded place list
        if (expanded)
          for (final a in places)
            isTransport
                ? _TransportStopCard(amenity: a, typeColor: color)
                : _GroupPlaceRow(amenity: a, color: color),
      ],
    );
  }

  // ── Mini map ─────────────────────────────────────────────────────────────────

  Widget _buildMiniMap() {
    final lat = widget.address!.lat!;
    final lng = widget.address!.lng!;
    final color = _color;
    final icon = _catIcon[widget.cat.id] ?? Icons.place_rounded;
    final sorted = [...widget.amenities]
      ..sort((a, b) =>
          (a.distanceMeters ?? 99999).compareTo(b.distanceMeters ?? 99999));
    final markers = sorted.take(15).toList();
    // Fit the camera to home + the closest places so they're actually visible
    // (instead of a fixed zoom that often shows only the home pin).
    final fitPoints = <LatLng>[
      LatLng(lat, lng),
      ...sorted.take(8).map((a) => LatLng(a.lat, a.lng)),
    ];

    return _Section(
      title: 'MAP PREVIEW',
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          height: 190,
          child: FlutterMap(
            options: MapOptions(
              initialCameraFit: CameraFit.coordinates(
                coordinates: fitPoints,
                padding: const EdgeInsets.all(28),
                maxZoom: 16.5,
              ),
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.homescope.app',
              ),
              // Dotted lines from home to each amenity
              PolylineLayer(polylines: [
                ...markers.map((a) => Polyline(
                  points: [LatLng(lat, lng), LatLng(a.lat, a.lng)],
                  color: color.withValues(alpha: 0.45),
                  strokeWidth: 1.5,
            
                )),
              ]),
              CircleLayer(circles: [
                CircleMarker(
                  point: LatLng(lat, lng),
                  radius: 500,
                  useRadiusInMeter: true,
                  color: color.withValues(alpha: 0.08),
                  borderColor: color.withValues(alpha: 0.35),
                  borderStrokeWidth: 1.5,
                ),
              ]),
              MarkerLayer(markers: [
                // Category amenity markers
                ...markers.map((a) => Marker(
                  point: LatLng(a.lat, a.lng),
                  width: 22, height: 22,
                  child: Container(
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    child: Icon(icon, color: Colors.white, size: 10),
                  ),
                )),
                // Home pin
                Marker(
                  point: LatLng(lat, lng),
                  width: 32, height: 32,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.bg, width: 2),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 6)],
                    ),
                    child: const Icon(Icons.home_rounded, color: AppColors.bg, size: 16),
                  ),
                ),
              ]),
            ],
          ),
        ),
      ),
    ).animate(delay: 160.ms).fadeIn(duration: 350.ms);
  }

  // ── What makes this score ────────────────────────────────────────────────────

  Widget _buildWhatMakes() {
    final score = widget.cat.score;
    final label = scoreLabel(score).toLowerCase();
    final color = _color;
    final p = AppPalette.of(context);

    // Build accurate bullet points: count is total within search radius (2km),
    // closestM is distance to the single nearest — not a containing radius.
    final bullets = <String>[];
    for (final st in _subtypes.take(4)) {
      final stLabel = _subTypeLabel[st.type] ?? _prettify(st.type);
      final within500 = widget.amenities
          .where((a) => a.type == st.type && (a.distanceMeters ?? 99999) <= 500)
          .length;
      final nearestStr = _dist(st.closestM);
      final extra = within500 > 0 ? ', $within500 within 500m' : '';
      bullets.add('${st.count} $stLabel within 2km$extra · nearest: $nearestStr');
    }
    if (widget.cat.closest?.walkingMinutes != null) {
      bullets.add('Nearest place: ${widget.cat.closest!.walkingMinutes} min walk');
    }

    return _Section(
      title: 'WHY IS THIS SCORE ${label.toUpperCase()}?',
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: p.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: p.border),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [p.surface, color.withValues(alpha: 0.06)],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.lightbulb_rounded, color: color, size: 16),
                const SizedBox(width: 8),
                Text(
                  'You have:',
                  style: TextStyle(
                    color: color, fontSize: 13, fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...bullets.map((b) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 6, height: 6,
                    margin: const EdgeInsets.only(top: 5, right: 10),
                    decoration: BoxDecoration(
                      color: color, shape: BoxShape.circle,
                    ),
                  ),
                  Expanded(
                    child: Text(b, style: TextStyle(
                      color: p.textSecondary,
                      fontSize: 13, height: 1.4,
                    )),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    ).animate(delay: 200.ms).fadeIn(duration: 350.ms);
  }


  // ── Lifestyle tags ────────────────────────────────────────────────────────────

  Widget _buildLifestyle() {
    final tags = _lifestyleTags[widget.cat.id] ?? [];
    if (tags.isEmpty) return const SizedBox.shrink();
    final p = AppPalette.of(context);

    return _Section(
      title: 'LIFESTYLE INSIGHTS',
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: tags.map((t) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: p.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: p.border),
          ),
          child: Text(t, style: TextStyle(
            color: p.textSecondary,
            fontSize: 12.5,
          )),
        )).toList(),
      ),
    ).animate(delay: 280.ms).fadeIn(duration: 350.ms);
  }

  // ── AI recommendation ─────────────────────────────────────────────────────────

  Widget _buildRecommendation() {
    final text = _recommendation(widget.cat.id, widget.cat.score);
    final p = AppPalette.of(context);
    return _Section(
      title: 'AI RECOMMENDATION',
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: p.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: p.border),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [p.surface, AppColors.accent2.withValues(alpha: 0.07)],
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.accent2.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.auto_awesome_rounded, color: AppColors.accent2, size: 16),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(text, style: TextStyle(
                color: p.textSecondary,
                fontSize: 13.5, height: 1.65,
              )),
            ),
          ],
        ),
      ),
    ).animate(delay: 320.ms).fadeIn(duration: 350.ms);
  }
}

// ── Arrivals grouping + directions helpers ───────────────────────────────────

/// One line + destination with its next upcoming times (minutes), soonest
/// first. Collapses the duplicate rows (e.g. two "Colégio Militar" arrivals)
/// into a single entry showing multiple times.
class _ArrivalGroup {
  final String lineId;
  final String headsign;
  final List<int> minutes;
  _ArrivalGroup(this.lineId, this.headsign, this.minutes);
}

List<_ArrivalGroup> _groupArrivals(List<CarrisArrival> arrivals) {
  final byKey = <String, _ArrivalGroup>{};
  final order = <String>[];
  for (final a in arrivals) {
    final m = a.minutesUntil;
    if (m == null) continue;
    final key = '${a.lineId}|${a.headsign}';
    final g = byKey.putIfAbsent(key, () {
      order.add(key);
      return _ArrivalGroup(a.lineId, a.headsign, []);
    });
    if (g.minutes.length < 3) g.minutes.add(m);
  }
  for (final g in byKey.values) {
    g.minutes.sort();
  }
  order.sort((x, y) => byKey[x]!.minutes.first.compareTo(byKey[y]!.minutes.first));
  return [for (final k in order) byKey[k]!];
}

/// Opens Apple or Google Maps with transit directions to [lat]/[lng].
/// Lets the user pick the app (both offered on iOS; Google on Android).
Future<void> _openDirections(
  BuildContext context,
  double lat,
  double lng, {
  String? label,
}) async {
  final p = AppPalette.of(context);
  Future<void> launch(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  final apple =
      'https://maps.apple.com/?daddr=$lat,$lng&dirflg=r';
  final google =
      'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&travelmode=transit';

  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: p.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
            child: Row(
              children: [
                Icon(Icons.directions_rounded, size: 18, color: p.textSecondary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    label == null ? 'Directions' : 'Directions to $label',
                    style: TextStyle(
                        color: p.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Text('🗺️', style: TextStyle(fontSize: 20)),
            title: Text('Apple Maps', style: TextStyle(color: p.textPrimary)),
            onTap: () { Navigator.pop(ctx); launch(apple); },
          ),
          ListTile(
            leading: const Text('📍', style: TextStyle(fontSize: 20)),
            title: Text('Google Maps', style: TextStyle(color: p.textPrimary)),
            onTap: () { Navigator.pop(ctx); launch(google); },
          ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
}

// ── Transport stop card (with route chips + Carris real-time) ─────────────────

class _TransportStopCard extends StatefulWidget {
  final AmenityModel amenity;
  final Color typeColor;
  const _TransportStopCard({required this.amenity, required this.typeColor});

  @override
  State<_TransportStopCard> createState() => _TransportStopCardState();
}

class _TransportStopCardState extends State<_TransportStopCard> {
  // OSM route_ref parsed immediately (works globally)
  late List<String> _osmRoutes;

  // Carris enrichment (Lisbon area only, loaded async)
  CarrisStop? _carrisStop;
  List<CarrisArrival> _arrivals = [];
  Map<String, CarrisLine> _lineColors = {};
  bool _carrisLoaded = false;

  @override
  void initState() {
    super.initState();
    final ref = widget.amenity.tags?['route_ref']?.toString() ?? '';
    _osmRoutes = ref.isEmpty
        ? []
        : ref
            .split(RegExp(r'[;,/\s]+'))
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList();
    _loadCarris();
  }

  Future<void> _loadCarris() async {
    final stop = await CarrisService.nearestStop(
        widget.amenity.lat, widget.amenity.lng);
    if (!mounted) return;

    List<CarrisArrival> arrivals = [];
    Map<String, CarrisLine> colors = {};

    if (stop != null) {
      arrivals = await CarrisService.realtimeArrivals(stop.id);
      final ids = {...stop.lines, ...arrivals.map((a) => a.lineId)}.toList();
      colors = await CarrisService.lineInfoMap(ids);
    }

    if (!mounted) return;
    setState(() {
      _carrisStop = stop;
      _arrivals = arrivals;
      _lineColors = colors;
      _carrisLoaded = true;
    });
  }

  List<String> get _routes {
    if (_carrisStop != null && _carrisStop!.lines.isNotEmpty) {
      return _carrisStop!.lines;
    }
    return _osmRoutes;
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.amenity;
    final stColor = _kTransportColors[a.type] ?? widget.typeColor;
    final icon = _subTypeIcon[a.type] ?? Icons.train_rounded;
    final routes = _routes;
    final p = AppPalette.of(context);

    final hasShelter = a.tags?['shelter'] == 'yes';
    final isAccessible = a.tags?['wheelchair'] == 'yes' ||
        (_carrisStop?.isWheelchairAccessible ?? false);
    final isLit = a.tags?['lit'] == 'yes';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Stop name + distance ──
          Row(
            children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: stColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: stColor, size: 16),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      a.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: p.textPrimary, fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                    if (_carrisStop != null)
                      Text(
                        'Carris · stop ${_carrisStop!.id}',
                        style: TextStyle(
                            color: p.textTertiary, fontSize: 10),
                      )
                    else
                      Text(
                        _prettify(a.type),
                        style: TextStyle(
                            color: p.textTertiary, fontSize: 10),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _dist(a.distanceMeters),
                    style: TextStyle(
                        color: p.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600),
                  ),
                  if (a.walkingMinutes != null)
                    Text(
                      '${a.walkingMinutes} min',
                      style: TextStyle(
                          color: p.textTertiary, fontSize: 11),
                    ),
                ],
              ),
            ],
          ),

          // ── Route chips ──
          if (routes.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 5,
              runSpacing: 4,
              children: routes
                  .take(10)
                  .map((id) => _routeChip(id, stColor))
                  .toList(),
            ),
          ],

          // ── Next arrivals (Carris real-time) ──
          if (_carrisLoaded && _arrivals.isNotEmpty) ...[
            const SizedBox(height: 8),
            _arrivalsRow(),
          ],

          // ── Facility badges ──
          if (hasShelter || isAccessible || isLit) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                if (hasShelter) _facilityBadge('shelter', Icons.roofing_rounded),
                if (isAccessible) _facilityBadge('accessible', Icons.accessible_rounded),
                if (isLit) _facilityBadge('lit', Icons.lightbulb_outline_rounded),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _routeChip(String lineId, Color fallback) {
    final line = _lineColors[lineId];
    final bg = line != null ? Color(line.colorInt) : fallback.withValues(alpha: 0.80);
    final fg = line != null ? Color(line.textColorInt) : Colors.white;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        line?.shortName ?? lineId,
        style: TextStyle(
            color: fg, fontSize: 10.5, fontWeight: FontWeight.w800, letterSpacing: 0.2),
      ),
    );
  }

  Widget _arrivalsRow() {
    final p = AppPalette.of(context);
    return Row(
      children: [
        Text('Next  ',
            style: TextStyle(
                color: p.textTertiary, fontSize: 10.5)),
        ..._arrivals.take(3).map((a) {
          final mins = a.minutesUntil;
          final line = _lineColors[a.lineId];
          final dot = line != null ? Color(line.colorInt) : widget.typeColor;
          final label = mins == null
              ? '?'
              : mins == 0
                  ? 'Now'
                  : '$mins min';
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(color: dot, shape: BoxShape.circle)),
              const SizedBox(width: 4),
              Text(label,
                  style: TextStyle(
                      color: p.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w600)),
            ]),
          );
        }),
      ],
    );
  }

  Widget _facilityBadge(String label, IconData icon) {
    final p = AppPalette.of(context);
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 11, color: p.textTertiary),
        const SizedBox(width: 3),
        Text(label,
            style: TextStyle(
                color: p.textTertiary, fontSize: 10)),
      ]),
    );
  }
}

// ── Nearby tile ───────────────────────────────────────────────────────────────

// Compact place row shown when a nearby group is expanded.
class _GroupPlaceRow extends StatelessWidget {
  final AmenityModel amenity;
  final Color color;
  const _GroupPlaceRow({required this.amenity, required this.color});

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Container(
      color: Colors.white.withValues(alpha: 0.02),
      padding: const EdgeInsets.fromLTRB(24, 10, 14, 10),
      child: Row(
        children: [
          Container(
            width: 5, height: 5,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.6),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              amenity.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: p.textSecondary, fontSize: 12.5),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _dist(amenity.distanceMeters),
            style: TextStyle(
              color: p.textSecondary,
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (amenity.walkingMinutes != null)
            Text(
              '  ·  ${amenity.walkingMinutes} min',
              style: TextStyle(color: p.textTertiary, fontSize: 11),
            ),
        ],
      ),
    );
  }
}


// ── Section wrapper ───────────────────────────────────────────────────────────

class _Section extends StatelessWidget {
  final String title;
  final Widget child;
  const _Section({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: p.textTertiary,
              fontSize: 10.5, fontWeight: FontWeight.w700, letterSpacing: 1.8,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

// ── Stat model & tile ─────────────────────────────────────────────────────────


// ── Sparkline painter ──────────────────────────────────────────────────────────


// ── Ring painter ──────────────────────────────────────────────────────────────

class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double stroke;
  const _RingPainter({required this.progress, required this.color, required this.stroke});

  @override
  void paint(Canvas canvas, Size size) {
    final inset = stroke / 2;
    final rect = Rect.fromLTWH(inset, inset, size.width - inset * 2, size.height - inset * 2);
    canvas.drawArc(
      rect, -pi / 2, 2 * pi * progress, false,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.progress != progress;
}

// ── Transit Radar section (premium stacked: stop card → radar hero → arrivals) ─

class _TransitRadarSection extends StatefulWidget {
  final List<AmenityModel> amenities;
  final AddressModel? address;
  final Color color;
  final List<_SubType> subtypes;

  const _TransitRadarSection({
    required this.amenities,
    required this.address,
    required this.color,
    required this.subtypes,
  });

  @override
  State<_TransitRadarSection> createState() => _TransitRadarSectionState();
}

class _TransitRadarSectionState extends State<_TransitRadarSection>
    with SingleTickerProviderStateMixin {
  CarrisStop? _carrisStop;
  List<CarrisArrival> _arrivals = [];
  Map<String, CarrisLine> _lineColors = {};
  bool _loaded = false;
  late final AnimationController _pulseCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
  )..repeat();

  // Live device heading (degrees clockwise from north) for the radar compass.
  StreamSubscription<CompassEvent>? _compassSub;
  double? _heading;

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _compassSub?.cancel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _load();
    _startCompass();
  }

  void _startCompass() {
    final events = FlutterCompass.events;
    if (events == null) return; // no magnetometer (e.g. simulator)
    _compassSub = events.listen((e) {
      final h = e.heading;
      if (h == null || !mounted) return;
      // Only rebuild on meaningful change to avoid churn from sensor noise.
      if (_heading == null || (h - _heading!).abs() >= 1.0) {
        setState(() => _heading = h);
      }
    });
  }

  Future<void> _load() async {
    if (widget.amenities.isEmpty) return;
    final nearest = widget.amenities.first;
    final stop = await CarrisService.nearestStop(nearest.lat, nearest.lng);
    if (!mounted) return;

    List<CarrisArrival> arrivals = [];
    Map<String, CarrisLine> colors = {};

    if (stop != null) {
      arrivals = await CarrisService.realtimeArrivals(stop.id);
      final ids = {...stop.lines, ...arrivals.map((a) => a.lineId)}.toList();
      colors = await CarrisService.lineInfoMap(ids);
    }

    if (!mounted) return;
    setState(() {
      _carrisStop = stop;
      _arrivals = arrivals;
      _lineColors = colors;
      _loaded = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final nearest = widget.amenities.isNotEmpty ? widget.amenities.first : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Nearest stop + live departures ──
        if (nearest != null)
          _Section(
            title: 'NEAREST STOP',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _stopInfoCard(nearest),
                if (_loaded && _arrivals.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _arrivalsCard(),
                ],
              ],
            ),
          ),
        // ── Directional radar ──
        _Section(
          title: 'AROUND YOU',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _modeSummary(),
              _radarHero(),
              const SizedBox(height: 10),
              _legendRow(),
            ],
          ),
        ),
      ],
    );
  }

  // ── 1. Stop info card ───────────────────────────────────────────────────────

  Widget _stopInfoCard(AmenityModel a) {
    final color = widget.color;
    final stColor = _kTransportColors[a.type] ?? color;
    final icon = _subTypeIcon[a.type] ?? Icons.train_rounded;
    final p = AppPalette.of(context);

    final mode = _modeTag(a.type);
    // Secondary line: "64m · 1 min walk · Stop 060219"
    final secondary = [
      _dist(a.distanceMeters),
      if (a.walkingMinutes != null) '${a.walkingMinutes} min walk',
      if (_carrisStop != null) 'Stop ${_carrisStop!.id}',
    ].join(' · ');

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: p.border),
      ),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: stColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: stColor.withValues(alpha: 0.25)),
            ),
            child: Icon(icon, color: stColor, size: 19),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        _carrisStop?.name ?? a.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: p.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _modeChip(mode, stColor),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  secondary,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: p.textTertiary, fontSize: 12.5),
                ),
              ],
            ),
          ),
          if (!_loaded)
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: SizedBox(
                width: 15, height: 15,
                child: CircularProgressIndicator(
                  strokeWidth: 1.5,
                  valueColor:
                      AlwaysStoppedAnimation(color.withValues(alpha: 0.45)),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _modeChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 9.5,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.4,
        ),
      ),
    );
  }

  // ── Mode summary (counts of nearby stops by transport type) ─────────────────

  Widget _modeSummary() {
    // Group the sub-type stop counts into human transport modes.
    const modeOf = {
      'subway_entrance': 'Metro',
      'station': 'Train',
      'tram_stop': 'Tram',
      'ferry_terminal': 'Ferry',
      'bus_stop': 'Bus',
      'taxi': 'Taxi',
      'bicycle_rental': 'Bike',
    };
    const iconOf = {
      'Metro': Icons.subway_rounded,
      'Train': Icons.train_rounded,
      'Tram': Icons.tram_rounded,
      'Ferry': Icons.directions_boat_rounded,
      'Bus': Icons.directions_bus_rounded,
      'Taxi': Icons.local_taxi_rounded,
      'Bike': Icons.pedal_bike_rounded,
    };
    const order = ['Metro', 'Train', 'Tram', 'Ferry', 'Bus', 'Taxi', 'Bike'];

    final counts = <String, int>{};
    final colors = <String, Color>{};
    for (final st in widget.subtypes) {
      final mode = modeOf[st.type];
      if (mode == null) continue;
      counts[mode] = (counts[mode] ?? 0) + st.count;
      colors.putIfAbsent(
          mode, () => _kTransportColors[st.type] ?? widget.color);
    }
    final modes = order.where((m) => (counts[m] ?? 0) > 0).toList();
    if (modes.isEmpty) return const SizedBox.shrink();

    final p = AppPalette.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: modes.map((m) {
          final c = colors[m] ?? widget.color;
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: c.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: c.withValues(alpha: 0.25)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(iconOf[m], size: 14, color: c),
                const SizedBox(width: 6),
                Text('${counts[m]}',
                    style: TextStyle(
                        color: p.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w800)),
                const SizedBox(width: 4),
                Text(m,
                    style: TextStyle(
                        color: p.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500)),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── 2. Radar hero (full-width, large) ──────────────────────────────────────

  Widget _radarHero() {
    final home = widget.address;
    if (home?.lat == null || home?.lng == null) return const SizedBox.shrink();
    final hlat = home!.lat!, hlng = home.lng!;

    // Plot nearby transit at its true compass bearing + distance from home.
    final pts = widget.amenities
        .where((a) => (a.distanceMeters ?? 0) > 0)
        .take(40)
        .toList();
    if (pts.isEmpty) return const SizedBox.shrink();

    double maxD = 0;
    for (final a in pts) {
      final d = (a.distanceMeters ?? 0).toDouble();
      if (d > maxD) maxD = d;
    }
    maxD = maxD.clamp(300, 2000).toDouble();

    double bearing(double lat2, double lon2) {
      final dLon = (lon2 - hlng) * pi / 180;
      final y = sin(dLon) * cos(lat2 * pi / 180);
      final x = cos(hlat * pi / 180) * sin(lat2 * pi / 180) -
          sin(hlat * pi / 180) * cos(lat2 * pi / 180) * cos(dLon);
      return atan2(y, x); // radians from north, clockwise
    }

    final blips = [
      for (final a in pts)
        _RadarBlip(
          bearing(a.lat, a.lng),
          ((a.distanceMeters ?? 0) / maxD).clamp(0.0, 1.0),
          _kTransportColors[a.type] ?? const Color(0xFF3B82F6),
        ),
    ];

    final p = AppPalette.of(context);
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF060C19),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: p.border),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          Center(
            child: SizedBox(
              height: 248,
              child: AspectRatio(
                aspectRatio: 1,
                // Pinch to zoom / pan the radar to inspect crowded directions.
                child: InteractiveViewer(
                  minScale: 1.0,
                  maxScale: 3.5,
                  // Pinch-to-zoom only. Panning must stay OFF so single-finger
                  // vertical drags fall through to the sheet's scroll — with it
                  // on, the full-width radar swallows drags and you can't scroll
                  // down to the sections below it (e.g. "Lines serving this area").
                  panEnabled: false,
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 900),
                    curve: Curves.easeOutCubic,
                    builder: (_, v, __) => AnimatedBuilder(
                      animation: _pulseCtrl,
                      builder: (_, __) => CustomPaint(
                        painter: _CompassRadarPainter(
                          blips: blips,
                          animValue: v,
                          pulseValue: _pulseCtrl.value,
                          headingRad: (_heading ?? 0) * pi / 180,
                          hasHeading: _heading != null,
                          ringColor: Colors.white,
                          labelColor: Colors.white.withValues(alpha: 0.92),
                          youColor: AppColors.accent2,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(_heading != null ? Icons.explore_rounded : Icons.pinch_rounded,
                  size: 11, color: p.textTertiary),
              const SizedBox(width: 5),
              Text(
                _heading != null
                    ? 'Compass live · ring = ${(maxD / 1000).toStringAsFixed(maxD >= 1000 ? 1 : 2)} km'
                    : 'Pinch to zoom · ring = ${(maxD / 1000).toStringAsFixed(maxD >= 1000 ? 1 : 2)} km',
                style: TextStyle(color: p.textTertiary, fontSize: 10.5),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── 3. Legend row ──────────────────────────────────────────────────────────

  Widget _legendRow() {
    final visible = widget.subtypes.take(6).toList();
    if (visible.isEmpty) return const SizedBox.shrink();
    final p = AppPalette.of(context);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          ...visible.map((st) {
            final color = _kTransportColors[st.type] ?? const Color(0xFF3B82F6);
            final label = (_subTypeLabel[st.type] ?? _prettify(st.type))
                .split(' ')
                .first;
            return Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Container(
                  width: 7, height: 7,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: color.withValues(alpha: 0.55), blurRadius: 4)],
                  ),
                ),
                const SizedBox(width: 5),
                Text(label,
                    style: TextStyle(
                        color: p.textTertiary,
                        fontSize: 11,
                        fontWeight: FontWeight.w500)),
              ]),
            );
          }),
          Row(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 7, height: 7,
              decoration: BoxDecoration(
                color: AppColors.accent2,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: AppColors.accent2.withValues(alpha: 0.55), blurRadius: 4)
                ],
              ),
            ),
            const SizedBox(width: 5),
            Text('You',
                style: TextStyle(
                    color: p.textTertiary,
                    fontSize: 11,
                    fontWeight: FontWeight.w500)),
          ]),
        ],
      ),
    );
  }

  // ── 4. Arrivals card ────────────────────────────────────────────────────────

  Widget _arrivalsCard() {
    final color = widget.color;
    final groups = _groupArrivals(_arrivals).take(5).toList();
    final p = AppPalette.of(context);
    final stop = _carrisStop;
    return Container(
      decoration: BoxDecoration(
        color: p.surface2,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: p.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Row(children: [
              Icon(Icons.schedule_rounded, size: 13,
                  color: p.textTertiary),
              const SizedBox(width: 6),
              Text(
                'UPCOMING ARRIVALS',
                style: TextStyle(
                  color: p.textTertiary,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.4,
                ),
              ),
              if (stop != null) ...[
                const Spacer(),
                Icon(Icons.directions_rounded, size: 13, color: color),
                const SizedBox(width: 3),
                Text('Tap for directions',
                    style: TextStyle(color: color, fontSize: 10)),
              ],
            ]),
          ),
          const SizedBox(height: 8),

          // One row per line + destination (duplicate times collapsed)
          ...List.generate(groups.length, (i) {
            final g = groups[i];
            final soonest = g.minutes.first;
            final line = _lineColors[g.lineId];
            final chipColor = line != null ? Color(line.colorInt) : color;
            final chipText = line?.shortName ?? g.lineId;
            final chipFg = line != null ? Color(line.textColorInt) : Colors.white;

            // Urgency colour keyed off the soonest arrival.
            final Color timeColor;
            if (soonest > 10) {
              timeColor = const Color(0xFF22C55E);
            } else if (soonest > 3) {
              timeColor = const Color(0xFFF59E0B);
            } else {
              timeColor = const Color(0xFFEF4444);
            }
            // "7 min" or "7 · 22 · 40 min"
            final timeLabel =
                '${g.minutes.map((m) => m == 0 ? 'Now' : '$m').join(' · ')} min';

            final isLast = i == groups.length - 1;
            return Column(children: [
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: stop == null
                    ? null
                    : () => _openDirections(context, stop.lat, stop.lon,
                        label: stop.name),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                  child: Row(children: [
                    // Line chip
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: chipColor,
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(
                        chipText,
                        style: TextStyle(
                            color: chipFg,
                            fontSize: 10,
                            fontWeight: FontWeight.w800),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Destination
                    Expanded(
                      child: Text(
                        g.headsign,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: p.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Time badge with urgency tint
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: timeColor.withValues(alpha: 0.11),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                            color: timeColor.withValues(alpha: 0.28),
                            width: 0.8),
                      ),
                      child: Text(
                        timeLabel,
                        style: TextStyle(
                          color: timeColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ]),
                ),
              ),
              if (!isLast)
                Divider(
                  height: 1, thickness: 0.5,
                  indent: 16, endIndent: 16,
                  color: p.border,
                ),
            ]);
          }),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

// ── Transit lines serving the area (Lisbon / Carris) ─────────────────────────

class _TransitLinesSection extends StatefulWidget {
  final double lat;
  final double lng;
  final Color color;
  final List<AmenityModel> amenities; // nearest-first transit amenities (OSM)
  const _TransitLinesSection({
    required this.lat,
    required this.lng,
    required this.color,
    required this.amenities,
  });

  @override
  State<_TransitLinesSection> createState() => _TransitLinesSectionState();
}

class _TransitLinesSectionState extends State<_TransitLinesSection> {
  bool _loaded = false;
  bool _expanded = false;
  final Map<String, CarrisStop> _lineStop = {}; // line id → nearest stop
  List<CarrisStop> _stops = []; // all stops within radius (nearest-first)
  Map<String, CarrisLine> _lines = {};
  List<String> _order = [];
  // OSM fallback lines used when Carris has no stops nearby — central Lisbon,
  // Porto, and everywhere outside the AML. Built first from local `route_ref`
  // tags (no network, always shows), then enriched with route-relation termini
  // + colour + mode when the Overpass call returns.
  List<_DisplayLine> _osmLines = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final stops = await CarrisService.stopsWithin(widget.lat, widget.lng, 700);
    final lineStop = <String, CarrisStop>{};
    for (final s in stops) {
      // stops are nearest-first, so first occurrence is the closest stop.
      for (final l in s.lines) {
        lineStop.putIfAbsent(l, () => s);
      }
    }
    final lines = await CarrisService.lineInfoMap(lineStop.keys.toList());
    final order = lineStop.keys.toList()
      ..sort((a, b) {
        final na = int.tryParse(a), nb = int.tryParse(b);
        if (na != null && nb != null) return na.compareTo(nb);
        return a.compareTo(b);
      });
    // Local baseline from OSM `route_ref` tags — no network, so the section
    // shows immediately when Carris has nothing nearby.
    final localLines = order.isEmpty ? _buildLocalLines() : <_DisplayLine>[];
    if (!mounted) return;
    setState(() {
      _lineStop
        ..clear()
        ..addAll(lineStop);
      _stops = stops;
      _lines = lines;
      _order = order;
      _osmLines = localLines;
      _loaded = true;
    });

    // Enrich the fallback lines with route-relation data (termini, colour,
    // mode) once Overpass responds. Failure here just leaves the baseline.
    if (order.isEmpty) {
      final routes =
          await OsmTransitService.linesAround(widget.lat, widget.lng, 700);
      if (!mounted || routes.isEmpty) return;
      setState(() => _osmLines = _mergeRelations(localLines, routes));
    }
  }

  static String _osmModeForType(String type) {
    switch (type) {
      case 'subway_entrance':
        return 'subway';
      case 'station':
        return 'train';
      case 'tram_stop':
        return 'tram';
      case 'ferry_terminal':
        return 'ferry';
      default:
        return 'bus';
    }
  }

  static void _sortDisplay(List<_DisplayLine> lines) {
    lines.sort((a, b) {
      if (a.modeRank != b.modeRank) return a.modeRank.compareTo(b.modeRank);
      final na = int.tryParse(a.ref), nb = int.tryParse(b.ref);
      if (na != null && nb != null) return na.compareTo(nb);
      if (na != null) return -1;
      if (nb != null) return 1;
      return a.ref.compareTo(b.ref);
    });
  }

  /// One line per distinct OSM `route_ref`, keyed to its nearest stop. Reliable
  /// baseline (no network) so the section never disappears.
  List<_DisplayLine> _buildLocalLines() {
    final stopByRef = <String, AmenityModel>{};
    final distByRef = <String, int>{};
    for (final a in widget.amenities) {
      final raw = a.tags?['route_ref']?.toString() ?? '';
      if (raw.isEmpty) continue;
      final d = a.distanceMeters ?? 999999;
      for (final r in raw
          .split(RegExp(r'[;,/]+'))
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)) {
        if (d < (distByRef[r] ?? 999999)) {
          distByRef[r] = d;
          stopByRef[r] = a;
        }
      }
    }
    final lines = stopByRef.entries
        .map((e) => _DisplayLine(
              ref: e.key,
              mode: _osmModeForType(e.value.type),
              from: '',
              to: '',
              colour: '',
              distanceM: distByRef[e.key],
              stop: e.value,
            ))
        .toList();
    _sortDisplay(lines);
    return lines;
  }

  /// Enrich the local baseline with route-relation termini/colour/mode, and add
  /// any relation-only lines (e.g. Metro, which has no stop `route_ref`).
  List<_DisplayLine> _mergeRelations(
      List<_DisplayLine> local, List<OsmRouteLine> routes) {
    final relByRef = <String, OsmRouteLine>{};
    for (final r in routes) {
      relByRef.putIfAbsent(r.ref, () => r);
    }
    final result = <_DisplayLine>[];
    final seen = <String>{};
    for (final l in local) {
      seen.add(l.ref);
      final rel = relByRef[l.ref];
      result.add(rel == null
          ? l
          : _DisplayLine(
              ref: l.ref,
              mode: rel.mode,
              from: rel.from,
              to: rel.to,
              colour: rel.colour,
              distanceM: l.distanceM,
              stop: l.stop,
            ));
    }
    for (final r in routes) {
      if (!seen.add(r.ref)) continue;
      result.add(_DisplayLine(
        ref: r.ref,
        mode: r.mode,
        from: r.from,
        to: r.to,
        colour: r.colour,
        distanceM: null,
        stop: null,
      ));
    }
    _sortDisplay(result);
    return result;
  }

  /// Full-route timeline sheet: every stop the line serves, in order, with the
  /// stops nearest you highlighted.
  void _showLineDetails(String id) {
    final line = _lines[id];
    final serving = _stops.where((s) => s.lines.contains(id)).toList();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (_) => _LineRouteSheet(
        lineId: id,
        line: line,
        accent: widget.color,
        userLat: widget.lat,
        userLng: widget.lng,
        nearbyServing: serving,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final usingCarris = _order.isNotEmpty;
    final usingOsm = !usingCarris && _osmLines.isNotEmpty;
    if (!_loaded || (!usingCarris && !usingOsm)) return const SizedBox.shrink();
    final p = AppPalette.of(context);
    final color = widget.color;

    final total = usingCarris ? _order.length : _osmLines.length;
    final hasMore = total > 6;

    final rows = <Widget>[];
    void addRow(Widget row) {
      if (rows.isNotEmpty) {
        rows.add(Divider(height: 1, color: Colors.white.withValues(alpha: 0.05)));
      }
      rows.add(row);
    }

    if (usingCarris) {
      final shown = _expanded ? _order : _order.take(6).toList();
      for (final id in shown) {
        addRow(_lineRow(id, p, color));
      }
    } else {
      final shown = _expanded ? _osmLines : _osmLines.take(6).toList();
      for (final l in shown) {
        addRow(_osmLineRow(l, p));
      }
    }

    return _Section(
      title: 'LINES SERVING THIS AREA',
      child: Container(
        decoration: BoxDecoration(
          color: p.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: p.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            if (usingOsm) _osmSourceNote(p),
            ...rows,
            if (hasMore)
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => setState(() => _expanded = !_expanded),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  child: Text(
                    _expanded ? 'Show fewer' : 'Show all $total lines',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: color, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
          ],
        ),
      ),
    ).animate(delay: 100.ms).fadeIn(duration: 350.ms);
  }

  // Small "sourced from OpenStreetMap" strip shown above the OSM fallback rows.
  Widget _osmSourceNote(AppPalette p) => Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(14, 9, 14, 9),
        decoration: BoxDecoration(
          border: Border(
              bottom: BorderSide(color: Colors.white.withValues(alpha: 0.05))),
        ),
        child: Row(
          children: [
            Icon(Icons.public_rounded, size: 12, color: p.textTertiary),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                'Routes & colours from OpenStreetMap · live times available in Lisbon',
                style: TextStyle(color: p.textTertiary, fontSize: 10.5),
              ),
            ),
          ],
        ),
      );

  // ── OSM route-relation row + detail sheet ───────────────────────────────────

  // English names for Lisbon Metro lines (OSM tags them in Portuguese).
  static const _ptMetroEn = {
    'Azul': 'Blue',
    'Amarela': 'Yellow',
    'Verde': 'Green',
    'Vermelha': 'Red',
  };

  Widget _osmLineRow(_DisplayLine l, AppPalette p) {
    final chipBg = Color(l.colorInt);
    final chipFg = Color(l.textColorInt);
    final dist = l.distanceM;
    final metroEn = l.mode == 'subway' ? _ptMetroEn[l.ref] : null;
    final subtitle = [
      metroEn != null ? '${l.modeLabel} · $metroEn line' : l.modeLabel,
      if (dist != null) _dist(dist),
    ].join(' · ');

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _showOsmRoute(l),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              constraints: const BoxConstraints(minWidth: 30),
              decoration: BoxDecoration(
                color: chipBg,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(l.ref,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: chipFg,
                      fontSize: 11,
                      fontWeight: FontWeight.w800)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l.primaryText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: p.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w500)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: p.textTertiary, fontSize: 11)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right_rounded, size: 18, color: p.textTertiary),
          ],
        ),
      ),
    );
  }

  /// Detail sheet for an OSM line: mode, both termini, colour, nearest stop +
  /// directions. (No live timeline outside Lisbon — OSM has no ordered pattern.)
  void _showOsmRoute(_DisplayLine l) {
    final p = AppPalette.of(context);
    final chipBg = Color(l.colorInt);
    final chipFg = Color(l.textColorInt);
    final metroEn = l.mode == 'subway' ? _ptMetroEn[l.ref] : null;
    final stop = l.stop;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: p.bg,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    constraints: const BoxConstraints(minWidth: 34),
                    decoration: BoxDecoration(
                      color: chipBg,
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: Text(l.ref,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: chipFg,
                            fontSize: 14,
                            fontWeight: FontWeight.w800)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      metroEn != null
                          ? '${l.modeLabel} · $metroEn line'
                          : '${l.modeLabel} line',
                      style: TextStyle(
                        color: p.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              if (l.hasTermini) ...[
                Text(
                  'ROUTE',
                  style: TextStyle(
                    color: p.textTertiary,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.4,
                  ),
                ),
                const SizedBox(height: 10),
                // Start → end termini as a mini timeline.
                _osmTerminus(p, chipBg, l.from.isEmpty ? '—' : l.from,
                    isStart: true),
                Padding(
                  padding: const EdgeInsets.only(left: 5),
                  child: Container(
                      width: 2, height: 16, color: chipBg.withValues(alpha: 0.5)),
                ),
                _osmTerminus(p, chipBg, l.to.isEmpty ? '—' : l.to, isStart: false),
                const SizedBox(height: 18),
              ] else if (stop != null) ...[
                Text('Serves ${stop.name} near you',
                    style: TextStyle(color: p.textSecondary, fontSize: 13)),
                const SizedBox(height: 18),
              ],
              if (stop != null)
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: widget.color.withValues(alpha: 0.16),
                      foregroundColor: widget.color,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      Navigator.pop(ctx);
                      _openDirections(context, stop.lat, stop.lng,
                          label: stop.name);
                    },
                    icon: const Icon(Icons.directions_rounded, size: 18),
                    label: Text('Directions to ${stop.name}'),
                  ),
                )
              else
                Text('Serves this area · nearest stop not identified',
                    style: TextStyle(color: p.textTertiary, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }

  // One terminus row (dot + name) for the OSM route detail sheet.
  Widget _osmTerminus(AppPalette p, Color dotColor, String name,
      {required bool isStart}) {
    return Row(
      children: [
        Container(
          width: 12, height: 12,
          decoration: BoxDecoration(
            color: isStart ? dotColor : p.bg,
            shape: BoxShape.circle,
            border: Border.all(color: dotColor, width: 2),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(name,
              style: TextStyle(
                  color: p.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }

  Widget _lineRow(String id, AppPalette p, Color fallback) {
    final stop = _lineStop[id]!;
    final line = _lines[id];
    final chipColor = line != null ? Color(line.colorInt) : fallback;
    final chipFg = line != null ? Color(line.textColorInt) : Colors.white;
    final chipText = line?.shortName ?? id;
    final (from, to) = line?.termini ?? (stop.name, '');
    final routeText = to.isEmpty ? from : '$from → $to';
    final dist = stop.distanceTo(widget.lat, widget.lng).round();

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _showLineDetails(id),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: chipColor,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(chipText,
                  style: TextStyle(
                      color: chipFg,
                      fontSize: 11,
                      fontWeight: FontWeight.w800)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(routeText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: p.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w500)),
                  const SizedBox(height: 2),
                  Text('${_dist(dist)} · ${stop.name}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: p.textTertiary, fontSize: 11)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right_rounded, size: 18, color: p.textTertiary),
          ],
        ),
      ),
    );
  }
}


// ── Full-route timeline sheet ─────────────────────────────────────────────────

/// A route's complete ordered stop list rendered as a vertical timeline, with
/// the stops nearest the user highlighted (and the single closest flagged).
class _LineRouteSheet extends StatefulWidget {
  final String lineId;
  final CarrisLine? line;
  final Color accent;
  final double userLat;
  final double userLng;
  final List<CarrisStop> nearbyServing;

  const _LineRouteSheet({
    required this.lineId,
    required this.line,
    required this.accent,
    required this.userLat,
    required this.userLng,
    required this.nearbyServing,
  });

  @override
  State<_LineRouteSheet> createState() => _LineRouteSheetState();
}

class _LineRouteSheetState extends State<_LineRouteSheet> {
  static const _nearRadiusM = 700.0;

  List<CarrisStop> _stops = [];
  bool _loaded = false;
  int _nearestIdx = -1; // index of the single closest stop on the route

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    var stops = await CarrisService.routeStops(widget.lineId);
    // Fallback to the nearby stops we already have if the pattern lookup fails
    // (non-Lisbon line or a transient API error).
    if (stops.isEmpty) stops = widget.nearbyServing;

    int nearestIdx = -1;
    double best = double.infinity;
    for (var i = 0; i < stops.length; i++) {
      final d = stops[i].distanceTo(widget.userLat, widget.userLng);
      if (d < best) { best = d; nearestIdx = i; }
    }

    if (!mounted) return;
    setState(() {
      _stops = stops;
      _nearestIdx = nearestIdx;
      _loaded = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final line = widget.line;
    final chipColor = line != null ? Color(line.colorInt) : widget.accent;
    final chipFg = line != null ? Color(line.textColorInt) : Colors.white;
    final chipText = line?.shortName ?? widget.lineId;
    final (from, to) = line?.termini ?? ('', '');
    final routeText =
        to.isEmpty ? (line?.longName ?? 'Line $chipText') : '$from → $to';
    final nearCount =
        _stops.where((s) => s.distanceTo(widget.userLat, widget.userLng) <= _nearRadiusM).length;

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (ctx, ctrl) => Container(
        decoration: BoxDecoration(
          color: p.bg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
        ),
        child: Column(
          children: [
            // Handle
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 4),
              child: Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
            // Header: line chip + route + stop-count subline
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 14),
              child: Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: chipColor,
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: Text(chipText,
                        style: TextStyle(
                            color: chipFg,
                            fontSize: 14,
                            fontWeight: FontWeight.w800)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          routeText,
                          style: TextStyle(
                            color: p.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            height: 1.2,
                          ),
                        ),
                        if (_loaded && _stops.isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Text(
                            nearCount > 0
                                ? '${_stops.length} stops · $nearCount near you'
                                : '${_stops.length} stops on this line',
                            style: TextStyle(
                                color: p.textTertiary, fontSize: 11.5),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: p.border),
            // Timeline
            Expanded(
              child: !_loaded
                  ? Center(
                      child: SizedBox(
                        width: 22, height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(
                              widget.accent.withValues(alpha: 0.6)),
                        ),
                      ),
                    )
                  : _stops.isEmpty
                      ? Center(
                          child: Text('Route details unavailable.',
                              style: TextStyle(
                                  color: p.textTertiary, fontSize: 13)),
                        )
                      : ListView.builder(
                          controller: ctrl,
                          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                          itemCount: _stops.length,
                          itemBuilder: (_, i) => _stopRow(i, chipColor, p),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stopRow(int i, Color railColor, AppPalette p) {
    final s = _stops[i];
    final isFirst = i == 0;
    final isLast = i == _stops.length - 1;
    final d = s.distanceTo(widget.userLat, widget.userLng);
    final isNear = d <= _nearRadiusM;
    final isNearest = i == _nearestIdx;
    final isTerminus = isFirst || isLast;

    final dotColor = isNearest
        ? widget.accent
        : isNear
            ? widget.accent.withValues(alpha: 0.9)
            : railColor;

    return IntrinsicHeight(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _openDirections(context, s.lat, s.lon, label: s.name),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Rail + dot
            SizedBox(
              width: 26,
              child: CustomPaint(
                painter: _RailPainter(
                  color: railColor.withValues(alpha: 0.35),
                  dotColor: dotColor,
                  holeColor: p.bg,
                  isFirst: isFirst,
                  isLast: isLast,
                  emphasized: isNear || isTerminus,
                  ringColor: isNearest
                      ? widget.accent.withValues(alpha: 0.35)
                      : Colors.transparent,
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Stop content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 9),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            s.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: isNear || isTerminus
                                  ? p.textPrimary
                                  : p.textSecondary,
                              fontSize: 13.5,
                              fontWeight: isNear || isTerminus
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              height: 1.2,
                            ),
                          ),
                        ),
                        if (isNearest) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: widget.accent.withValues(alpha: 0.16),
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: Text(
                              'NEAREST',
                              style: TextStyle(
                                color: widget.accent,
                                fontSize: 8.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ] else if (isFirst || isLast) ...[
                          const SizedBox(width: 8),
                          Text(
                            isFirst ? 'START' : 'END',
                            style: TextStyle(
                              color: p.textTertiary,
                              fontSize: 8.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (isNear) ...[
                      const SizedBox(height: 2),
                      Text(
                        '${_dist(d.round())} from you · tap for directions',
                        style: TextStyle(
                            color: widget.accent.withValues(alpha: 0.85),
                            fontSize: 11),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Draws the vertical connector + stop dot for one timeline row.
class _RailPainter extends CustomPainter {
  final Color color;
  final Color dotColor;
  final Color ringColor;
  final Color holeColor;
  final bool isFirst;
  final bool isLast;
  final bool emphasized;

  const _RailPainter({
    required this.color,
    required this.dotColor,
    required this.ringColor,
    required this.holeColor,
    required this.isFirst,
    required this.isLast,
    required this.emphasized,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    // Dot sits near the top of the row so it aligns with the first text line.
    final cy = 18.0;
    final line = Paint()
      ..color = color
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    if (!isFirst) canvas.drawLine(Offset(cx, 0), Offset(cx, cy), line);
    if (!isLast) canvas.drawLine(Offset(cx, cy), Offset(cx, size.height), line);

    final r = emphasized ? 6.0 : 4.0;
    if (ringColor.a > 0) {
      canvas.drawCircle(Offset(cx, cy), r + 4, Paint()..color = ringColor);
    }
    // Filled dot for emphasized/terminus stops; hollow for the rest.
    canvas.drawCircle(Offset(cx, cy), r, Paint()..color = dotColor);
    if (!emphasized) {
      canvas.drawCircle(Offset(cx, cy), r - 1.5, Paint()..color = holeColor);
    }
  }

  @override
  bool shouldRepaint(_RailPainter old) =>
      old.dotColor != dotColor ||
      old.color != color ||
      old.ringColor != ringColor ||
      old.holeColor != holeColor ||
      old.emphasized != emphasized;
}

// ── Display line for the OSM "lines serving this area" fallback ───────────────

/// A line shown in the fallback list. Built from a local OSM `route_ref` stop
/// (reliable baseline) and optionally enriched with route-relation termini +
/// colour + mode. Delegates colour/label helpers to [OsmRouteLine].
class _DisplayLine {
  final String ref;
  final String mode;
  final String from;
  final String to;
  final String colour;
  final int? distanceM;
  final AmenityModel? stop; // nearest local stop (directions + fallback name)

  const _DisplayLine({
    required this.ref,
    required this.mode,
    required this.from,
    required this.to,
    required this.colour,
    required this.distanceM,
    required this.stop,
  });

  OsmRouteLine get _osm => OsmRouteLine(
      mode: mode, ref: ref, from: from, to: to, colour: colour, name: '');

  int get colorInt => _osm.colorInt;
  int get textColorInt => _osm.textColorInt;
  String get modeLabel => _osm.modeLabel;
  bool get hasTermini => from.isNotEmpty || to.isNotEmpty;
  String get terminiText => _osm.terminiText;

  int get modeRank {
    const order = {
      'subway': 0,
      'light_rail': 1,
      'train': 2,
      'tram': 3,
      'ferry': 4,
      'trolleybus': 5,
      'bus': 6,
    };
    return order[mode] ?? 7;
  }

  /// Primary row text: termini when enriched, else "via [nearest stop]".
  String get primaryText => hasTermini
      ? terminiText
      : (stop != null ? 'via ${stop!.name}' : modeLabel);
}

// ── Compass radar (nearby transit by true bearing + distance) ────────────────

class _RadarBlip {
  final double bearingRad; // 0 = north, clockwise
  final double distNorm;   // 0..1 (distance / maxDist)
  final Color color;
  const _RadarBlip(this.bearingRad, this.distNorm, this.color);
}

class _CompassRadarPainter extends CustomPainter {
  final List<_RadarBlip> blips;
  final double animValue;
  final double pulseValue; // 0..1 repeating, drives the "you" pulse
  final double headingRad; // device heading (clockwise from N); 0 = north-up
  final bool hasHeading;   // true once a live magnetometer reading is in
  final Color ringColor;
  final Color labelColor;
  final Color youColor;
  const _CompassRadarPainter({
    required this.blips,
    required this.animValue,
    required this.pulseValue,
    required this.headingRad,
    required this.hasHeading,
    required this.ringColor,
    required this.labelColor,
    required this.youColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    // Extra inset leaves room for the outer N/E/S/W labels so they never clip
    // the box edge (notably "S" against the caption below).
    final maxR = min(size.width, size.height) / 2 - 26;

    // Screen position for a compass angle (radians clockwise from true north),
    // rotated so the direction the phone faces sits at the top of the radar.
    Offset atAngle(double compassRad, double radius) {
      final a = compassRad - headingRad;
      return Offset(c.dx + radius * sin(a), c.dy - radius * cos(a));
    }

    // Concentric distance rings.
    for (int i = 1; i <= 3; i++) {
      canvas.drawCircle(
        c,
        maxR * i / 3,
        Paint()
          ..color = ringColor.withValues(alpha: 0.12)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
    }
    // N–S and E–W axes (rotate with heading so they track true compass).
    final axis = Paint()
      ..color = ringColor.withValues(alpha: 0.14)
      ..strokeWidth = 1;
    canvas.drawLine(atAngle(0, maxR), atAngle(pi, maxR), axis);
    canvas.drawLine(atAngle(pi / 2, maxR), atAngle(3 * pi / 2, maxR), axis);

    // Fixed "ahead" marker straddling the top of the ring — the direction the
    // phone is pointing. Only meaningful with a live heading (not on simulator).
    if (hasHeading) {
      final ahead = ui.Path()
        ..moveTo(c.dx, c.dy - maxR - 6)
        ..lineTo(c.dx - 5, c.dy - maxR + 3)
        ..lineTo(c.dx + 5, c.dy - maxR + 3)
        ..close();
      canvas.drawPath(ahead, Paint()..color = youColor);
    }

    // Compass labels — bright, upright, positioned around the rotated ring so
    // N always points to true north as you turn.
    final tp = TextPainter(textDirection: TextDirection.ltr);
    void label(String s, Offset o, {Color? color}) {
      tp.text = TextSpan(
        text: s,
        style: TextStyle(
          color: color ?? labelColor,
          fontSize: 12.5,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
          shadows: const [
            Shadow(color: Color(0xCC060C19), blurRadius: 4),
          ],
        ),
      );
      tp.layout();
      tp.paint(canvas, o - Offset(tp.width / 2, tp.height / 2));
    }

    // Cardinals coloured like a phone compass: north red, the rest bright white.
    const northColor = Color(0xFFFF453A);
    label('N', atAngle(0, maxR + 13), color: northColor);
    label('E', atAngle(pi / 2, maxR + 13));
    label('S', atAngle(pi, maxR + 13));
    label('W', atAngle(3 * pi / 2, maxR + 13));

    // Blips at true bearing + scaled distance (rotated with heading).
    for (final b in blips) {
      final r = maxR * b.distNorm.clamp(0.06, 1.0) * animValue;
      final pos = atAngle(b.bearingRad, r);
      canvas.drawCircle(pos, 8, Paint()..color = b.color.withValues(alpha: 0.18));
      canvas.drawCircle(pos, 4.5, Paint()..color = b.color);
      canvas.drawCircle(
        pos,
        4.5,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.85)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
    }

    // Animated "you" pulse — two rings expanding out of the centre, staggered
    // half a cycle apart, fading as they grow. Gives the "you are here" beacon.
    const youR = 7.0;
    for (int i = 0; i < 2; i++) {
      final phase = (pulseValue + i * 0.5) % 1.0;
      final pr = youR + phase * (maxR * 0.55);
      canvas.drawCircle(
        c,
        pr,
        Paint()
          ..color = youColor.withValues(alpha: (1 - phase) * 0.40 * animValue)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }

    // "You" at the centre — soft glow + solid dot + white ring.
    canvas.drawCircle(
        c, youR * 2.2 * animValue, Paint()..color = youColor.withValues(alpha: 0.22));
    canvas.drawCircle(c, youR * animValue, Paint()..color = youColor);
    canvas.drawCircle(
      c,
      youR * animValue,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  @override
  bool shouldRepaint(_CompassRadarPainter old) =>
      old.animValue != animValue ||
      old.pulseValue != pulseValue ||
      old.headingRad != headingRad ||
      old.hasHeading != hasHeading ||
      old.blips != blips;
}

// ── Utilities ──────────────────────────────────────────────────────────────────

/// Human transit-mode tag from an OSM sub-type.
String _modeTag(String type) {
  switch (type) {
    case 'subway_entrance':
      return 'METRO';
    case 'station':
      return 'TRAIN';
    case 'tram_stop':
      return 'TRAM';
    case 'ferry_terminal':
      return 'FERRY';
    case 'taxi':
      return 'TAXI';
    case 'bus_stop':
      return 'BUS';
    default:
      return 'TRANSIT';
  }
}

String _prettify(String type) =>
    type.replaceAll('_', ' ').split(' ').map((w) => w.isEmpty ? '' : w[0].toUpperCase() + w.substring(1)).join(' ');
