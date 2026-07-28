import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../models/amenity_model.dart';
import '../../providers/analysis_provider.dart';
import 'amenity_marker.dart';
import 'filter_chips.dart';
import 'amenity_bottom_sheet.dart';

const _kAccent   = Color(0xFF3B82F6);
const _kSurface  = Color(0xFF0D1625);
const _kBorder   = Color(0xFF1A2845);

class MapTabBody extends ConsumerStatefulWidget {
  const MapTabBody({super.key});

  @override
  ConsumerState<MapTabBody> createState() => _MapTabBodyState();
}

class _MapTabBodyState extends ConsumerState<MapTabBody> {
  final _mapController = MapController();
  AmenityModel? _selectedAmenity;

  @override
  Widget build(BuildContext context) {
    final analysisState = ref.watch(analysisProvider);
    final filteredAmenities = ref.watch(filteredAmenitiesProvider);
    final activeFilter = ref.watch(mapFilterProvider);

    final address = analysisState.address;
    final centerLat = address?.lat ?? 38.7139;
    final centerLng = address?.lng ?? -9.1394;

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: LatLng(centerLat, centerLng),
            initialZoom: 15.0,
            maxZoom: 19.0,
            minZoom: 10.0,
            onTap: (_, __) => setState(() => _selectedAmenity = null),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.homescope.app',
              maxZoom: 19,
            ),
            CircleLayer(
              circles: [
                CircleMarker(
                  point: LatLng(centerLat, centerLng),
                  radius: 2000,
                  useRadiusInMeter: true,
                  color: _kAccent.withOpacity(0.05),
                  borderColor: _kAccent.withOpacity(0.3),
                  borderStrokeWidth: 1.5,
                ),
              ],
            ),
            MarkerLayer(
              markers: filteredAmenities.map((amenity) {
                return Marker(
                  point: LatLng(amenity.lat, amenity.lng),
                  width: 40,
                  height: 40,
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedAmenity = amenity),
                    child: AmenityMarker(
                      amenity: amenity,
                      isSelected: _selectedAmenity?.id == amenity.id,
                    ),
                  ),
                );
              }).toList(),
            ),
            // Home pin
            MarkerLayer(
              markers: [
                Marker(
                  point: LatLng(centerLat, centerLng),
                  width: 48,
                  height: 56,
                  child: Column(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: _kAccent,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: _kAccent.withOpacity(0.45),
                              blurRadius: 10,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: const Icon(Icons.home_rounded,
                            color: Colors.white, size: 18),
                      ),
                      Container(width: 2, height: 12, color: _kAccent),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),

        // Category filter chips
        Positioned(
          top: 12,
          left: 12,
          right: 12,
          child: MapFilterChips(
            activeFilter: activeFilter,
            onFilterChanged: (f) =>
                ref.read(mapFilterProvider.notifier).state = f,
            amenities: analysisState.result?.amenities ?? [],
          ),
        ),

        // Stats pill
        Positioned(
          bottom: _selectedAmenity != null ? 168 : 20,
          left: 16,
          right: 16,
          child: Align(
            alignment: Alignment.centerLeft,
            child: _StatsPill(
              total: filteredAmenities.length,
              filter: activeFilter,
            ),
          ),
        ),

        // Amenity card
        if (_selectedAmenity != null)
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: AmenityBottomSheet(
              amenity: _selectedAmenity!,
              onClose: () => setState(() => _selectedAmenity = null),
            ),
          ),

        // Re-centre FAB
        Positioned(
          bottom: _selectedAmenity != null ? 168 : 20,
          right: 16,
          child: GestureDetector(
            onTap: () => _mapController.move(
                LatLng(centerLat, centerLng), 15.0),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: _kSurface,
                shape: BoxShape.circle,
                border: Border.all(color: _kBorder),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.3), blurRadius: 8)
                ],
              ),
              child: const Icon(Icons.my_location_rounded,
                  color: _kAccent, size: 17),
            ),
          ),
        ),
      ],
    );
  }
}

class _StatsPill extends StatelessWidget {
  final int total;
  final AmenityCategory? filter;
  const _StatsPill({required this.total, this.filter});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1625).withOpacity(0.92),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF1A2845)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.place_rounded, size: 13, color: _kAccent),
          const SizedBox(width: 5),
          Text(
            filter == null
                ? '$total places nearby'
                : '$total ${filter!.name}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
