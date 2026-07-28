// NeighborLens – Neighbourhood Intelligence Screen (6 tabs: Map + 5 original)
// Map tab is first; all original tabs remain unchanged.

import { setState, getState } from '../state.js';
import { scoreColor, scoreLabel, streetViewUrl } from '../utils.js';
import { renderRadarChart } from '../widgets/radar_chart.js';
import { renderTimeMachine } from '../widgets/time_machine.js';
import { renderAiStory } from '../widgets/ai_story.js';
import { renderFutureScore } from '../widgets/future_score.js';
import { renderLifeRadius } from '../widgets/life_radius.js';
import { renderMapView } from '../widgets/map_view.js';
import { renderNeighborhoodExplorer } from '../widgets/neighborhood_explorer.js';
import { renderPropertyCompare } from '../widgets/property_compare.js';
import { renderNeighborhoodTimeline } from '../widgets/neighborhood_timeline.js';

const TABS = [
  { id: 'map',          label: 'Map',      emoji: '🗺' },
  { id: 'explore',      label: 'Explore',  emoji: '🔍' },
  { id: 'dna',          label: 'DNA',      emoji: '🧬' },
  { id: 'timeline',     label: 'Timeline', emoji: '⏱' },
  { id: 'life-radius',  label: 'Radius',   emoji: '📍' },
  { id: 'time-machine', label: 'Time',     emoji: '🕐' },
  { id: 'ai-story',     label: 'Story',    emoji: '✨' },
  { id: 'future-score', label: 'Future',   emoji: '🔮' },
  { id: 'compare',      label: 'Compare',  emoji: '⚖️' },
];

export function renderNeighborhood(container, result) {
  container.innerHTML = `
    <div class="ni-screen">
      <!-- Tab navigation -->
      <div class="ni-tabs">
        ${TABS.map(tab => `
          <button class="ni-tab ${tab.id === (getState().niTab || 'map') ? 'active' : ''}"
            data-tab="${tab.id}">
            <span class="ni-tab-emoji">${tab.emoji}</span>
            <span class="ni-tab-label">${tab.label}</span>
          </button>
        `).join('')}
      </div>

      <!-- Tab content -->
      <div id="ni-content" class="ni-content"></div>
    </div>
  `;

  const content = container.querySelector('#ni-content');
  const tabs = container.querySelectorAll('.ni-tab');

  function activateTab(tabId) {
    setState({ niTab: tabId });
    tabs.forEach(t => t.classList.toggle('active', t.dataset.tab === tabId));
    renderTab(tabId, content, result);
  }

  tabs.forEach(btn => {
    btn.addEventListener('click', () => activateTab(btn.dataset.tab));
  });

  // Render initial tab – default to 'map' (most prominent)
  activateTab(getState().niTab || 'map');
}

function renderTab(tabId, content, result) {
  content.innerHTML = '';
  content.scrollTop = 0;

  switch (tabId) {
    case 'map':          renderMapView(content, result);               break;
    case 'explore':      renderNeighborhoodExplorer(content, result);  break;
    case 'dna':          renderDNA(content, result);                   break;
    case 'life-radius':  renderLifeRadius(content, result);            break;
    case 'time-machine': renderTimeMachine(content, result.score);     break;
    case 'ai-story':     renderAiStory(content, result);               break;
    case 'future-score': renderFutureScore(content, result.score);     break;
    case 'timeline':     renderNeighborhoodTimeline(content, result);  break;
    case 'compare':      renderPropertyCompare(content, result);       break;
  }
}

