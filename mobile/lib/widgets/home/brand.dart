import 'package:flutter/material.dart';

import '../../config/app_theme.dart';

// ── Brand assets ──────────────────────────────────────────────────────────────
// Brand furniture for the home hero:
//   • BairrolyzeLogoMark — the designed "B + house + pin" monogram (raster).
//   • BairrolyzeWordmark — the heavy "Bairrolyze" wordmark.
//   • CityHeroBackdrop   — the night-city illustration behind the hero.

// ── Logo mark ─────────────────────────────────────────────────────────────────

/// The Bairrolyze glyph: the designed cyan→blue→purple "B" whose body frames a
/// house and whose lower bowl forms a map pin. Rendered from a transparent PNG
/// (`assets/images/logo_mark.png`, extracted from the brand artwork); the app
/// launcher icon uses the opaque navy version at `assets/icons/app_icon.png`.
///
/// The mark is taller than it is wide, so [size] sets its height and the width
/// follows the artwork's aspect ratio.
class BairrolyzeLogoMark extends StatelessWidget {
  final double size;
  const BairrolyzeLogoMark({super.key, this.size = 96});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/logo_mark.png',
      height: size,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
    );
  }
}

// ── Wordmark ──────────────────────────────────────────────────────────────────

class BairrolyzeWordmark extends StatelessWidget {
  final double fontSize;
  final Color? color;
  const BairrolyzeWordmark({super.key, this.fontSize = 42, this.color});

  @override
  Widget build(BuildContext context) {
    return Text(
      'Bairrolyze',
      textAlign: TextAlign.center,
      style: TextStyle(
        color: color ?? Colors.white,
        fontSize: fontSize,
        fontWeight: FontWeight.w800,
        letterSpacing: -1.2,
        height: 1.0,
      ),
    );
  }
}

// ── City hero backdrop ────────────────────────────────────────────────────────

/// The night-city hero backdrop: a full-bleed illustration of a navy sky
/// fading into a warm-lit city, aligned so the skyline sits along the bottom
/// and open sky fills in behind the brand lockup, with floating location pins
/// overlaid and a soft fade into the app background at the bottom edge.
class CityHeroBackdrop extends StatelessWidget {
  final double height;
  const CityHeroBackdrop({super.key, required this.height});

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final bg = dark ? AppColors.bg : AppColors.bgLight;
    return SizedBox(
      height: height,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // City illustration; shifted down (showing a higher slice of the
          // tall image) so the skyline sits in the lower half and clean navy
          // sky rises behind the logo + wordmark.
          Image.asset(
            'assets/images/city_sky.png',
            fit: BoxFit.cover,
            alignment: const Alignment(0.0, 0.15),
          ),
          // Floating location pins over the city band.
          CustomPaint(painter: _PinsPainter()),
          // Blend the bottom edge into the app background.
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [bg.withValues(alpha: 0.0), bg],
                stops: const [0.93, 1.0],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PinsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    // Location pins on the visible rooftops: two on the skyline towers at the
    // sides, two on foreground houses lower down — all clear of the centred text.
    final pins = <_Pin>[
      _Pin(w * 0.08, h * 0.68, const Color(0xFF3B82F6)),
      _Pin(w * 0.90, h * 0.66, const Color(0xFF22C55E)),
      _Pin(w * 0.22, h * 0.85, const Color(0xFF5B8CFF)),
      _Pin(w * 0.66, h * 0.83, const Color(0xFF8B5CF6)),
    ];
    for (final p in pins) {
      _drawPin(canvas, p);
    }
  }

  void _drawPin(Canvas canvas, _Pin p) {
    final r = 8.0;
    // Glow.
    canvas.drawCircle(
      Offset(p.x, p.y - r),
      r * 2.4,
      Paint()
        ..color = p.color.withValues(alpha: 0.30)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );
    // Teardrop body.
    final body = Path();
    body.addOval(Rect.fromCircle(center: Offset(p.x, p.y - r), radius: r));
    body.moveTo(p.x - r * 0.62, p.y - r * 0.5);
    body.lineTo(p.x, p.y + r * 0.9);
    body.lineTo(p.x + r * 0.62, p.y - r * 0.5);
    body.close();
    canvas.drawPath(body, Paint()..color = p.color);
    // Inner dot.
    canvas.drawCircle(
      Offset(p.x, p.y - r),
      r * 0.42,
      Paint()..color = Colors.white.withValues(alpha: 0.9),
    );
  }

  @override
  bool shouldRepaint(covariant _PinsPainter oldDelegate) => false;
}

class _Pin {
  final double x;
  final double y;
  final Color color;
  const _Pin(this.x, this.y, this.color);
}
