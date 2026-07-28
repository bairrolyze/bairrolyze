// HomeScope – Shared Utilities

export const CAT_COLORS = {
  transportation: '#29B6F6',
  education:      '#66BB6A',
  healthcare:     '#EF5350',
  shopping:       '#FFA726',
  safety:         '#AB47BC',
  religion:       '#8D6E63',
  recreation:     '#26C6DA',
};

export const CAT_EMOJI = {
  transportation: '🚇',
  education:      '🎓',
  healthcare:     '🏥',
  shopping:       '🛍',
  safety:         '🛡',
  religion:       '⛪',
  recreation:     '🌳',
};

export const CATEGORIES = ['transportation','education','healthcare','shopping','safety','religion','recreation'];

export function scoreColor(score) {
  if (score >= 80) return '#22C55E';
  if (score >= 60) return '#3B82F6';
  if (score >= 40) return '#F59E0B';
  return '#EF4444';
}

export function scoreLabel(score) {
  if (score >= 80) return 'Excellent';
  if (score >= 60) return 'Good';
  if (score >= 40) return 'Fair';
  return 'Poor';
}

export function categoryEmoji(catId) {
  return CAT_EMOJI[catId] || '📍';
}

export function categoryColor(catId) {
  return CAT_COLORS[catId] || '#888';
}

export function formatDistance(meters) {
  if (!meters) return '—';
  if (meters < 1000) return `${meters}m`;
  return `${(meters / 1000).toFixed(1)}km`;
}

export function formatWalkTime(minutes) {
  if (!minutes) return '—';
  return `${minutes} min walk`;
}

export function streetViewUrl(lat, lng) {
  return `https://www.google.com/maps/@?api=1&map_action=pano&viewpoint=${lat},${lng}`;
}

export function mapsUrl(lat, lng, label) {
  return `https://www.google.com/maps/search/?api=1&query=${lat},${lng}&query_place_id=${encodeURIComponent(label || '')}`;
}

export function uuid() {
  return crypto.randomUUID();
}

export function relativeTime(isoDate) {
  const ms = Date.now() - new Date(isoDate).getTime();
  const s = Math.floor(ms / 1000);
  if (s < 60) return 'Just now';
  const m = Math.floor(s / 60);
  if (m < 60) return `${m}m ago`;
  const h = Math.floor(m / 60);
  if (h < 24) return `${h}h ago`;
  return `${Math.floor(h / 24)}d ago`;
}