function renderDNA(content, result) {
  const cats = result.score?.categories || {};
  const address = result.address;
  const overall = result.score?.overall ?? 0;
  const color = scoreColor(overall);
  const label = scoreLabel(overall);

  content.innerHTML = `
    <div class="dna-screen">
      <div class="dash-header" style="--accent:${color}">
        <div class="dash-score-ring">
          <svg viewBox="0 0 120 120" class="ring-svg">
            <circle cx="60" cy="60" r="50" class="ring-bg"/>
            <circle cx="60" cy="60" r="50" class="ring-fill"
              style="stroke:${color};stroke-dasharray:${Math.round(314 * overall / 100)} 314"/>
          </svg>
          <div class="ring-inner">
            <div class="ring-score" style="color:${color}">${Math.round(overall)}</div>
            <div class="ring-label">${label}</div>
          </div>
        </div>
        <div class="dash-address-block">
          <div class="dash-address">${address?.display_name || result._address || '—'}</div>
          ${address ? `<div class="dash-meta">${[address.district, address.city, address.postalCode || address.postal_code].filter(Boolean).join(' · ')}</div>` : ''}
          ${address?.lat ? `<a href="${streetViewUrl(address.lat, address.lng)}" target="_blank" class="street-view-link">📷 Street View</a>` : ''}
        </div>
      </div>

      <div class="section-label" style="color:rgba(255,255,255,0.5);margin-top:4px">CATEGORY DNA</div>

      <div class="dna-chart-wrap">
        <canvas id="radar-canvas" width="280" height="280"></canvas>
      </div>

      <div class="dna-legend">
        ${Object.values(cats).map(cat => `
          <div class="dna-legend-row">
            <div class="dna-legend-dot" style="background:${getCatColor(cat.id)}"></div>
            <span class="dna-legend-label">${cat.label}</span>
            <div class="dna-legend-bar-bg">
              <div class="dna-legend-bar"
                style="width:${cat.score}%;background:${getCatColor(cat.id)}"></div>
            </div>
            <span class="dna-legend-score" style="color:${getCatColor(cat.id)}">${Math.round(cat.score)}</span>
          </div>
        `).join('')}
      </div>
    </div>
  `;

  // Draw canvas radar chart
  requestAnimationFrame(() => {
    const canvas = content.querySelector('#radar-canvas');
    if (canvas) renderRadarChart(canvas, cats);
  });

  // Append DNA explained section
  _renderDNAExplained(content.querySelector('.dna-screen'), result);
}

// ── DNA Explained: expandable score cards ──────────────────────────────────────

function _renderDNAExplained(container, result) {
  if (!container) return;
  const cats      = result.score?.categories || {};
  const amenities = result.amenities || [];

  if (Object.keys(cats).length === 0) return;

  const CAT_EMOJI_MAP = {
    transportation: '🚇', education: '🎓', healthcare: '🏥',
    shopping: '🛍', safety: '🛡', religion: '⛪', recreation: '🌳',
  };
  const CAT_LABELS_MAP = {
    transportation: 'Transit', education: 'Schools', healthcare: 'Health',
    shopping: 'Shopping', safety: 'Safety', religion: 'Community', recreation: 'Parks',
  };

  const html = Object.entries(cats).map(([catId, cat]) => {
    const color  = getCatColor(catId);
    const emoji  = CAT_EMOJI_MAP[catId] || '📍';
    const label  = CAT_LABELS_MAP[catId] || cat.label || catId;
    const score  = cat.score ?? 0;

    const nearby = amenities
      .filter(a => a.category === catId)
      .sort((a, b) => a.distance_meters - b.distance_meters)
      .slice(0, 3);

    const poisHTML = catId === 'transportation'
      ? _buildTransportNearbyHTML(amenities, color)
      : (nearby.length ? nearby.map(a => `
          <div class="dna-exp-poi">
            <span class="dna-exp-poi-name">${_escDNA(a.name || a.type || 'Place')}</span>
            <span class="dna-exp-poi-dist" style="color:${color}">${a.distance_meters}m</span>
            <span class="dna-exp-poi-walk">${a.walking_minutes != null ? a.walking_minutes + ' min' : '—'}</span>
          </div>`).join('')
        : '<div class="dna-exp-none">No nearby data available</div>');

    return `
      <div class="dna-exp-card" data-cat="${catId}">
        <div class="dna-exp-header">
          <span class="dna-exp-emoji">${emoji}</span>
          <span class="dna-exp-name">${label}</span>
          <div class="dna-exp-bar-wrap">
            <div class="dna-exp-bar" style="width:${score}%;background:${color}"></div>
          </div>
          <span class="dna-exp-score" style="color:${color}">${Math.round(score)}</span>
          <button class="dna-exp-toggle" aria-label="Toggle details">›</button>
        </div>
        <div class="dna-exp-body" style="display:none">
          ${poisHTML}
        </div>
      </div>`;
  }).join('');

  const section = document.createElement('div');
  section.className = 'dna-exp-section';
  section.innerHTML = `
    <div class="section-label" style="color:rgba(255,255,255,0.5);margin-top:16px;margin-bottom:8px">SCORE BREAKDOWN</div>
    ${html}`;
  container.appendChild(section);

  // Wire accordion toggle
  section.querySelectorAll('.dna-exp-header').forEach(header => {
    header.addEventListener('click', () => {
      const card = header.closest('.dna-exp-card');
      const body = card.querySelector('.dna-exp-body');
      const isOpen = card.classList.toggle('open');
      body.style.display = isOpen ? 'block' : 'none';

      // Initialize transport radar on first open
      if (isOpen && card.dataset.cat === 'transportation') {
        const canvas = body.querySelector('.tr-radar-canvas');
        if (canvas && !canvas.dataset.initialized) {
          canvas.dataset.initialized = '1';
          const transportItems = amenities
            .filter(a => a.category === 'transportation')
            .sort((a, b) => a.distance_meters - b.distance_meters)
            .slice(0, 8);
          _drawTransportRadar(canvas, transportItems);
          _bindTransportCards(body, transportItems, canvas);
        }
      }
    });
  });
}

