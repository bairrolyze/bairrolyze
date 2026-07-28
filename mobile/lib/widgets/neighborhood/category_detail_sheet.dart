import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../models/address_model.dart';
import '../../models/amenity_model.dart';
import '../../models/carris_models.dart';
import '../../models/score_model.dart';
import '../../services/carris_service.dart';

// ── Tokens ────────────────────────────────────────────────────────────────────
const _kBg      = Color(0xFF060B14);
const _kSurface = Color(0xFF0D1625);
const _kSurface2= Color(0xFF131F33);
const _kBorder  = Color(0xFF1A2845);
const _kAccent2 = Color(0xFF6C63FF);

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

Color _scoreColor(double s) {
  if (s >= 80) return const Color(0xFF22C55E);
  if (s >= 60) return const Color(0xFF3B82F6);
  if (s >= 40) return const Color(0xFFF59E0B);
  return const Color(0xFFEF4444);
}

String _scoreLabel(double s) {
  if (s >= 80) return 'Excellent';
  if (s >= 60) return 'Good';
  if (s >= 40) return 'Fair';
  return 'Poor';
}

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

String _whyText(String catId, double score, int count, int? closestM) {
  final tier = _scoreLabel(score).toLowerCase();
  final distStr = closestM != null ? _dist(closestM) : 'nearby';
  switch (catId) {
    case 'transportation':
      return score >= 80
          ? 'This property has $tier transportation access with $count transit options available, the nearest being just $distStr away. Car-free living is very practical here.'
          : score >= 60
          ? 'Transportation access is $tier with $count options within range. Most daily destinations are reachable without a car.'
          : 'Transportation options are limited with $count facilities in range. A private vehicle may be needed for some journeys.';
    case 'education':
      return score >= 80
          ? 'Education access is $tier with $count learning facilities nearby. The closest is just $distStr away, making school runs and campus visits easy.'
          : score >= 60
          ? 'Education provision is $tier with $count facilities within reach. Families and students will find reasonable access to schools and institutions.'
          : 'Educational facilities are limited with $count options in the area. Consider this if schooling proximity is a priority.';
    case 'healthcare':
      return score >= 80
          ? 'Healthcare access is $tier with $count facilities available, starting from $distStr. Emergency and routine care are both well covered.'
          : score >= 60
          ? 'Healthcare provision is $tier with $count facilities within range. Routine care is accessible without long travel.'
          : 'Healthcare options are limited with $count facilities nearby. Urgent or specialist care may require longer journeys.';
    case 'shopping':
      return score >= 80
          ? 'Shopping convenience is $tier with $count retail options available. Daily essentials are within easy walking distance — no car needed.'
          : score >= 60
          ? 'Shopping access is $tier with $count stores and markets in range. Most everyday needs can be met locally.'
          : 'Shopping options are limited with $count facilities nearby. A larger supermarket or shopping centre may require travel.';
    case 'safety':
      return score >= 80
          ? 'Safety infrastructure is $tier with $count emergency services in the vicinity. Response times should be fast given the proximity of services.'
          : score >= 60
          ? 'Safety provision is $tier with $count emergency services within range.'
          : 'Emergency services coverage is limited with $count facilities in the area.';
    case 'recreation':
      return score >= 80
          ? 'Recreation access is $tier with $count green spaces and leisure facilities nearby. The closest is just $distStr away — an active, outdoor lifestyle is well supported.'
          : score >= 60
          ? 'Recreation options are $tier with $count facilities in range. Parks and leisure areas are reasonably accessible.'
          : 'Recreation facilities are limited with $count options nearby. Green space access may require more deliberate travel.';
    default:
      return score >= 80
          ? 'This category scores $tier with $count places of interest, the nearest at $distStr.'
          : 'This category shows $tier availability with $count options within the search area.';
  }
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
  late final List<int> _distBands; // count per band: 0-200, 200-500, 500-1k, 1-2k, >2k
  late final List<double> _curve;  // relative score per distance band
  bool _showAllNearby = false;

  @override
  void initState() {
    super.initState();
    _color = _catColor[widget.cat.id] ?? const Color(0xFF3B82F6);
    _subtypes = _computeSubtypes();
    _distBands = _computeDistBands();
    _curve = _computeCurve();
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

  List<int> _computeDistBands() {
    final bands = [200, 500, 1000, 2000, 99999];
    final prev = [0, 200, 500, 1000, 2000];
    return List.generate(bands.length, (i) => widget.amenities
        .where((a) {
          final d = a.distanceMeters ?? 99999;
          return d > prev[i] && d <= bands[i];
        })
        .length);
  }

  List<double> _computeCurve() {
    final thresholds = [200.0, 500.0, 1000.0, 2000.0, 5000.0];
    final total = widget.amenities.length;
    if (total == 0) return List.filled(thresholds.length, 0);
    return thresholds.map((t) {
      final inRange = widget.amenities.where((a) => (a.distanceMeters ?? 99999) <= t).length;
      return (widget.cat.score * (0.35 + 0.65 * inRange / total)).clamp(0.0, 100.0);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;
    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      minChildSize: 0.5,
      maxChildSize: 0.96,
      builder: (ctx, ctrl) => Container(
        decoration: const BoxDecoration(
          color: _kBg,
          borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
        ),
        child: CustomScrollView(
          controller: ctrl,
          slivers: [
            SliverToBoxAdapter(child: _buildHandle()),
            SliverToBoxAdapter(child: _buildHeader()),
            SliverToBoxAdapter(child: _buildScoreOverview()),
            if (widget.cat.id == 'transportation')
              SliverToBoxAdapter(child: _buildTransportDNA()),
            SliverToBoxAdapter(child: _buildBreakdown()),
            SliverToBoxAdapter(child: _buildNearby()),
            if (widget.address?.lat != null && widget.address?.lng != null)
              SliverToBoxAdapter(child: _buildMiniMap()),
            SliverToBoxAdapter(child: _buildWhatMakes()),
            SliverToBoxAdapter(child: _buildQuickStats()),
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
          color: Colors.white.withOpacity(0.18),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    ),
  );

  // ── Header ──────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    final score = widget.cat.score;
    final color = _color;
    final label = _scoreLabel(score);

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: _kBorder)),
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
                    painter: _RingPainter(progress: 1, color: _kBorder, stroke: 5),
                  ),
                  CustomPaint(
                    size: const Size(80, 80),
                    painter: _RingPainter(progress: v, color: color, stroke: 5),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        score.round().toString(),
                        style: TextStyle(
                          color: color, fontSize: 24,
                          fontWeight: FontWeight.w900, height: 1,
                        ),
                      ),
                      Text('/ 100', style: TextStyle(
                        color: Colors.white.withOpacity(0.3), fontSize: 9.5,
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
                      widget.cat.label,
                      style: const TextStyle(
                        color: Colors.white,
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
                        color: _scoreColor(score).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: Text(
                        label,
                        style: TextStyle(
                          color: _scoreColor(score),
                          fontSize: 11.5, fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(7),
                        border: Border.all(color: color.withOpacity(0.25)),
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
                    color: Colors.white.withOpacity(0.38),
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

  // ── Score overview chart ─────────────────────────────────────────────────────

  Widget _buildScoreOverview() {
    const xLabels = ['0–200m', '–500m', '–1km', '–2km', '–5km'];
    const leftPad = 32.0;
    final color = _color;

    return _Section(
      title: 'SCORE OVERVIEW',
      child: SizedBox(
        height: 168,
        child: Stack(
          children: [
            // Chart canvas (leaves 20px at bottom for X labels)
            Positioned(
              left: 0, right: 0, top: 0, bottom: 20,
              child: CustomPaint(
                painter: _SparklinePainter(
                  values: _curve,
                  color: color,
                  leftPad: leftPad,
                ),
              ),
            ),
            // X-axis labels aligned to the chart area
            Positioned(
              left: leftPad, right: 0, bottom: 0, height: 20,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: xLabels.map((l) => Expanded(
                  child: Text(
                    l,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.30),
                      fontSize: 8.5,
                    ),
                  ),
                )).toList(),
              ),
            ),
          ],
        ),
      ),
    ).animate(delay: 80.ms).fadeIn(duration: 350.ms);
  }

  // ── Transit radar (transportation only) ──────────────────────────────────────

  // ── Subtype count cards (replaces sparkline) ─────────────────────────────────

  Widget _buildSubtypeCounts() {
    if (_subtypes.isEmpty) return const SizedBox.shrink();
    final isTransport = widget.cat.id == 'transportation';

    return _Section(
      title: 'AT A GLANCE',
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: _subtypes.map((st) {
          final stColor = isTransport
              ? (_kTransportColors[st.type] ?? _color)
              : _color;
          final icon  = _subTypeIcon[st.type] ?? _catIcon[widget.cat.id] ?? Icons.place_rounded;
          final label = (_subTypeLabel[st.type] ?? _prettify(st.type))
              .split(' ').first; // first word keeps chips compact

          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: _kSurface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: stColor.withOpacity(0.30)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: stColor, size: 20),
                const SizedBox(height: 6),
                Text(
                  '${st.count}',
                  style: TextStyle(
                    color: stColor,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.42),
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    ).animate(delay: 80.ms).fadeIn(duration: 300.ms);
  }

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

  // ── Breakdown ────────────────────────────────────────────────────────────────

  Widget _buildBreakdown() {
    if (_subtypes.isEmpty) return const SizedBox.shrink();
    final color = _color;
    final top = _subtypes.take(6).toList();
    final maxScore = top.map((s) => s.score).reduce(max);

    return _Section(
      title: 'BREAKDOWN',
      child: Column(
        children: List.generate(top.length, (i) {
          final s = top[i];
          final label = _subTypeLabel[s.type] ?? _prettify(s.type);
          final icon = _subTypeIcon[s.type] ?? _catIcon[widget.cat.id] ?? Icons.place_rounded;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Icon(icon, color: color, size: 15),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(label, style: const TextStyle(
                            color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w500,
                          )),
                          Text(
                            s.score.round().toString(),
                            style: TextStyle(
                              color: color, fontSize: 13, fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: s.score / maxScore),
                        duration: Duration(milliseconds: 700 + i * 80),
                        curve: Curves.easeOutCubic,
                        builder: (_, v, __) => ClipRRect(
                          borderRadius: BorderRadius.circular(3),
                          child: LinearProgressIndicator(
                            value: v,
                            minHeight: 5,
                            backgroundColor: _kBorder,
                            valueColor: AlwaysStoppedAnimation(color),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ).animate(delay: (i * 60).ms).fadeIn(duration: 300.ms).slideX(begin: 0.04, end: 0);
        }),
      ),
    );
  }

  // ── Nearby places ────────────────────────────────────────────────────────────

  Widget _buildNearby() {
    final isTransport = widget.cat.id == 'transportation';
    final limit = isTransport ? 8 : 6;
    final hasMore = widget.amenities.length > limit;
    final top = (_showAllNearby ? widget.amenities : widget.amenities.take(limit)).toList();
    if (top.isEmpty) return const SizedBox.shrink();
    final color = _color;
    final icon = _catIcon[widget.cat.id] ?? Icons.place_rounded;

    return _Section(
      title: isTransport ? 'NEARBY STOPS' : 'NEARBY PLACES',
      trailing: hasMore
          ? GestureDetector(
              onTap: () => setState(() => _showAllNearby = !_showAllNearby),
              child: Text(
                _showAllNearby
                    ? 'Show less'
                    : 'View all ${widget.amenities.length}',
                style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600),
              ),
            )
          : null,
      child: Container(
        decoration: BoxDecoration(
          color: _kSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _kBorder),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            for (int i = 0; i < top.length; i++) ...[
              if (i > 0) Divider(height: 1, color: Colors.white.withOpacity(0.05)),
              if (isTransport)
                _TransportStopCard(amenity: top[i], typeColor: color)
              else
                _NearbyTile(amenity: top[i], color: color, icon: icon),
            ],
          ],
        ),
      ),
    ).animate(delay: 120.ms).fadeIn(duration: 350.ms);
  }

  // ── Mini map ─────────────────────────────────────────────────────────────────

  Widget _buildMiniMap() {
    final lat = widget.address!.lat!;
    final lng = widget.address!.lng!;
    final color = _color;
    final icon = _catIcon[widget.cat.id] ?? Icons.place_rounded;
    final markers = widget.amenities.take(15).toList();

    return _Section(
      title: 'MAP PREVIEW',
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          height: 190,
          child: FlutterMap(
            options: MapOptions(
              initialCenter: LatLng(lat, lng),
              initialZoom: 15.5,
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
                  color: color.withOpacity(0.45),
                  strokeWidth: 1.5,
                  isDotted: true,
                )),
              ]),
              CircleLayer(circles: [
                CircleMarker(
                  point: LatLng(lat, lng),
                  radius: 500,
                  useRadiusInMeter: true,
                  color: color.withOpacity(0.08),
                  borderColor: color.withOpacity(0.35),
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
                      border: Border.all(color: _kBg, width: 2),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 6)],
                    ),
                    child: const Icon(Icons.home_rounded, color: Color(0xFF060B14), size: 16),
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
    final label = _scoreLabel(score).toLowerCase();
    final color = _color;

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
          color: _kSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _kBorder),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_kSurface, color.withOpacity(0.06)],
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
                      color: Colors.white.withOpacity(0.78),
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

  // ── Quick stats ──────────────────────────────────────────────────────────────

  Widget _buildQuickStats() {
    final closest = widget.amenities.isNotEmpty ? widget.amenities.first : null;
    final within500 = widget.amenities.where((a) => (a.distanceMeters ?? 99999) <= 500).length;
    final within1k = widget.amenities.where((a) => (a.distanceMeters ?? 99999) <= 1000).length;

    final stats = [
      _Stat('Nearest', closest != null ? _dist(closest.distanceMeters) : '—', Icons.near_me_rounded),
      _Stat('Walk time', closest?.walkingMinutes != null ? '${closest!.walkingMinutes} min' : '—', Icons.directions_walk_rounded),
      _Stat('Within 500m', '$within500 places', Icons.radio_button_checked_rounded),
      _Stat('Within 1km', '$within1k places', Icons.radio_button_off_rounded),
      _Stat('Within 2km', '${widget.cat.count} places', Icons.place_rounded),
      _Stat('Score', '${widget.cat.score.round()} / 100', Icons.bar_chart_rounded),
    ];

    return _Section(
      title: 'QUICK STATISTICS',
      child: GridView.count(
        crossAxisCount: 3,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1.45,
        children: stats.map((s) => _StatTile(stat: s, color: _color)).toList(),
      ),
    ).animate(delay: 240.ms).fadeIn(duration: 350.ms);
  }

  // ── Lifestyle tags ────────────────────────────────────────────────────────────

  Widget _buildLifestyle() {
    final tags = _lifestyleTags[widget.cat.id] ?? [];
    if (tags.isEmpty) return const SizedBox.shrink();

    return _Section(
      title: 'LIFESTYLE INSIGHTS',
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: tags.map((t) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: _kSurface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _kBorder),
          ),
          child: Text(t, style: TextStyle(
            color: Colors.white.withOpacity(0.82),
            fontSize: 12.5,
          )),
        )).toList(),
      ),
    ).animate(delay: 280.ms).fadeIn(duration: 350.ms);
  }

  // ── AI recommendation ─────────────────────────────────────────────────────────

  Widget _buildRecommendation() {
    final text = _recommendation(widget.cat.id, widget.cat.score);
    return _Section(
      title: 'AI RECOMMENDATION',
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _kSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _kBorder),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_kSurface, _kAccent2.withOpacity(0.07)],
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _kAccent2.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.auto_awesome_rounded, color: _kAccent2, size: 16),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(text, style: TextStyle(
                color: Colors.white.withOpacity(0.75),
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
                  color: stColor.withOpacity(0.12),
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
                      style: const TextStyle(
                          color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                    if (_carrisStop != null)
                      Text(
                        'Carris · stop ${_carrisStop!.id}',
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.30), fontSize: 10),
                      )
                    else
                      Text(
                        _prettify(a.type),
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.30), fontSize: 10),
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
                        color: Colors.white.withOpacity(0.55),
                        fontSize: 12,
                        fontWeight: FontWeight.w600),
                  ),
                  if (a.walkingMinutes != null)
                    Text(
                      '${a.walkingMinutes} min',
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.28), fontSize: 11),
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
    final bg = line != null ? Color(line.colorInt) : fallback.withOpacity(0.80);
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
    return Row(
      children: [
        Text('Next  ',
            style: TextStyle(
                color: Colors.white.withOpacity(0.30), fontSize: 10.5)),
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
                      color: Colors.white.withOpacity(0.72),
                      fontSize: 11,
                      fontWeight: FontWeight.w600)),
            ]),
          );
        }),
      ],
    );
  }

  Widget _facilityBadge(String label, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 11, color: Colors.white.withOpacity(0.32)),
        const SizedBox(width: 3),
        Text(label,
            style: TextStyle(
                color: Colors.white.withOpacity(0.32), fontSize: 10)),
      ]),
    );
  }
}

