import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../config/app_theme.dart';
import '../../config/score_format.dart';
import '../../models/address_model.dart';
import '../../models/amenity_model.dart';
import '../../models/carris_models.dart';
import '../../models/score_model.dart';
import '../../services/carris_service.dart';

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

const _subTypeEmoji = <String, String>{
  'subway_entrance': '🚇',
  'bus_stop':        '🚌',
  'station':         '🚆',
  'taxi':            '🚕',
  'bicycle_rental':  '🚲',
  'tram_stop':       '🚃',
  'ferry_terminal':  '⛴',
  'parking':         '🅿',
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
            SliverToBoxAdapter(child: _buildScoreOverview()),
            if (widget.cat.id == 'transportation')
              SliverToBoxAdapter(child: _buildTransportDNA()),
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
                  '${widget.cat.count} places found within 2km',
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
    return _Section(
      title: 'TRANSIT RADAR',
      child: _TransitRadarSection(
        amenities: widget.amenities,
        address: widget.address,
        color: _color,
        subtypes: _subtypes,
      ),
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

class _TransitRadarSectionState extends State<_TransitRadarSection> {
  CarrisStop? _carrisStop;
  List<CarrisArrival> _arrivals = [];
  Map<String, CarrisLine> _lineColors = {};
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
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

  List<String> get _routes {
    if (_carrisStop != null && _carrisStop!.lines.isNotEmpty) {
      return _carrisStop!.lines;
    }
    final nearest = widget.amenities.isNotEmpty ? widget.amenities.first : null;
    if (nearest == null) return [];
    final ref = nearest.tags?['route_ref']?.toString() ?? '';
    return ref.isEmpty
        ? []
        : ref
            .split(RegExp(r'[;,/\s]+'))
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList();
  }

  @override
  Widget build(BuildContext context) {
    final nearest = widget.amenities.isNotEmpty ? widget.amenities.first : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1 ── Nearest stop information card
        if (nearest != null) _stopInfoCard(nearest),
        const SizedBox(height: 16),
        // 2 ── Radar as the hero visualization
        _radarHero(),
        const SizedBox(height: 10),
        // 3 ── Legend
        _legendRow(),
        // 4 ── Upcoming arrivals (shown after Carris loads)
        if (_loaded && _arrivals.isNotEmpty) ...[
          const SizedBox(height: 16),
          _arrivalsCard(),
        ],
      ],
    );
  }

  // ── 1. Stop info card ───────────────────────────────────────────────────────

  Widget _stopInfoCard(AmenityModel a) {
    final color = widget.color;
    final stColor = _kTransportColors[a.type] ?? color;
    final icon = _subTypeIcon[a.type] ?? Icons.train_rounded;
    final routes = _routes;
    final p = AppPalette.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: p.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header: icon + stop name + stop ID ─────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: stColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: stColor.withValues(alpha: 0.25)),
                ),
                child: Icon(icon, color: stColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _carrisStop?.name ?? a.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: p.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        height: 1.25,
                        letterSpacing: -0.2,
                      ),
                    ),
                    if (_carrisStop != null) ...[
                      const SizedBox(height: 2),
                      Row(children: [
                        Icon(Icons.bookmark_outline_rounded, size: 11,
                            color: p.textTertiary),
                        const SizedBox(width: 4),
                        Text(
                          'Stop ${_carrisStop!.id}',
                          style: TextStyle(
                            color: p.textTertiary,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ]),
                    ],
                  ],
                ),
              ),
              // Spinner while Carris loads
              if (!_loaded)
                SizedBox(
                  width: 16, height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.5,
                    valueColor: AlwaysStoppedAnimation(color.withValues(alpha: 0.45)),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 14),

          // ── Distance + walk time metadata row ────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: p.border, width: 0.8),
            ),
            child: Row(children: [
              _metaPill(Icons.near_me_rounded, _dist(a.distanceMeters), stColor),
              if (a.walkingMinutes != null) ...[
                Container(
                  width: 1, height: 16,
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                  color: p.border,
                ),
                _metaPill(
                  Icons.directions_walk_rounded,
                  '${a.walkingMinutes} min walk',
                  p.textSecondary,
                ),
              ],
            ]),
          ),

          // ── Route chips ──────────────────────────────────────────────
          if (routes.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(
              'ROUTES SERVED',
              style: TextStyle(
                color: p.textTertiary,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.4,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: routes.take(12).map((id) {
                final line = _lineColors[id];
                final bg = line != null ? Color(line.colorInt) : stColor;
                final fg = line != null ? Color(line.textColorInt) : Colors.white;
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: BorderRadius.circular(7),
                    boxShadow: [
                      BoxShadow(
                          color: bg.withValues(alpha: 0.35),
                          blurRadius: 6,
                          offset: const Offset(0, 2)),
                    ],
                  ),
                  child: Text(
                    line?.shortName ?? id,
                    style: TextStyle(
                      color: fg,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.3,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _metaPill(IconData icon, String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // ── 2. Radar hero (full-width, large) ──────────────────────────────────────

  Widget _radarHero() {
    if (widget.subtypes.isEmpty) return const SizedBox.shrink();
    final p = AppPalette.of(context);
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF060C19),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: p.border),
      ),
      padding: const EdgeInsets.all(12),
      child: Center(
        child: SizedBox(
          height: 220,
          child: AspectRatio(
            aspectRatio: 1,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 1400),
              curve: Curves.elasticOut,
              builder: (_, v, __) => CustomPaint(
                painter: _TransportDNARadarPainter(
                  subtypes: widget.subtypes,
                  animValue: v,
                ),
              ),
            ),
          ),
        ),
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
    final count = _arrivals.length.clamp(0, 4);
    final p = AppPalette.of(context);
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
            ]),
          ),
          const SizedBox(height: 8),

          // One row per arrival
          ...List.generate(count, (i) {
            final arr = _arrivals[i];
            final mins = arr.minutesUntil;
            final line = _lineColors[arr.lineId];
            final chipColor = line != null ? Color(line.colorInt) : color;
            final chipText = line?.shortName ?? arr.lineId;
            final chipFg = line != null ? Color(line.textColorInt) : Colors.white;

            // Urgency colour for the time badge
            final Color timeColor;
            if (mins == null || mins > 10) {
              timeColor = const Color(0xFF22C55E);
            } else if (mins > 3) {
              timeColor = const Color(0xFFF59E0B);
            } else {
              timeColor = const Color(0xFFEF4444);
            }
            final timeLabel =
                mins == null ? '—' : mins == 0 ? 'Now' : '$mins min';

            final isLast = i == count - 1;
            return Column(children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                child: Row(children: [
                  // Line chip
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
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
                      arr.headsign,
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
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: timeColor.withValues(alpha: 0.11),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: timeColor.withValues(alpha: 0.28), width: 0.8),
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

// ── Transport DNA spoke radar painter (premium) ───────────────────────────────

class _TransportDNARadarPainter extends CustomPainter {
  final List<_SubType> subtypes;
  final double animValue;

  const _TransportDNARadarPainter({
    required this.subtypes,
    required this.animValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final maxR = size.width / 2 * 0.80;
    final visible = subtypes.take(8).toList();
    final n = visible.length;

    canvas.drawCircle(c, size.width / 2, Paint()..color = const Color(0xFF060C19));

    for (int r = 1; r <= 4; r++) {
      canvas.drawCircle(c, maxR * r / 4,
          Paint()
            ..color = Colors.white.withValues(alpha: r == 4 ? 0.10 : 0.04)
            ..style = PaintingStyle.stroke
            ..strokeWidth = r == 4 ? 1.0 : 0.7);
    }

    if (n > 0) {
      for (int i = 0; i < n; i++) {
        final a = (2 * pi / n) * i - pi / 2;
        canvas.drawLine(c, Offset(c.dx + maxR * cos(a), c.dy + maxR * sin(a)),
            Paint()..color = Colors.white.withValues(alpha: 0.04)..strokeWidth = 0.8);
      }
    }

    _drawHomeIcon(canvas, c, animValue.clamp(0.0, 1.0));

    if (animValue <= 0.01 || n == 0) return;

    final maxScore = visible.map((s) => s.score).reduce(max);

    for (int i = 0; i < n; i++) {
      final angle = (2 * pi / n) * i - pi / 2;
      final st = visible[i];
      final normalized = maxScore > 0 ? st.score / maxScore : 0.0;
      final r = maxR * normalized * animValue;
      final tip = Offset(c.dx + r * cos(angle), c.dy + r * sin(angle));
      final color = _kTransportColors[st.type] ?? const Color(0xFF3B82F6);

      final a01 = animValue.clamp(0.0, 1.0);

      canvas.drawLine(c, tip,
          Paint()
            ..color = color.withValues(alpha: 0.38 * a01)
            ..strokeWidth = 1.5
            ..strokeCap = StrokeCap.round);

      canvas.drawCircle(tip, 20, Paint()..color = color.withValues(alpha: 0.07 * a01));
      canvas.drawCircle(tip, 14, Paint()..color = color.withValues(alpha: 0.14 * a01));
      canvas.drawCircle(tip, 11, Paint()..color = color.withValues(alpha: 0.90 * a01));
      canvas.drawCircle(tip, 11,
          Paint()
            ..color = Colors.white.withValues(alpha: 0.16)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.0);

      final emoji = _subTypeEmoji[st.type] ?? '🚌';
      final ep = TextPainter(textDirection: TextDirection.ltr)
        ..text = TextSpan(text: emoji, style: const TextStyle(fontSize: 10))
        ..layout();
      ep.paint(canvas, Offset(tip.dx - ep.width / 2, tip.dy - ep.height / 2));

      if (animValue > 0.60) {
        final alpha = ((animValue - 0.60) / 0.40).clamp(0.0, 1.0);
        final lp = TextPainter(textDirection: TextDirection.ltr)
          ..text = TextSpan(
              text: '×${st.count}',
              style: TextStyle(
                  color: color.withValues(alpha: 0.80 * alpha),
                  fontSize: 10,
                  fontWeight: FontWeight.w700))
          ..layout();
        final labelR = r + 20;
        lp.paint(canvas,
            Offset(c.dx + labelR * cos(angle) - lp.width / 2,
                c.dy + labelR * sin(angle) - lp.height / 2));
      }
    }
  }

  void _drawHomeIcon(Canvas canvas, Offset c, double alpha) {
    canvas.drawCircle(c, 28,
        Paint()..color = const Color(0xFF6C63FF).withValues(alpha: 0.05 * alpha));
    canvas.drawCircle(c, 20,
        Paint()..color = const Color(0xFF6C63FF).withValues(alpha: 0.12 * alpha));
    canvas.drawCircle(c, 20,
        Paint()
          ..color = const Color(0xFF6C63FF).withValues(alpha: 0.65 * alpha)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5);
    canvas.drawCircle(c, 12,
        Paint()..color = const Color(0xFF6C63FF).withValues(alpha: alpha));

    final tp = TextPainter(textDirection: TextDirection.ltr)
      ..text = const TextSpan(text: '🏠', style: TextStyle(fontSize: 13))
      ..layout();
    tp.paint(canvas, Offset(c.dx - tp.width / 2, c.dy - tp.height / 2));
  }

  @override
  bool shouldRepaint(_TransportDNARadarPainter old) =>
      old.animValue != animValue;
}

// ── Utilities ──────────────────────────────────────────────────────────────────

String _prettify(String type) =>
    type.replaceAll('_', ' ').split(' ').map((w) => w.isEmpty ? '' : w[0].toUpperCase() + w.substring(1)).join(' ');