function _escDNA(str) {
  return String(str || '')
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;');
}

// ── Transport constants ────────────────────────────────────────────────────────

const _TR_COLORS = {
  subway_entrance: '#8B5CF6',
  bus_stop:        '#3B82F6',
  station:         '#22C55E',
  taxi:            '#F59E0B',
  bicycle_rental:  '#06B6D4',
  tram_stop:       '#EC4899',
  ferry_terminal:  '#14B8A6',
  parking:         '#64748B',
};

const _TR_EMOJI = {
  subway_entrance: '🚇',
  bus_stop:        '🚌',
  station:         '🚆',
  taxi:            '🚕',
  bicycle_rental:  '🚲',
  tram_stop:       '🚃',
  ferry_terminal:  '⛴',
  parking:         '🅿️',
};

// ── Build transport nearby HTML ────────────────────────────────────────────────

function _buildTransportNearbyHTML(allAmenities, baseColor) {
  const items = allAmenities
    .filter(a => a.category === 'transportation')
    .sort((a, b) => a.distance_meters - b.distance_meters)
    .slice(0, 8);

  if (!items.length) return '<div class="dna-exp-none">No transport data available</div>';

  const cards = items.map((a, i) => {
    const tc   = _TR_COLORS[a.type] || baseColor;
    const emoji = _TR_EMOJI[a.type] || '🚌';
    const dist = a.distance_meters < 1000
      ? `${a.distance_meters}m`
      : `${(a.distance_meters / 1000).toFixed(1)}km`;
    const walk = a.walking_minutes != null ? `· ${a.walking_minutes} min walk` : '';
    const refs = (a.tags?.ref || '').split(/[;,/]/).map(s => s.trim()).filter(Boolean).slice(0, 4);
    const routeTags = refs.length
      ? `<div class="tr-route-row">${refs.map(r =>
          `<span class="tr-route-tag" style="color:${tc};background:${tc}1C;border-color:${tc}44">${r}</span>`
        ).join('')}</div>`
      : '';

    return `
      <div class="tr-card" data-idx="${i}" data-type="${a.type}" style="--tc:${tc}">
        <div class="tr-card-icon" style="color:${tc};background:${tc}1A">${emoji}</div>
        <div class="tr-card-info">
          <div class="tr-card-name">${_escDNA(a.name || a.type)}</div>
          <div class="tr-card-meta"><span style="color:${tc};font-weight:600">${dist}</span> <span class="tr-card-walk">${walk}</span></div>
          ${routeTags}
        </div>
      </div>`;
  }).join('');

  return `
    <div class="tr-panel">
      <div class="tr-cards" id="tr-cards">${cards}</div>
      <div class="tr-radar-wrap">
        <canvas class="tr-radar-canvas" width="160" height="160"></canvas>
      </div>
    </div>`;
}

