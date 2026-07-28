// HomeScope – Neighbourhood Intelligence Screen (5 tabs)
// Mirrors neighborhood_screen.dart exactly.

import { setState, getState } from '../state.js';
import { scoreColor, scoreLabel, streetViewUrl } from '../utils.js';
import { renderRadarChart } from '../widgets/radar_chart.js';
import { renderTimeMachine } from '../widgets/time_machine.js';
import { renderAiStory } from '../widgets/ai_story.js';
import { renderFutureScore } from '../widgets/future_score.js';
import { renderLifeRadius } from '../widgets/life_radius.js';

const TABS = [
  { id: 'dna',          label: 'DNA',     emoji: '🧬' },
  { id: 'life-radius',  label: 'Radius',  emoji: '📍' },
  { id: 'time-machine', label: 'Time',    emoji: '🕐' },
  { id: 'ai-story',     label: 'Story',   emoji: '✨' },
  { id: 'future-score', label: 'Future',  emoji: '🔮' },
];

export function renderNeighborhood(container, result) {
  container.innerHTML = `
    <div class="ni-screen">
      <!-- Tab navigation -->
      <div class="ni-tabs">
        ${TABS.map(tab => `
          <button class="ni-tab ${tab.id === (getState().niTab || 'dna') ? 'active' : ''}"
            data-tab="${tab.id}">
            <span class="ni-tab-emoji">${tab.emoji}</span>
            <span class="ni-tab-label">${tab.label}</span>
          </button>
        `).join('')}
      </div>

      <!-- Tab content -->
      <div class="ni-content ni-tab-content"></div>
    </div>
  `;

  const content = container.querySelector('.ni-tab-content');
  const tabs = container.querySelectorAll('.ni-tab');

  function activateTab(tabId) {
    setState({ niTab: tabId });
    tabs.forEach(t => t.classList.toggle('active', t.dataset.tab === tabId));
    renderTab(tabId, content, result);
  }

  tabs.forEach(btn => {
    btn.addEventListener('click', () => activateTab(btn.dataset.tab));
  });

  // Render initial tab
  activateTab(getState().niTab || 'dna');
}

function renderTab(tabId, content, result) {
  content.innerHTML = '';
  content.scrollTop = 0;

  switch (tabId) {
    case 'dna':          renderDNA(content, result);                    break;
    case 'life-radius':  renderLifeRadius(content, result);            break;
    case 'time-machine': renderTimeMachine(content, result.score);     break;
    case 'ai-story':     renderAiStory(content, result);               break;
    case 'future-score': renderFutureScore(content, result.score);     break;
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

      <div class="dna-legend" id="dna-legend">
        ${Object.values(cats).map(cat => `
          <div class="dna-legend-row" data-cat-id="${cat.id}" style="cursor:pointer;--cat-color:${getCatColor(cat.id)}">
            <div class="dna-legend-dot" style="background:${getCatColor(cat.id)}"></div>
            <span class="dna-legend-label">${cat.label}</span>
            <div class="dna-legend-bar-bg">
              <div class="dna-legend-bar"
                style="width:${cat.score}%;background:${getCatColor(cat.id)}"></div>
            </div>
            <span class="dna-legend-score" style="color:${getCatColor(cat.id)}">${Math.round(cat.score)}</span>
            <span class="dna-legend-chevron">›</span>
          </div>
          <div class="dna-cat-detail" id="dna-detail-${cat.id}" style="display:none">
            ${_buildCatDetail(cat, getCatColor(cat.id))}
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

  // Legend row toggle
  let openCatId = null;
  content.querySelector('#dna-legend').addEventListener('click', e => {
    const row = e.target.closest('.dna-legend-row[data-cat-id]');
    if (!row) return;
    const catId = row.dataset.catId;
    const detail = content.querySelector(`#dna-detail-${catId}`);
    if (!detail) return;
    const isOpen = openCatId === catId;
    // Close any open detail
    if (openCatId) {
      const prev = content.querySelector(`#dna-detail-${openCatId}`);
      if (prev) prev.style.display = 'none';
      content.querySelectorAll('.dna-legend-row').forEach(r => r.classList.remove('active'));
    }
    if (!isOpen) {
      detail.style.display = 'block';
      row.classList.add('active');
      openCatId = catId;
    } else {
      openCatId = null;
    }
  });
}

function _buildCatDetail(cat, color) {
  const closest = cat.closest;
  const score = Math.round(cat.score);
  const scoreLabel_ = score >= 80 ? 'Excellent' : score >= 60 ? 'Good' : score >= 40 ? 'Fair' : 'Poor';

  return `
    <div class="dna-detail-card" style="--cat-color:${color}">
      <div class="dna-detail-row">
        <div class="dna-detail-stat">
          <div class="dna-detail-num" style="color:${color}">${score}</div>
          <div class="dna-detail-sub">${scoreLabel_} score</div>
        </div>
        <div class="dna-detail-stat">
          <div class="dna-detail-num">${cat.count ?? '—'}</div>
          <div class="dna-detail-sub">places nearby</div>
        </div>
        ${closest ? `
        <div class="dna-detail-stat">
          <div class="dna-detail-num" style="color:${color}">
            ${closest.walking_minutes != null ? closest.walking_minutes + 'm' : Math.round((closest.distance_meters || 0)) + 'm'}
          </div>
          <div class="dna-detail-sub">closest</div>
        </div>` : ''}
      </div>
      ${closest ? `
      <div class="dna-detail-closest">
        <span class="dna-detail-closest-label">Nearest:</span>
        <span class="dna-detail-closest-name">${closest.name || closest.type || '—'}</span>
        ${closest.distance_meters ? `<span class="dna-detail-closest-dist" style="color:${color}">${closest.distance_meters < 1000 ? Math.round(closest.distance_meters) + 'm' : (closest.distance_meters / 1000).toFixed(1) + 'km'}</span>` : ''}
      </div>` : ''}
    </div>
  `;
}

// Inline color lookup to avoid circular import in template literal
function getCatColor(catId) {
  const MAP = {
    transportation:'#29B6F6', education:'#66BB6A', healthcare:'#EF5350',
    shopping:'#FFA726', safety:'#AB47BC', religion:'#8D6E63', recreation:'#26C6DA',
  };
  return MAP[catId] || '#888';
}
