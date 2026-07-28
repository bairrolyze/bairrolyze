import 'package:flutter/material.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';

import '../../config/app_constants.dart';
import '../../models/score_model.dart';

class OverallScoreCard extends StatelessWidget {
  final LocationScore score;

  const OverallScoreCard({super.key, required this.score});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pct = score.overall / 100;
    final color = _scoreColor(score.overall);
    final label = _scoreLabel(score.overall);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          children: [
            CircularPercentIndicator(
              radius: 60,
              lineWidth: 10,
              percent: pct.clamp(0.0, 1.0),
              center: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    score.overall.round().toString(),
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: color,
                    ),
                  ),
                  Text(
                    '/100',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              progressColor: color,
              backgroundColor: color.withOpacity(0.15),
              circularStrokeCap: CircularStrokeCap.round,
              animation: true,
              animationDuration: 800,
            ),
            const SizedBox(width: 24),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Location Score',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      label,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: color,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '${score.categories.length} categories analyzed',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    'Profile: ${_profileLabel(score.profile)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Color _scoreColor(double score) {
    if (score >= AppConstants.scoreExcellent) return const Color(0xFF4CAF50);
    if (score >= AppConstants.scoreGood) return const Color(0xFF2196F3);
    if (score >= AppConstants.scoreFair) return const Color(0xFFFF9800);
    return const Color(0xFFF44336);
  }

  static String _scoreLabel(double score) {
    if (score >= AppConstants.scoreExcellent) return 'Excellent';
    if (score >= AppConstants.scoreGood) return 'Good';
    if (score >= AppConstants.scoreFair) return 'Fair';
    return 'Poor';
  }

  static String _profileLabel(String profile) {
    const labels = {
      'default': 'General',
      'family': 'Family',
      'student': 'Student',
      'professional': 'Professional',
      'retired': 'Retired',
      'investor': 'Investor',
    };
    return labels[profile] ?? profile;
  }
}