// ── Draw transport radar on canvas ─────────────────────────────────────────────

function _drawTransportRadar(canvas, items, selectedIdx = null) {
  const ctx = canvas.getContext('2d');
  const W = canvas.width, H = canvas.height;
  const cx = W / 2, cy = H / 2;
  const maxR = Math.min(W, H) / 2 - 22;
  ctx.clearRect(0, 0, W, H);

  // Background circle
  ctx.beginPath();
  ctx.arc(cx, cy, maxR + 4, 0, Math.PI * 2);
  ctx.fillStyle = '#0A1628';
  ctx.fill();

  // Concentric rings
  const RING_RADII = [0.25, 0.5, 0.75, 1.0];
  const RING_LABELS = ['500m', '1km', '1.5km', '2km'];
  RING_RADII.forEach((rf, ri) => {
    const r = rf * maxR;
    ctx.beginPath();
    ctx.arc(cx, cy, r, 0, Math.PI * 2);
    ctx.strokeStyle = 'rgba(255,255,255,0.07)';
    ctx.lineWidth = 0.8;
    ctx.setLineDash([3, 5]);
    ctx.stroke();
    ctx.setLineDash([]);
    if (ri === RING_RADII.length - 1) {
      ctx.fillStyle = 'rgba(255,255,255,0.22)';
      ctx.font = '8px -apple-system, sans-serif';
      ctx.fillText(RING_LABELS[ri], cx + r * Math.cos(Math.PI / 8) + 2, cy + r * Math.sin(Math.PI / 8));
    }
  });

  // Group items by type
  const groups = {};
  items.forEach(a => {
    if (!groups[a.type]) groups[a.type] = [];
    groups[a.type].push(a);
  });
  const subtypes = Object.keys(groups);
  if (!subtypes.length) return;

  const step = (2 * Math.PI) / subtypes.length;
  const MAX_DIST = 2000;

  subtypes.forEach((type, i) => {
    const angle = -Math.PI / 2 + i * step;
    const tc = _TR_COLORS[type] || '#3B82F6';
    const isSelected = selectedIdx === i;

    // Spoke
    ctx.beginPath();
    ctx.moveTo(cx, cy);
    ctx.lineTo(cx + maxR * Math.cos(angle), cy + maxR * Math.sin(angle));
    ctx.strokeStyle = isSelected ? tc + 'CC' : tc + '30';
    ctx.lineWidth = isSelected ? 2.0 : 1.0;
    ctx.stroke();

    // Amenity dots along spoke
    groups[type].slice(0, 5).forEach(a => {
      const d = Math.min(a.distance_meters || MAX_DIST, MAX_DIST);
      const r = (d / MAX_DIST) * maxR;
      const px = cx + r * Math.cos(angle);
      const py = cy + r * Math.sin(angle);
      ctx.beginPath();
      ctx.arc(px, py, 5, 0, Math.PI * 2);
      ctx.fillStyle = tc + '22';
      ctx.fill();
      ctx.beginPath();
      ctx.arc(px, py, 3.5, 0, Math.PI * 2);
      ctx.fillStyle = tc;
      ctx.fill();
    });

    // Node at spoke end
    const nx = cx + maxR * Math.cos(angle);
    const ny = cy + maxR * Math.sin(angle);
    const nr = isSelected ? 13 : 11;

    if (isSelected) {
      ctx.beginPath();
      ctx.arc(nx, ny, nr + 8, 0, Math.PI * 2);
      ctx.fillStyle = tc + '30';
      ctx.fill();
    }

    ctx.beginPath();
    ctx.arc(nx, ny, nr, 0, Math.PI * 2);
    ctx.fillStyle = tc + (isSelected ? '55' : '28');
    ctx.fill();
    ctx.beginPath();
    ctx.arc(nx, ny, nr, 0, Math.PI * 2);
    ctx.strokeStyle = tc + (isSelected ? 'EE' : '80');
    ctx.lineWidth = isSelected ? 2 : 1.5;
    ctx.stroke();

    // Emoji inside node
    const emoji = _TR_EMOJI[type] || '🚌';
    ctx.font = `${isSelected ? 10 : 9}px serif`;
    ctx.textAlign = 'center';
    ctx.textBaseline = 'middle';
    ctx.fillText(emoji, nx, ny);
  });

  // Home dot at centre
  ctx.beginPath();
  ctx.arc(cx, cy, 10, 0, Math.PI * 2);
  ctx.fillStyle = '#FFFFFF';
  ctx.fill();
  ctx.font = '9px serif';
  ctx.textAlign = 'center';
  ctx.textBaseline = 'middle';
  ctx.fillText('🏠', cx, cy);
}