// ── Nearby tile ───────────────────────────────────────────────────────────────

class _NearbyTile extends StatelessWidget {
  final AmenityModel amenity;
  final Color color;
  final IconData icon;
  const _NearbyTile({required this.amenity, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  amenity.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _prettify(amenity.type),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.38), fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _dist(amenity.distanceMeters),
                style: TextStyle(
                  color: Colors.white.withOpacity(0.55), fontSize: 12, fontWeight: FontWeight.w600,
                ),
              ),
              if (amenity.walkingMinutes != null)
                Text(
                  '${amenity.walkingMinutes} min',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.3), fontSize: 11,
                  ),
                ),
            ],
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
  final Widget? trailing;
  const _Section({required this.title, required this.child, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.32),
                  fontSize: 10.5, fontWeight: FontWeight.w700, letterSpacing: 1.8,
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

// ── Stat model & tile ─────────────────────────────────────────────────────────

class _Stat {
  final String label;
  final String value;
  final IconData icon;
  const _Stat(this.label, this.value, this.icon);
}

class _StatTile extends StatelessWidget {
  final _Stat stat;
  final Color color;
  const _StatTile({required this.stat, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: _kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(stat.icon, color: color.withOpacity(0.7), size: 15),
          const Spacer(),
          Text(
            stat.value,
            style: const TextStyle(
              color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            stat.label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.32), fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Sparkline painter ──────────────────────────────────────────────────────────

class _SparklinePainter extends CustomPainter {
  final List<double> values;
  final Color color;
  final double leftPad;

  const _SparklinePainter({
    required this.values,
    required this.color,
    this.leftPad = 0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;

    const topPad    = 16.0; // room for score labels above dots
    const bottomPad = 6.0;  // gap above the X-axis line
    final chartW = size.width - leftPad;
    final chartH = size.height - topPad - bottomPad;
    // Y coordinate for a given score (0-100 scale)
    double scoreY(double s) => topPad + chartH - (s / 100) * chartH;

    final tp = TextPainter(textDirection: TextDirection.ltr);

    // ── Horizontal grid lines + Y-axis labels ──────────────────────────────
    const yTicks = [0, 25, 50, 75, 100];
    for (final yv in yTicks) {
      final y = scoreY(yv.toDouble());
      final isBaseline = yv == 0;

      canvas.drawLine(
        Offset(leftPad, y),
        Offset(size.width, y),
        Paint()
          ..color = Colors.white.withOpacity(isBaseline ? 0.20 : 0.055)
          ..strokeWidth = isBaseline ? 1.2 : 0.8,
      );

      tp.text = TextSpan(
        text: '$yv',
        style: TextStyle(
          color: Colors.white.withOpacity(0.28),
          fontSize: 8.5,
          fontWeight: FontWeight.w500,
        ),
      );
      tp.layout();
      tp.paint(canvas, Offset(
        leftPad - tp.width - 5,
        y - tp.height / 2,
      ));
    }

    // ── Y-axis vertical line ───────────────────────────────────────────────
    canvas.drawLine(
      Offset(leftPad, scoreY(100)),
      Offset(leftPad, scoreY(0)),
      Paint()
        ..color = Colors.white.withOpacity(0.20)
        ..strokeWidth = 1.2,
    );

    // ── Data points ────────────────────────────────────────────────────────
    final step = chartW / (values.length - 1);
    final pts = List.generate(values.length, (i) =>
        Offset(leftPad + i * step, scoreY(values[i])));

    // Gradient fill under curve
    final fillPath = ui.Path()..moveTo(pts.first.dx, pts.first.dy);
    for (int i = 1; i < pts.length; i++) {
      final cp1 = Offset((pts[i - 1].dx + pts[i].dx) / 2, pts[i - 1].dy);
      final cp2 = Offset((pts[i - 1].dx + pts[i].dx) / 2, pts[i].dy);
      fillPath.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, pts[i].dx, pts[i].dy);
    }
    fillPath
      ..lineTo(size.width, scoreY(0))
      ..lineTo(leftPad, scoreY(0))
      ..close();

    canvas.drawPath(
      fillPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color.withOpacity(0.28), color.withOpacity(0.02)],
        ).createShader(Rect.fromLTWH(leftPad, topPad, chartW, chartH)),
    );

    // Bezier line
    final linePath = ui.Path()..moveTo(pts.first.dx, pts.first.dy);
    for (int i = 1; i < pts.length; i++) {
      final cp1 = Offset((pts[i - 1].dx + pts[i].dx) / 2, pts[i - 1].dy);
      final cp2 = Offset((pts[i - 1].dx + pts[i].dx) / 2, pts[i].dy);
      linePath.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, pts[i].dx, pts[i].dy);
    }
    canvas.drawPath(
      linePath,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round,
    );

    // Dots + score labels
    for (int i = 0; i < pts.length; i++) {
      final p = pts[i];
      canvas.drawCircle(p, 4.5, Paint()..color = color);
      canvas.drawCircle(p, 3.0, Paint()..color = _kBg);

      tp.text = TextSpan(
        text: values[i].round().toString(),
        style: TextStyle(color: color, fontSize: 8.5, fontWeight: FontWeight.w700),
      );
      tp.layout();
      tp.paint(canvas, Offset(p.dx - tp.width / 2, p.dy - 16));
    }
  }

  @override
  bool shouldRepaint(_SparklinePainter old) =>
      old.values != values || old.leftPad != leftPad;
}

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

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _kBorder),
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
                  color: stColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: stColor.withOpacity(0.25)),
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
                      style: const TextStyle(
                        color: Colors.white,
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
                            color: Colors.white.withOpacity(0.30)),
                        const SizedBox(width: 4),
                        Text(
                          'Stop ${_carrisStop!.id}',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.35),
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
                    valueColor: AlwaysStoppedAnimation(color.withOpacity(0.45)),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 14),

          // ── Distance + walk time metadata row ────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.04),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _kBorder, width: 0.8),
            ),
            child: Row(children: [
              _metaPill(Icons.near_me_rounded, _dist(a.distanceMeters), stColor),
              if (a.walkingMinutes != null) ...[
                Container(
                  width: 1, height: 16,
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                  color: _kBorder,
                ),
                _metaPill(
                  Icons.directions_walk_rounded,
                  '${a.walkingMinutes} min walk',
                  Colors.white.withOpacity(0.48),
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
                color: Colors.white.withOpacity(0.28),
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
                          color: bg.withOpacity(0.35),
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
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF060C19),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _kBorder),
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
                    boxShadow: [BoxShadow(color: color.withOpacity(0.55), blurRadius: 4)],
                  ),
                ),
                const SizedBox(width: 5),
                Text(label,
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.42),
                        fontSize: 11,
                        fontWeight: FontWeight.w500)),
              ]),
            );
          }),
          Row(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 7, height: 7,
              decoration: BoxDecoration(
                color: const Color(0xFF6C63FF),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: const Color(0xFF6C63FF).withOpacity(0.55), blurRadius: 4)
                ],
              ),
            ),
            const SizedBox(width: 5),
            Text('You',
                style: TextStyle(
                    color: Colors.white.withOpacity(0.42),
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
    return Container(
      decoration: BoxDecoration(
        color: _kSurface2,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Row(children: [
              Icon(Icons.schedule_rounded, size: 13,
                  color: Colors.white.withOpacity(0.32)),
              const SizedBox(width: 6),
              Text(
                'UPCOMING ARRIVALS',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.32),
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
                      style: const TextStyle(
                        color: Colors.white,
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
                      color: timeColor.withOpacity(0.11),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: timeColor.withOpacity(0.28), width: 0.8),
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
                  color: _kBorder,
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
            ..color = Colors.white.withOpacity(r == 4 ? 0.10 : 0.04)
            ..style = PaintingStyle.stroke
            ..strokeWidth = r == 4 ? 1.0 : 0.7);
    }

    if (n > 0) {
      for (int i = 0; i < n; i++) {
        final a = (2 * pi / n) * i - pi / 2;
        canvas.drawLine(c, Offset(c.dx + maxR * cos(a), c.dy + maxR * sin(a)),
            Paint()..color = Colors.white.withOpacity(0.04)..strokeWidth = 0.8);
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
            ..color = color.withOpacity(0.38 * a01)
            ..strokeWidth = 1.5
            ..strokeCap = StrokeCap.round);

      canvas.drawCircle(tip, 20, Paint()..color = color.withOpacity(0.07 * a01));
      canvas.drawCircle(tip, 14, Paint()..color = color.withOpacity(0.14 * a01));
      canvas.drawCircle(tip, 11, Paint()..color = color.withOpacity(0.90 * a01));
      canvas.drawCircle(tip, 11,
          Paint()
            ..color = Colors.white.withOpacity(0.16)
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
                  color: color.withOpacity(0.80 * alpha),
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
        Paint()..color = const Color(0xFF6C63FF).withOpacity(0.05 * alpha));
    canvas.drawCircle(c, 20,
        Paint()..color = const Color(0xFF6C63FF).withOpacity(0.12 * alpha));
    canvas.drawCircle(c, 20,
        Paint()
          ..color = const Color(0xFF6C63FF).withOpacity(0.65 * alpha)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5);
    canvas.drawCircle(c, 12,
        Paint()..color = const Color(0xFF6C63FF).withOpacity(alpha));

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
