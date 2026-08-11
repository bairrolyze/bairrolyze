import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../models/amenity_model.dart';

class MapFilterChips extends StatelessWidget {
  final AmenityCategory? activeFilter;
  final ValueChanged<AmenityCategory?> onFilterChanged;
  final List<AmenityModel> amenities;

  const MapFilterChips({
    super.key,
    required this.activeFilter,
    required this.onFilterChanged,
    required this.amenities,
  });

  int _count(AmenityCategory? cat) {
    if (cat == null) return amenities.length;
    return amenities.where((a) => a.category == cat).length;
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final chips = [
      (category: null, label: l.filterAll, icon: Icons.apps_rounded),
      (category: AmenityCategory.transportation, label: AmenityCategory.transportation.label(l), icon: Icons.train_rounded),
      (category: AmenityCategory.education, label: AmenityCategory.education.label(l), icon: Icons.school_rounded),
      (category: AmenityCategory.healthcare, label: AmenityCategory.healthcare.label(l), icon: Icons.local_hospital_rounded),
      (category: AmenityCategory.shopping, label: AmenityCategory.shopping.label(l), icon: Icons.shopping_cart_rounded),
      (category: AmenityCategory.religion, label: AmenityCategory.religion.label(l), icon: Icons.church_rounded),
      (category: AmenityCategory.recreation, label: AmenityCategory.recreation.label(l), icon: Icons.park_rounded),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: chips.map((chip) {
          final isActive = activeFilter == chip.category;
          final count = _count(chip.category);
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(chip.icon, size: 14),
                  const SizedBox(width: 4),
                  Text(l.amenityCountLabel(chip.label, count)),
                ],
              ),
              selected: isActive,
              onSelected: (_) => onFilterChanged(isActive ? null : chip.category),
              elevation: 2,
              pressElevation: 4,
            ),
          );
        }).toList(),
      ),
    );
  }
}
