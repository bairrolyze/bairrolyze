// HomeScope – Life Radius Widget  (Phases 1–8 redesign)

import {
  categoryColor, categoryEmoji, formatDistance, formatWalkTime,
  CATEGORIES, CAT_COLORS, scoreColor,
} from '../utils.js';

// ── Constants ──────────────────────────────────────────────────────────────────

const CAT_LABELS = {
  transportation: 'Transit',
  education:      'Schools',
  healthcare:     'Health',
  shopping:       'Shopping',
  safety:         'Safety',
  religion:       'Community',
  recreation:     'Parks',
};

// Distances in metres; labels as the user sees them
const RINGS = [
  [400,  '5 min walk'],
  [800,  '10 min'],
  [1600, '20 min'],
  [2400, '30 min'],
];

// Outermost ring = 30-min walk at ~80 m/min
const MAX_DIST = 2400;

const ZONE_RGB = [
  [34,  197,  94],   // ≤400m:  green  – very walkable
  [59,  130, 246],   // ≤800m:  blue   – walkable
  [245, 158,  11],   // ≤1200m: amber  – moderate
  [239,  68,  68],   // ≤2000m: red    – driving
];

// ── Public API ─────────────────────────────────────────────────────────────────

export function renderLifeRadius(container, result) {
  const { score, address, amenities } = result;
  const cats         = score?.categories || {};
  const overall      = score?.overall ?? 0;
  const allAmenities = (amenities || []).filter(a => a.distance_meters > 0);

  let activeFilter = null;
  let tapped       = null;
  let dotPositions = [];
  let tooltipEl    = null;

  // Derived data
  const reachCounts = [400, 800, 1200, 2000].map(d =>
    allAmenities.filter(a => a.distance_meters <= d).length
  );
  const quickFacts = CATEGORIES
    .map(catId => cats[catId]?.closest ? { catId, closest: cats[catId].closest } : null)
    .filter(Boolean)
    .sort((a, b) => a.closest.distance_meters - b.closest.distance_meters);

  // ── HTML ──────────────────────────────────────────────────────────────────
  container.innerHTML = `
    <div class="lr-screen">

      <!-- Phase 1: Location Summary Card -->
      ${_buildSummaryCard(overall, cats)}

      <!-- Phase 3: Filter chips -->
      <div class="lr-filter-row" id="lr-filter-row">
        <button class="lr-chip active" data-cat="">
          <span class="lr-chip-emoji">🗺</span>
          <span class="lr-chip-name">All</span>
          <span class="lr-chip-count">${allAmenities.length}</span>
        </button>
        ${CATEGORIES.map(catId => {
          const count = allAmenities.filter(a => a.category === catId).length;
          if (!count) return '';
          return `
            <button class="lr-chip" data-cat="${catId}" style="--chip-color:${categoryColor(catId)}">
              <span class="lr-chip-emoji">${categoryEmoji(catId)}</span>
              <span class="lr-chip-name">${CAT_LABELS[catId]}</span>
              <span class="lr-chip-count">${count}</span>
            </button>`;
        }).join('')}
      </div>

      <!-- Phase 4: Canvas radial map -->
      <div class="lr-canvas-wrap">
        <canvas id="lr-canvas"></canvas>
      </div>

      <!-- Phase 4: Color legend -->
      <div class="lr-legend">
        ${CATEGORIES
          .filter(catId => allAmenities.some(a => a.category === catId))
          .map(catId => `
            <div class="lr-legend-item">
              <span class="lr-legend-dot" style="background:${categoryColor(catId)}"></span>
              <span>${CAT_LABELS[catId]}</span>
            </div>`)
          .join('')}
      </div>

      <!-- Tap info bar -->
      <div class="lr-info-bar">
        <span class="lr-info-hint" id="lr-info-text">${allAmenities.length} places · Tap a dot to explore</span>
      </div>

      <!-- Phase 7: Empty state (hidden by default) -->
      <div id="lr-empty" class="lr-empty-state" style="display:none">
        <div class="lr-empty-icon">🔍</div>
        <div class="lr-empty-title" id="lr-empty-title">No places found</div>
        <div class="lr-empty-sub" id="lr-empty-sub">Try a different category or increase the search radius in Settings.</div>
      </div>

      <!-- Phase 2: Life Around This Home (below the radar) -->
      ${quickFacts.length ? _buildLifeAround(quickFacts) : ''}

      <div class="lr-divider"></div>

      <!-- Phase 5: Within Reach -->
      ${_buildWithinReach(reachCounts)}

      <!-- Phase 6: Closest Essentials -->
      ${_buildEssentials(cats)}

      <!-- Open map -->
      <button id="lr-open-map" class="btn-ghost"
        style="width:100%;margin-top:4px;margin-bottom:4px;${!address?.lat ? 'opacity:0.4;cursor:not-allowed' : ''}">
        🗺&nbsp; Open in OpenStreetMap
      </button>

    </div>
  `;

  // ── Canvas ────────────────────────────────────────────────────────────────
  const canvas  = container.querySelector('#lr-canvas');
  const infoTxt = container.querySelector('#lr-info-text');
  const emptyEl = container.querySelector('#lr-empty');

  function sizeCanvas() {
    const wrap = container.querySelector('.lr-canvas-wrap');
    const w    = wrap.offsetWidth || 300;
    canvas.width  = w;
    canvas.height = w;
  }

  function redraw(animFrac = 1) {
    dotPositions = _drawRadial(canvas, result, activeFilter, tapped, animFrac);
    // Phase 7: empty state
    if (activeFilter) {
      const n = allAmenities.filter(a => a.category === activeFilter).length;
      if (n === 0) {
        const label = CAT_LABELS[activeFilter] || activeFilter;
        container.querySelector('#lr-empty-title').textContent = `No ${label} found nearby`;
        container.querySelector('#lr-empty-sub').textContent =
          `No ${label.toLowerCase()} within a 20-minute walk. Try a different category or increase the search radius in Settings.`;
        emptyEl.style.display = 'block';
      } else {
        emptyEl.style.display = 'none';
      }
    } else {
      emptyEl.style.display = 'none';
    }
  }

  // Phase 8: entrance animation
  let animStart = null;
  function tick(ts) {
    if (!animStart) animStart = ts;
    const t    = Math.min((ts - animStart) / 1000, 1);
    const ease = 1 - Math.pow(1 - t, 3);
    redraw(ease);
    if (t < 1) requestAnimationFrame(tick);
  }
  requestAnimationFrame(() => { sizeCanvas(); requestAnimationFrame(tick); });

  // Phase 8: score counter animation
  const scoreEl = container.querySelector('#lr-score-num');
  if (scoreEl) _countUp(scoreEl, overall);

  // ── Filter chips ──────────────────────────────────────────────────────────
  container.querySelector('#lr-filter-row').addEventListener('click', e => {
    const chip = e.target.closest('.lr-chip');
    if (!chip) return;
    activeFilter = chip.dataset.cat || null;
    tapped = null;
    container.querySelectorAll('.lr-chip').forEach(c => c.classList.remove('active'));
    chip.classList.add('active');
    const n = activeFilter
      ? allAmenities.filter(a => a.category === activeFilter).length
      : allAmenities.length;
    _setHint(infoTxt, `${n} places · Tap a dot to explore`);
    redraw(1);
  });

  // ── Canvas tap ────────────────────────────────────────────────────────────
  canvas.addEventListener('click', e => {
    const rect = canvas.getBoundingClientRect();
    const mx = (e.clientX - rect.left) * (canvas.width  / rect.width);
    const my = (e.clientY - rect.top)  * (canvas.height / rect.height);

    let nearest = null, nearestD = Infinity;
    for (const { x, y, amenity } of dotPositions) {
      const d = Math.hypot(mx - x, my - y);
      if (d < 22 && d < nearestD) { nearestD = d; nearest = amenity; }
    }

    tapped = (tapped === nearest) ? null : nearest;
    redraw(1);

    if (tapped) {
      const c = categoryColor(tapped.category);
      infoTxt.className = 'lr-info-detail';
      infoTxt.innerHTML = `
        <span class="lr-info-dot" style="background:${c}"></span>
        <span class="lr-info-name">${tapped.name || tapped.type}</span>
        <span class="lr-info-walk" style="color:${c}">${formatDistance(tapped.distance_meters)} · ${formatWalkTime(tapped.walking_minutes)}</span>
      `;
    } else {
      const n = activeFilter
        ? allAmenities.filter(a => a.category === activeFilter).length
        : allAmenities.length;
      _setHint(infoTxt, `${n} places · Tap a dot to explore`);
    }
  });

  // Phase 8: hover tooltip
  canvas.addEventListener('mousemove', e => {
    const rect = canvas.getBoundingClientRect();
    const mx = (e.clientX - rect.left) * (canvas.width  / rect.width);
    const my = (e.clientY - rect.top)  * (canvas.height / rect.height);

    let nearest = null, nearestD = Infinity;
    for (const { x, y, amenity } of dotPositions) {
      const d = Math.hypot(mx - x, my - y);
      if (d < 20 && d < nearestD) { nearestD = d; nearest = amenity; }
    }

    if (nearest) {
      if (!tooltipEl) {
        tooltipEl = document.createElement('div');
        tooltipEl.className = 'lr-tooltip';
        document.body.appendChild(tooltipEl);
      }
      tooltipEl.textContent  = `${nearest.name || nearest.type} · ${formatWalkTime(nearest.walking_minutes)}`;
      tooltipEl.style.left   = (e.clientX + 14) + 'px';
      tooltipEl.style.top    = (e.clientY - 36) + 'px';
      tooltipEl.style.opacity = '1';
      canvas.style.cursor = 'pointer';
    } else {
      if (tooltipEl) tooltipEl.style.opacity = '0';
      canvas.style.cursor = 'default';
    }
  });

  canvas.addEventListener('mouseleave', () => {
    if (tooltipEl) tooltipEl.style.opacity = '0';
  });

  // Clean up floating tooltip when tab switches
  new MutationObserver(() => {
    if (!document.contains(canvas) && tooltipEl) {
      tooltipEl.remove();
      tooltipEl = null;
    }
  }).observe(container, { childList: true });

  // Open map
  container.querySelector('#lr-open-map')?.addEventListener('click', () => {
    if (!address?.lat || !address?.lng) return;
    chrome.tabs.create({ url: `https://www.openstreetmap.org/#map=15/${address.lat}/${address.lng}` });
  });
}

