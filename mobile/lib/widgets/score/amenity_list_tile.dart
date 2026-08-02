import 'package:flutter/material.dart';

import '../../models/amenity_model.dart';

class AmenityListTile extends StatelessWidget {
  final AmenityModel amenity;

  const AmenityListTile({super.key, required this.amenity});

  static const _categoryIcons = {
    AmenityCategory.transportation: Icons.train_rounded,
    AmenityCategory.education: Icons.school_rounded,
    AmenityCategory.healthcare: Icons.local_hospital_rounded,
    AmenityCategory.shopping: Icons.shopping_cart_rounded,
    AmenityCategory.safety: Icons.security_rounded,
    AmenityCategory.religion: Icons.church_rounded,
    AmenityCategory.recreation: Icons.park_rounded,
  };

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
    final color = _categoryColors[amenity.category] ?? theme.colorScheme.primary;
    final icon = _categoryIcons[amenity.category] ?? Icons.place_rounded;

    return Card(
      margin: const EdgeInsets.only(bottom: 4),
      child: ListTile(
        dense: true,
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        title: Text(
          amenity.name,
          style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          amenity.type,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        trailing: amenity.walkingMinutes != null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${amenity.walkingMinutes}min',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (amenity.distanceMeters != null)
                    Text(
                      '${(amenity.distanceMeters! / 1000).toStringAsFixed(1)}km',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              )
            : null,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      ),
    );
  }
}
