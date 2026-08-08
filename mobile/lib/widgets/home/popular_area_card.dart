import 'package:flutter/material.dart';

import '../../config/app_theme.dart';
import '../../config/score_format.dart';
import '../../data/popular_areas.dart';

/// A compact, tappable card for a single [PopularArea].
///
/// Width-agnostic: the parent decides the footprint (a fixed box for the
/// horizontal home rail, or full width in the "See all" list), so the same
/// widget serves both surfaces.
class PopularAreaCard extends StatelessWidget {
  final PopularArea area;
  final VoidCallback onTap;

  const PopularAreaCard({super.key, required this.area, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final ring = scoreColor(area.score.toDouble());

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: p.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: p.border, width: 1),
        ),
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            // Leading: score ring (curated) or a neutral pin for areas that
            // come purely from live search data (no curated score).
            if (area.score > 0)
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: ring, width: 2.5),
                  color: ring.withValues(alpha: 0.10),
                ),
                child: Center(
                  // Same /10 scale as the main score (score_format.dart).
                  child: Text(
                    scoreTenth(area.score.toDouble()),
                    style: TextStyle(
                      color: ring,
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
              )
            else
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: p.surface2,
                  border: Border.all(color: p.border),
                ),
                child: Icon(Icons.place_rounded,
                    size: 18, color: p.textTertiary),
              ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    area.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: p.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Icon(Icons.place_rounded, size: 12, color: p.textTertiary),
                      const SizedBox(width: 3),
                      Flexible(
                        child: Text(
                          area.region,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: p.textTertiary,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, size: 20, color: p.textTertiary),
          ],
        ),
      ),
    );
  }
}
