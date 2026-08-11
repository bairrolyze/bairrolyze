import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../models/amenity_model.dart';

class AmenityBottomSheet extends StatelessWidget {
  final AmenityModel amenity;
  final VoidCallback onClose;

  const AmenityBottomSheet({
    super.key,
    required this.amenity,
    required this.onClose,
  });

  static const _categoryColors = {
    AmenityCategory.transportation: Color(0xFF2196F3),
    AmenityCategory.education: Color(0xFF4CAF50),
    AmenityCategory.healthcare: Color(0xFFF44336),
    AmenityCategory.shopping: Color(0xFFFF9800),
    AmenityCategory.safety: Color(0xFF9C27B0),
    AmenityCategory.religion: Color(0xFF795548),
    AmenityCategory.recreation: Color(0xFF00BCD4),
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = AppLocalizations.of(context);
    final color = _categoryColors[amenity.category] ?? theme.colorScheme.primary;

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          amenity.category.label(l).toUpperCase(),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: color,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        amenity.name,
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      Text(
                        amenity.type,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: onClose,
                ),
              ],
            ),
            if (amenity.walkingMinutes != null || amenity.distanceMeters != null) ...[
              const Divider(height: 16),
              Row(
                children: [
                  if (amenity.walkingMinutes != null)
                    _InfoChip(
                      icon: Icons.directions_walk_rounded,
                      label: l.amenityMinWalk(amenity.walkingMinutes!),
                      color: color,
                    ),
                  const SizedBox(width: 8),
                  if (amenity.distanceMeters != null)
                    _InfoChip(
                      icon: Icons.straighten_rounded,
                      label: '${(amenity.distanceMeters! / 1000).toStringAsFixed(2)} km',
                      color: color,
                    ),
                  if (amenity.drivingMinutes != null) ...[
                    const SizedBox(width: 8),
                    _InfoChip(
                      icon: Icons.directions_car_rounded,
                      label: l.amenityMinDrive(amenity.drivingMinutes!),
                      color: theme.colorScheme.secondary,
                    ),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InfoChip({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
