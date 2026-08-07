import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../models/address_model.dart';
import '../../models/amenity_model.dart';
import '../../providers/analysis_provider.dart';
import '../../widgets/map/amenity_marker.dart';
import '../../widgets/map/filter_chips.dart';
import '../../widgets/map/amenity_bottom_sheet.dart';

class MapScreen extends ConsumerStatefulWidget {
  final AddressModel? address;

  const MapScreen({super.key, this.address});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  final _mapController = MapController();
  AmenityModel? _selectedAmenity;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final analysisState = ref.watch(analysisProvider);
    final filteredAmenities = ref.watch(filteredAmenitiesProvider);
    final activeFilter = ref.watch(mapFilterProvider);

    final address = analysisState.address ?? widget.address;
    final centerLat = address?.lat ?? 38.7139;
    final centerLng = address?.lng ?? -9.1394;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface.withValues(alpha: 0.95),
        title: Text(
          address?.displayAddress ?? 'Map',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.titleSmall,
        ),
        elevation: 0,
      ),
      body: Stack(
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

              // 2km radius circle
              CircleLayer(
                circles: [
                  CircleMarker(
                    point: LatLng(centerLat, centerLng),
                    radius: 2000,
                    useRadiusInMeter: true,
                    color: theme.colorScheme.primary.withValues(alpha: 0.05),
                    borderColor: theme.colorScheme.primary.withValues(alpha: 0.3),
                    borderStrokeWidth: 1.5,
                  ),
                ],
              ),

              // Amenity markers
              MarkerLayer(
                markers: filteredAmenities
                    .map(
                      (amenity) => Marker(
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
                      ),
                    )
                    .toList(),
              ),

              // Center pin
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
                            color: theme.colorScheme.primary,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                            boxShadow: [
                              BoxShadow(
                                color: theme.colorScheme.primary.withValues(alpha: 0.4),
                                blurRadius: 8,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: const Icon(Icons.home_rounded, color: Colors.white, size: 18),
                        ),
                        Container(
                          width: 2,
                          height: 12,
                          color: theme.colorScheme.primary,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Filter chips
          Positioned(
            top: kToolbarHeight + MediaQuery.of(context).padding.top + 12,
            left: 16,
            right: 16,
            child: MapFilterChips(
              activeFilter: activeFilter,
              onFilterChanged: (f) => ref.read(mapFilterProvider.notifier).state = f,
              amenities: analysisState.result?.amenities ?? [],
            ),
          ),

          // Stats bar
          Positioned(
            bottom: _selectedAmenity != null ? 180 : 20,
            left: 16,
            right: 16,
            child: _MapStatsBar(
              total: filteredAmenities.length,
              filter: activeFilter,
            ),
          ),

          // Amenity detail sheet
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
        ],
      ),
      floatingActionButton: FloatingActionButton.small(
        onPressed: () => _mapController.move(LatLng(centerLat, centerLng), 15.0),
        tooltip: 'Center map',
        child: const Icon(Icons.my_location_rounded),
      ),
    );
  }
}

class _MapStatsBar extends StatelessWidget {
  final int total;
  final AmenityCategory? filter;

  const _MapStatsBar({required this.total, this.filter});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Icon(Icons.place_rounded, size: 16, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              filter == null ? '$total places found' : '$total ${filter!.name} places',
              style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
