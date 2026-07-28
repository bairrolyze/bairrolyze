// NeighborLens – Property Compare Widget (Phase 5)
// Side-by-side comparison of two scored properties.
// Saved comparison is persisted in chrome.storage.local as 'nl_compare'.

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
  healthcare:     'Health',
  shopping:       'Shopping',
  safety:         'Safety',
  religion:       'Community',
  recreation:     'Parks',
};

const STORAGE_KEY = 'nl_compare';

// ── Storage helpers ─────────────────────────────────────────────────────────────

async function _saveComparison(result) {
  return chrome.storage.local.set({ [STORAGE_KEY]: JSON.stringify(result) });
}

async function _loadSavedComparison() {
  const d = await chrome.storage.local.get(STORAGE_KEY);
  return d[STORAGE_KEY] ? JSON.parse(d[STORAGE_KEY]) : null;
}

async function _clearComparison() {
  return chrome.storage.local.remove(STORAGE_KEY);
}

// ── Public API ──────────────────────────────────────────────────────────────────

/**
 * Renders the property comparison widget into `container`.
 *
 * @param {HTMLElement} container
 * @param {object} currentResult — currently viewed property's API result
 */
export async function renderPropertyCompare(container, currentResult) {
  // Show a loading placeholder while we read storage
  container.innerHTML = `
    <div class="pc-screen" style="align-items:center;justify-content:center">
      <div style="font-size:12px;color:var(--text3)">Loading…</div>
    </div>`;

  const saved = await _loadSavedComparison();

  if (!saved) {
    _renderEmpty(container, currentResult);
  } else {
    _renderComparison(container, saved, currentResult);
  }
}

// ── Empty state ─────────────────────────────────────────────────────────────────

function _renderEmpty(container, currentResult) {
  const addr = _shortAddr(currentResult);
  container.innerHTML = `
    <div class="pc-screen">
      <div class="pc-empty">
        <div class="pc-empty-icon">⚖️</div>
        <div class="pc-empty-title">Compare properties</div>
        <div class="pc-empty-desc">Save this property, then search a second address to compare side by side.</div>
        <button id="pc-save-btn" class="btn-primary">Save "${addr}"</button>
      </div>
    </div>`;

  container.querySelector('#pc-save-btn').addEventListener('click', async () => {
    await _saveComparison(currentResult);
    renderPropertyCompare(container, currentResult);
  });
}

// ── Side-by-side comparison ─────────────────────────────────────────────────────

function _renderComparison(container, saved, current) {
  const savedAddr   = _shortAddr(saved);
  const currentAddr = _shortAddr(current);

  const savedOverall   = saved.score?.overall ?? 0;
  const currentOverall = current.score?.overall ?? 0;

  // Build rows: overall + each category
  const savedCats   = saved.score?.categories || {};
  const currentCats = current.score?.categories || {};

  // Gather all category IDs from both
  const allCatIds = [...new Set([...Object.keys(savedCats), ...Object.keys(currentCats)])];

  const overallRow = _buildRow(
    'Overall Score',
    savedOverall,
    currentOverall,
    v => `<span style="font-size:18px;font-weight:900">${Math.round(v)}</span>`
  );

  const catRows = allCatIds.map(catId => {
    const emoji = CAT_EMOJI[catId] || '📍';
    const label = CAT_LABELS[catId] || catId;
    const sScore = savedCats[catId]?.score ?? null;
    const cScore = currentCats[catId]?.score ?? null;
    return _buildRow(`${emoji} ${label}`, sScore, cScore);
  }).join('');

  // Closest essentials rows
  const KEY_CATS = [
    { id: 'education',      label: '🎓 Nearest School' },
    { id: 'transportation', label: '🚇 Nearest Transit' },
    { id: 'healthcare',     label: '🏥 Nearest Hospital' },
    { id: 'recreation',     label: '🌳 Nearest Park' },
  ];

  const closestRows = KEY_CATS.map(({ id, label }) => {
    const sClosest = savedCats[id]?.closest;
    const cClosest = currentCats[id]?.closest;
    const sVal = sClosest ? sClosest.distance_meters : null;
    const cVal = cClosest ? cClosest.distance_meters : null;
    // Lower is better for distances — invert comparison
    return _buildRow(label, sVal, cVal, v => `${v}m`, true);
  }).join('');

  container.innerHTML = `
    <div class="pc-screen">
      <div class="pc-table">
        <div class="pc-header">
          <div class="pc-col-label">Category</div>
          <div class="pc-col-a" title="${_esc(savedAddr)}">A: ${_shortAddr2(savedAddr)}</div>
          <div class="pc-col-b" title="${_esc(currentAddr)}">B: ${_shortAddr2(currentAddr)}</div>
        </div>
        <div class="pc-divider-header"></div>
        ${overallRow}
        ${catRows}
        ${closestRows}
      </div>
      <div style="display:flex;gap:8px;margin-top:12px">
        <button id="pc-save-current-btn" class="btn-ghost" style="flex:1">Save current as A</button>
        <button id="pc-clear-btn" class="pc-clear-btn">Clear A</button>
      </div>
    </div>`;

  container.querySelector('#pc-clear-btn').addEventListener('click', async () => {
    await _clearComparison();
    renderPropertyCompare(container, current);
  });

  container.querySelector('#pc-save-current-btn').addEventListener('click', async () => {
    await _saveComparison(current);
    renderPropertyCompare(container, current);
  });
}

/**
 * Build a comparison row showing two values with "better" / "worse" highlighting.
 * @param {string} label
 * @param {number|null} aVal — saved property value
 * @param {number|null} bVal — current property value
 * @param {Function} [fmt] — formatter function
 * @param {boolean} [lowerBetter] — if true, lower value is better (e.g. distance)
 */
function _buildRow(label, aVal, bVal, fmt = v => `${Math.round(v)}`, lowerBetter = false) {
  const fmtNull = v => v == null ? '<span style="color:var(--text3)">—</span>' : fmt(v);

  let aClass = '', bClass = '';
  if (aVal != null && bVal != null) {
    if (aVal === bVal) {
      // tie — no highlight
    } else {
      const aBetter = lowerBetter ? (aVal < bVal) : (aVal > bVal);
      aClass = aBetter ? 'better' : 'worse';
      bClass = aBetter ? 'worse'  : 'better';
    }
  }

  // Visual bar (only for scores 0-100)
  const showBar = !lowerBetter && aVal != null && bVal != null && aVal <= 100 && bVal <= 100;
  const barA = showBar ? `<div style="height:3px;background:#3B82F6;width:${aVal}%;border-radius:2px;margin-top:3px;opacity:0.6"></div>` : '';
  const barB = showBar ? `<div style="height:3px;background:#F59E0B;width:${bVal}%;border-radius:2px;margin-top:3px;opacity:0.6"></div>` : '';

  return `
    <div class="pc-row">
      <div class="pc-row-label">${_esc(label)}</div>
      <div class="pc-val ${aClass}">${fmtNull(aVal)}${barA}</div>
      <div class="pc-val ${bClass}">${fmtNull(bVal)}${barB}</div>
    </div>`;
}

// ── Helpers ─────────────────────────────────────────────────────────────────────

function _shortAddr(result) {
  const d = result?.address?.display_name || result?._address || 'Property';
  // Take first two comma-separated parts
  return d.split(',').slice(0, 2).join(',').trim();
}

function _shortAddr2(addr) {
  return addr.length > 20 ? addr.slice(0, 20) + '…' : addr;
}

function _esc(str) {
  return String(str || '')
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;');
}