// ── HTML builders ──────────────────────────────────────────────────────────────

// Phase 1: Location Summary Card
function _buildSummaryCard(overall, cats) {
  const color   = scoreColor(overall);
  const stars   = _starsFor(overall);
  const verdict = _verdict(overall);

  const metrics = CATEGORIES
    .map(catId => ({ catId, score: cats[catId]?.score }))
    .filter(m => m.score != null)
    .sort((a, b) => b.score - a.score);

  return `
    <div class="lr-summary-card">
      <div class="lr-score-col">
        <div class="lr-score-label">SCORE</div>
        <div class="lr-score-big" style="color:${color}" id="lr-score-num">0</div>
        <div class="lr-stars" style="color:${color}">${stars}</div>
        <div class="lr-verdict">${verdict}</div>
      </div>
      <div class="lr-metrics-col">
        ${metrics.map(({ catId, score }) => `
          <div class="lr-metric">
            <div class="lr-metric-top">
              <span class="lr-metric-emoji">${categoryEmoji(catId)}</span>
              <span class="lr-metric-val" style="color:${categoryColor(catId)}">${(score / 10).toFixed(1)}</span>
            </div>
            <div class="lr-metric-name">${CAT_LABELS[catId]}</div>
          </div>
        `).join('')}
      </div>
    </div>
  `;
}

