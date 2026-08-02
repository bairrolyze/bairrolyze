import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../config/app_theme.dart';
import '../../providers/analysis_provider.dart';

/// Premium "recent search" card used on both the Home and Saved screens.
///
/// Shows a location thumbnail (a live OSM map tile for the saved coordinate,
/// with a graceful fallback), the area name, a secondary line, and a score
/// badge. Tapping opens the saved analysis; swiping left removes it.
class RecentSearchTile extends StatelessWidget {
  final SearchHistoryEntry entry;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const RecentSearchTile({
    super.key,
    required this.entry,
    required this.onTap,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    final a = entry.address;
    final title = a.shortPrimary;
    final subtitle = a.shortSecondary;
    final scoreStr = (entry.score.overall / 10).toStringAsFixed(1);

    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 0, 22, 12),
      child: Dismissible(
        key: ValueKey(entry.id),
        direction: DismissDirection.endToStart,
        onDismissed: (_) => onRemove(),
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 22),
          decoration: BoxDecoration(
            color: AppColors.error.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Icon(Icons.delete_outline_rounded,
              color: AppColors.error, size: 22),
        ),
        child: Material(
          color: p.surface,
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: p.border),
              ),
              child: Row(
                children: [
                  _Thumbnail(lat: a.lat, lng: a.lng),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: p.textPrimary,
                            fontSize: 15.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: p.textTertiary, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: AppColors.accent.withValues(alpha: 0.25)),
                    ),
                    child: Text(
                      scoreStr,
                      style: const TextStyle(
                        color: AppColors.accent,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

}

// ── Location thumbnail (OSM map tile, with graceful fallback) ──────────────────

class _Thumbnail extends StatelessWidget {
  final double? lat;
  final double? lng;
  const _Thumbnail({this.lat, this.lng});

  static const _size = 58.0;
  static const _zoom = 15;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    Widget fallback() => Container(
          width: _size,
          height: _size,
          alignment: Alignment.center,
          color: AppColors.accent.withValues(alpha: 0.12),
          child: Icon(Icons.location_city_rounded,
              color: AppColors.accent.withValues(alpha: 0.8), size: 24),
        );

    Widget child;
    if (lat != null && lng != null) {
      final x = _lon2tile(lng!, _zoom);
      final y = _lat2tile(lat!, _zoom);
      final url = 'https://tile.openstreetmap.org/$_zoom/$x/$y.png';
      child = Image.network(
        url,
        width: _size,
        height: _size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => fallback(),
        loadingBuilder: (ctx, w, progress) => progress == null
            ? w
            : Container(width: _size, height: _size, color: p.surface2),
      );
    } else {
      child = fallback();
    }

    return Container(
      width: _size,
      height: _size,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: p.border),
      ),
      child: child,
    );
  }

  int _lon2tile(double lon, int z) =>
      ((lon + 180.0) / 360.0 * (1 << z)).floor();

  int _lat2tile(double lat, int z) {
    final r = lat * math.pi / 180.0;
    return ((1 - (math.log(math.tan(r) + 1 / math.cos(r)) / math.pi)) /
            2 *
            (1 << z))
        .floor();
  }
}
