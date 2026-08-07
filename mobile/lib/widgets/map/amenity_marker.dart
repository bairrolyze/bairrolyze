import 'package:flutter/material.dart';

import '../../models/amenity_model.dart';

class AmenityMarker extends StatelessWidget {
  final AmenityModel amenity;
  final bool isSelected;

  const AmenityMarker({super.key, required this.amenity, this.isSelected = false});

  static const _categoryColors = {
    AmenityCategory.transportation: Color(0xFF2196F3),
    AmenityCategory.education: Color(0xFF4CAF50),
    AmenityCategory.healthcare: Color(0xFFF44336),
    AmenityCategory.shopping: Color(0xFFFF9800),
    AmenityCategory.safety: Color(0xFF9C27B0),
    AmenityCategory.religion: Color(0xFF795548),
    AmenityCategory.recreation: Color(0xFF00BCD4),
  };

  static const _categoryIcons = {
    AmenityCategory.transportation: Icons.train_rounded,
    AmenityCategory.education: Icons.school_rounded,
    AmenityCategory.healthcare: Icons.local_hospital_rounded,
    AmenityCategory.shopping: Icons.shopping_cart_rounded,
    AmenityCategory.safety: Icons.security_rounded,
    AmenityCategory.religion: Icons.church_rounded,
    AmenityCategory.recreation: Icons.park_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final color = _categoryColors[amenity.category] ?? Colors.grey;
    final icon = _categoryIcons[amenity.category] ?? Icons.place_rounded;
    final size = isSelected ? 44.0 : 34.0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: isSelected ? 3 : 2),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.4),
            blurRadius: isSelected ? 12 : 6,
            spreadRadius: isSelected ? 2 : 0,
          ),
        ],
      ),
      child: Icon(
        icon,
        color: Colors.white,
        size: size * 0.5,
      ),
    );
  }
}