// Phase 2: Life Around This Home
function _buildLifeAround(quickFacts) {
  return `
    <div class="lr-life-section">
      <div class="lr-section-header">Life Around This Home</div>
      <div class="lr-quick-row">
        ${quickFacts.map(({ catId, closest }) => {
          const mins  = closest.walking_minutes;
          const label = mins != null ? `${mins} min` : formatDistance(closest.distance_meters);
          const c     = categoryColor(catId);
          return `
            <div class="lr-quick-card" style="--qc:${c}">
              <span class="lr-quick-emoji">${categoryEmoji(catId)}</span>
              <span class="lr-quick-name">${closest.name || closest.type || CAT_LABELS[catId]}</span>
              <span class="lr-quick-time" style="color:${c}">${label}</span>
            </div>`;
        }).join('')}
      </div>
    </div>
  `;
}

// Phase 5: Within Reach
function _buildWithinReach(reachCounts) {
  const labels = ['5 min', '10 min', '15 min', '20 min'];
  return `
    <div class="lr-section-header">Within Reach</div>
    <div class="lr-reach-cards">
      ${reachCounts.map((count, i) => `
        <div class="lr-reach-card">
          <div class="lr-reach-time">${labels[i]}</div>
          <div class="lr-reach-count">${count}</div>
          <div class="lr-reach-sub">places</div>
        </div>`).join('')}
    </div>
  `;
}

