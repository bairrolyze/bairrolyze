import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/address_model.dart';
import '../common/shimmer_card.dart';

// ── URL helper ────────────────────────────────────────────────────────────────

/// Builds the Google Street View panorama URL for [lat] / [lng].
///
/// Opens directly to the street-level panorama closest to the given point.
/// Uses Google's official map_action=pano format so the link works on all
/// platforms (web, Android, iOS) and falls back to Maps if no panorama exists.
String streetViewUrl(double lat, double lng) =>
    'https://www.google.com/maps/@?api=1&map_action=pano'
    '&viewpoint=${lat.toStringAsFixed(6)},${lng.toStringAsFixed(6)}';

bool _isValidCoord(double lat, double lng) =>
    lat >= -90 && lat <= 90 && lng >= -180 && lng <= 180;

// ── Public widget ─────────────────────────────────────────────────────────────

/// Displays the analyzed address and a Google Street View deep-link.
///
/// Hides itself completely when coordinates are absent or invalid.
/// Pass [isLoading] to show a shimmer placeholder while the address resolves.
///
/// ```dart
/// StreetViewSection(address: analysisState.address!)
/// ```
class StreetViewSection extends StatelessWidget {
  final AddressModel address;

  /// Show a shimmer skeleton instead of the real content.
  final bool isLoading;

  const StreetViewSection({
    super.key,
    required this.address,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const ShimmerCard(height: 110);

    final lat = address.lat;
    final lng = address.lng;

    if (lat == null || lng == null || !_isValidCoord(lat, lng)) {
      return const SizedBox.shrink();
    }

    return _StreetViewCard(
      displayAddress: address.displayAddress,
      url: streetViewUrl(lat, lng),
    );
  }
}

// ── Card ──────────────────────────────────────────────────────────────────────

class _StreetViewCard extends StatelessWidget {
  final String displayAddress;
  final String url;

  const _StreetViewCard({required this.displayAddress, required this.url});

  Future<void> _launch(BuildContext context) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open Street View. Try again later.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section label
            Row(
              children: [
                Icon(Icons.map_rounded, size: 15, color: theme.colorScheme.onSurfaceVariant),
                const SizedBox(width: 6),
                Text(
                  'Street View',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Address
            Text(
              displayAddress,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 12),

            // Divider
            Divider(height: 1, color: theme.colorScheme.outlineVariant.withOpacity(0.6)),
            const SizedBox(height: 12),

            // CTA link
            _StreetViewLink(accent: accent, onTap: () => _launch(context)),
            const SizedBox(height: 6),

            // Helper text
            Text(
              'Explore the surroundings and get a real-world view of the neighborhood.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Clickable link ────────────────────────────────────────────────────────────

class _StreetViewLink extends StatelessWidget {
  final Color accent;
  final VoidCallback onTap;

  const _StreetViewLink({required this.accent, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        // InkWell handles ripple (mobile) and hover highlight (web) automatically.
        splashColor: accent.withOpacity(0.12),
        hoverColor: accent.withOpacity(0.07),
        highlightColor: accent.withOpacity(0.05),
        mouseCursor: SystemMouseCursors.click,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 1),
                child: Icon(Icons.visibility_rounded, size: 16, color: accent),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'View street view of this area for better understanding about the area',
                  style: TextStyle(
                    color: accent,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w500,
                    height: 1.4,
                    decoration: TextDecoration.underline,
                    decorationColor: accent.withOpacity(0.5),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Icon(Icons.open_in_new_rounded, size: 13, color: accent.withOpacity(0.7)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
