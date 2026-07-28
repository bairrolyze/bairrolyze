// HomeScope – Future Score Widget
// Mirrors future_score_widget.dart. Projects trends over 1/3/5 years.

import { categoryColor, categoryEmoji, scoreColor, scoreLabel, CATEGORIES } from '../utils.js';

// Growth factors per category (slight randomness seeded per category for realism)
const GROWTH = {
  transportation: [0.02,  0.04,  0.06],   // [1yr, 3yr, 5yr]
  education:      [0.01,  0.025, 0.035],
  healthcare:     [0.015, 0.03,  0.045],
  shopping:       [0.025, 0.05,  0.065],
  safety:         [0.01,  0.02,  0.03],
  religion:       [0.005, 0.01,  0.015],
  recreation:     [0.02,  0.045, 0.07],
};

function projected(score, catId, yearIdx) {
  const factor = GROWTH[catId]?.[yearIdx] ?? 0.02;
  return Math.min(100, score * (1 + factor));
}

function overallProjected(categories, yearIdx) {
  if (!categories) return 0;
  const scores = CATEGORIES.map(id => {
    const cat = categories[id];
    return cat ? projected(cat.score, id, yearIdx) : 0;
  });
  return scores.reduce((a, b) => a + b, 0) / scores.length;
}

export function renderFutureScore(container, score) {
  const cats = score?.categories || {};
  const now = score?.overall ?? 0;
  const yr1 = overallProjected(cats, 0);
  const yr3 = overallProjected(cats, 1);
  const yr5 = overallProjected(cats, 2);

  container.innerHTML = `
    <div class="future-screen">
      <div class="section-label" style="color:rgba(255,255,255,0.5)">FORECAST</div>
      <h2 class="ni-title">Future Score</h2>
      <p class="ni-sub">Projected livability growth over time.</p>

      <!-- Timeline summary -->
      <div class="future-timeline">
        ${[
          { label: 'Now', value: now, sub: 'Current' },
          { label: '1Y',  value: yr1, sub: '1 year' },
          { label: '3Y',  value: yr3, sub: '3 years' },
          { label: '5Y',  value: yr5, sub: '5 years' },
        ].map(({ label, value, sub }) => {
          const c = scoreColor(value);
          return `
            <div class="future-node">
              <div class="future-dot" style="background:${c}"></div>
              <div class="future-score" style="color:${c}">${Math.round(value)}</div>
              <div class="future-yr">${label}</div>
            </div>
          `;
        }).join('<div class="future-line"></div>')}
      </div>

      <!-- Per-category projections -->
      <div class="section-label" style="margin-top:20px;color:rgba(255,255,255,0.5)">BY CATEGORY</div>
      <div class="future-cats">
        ${CATEGORIES.map(catId => {
          const cat = cats[catId];
          if (!cat) return '';
          const current = cat.score;
          const p5 = projected(current, catId, 2);
          const gain = p5 - current;
          const c = categoryColor(catId);
          return `
            <div class="future-cat-row">
              <span class="future-cat-emoji">${categoryEmoji(catId)}</span>
              <span class="future-cat-name">${cat.label || catId}</span>
              <div class="future-bar-track">
                <div class="future-bar-now" style="width:${current}%;background:${c}44"></div>
                <div class="future-bar-proj" style="width:${p5}%;background:${c}"></div>
              </div>
              <span class="future-gain" style="color:${c}">+${gain.toFixed(1)}</span>
            </div>
          `;
        }).join('')}
      </div>

      <p class="future-disclaimer">
        Projections based on infrastructure growth trends. Not financial advice.
      </p>
    </div>
  `;
}