// Phase 6: Closest Essentials
function _buildEssentials(cats) {
  return `
    <div class="lr-section-header">Closest Essentials</div>
    <div class="lr-essentials-grid">
      ${CATEGORIES.map(catId => {
        const cat     = cats[catId];
        const closest = cat?.closest;
        if (!cat) return '';
        const c = categoryColor(catId);
        return `
          <div class="lr-ess-row">
            <div class="lr-ess-icon" style="background:${c}18;color:${c}">${categoryEmoji(catId)}</div>
            <div class="lr-ess-body">
              <div class="lr-ess-cat">${CAT_LABELS[catId]}</div>
              <div class="lr-ess-name">${closest ? (closest.name || closest.type || '—') : '—'}</div>
            </div>
            ${closest ? `
              <div class="lr-ess-meta">
                <span class="lr-ess-dist" style="color:${c}">${formatDistance(closest.distance_meters)}</span>
                <span class="lr-ess-time">${closest.walking_minutes != null ? closest.walking_minutes + ' min' : '—'}</span>
              </div>
            ` : `<span class="lr-ess-none">None nearby</span>`}
          </div>`;
      }).join('')}
    </div>
  `;
}

// ── Canvas renderer ────────────────────────────────────────────────────────────

function _drawRadial(canvas, result, filter, tapped, animFrac) {
  const ctx  = canvas.getContext('2d');
  const W    = canvas.width;
  const H    = canvas.height;
  const cx   = W / 2;
  const cy   = H / 2;
  // Reserve outer margin for compass labels; rings fill most of the canvas
  const maxR = Math.min(W, H) / 2 * 0.80;

  const { amenities, address } = result;
  const addrLat = address?.lat;
  const addrLng = address?.lng;

  // Sqrt scale: gives the 5-min zone generous space instead of cramming it at 17% radius
  const toR = (metres) => Math.sqrt(Math.min(metres, MAX_DIST) / MAX_DIST) * maxR;
  const ringRadii = RINGS.map(([d]) => toR(d));

  ctx.clearRect(0, 0, W, H);

  // ── 1. Background ─────────────────────────────────────────────────────────
  // Flat fill matching the app's --surface token; no gradient noise
  ctx.fillStyle = '#0D1625';
  ctx.fillRect(0, 0, W, H);

  // ── 2. Zone-coloured annuli ───────────────────────────────────────────────
  const boundaries = [0, ...ringRadii];
  ZONE_RGB.forEach(([r, g, b], i) => {
    ctx.save();
    ctx.beginPath();
    ctx.arc(cx, cy, boundaries[i + 1], 0, 2 * Math.PI, false);
    if (boundaries[i] > 0) ctx.arc(cx, cy, boundaries[i], 0, 2 * Math.PI, true);
    ctx.closePath();
    ctx.fillStyle = `rgba(${r},${g},${b},0.09)`;
    ctx.fill('evenodd');
    ctx.restore();
  });

  // ── 4. Ring strokes ───────────────────────────────────────────────────────
  ringRadii.forEach((r, i) => {
    ctx.beginPath();
    ctx.arc(cx, cy, r, 0, 2 * Math.PI);
    ctx.strokeStyle = i === RINGS.length - 1
      ? 'rgba(255,255,255,0.22)'
      : 'rgba(255,255,255,0.09)';
    ctx.lineWidth = i === RINGS.length - 1 ? 1.5 : 0.8;
    ctx.stroke();
  });

  // ── 5. Amenity dots ───────────────────────────────────────────────────────
  const allVisible  = (amenities || []).filter(a => a.distance_meters > 0);
  const dotPositions = [];

  allVisible.forEach((a, idx) => {
    const isFiltered = filter && a.category !== filter;
    const r = toR(a.distance_meters) * animFrac;

    let angle;
    if (addrLat && addrLng && a.lat != null && a.lng != null && (a.lat !== 0 || a.lng !== 0)) {
      const dLat = a.lat - addrLat;
      const dLng = (a.lng - addrLng) * Math.cos(addrLat * Math.PI / 180);
      angle = Math.atan2(dLng, dLat);
    } else {
      const ci = CATEGORIES.indexOf(a.category);
      angle = (2 * Math.PI / CATEGORIES.length) * (ci >= 0 ? ci : idx % CATEGORIES.length) - Math.PI / 2;
    }

    const px   = cx + r * Math.sin(angle);
    const py   = cy - r * Math.cos(angle);
    const hex  = CAT_COLORS[a.category] || '#888888';
    const dotR = tapped === a ? 6 : 4;

    if (isFiltered) return;
    dotPositions.push({ x: px, y: py, amenity: a });

    ctx.save();

    // Soft glow
    const glow = ctx.createRadialGradient(px, py, 0, px, py, 11);
    glow.addColorStop(0, hex + 'aa');
    glow.addColorStop(1, hex + '00');
    ctx.beginPath();
    ctx.arc(px, py, 11, 0, 2 * Math.PI);
    ctx.fillStyle = glow;
    ctx.fill();

    // Tap highlight ring
    if (tapped === a) {
      ctx.beginPath();
      ctx.arc(px, py, 12, 0, 2 * Math.PI);
      ctx.strokeStyle = hex;
      ctx.lineWidth   = 1.5;
      ctx.globalAlpha = 0.5;
      ctx.stroke();
      ctx.globalAlpha = 1;
    }

    // Dot
    ctx.beginPath();
    ctx.arc(px, py, dotR, 0, 2 * Math.PI);
    ctx.fillStyle = hex;
    ctx.fill();

    // White centre
    ctx.beginPath();
    ctx.arc(px, py, tapped === a ? 2.5 : 1.5, 0, 2 * Math.PI);
    ctx.fillStyle = 'rgba(255,255,255,0.95)';
    ctx.fill();

    ctx.restore();
  });

  // ── 6. Walk-time labels (drawn after dots so always readable) ─────────────
  // Labels sit ON the ring at ~25° east of north (NNE), with a dark pill background.
  const lFont    = `500 ${Math.max(9, Math.round(W * 0.031))}px system-ui, sans-serif`;
  const lAngle   = (25 * Math.PI) / 180;  // 25° clockwise from north
  const lPadX    = 5;
  const lPadY    = 4;

  ctx.font         = lFont;
  ctx.textAlign    = 'left';
  ctx.textBaseline = 'middle';

  ringRadii.forEach((r, i) => {
    const [, label] = RINGS[i];
    const isOuter   = i === RINGS.length - 1;

    // Point on the ring at the chosen angle
    const lx = cx + r * Math.sin(lAngle);
    const ly = cy - r * Math.cos(lAngle);

    const tw = ctx.measureText(label).width;
    const ph = 12 + lPadY;  // pill height

    // Dark pill — "erases" the ring line behind the text so it reads clearly
    ctx.beginPath();
    ctx.roundRect(lx - lPadX, ly - ph / 2, tw + lPadX * 2, ph, 4);
    ctx.fillStyle = 'rgba(4, 10, 24, 0.82)';
    ctx.fill();

    // Label text
    ctx.fillStyle = isOuter ? 'rgba(255,255,255,0.78)' : 'rgba(255,255,255,0.52)';
    ctx.fillText(label, lx, ly);
  });

  // ── 7. Compass labels ─────────────────────────────────────────────────────
  const compR = maxR + 17;
  ctx.font         = `600 ${Math.max(9, Math.round(W * 0.032))}px system-ui, sans-serif`;
  ctx.fillStyle    = 'rgba(255,255,255,0.20)';
  ctx.textAlign    = 'center';
  ctx.textBaseline = 'middle';
  ctx.fillText('N', cx,         cy - compR);
  ctx.fillText('S', cx,         cy + compR);
  ctx.fillText('E', cx + compR, cy);
  ctx.fillText('W', cx - compR, cy);

  // ── 8. Home icon (always on top) ─────────────────────────────────────────
  _drawHomeIcon(ctx, cx, cy, 36);

  return dotPositions;
}