// ── Bind transport card ↔ radar interaction ────────────────────────────────────

function _bindTransportCards(container, items, canvas) {
  const groups = {};
  items.forEach(a => {
    if (!groups[a.type]) groups[a.type] = [];
    groups[a.type].push(a);
  });
  const subtypes = Object.keys(groups);
  let selectedIdx = null;

  function refresh() {
    _drawTransportRadar(canvas, items, selectedIdx);
    container.querySelectorAll('.tr-card').forEach(card => {
      const typeIdx = subtypes.indexOf(card.dataset.type);
      const sel = selectedIdx === typeIdx;
      card.classList.toggle('tr-card--selected', sel);
    });
  }

  // Card tap → select type spoke on radar
  container.querySelectorAll('.tr-card').forEach(card => {
    card.addEventListener('click', () => {
      const typeIdx = subtypes.indexOf(card.dataset.type);
      selectedIdx = selectedIdx === typeIdx ? null : typeIdx;
      refresh();
    });
  });

  // Radar tap → find nearest spoke node → highlight card
  canvas.addEventListener('click', e => {
    const rect = canvas.getBoundingClientRect();
    const scaleX = canvas.width / rect.width;
    const scaleY = canvas.height / rect.height;
    const px = (e.clientX - rect.left) * scaleX;
    const py = (e.clientY - rect.top) * scaleY;
    const cx = canvas.width / 2, cy = canvas.height / 2;
    const maxR = Math.min(canvas.width, canvas.height) / 2 - 22;
    const step = (2 * Math.PI) / subtypes.length;

    let nearest = null, nearestDist = Infinity;
    subtypes.forEach((_, i) => {
      const angle = -Math.PI / 2 + i * step;
      const nx = cx + maxR * Math.cos(angle);
      const ny = cy + maxR * Math.sin(angle);
      const d = Math.hypot(px - nx, py - ny);
      if (d < nearestDist) { nearestDist = d; nearest = i; }
    });

    if (nearest !== null && nearestDist < 30) {
      selectedIdx = selectedIdx === nearest ? null : nearest;
      refresh();
      // Scroll to first card of this type
      const type = subtypes[nearest];
      const card = container.querySelector(`.tr-card[data-type="${type}"]`);
      if (card) card.scrollIntoView({ behavior: 'smooth', block: 'nearest' });
    }
  });
}

// Inline color lookup to avoid circular import in template literal
function getCatColor(catId) {
  const MAP = {
    transportation:'#29B6F6', education:'#66BB6A', healthcare:'#EF5350',
    shopping:'#FFA726', safety:'#AB47BC', religion:'#8D6E63', recreation:'#26C6DA',
  };
  return MAP[catId] || '#888';
}
