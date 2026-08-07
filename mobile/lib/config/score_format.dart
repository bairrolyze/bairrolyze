import 'package:flutter/material.dart';

/// Single source of truth for how a 0–100 score (overall or per-category) is
/// presented to the user, so the number, word, and colour agree on every
/// screen (summary header, category cards, and the detail sheet).

/// The headline number, always on the app's /10 scale (e.g. 82.0 -> "8.2").
String scoreTenth(double score) =>
    (score / 10).clamp(0.0, 10.0).toStringAsFixed(1);

/// Qualitative band label. Five bands so 80–89 reads "Very Good" rather than
/// jumping straight to "Excellent".
String scoreLabel(double score) {
  if (score >= 90) return 'Excellent';
  if (score >= 80) return 'Very Good';
  if (score >= 65) return 'Good';
  if (score >= 45) return 'Fair';
  return 'Poor';
}

/// Score-based accent colour (green / blue / amber / red).
Color scoreColor(double score) {
  if (score >= 80) return const Color(0xFF22C55E);
  if (score >= 60) return const Color(0xFF3B82F6);
  if (score >= 40) return const Color(0xFFF59E0B);
  return const Color(0xFFEF4444);
}

/// Compact category names, kept consistent between the summary cards and the
/// detail-sheet title (e.g. "Recreation" -> "Leisure").
const _shortCategoryLabels = {
  'transportation': 'Transport',
  'education': 'Education',
  'healthcare': 'Health',
  'shopping': 'Shopping',
  'safety': 'Safety',
  'religion': 'Religion',
  'recreation': 'Leisure',
};

String shortCategoryLabel(String id, [String fallback = '']) =>
    _shortCategoryLabels[id] ?? (fallback.isNotEmpty ? fallback : id);
