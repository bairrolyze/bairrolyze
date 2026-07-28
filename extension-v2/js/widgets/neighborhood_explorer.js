// NeighborLens – Neighborhood Explorer Widget (Phase 3)
// Renders a categorised, sortable list of all nearby amenities.

const CAT_COLORS = {
  transportation: '#29B6F6',
  education:      '#66BB6A',
  healthcare:     '#EF5350',
  shopping:       '#FFA726',
  safety:         '#AB47BC',
  religion:       '#8D6E63',
  recreation:     '#26C6DA',
};

const CAT_EMOJI = {
  transportation: '🚇',
  education:      '🎓',
  healthcare:     '🏥',
  shopping:       '🛍',
  safety:         '🛡',
  religion:       '⛪',
  recreation:     '🌳',
};

const CAT_LABELS = {
  transportation: 'Transit',
  education:      'Schools',
  healthcare:     'Healthcare',
  shopping:       'Shopping',
  safety:         'Safety',
  religion:       'Community',
  recreation:     'Parks & Recreation',
};

// Preferred display order
const CAT_ORDER = ['education','transportation','healthcare','shopping','recreation','safety','religion'];

/**
 * Renders the neighborhood explorer into `container`.
 * Groups all amenities by category, sorted by distance within each group.
 *
 * @param {HTMLElement} container
 * @param {object} result — API result object
 */
export function renderNeighborhoodExplorer(container, result) {
  const amenities = result.amenities || [];
  const cats      = result.score?.categories || {};

  // ── Empty state ─────────────────────────────────────────────────────────────
  if (amenities.length === 0) {
    container.innerHTML = `
      <div class="ne-screen">
        <div class="lr-empty-state">
          <div class="lr-empty-icon">🔍</div>
          <div class="lr-empty-title">No nearby places found</div>
          <div class="lr-empty-sub">Score this address first to populate nearby amenities.</div>
        </div>
      </div>`;
    return;
  }

  // ── Group by category ────────────────────────────────────────────────────────
  const grouped = {};
  for (const a of amenities) {
    if (!a.category) continue;
    if (!grouped[a.category]) grouped[a.category] = [];
    grouped[a.category].push(a);
  }

  // Sort within each group by distance
  for (const cat of Object.keys(grouped)) {
    grouped[cat].sort((a, b) => (a.distance_meters || 0) - (b.distance_meters || 0));
  }

  // Build sections in preferred order, then any extras
  const orderedCats = [
    ...CAT_ORDER.filter(c => grouped[c]),
    ...Object.keys(grouped).filter(c => !CAT_ORDER.includes(c)),
  ];

  const sectionsHTML = orderedCats.map(cat => {
    const items   = grouped[cat];
    const color   = CAT_COLORS[cat] || '#888';
    const emoji   = CAT_EMOJI[cat] || '📍';
    const label   = CAT_LABELS[cat] || cat;
    const catScore = cats[cat]?.score;

    const itemsHTML = items.map(a => {
      const name = a.name || a.type || 'Place';
      const dist = _formatDist(a.distance_meters);
      const walk = a.walking_minutes != null ? `${a.walking_minutes} min` : '—';
      return `
        <div class="ne-poi-item">
          <span class="ne-poi-dot" style="background:${color}"></span>
          <span class="ne-poi-name">${_esc(name)}</span>
          <span class="ne-poi-dist" style="color:${color}">${dist}</span>
          <span class="ne-poi-walk">${walk}</span>
        </div>`;
    }).join('');

    const scoreChip = catScore != null
      ? `<span class="ne-cat-score" style="color:${color};font-size:11px;font-weight:700">${Math.round(catScore)}</span>`
      : '';

    return `
      <div class="ne-cat-section">
        <div class="ne-cat-header">
          <span class="ne-cat-emoji">${emoji}</span>
          <span class="ne-cat-name">${label}</span>
          ${scoreChip}
          <span class="ne-cat-count">${items.length} place${items.length !== 1 ? 's' : ''}</span>
        </div>
        ${itemsHTML}
      </div>`;
  }).join('');

  container.innerHTML = `<div class="ne-screen">${sectionsHTML}</div>`;
}

// ── Helpers ─────────────────────────────────────────────────────────────────────

function _formatDist(meters) {
  if (meters == null) return '—';
  if (meters < 1000) return `${meters}m`;
  return `${(meters / 1000).toFixed(1)}km`;
}

function _esc(str) {
  return String(str || '')
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;');
}
