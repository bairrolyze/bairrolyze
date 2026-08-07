import 'package:flutter/material.dart';

import '../../config/app_constants.dart';

class ScoreBadge extends StatelessWidget {
  final int score;
  final double size;

  const ScoreBadge({super.key, required this.score, this.size = 48});

  Color get _color {
    if (score >= AppConstants.scoreExcellent) return const Color(0xFF4CAF50);
    if (score >= AppConstants.scoreGood) return const Color(0xFF2196F3);
    if (score >= AppConstants.scoreFair) return const Color(0xFFFF9800);
    return const Color(0xFFF44336);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _color.withValues(alpha: 0.12),
        border: Border.all(color: _color, width: 2),
      ),
      child: Center(
        child: Text(
          score.toString(),
          style: TextStyle(
            color: _color,
            fontWeight: FontWeight.w800,
            fontSize: size * 0.3,
          ),
        ),
      ),
    );
  }
}