// ── Home icon ──────────────────────────────────────────────────────────────────

function _drawHomeIcon(ctx, cx, cy, size) {
  const r = size / 2;

  // Soft purple glow behind the circle
  const glow = ctx.createRadialGradient(cx, cy, 0, cx, cy, r + 10);
  glow.addColorStop(0, 'rgba(108,99,255,0.45)');
  glow.addColorStop(1, 'rgba(108,99,255,0)');
  ctx.beginPath();
  ctx.arc(cx, cy, r + 10, 0, 2 * Math.PI);
  ctx.fillStyle = glow;
  ctx.fill();

  // Filled circle background
  ctx.beginPath();
  ctx.arc(cx, cy, r, 0, 2 * Math.PI);
  ctx.fillStyle = '#6C63FF';
  ctx.fill();

  // Thin white border ring
  ctx.beginPath();
  ctx.arc(cx, cy, r, 0, 2 * Math.PI);
  ctx.strokeStyle = 'rgba(255,255,255,0.25)';
  ctx.lineWidth   = 1.5;
  ctx.stroke();

  // ── House shape (white, centered, vertically offset slightly up) ───────────
  // Dimensions tuned for a circle of radius 18 px (size=36)
  const scale = r / 18;
  const oy    = -1.5 * scale;  // nudge up so the house looks centered in the circle

  ctx.save();
  ctx.fillStyle   = 'white';
  ctx.strokeStyle = 'white';
  ctx.lineJoin    = 'round';
  ctx.lineCap     = 'round';

  // Roof triangle
  const roofPeakY  = cy - 11 * scale + oy;
  const roofBaseY  = cy - 3  * scale + oy;
  const roofLeft   = cx - 10 * scale;
  const roofRight  = cx + 10 * scale;

  ctx.beginPath();
  ctx.moveTo(cx,         roofPeakY);
  ctx.lineTo(roofLeft,   roofBaseY);
  ctx.lineTo(roofRight,  roofBaseY);
  ctx.closePath();
  ctx.fill();

  // House body rectangle (sits directly below roof base)
  const bodyLeft   = cx - 7.5 * scale;
  const bodyRight  = cx + 7.5 * scale;
  const bodyTop    = roofBaseY;
  const bodyBottom = cy + 9   * scale + oy;

  ctx.beginPath();
  ctx.rect(bodyLeft, bodyTop, bodyRight - bodyLeft, bodyBottom - bodyTop);
  ctx.fill();

  // Door cutout in the circle color so it looks like an opening
  ctx.fillStyle = '#6C63FF';
  const doorW = 4.5 * scale;
  const doorH = 5.5 * scale;
  ctx.beginPath();
  ctx.rect(cx - doorW / 2, bodyBottom - doorH, doorW, doorH);
  ctx.fill();

  ctx.restore();
}

// ── Utilities ──────────────────────────────────────────────────────────────────

function _starsFor(score) {
  const n = score >= 80 ? 5 : score >= 65 ? 4 : score >= 50 ? 3 : score >= 35 ? 2 : 1;
  return '★'.repeat(n) + '☆'.repeat(5 - n);
}

function _verdict(score) {
  if (score >= 80) return 'Excellent everyday convenience';
  if (score >= 65) return 'Good walkable location';
  if (score >= 50) return 'Decent access to amenities';
  if (score >= 35) return 'Limited walkability';
  return 'Car-dependent location';
}

// Phase 8: animated score counter
function _countUp(el, target, duration = 1200) {
  let start = null;
  function step(ts) {
    if (!start) start = ts;
    const p = Math.min((ts - start) / duration, 1);
    el.textContent = Math.round((1 - Math.pow(1 - p, 3)) * target);
    if (p < 1) requestAnimationFrame(step);
  }
  requestAnimationFrame(step);
}

function _setHint(el, msg) {
  el.className   = 'lr-info-hint';
  el.textContent = msg;
}
