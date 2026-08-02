import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/score_model.dart';

class CategoryCard extends ConsumerWidget {
  final CategoryScore categoryScore;

  const CategoryCard({super.key, required this.categoryScore});

  static const _icons = {
    'transportation': Icons.train_rounded,
    'education': Icons.school_rounded,
    'healthcare': Icons.local_hospital_rounded,
    'shopping': Icons.shopping_cart_rounded,
    'safety': Icons.security_rounded,
    'religion': Icons.church_rounded,
    'recreation': Icons.park_rounded,
  };

  static const _colors = {
    'transportation': Color(0xFF2196F3),
    'education': Color(0xFF4CAF50),
    'healthcare': Color(0xFFF44336),
    'shopping': Color(0xFFFF9800),
    'safety': Color(0xFF9C27B0),
    'religion': Color(0xFF795548),
    'recreation': Color(0xFF00BCD4),
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final color = _colors[categoryScore.id] ?? theme.colorScheme.primary;
    final icon = _icons[categoryScore.id] ?? Icons.place_rounded;
    final pct = (categoryScore.score / 100).clamp(0.0, 1.0);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        categoryScore.label,
                        style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      Row(
                        children: [
                          Text(
                            '${categoryScore.score.round()}',
                            style: theme.textTheme.titleSmall?.copyWith(
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
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: pct,
                      backgroundColor: color.withValues(alpha: 0.12),
                      valueColor: AlwaysStoppedAnimation(color),
                      minHeight: 6,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(
                        '${categoryScore.count} nearby',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      if (categoryScore.closest != null) ...[
                        const Text(' · '),
                        Expanded(
                          child: Text(
                            categoryScore.closest!.name,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (categoryScore.closest!.walkingMinutes != null)
                          Text(
                            '${categoryScore.closest!.walkingMinutes}min walk',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: color,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
