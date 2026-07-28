// HomeScope – Time Machine Widget
// Mirrors time_machine_widget.dart exactly (same profiles, same sky logic)

import { categoryColor, categoryEmoji, CATEGORIES } from '../utils.js';

// Time-of-day activity multipliers — identical to Flutter source
const PROFILES = {
  transportation: [0.1,0.2,0.5,0.9,0.8,0.7,0.7,0.8,0.9,0.8,0.7,0.7,0.7,0.6,0.6,0.7,0.8,1.0,0.9,0.7,0.5,0.4,0.3,0.1],
  education:      [0.0,0.0,0.0,0.0,0.0,0.0,0.3,0.8,1.0,1.0,1.0,1.0,0.9,0.9,0.9,0.5,0.2,0.1,0.0,0.0,0.0,0.0,0.0,0.0],
  healthcare:     [0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.4,0.9,1.0,1.0,0.9,0.8,0.9,0.9,0.8,0.7,0.3,0.2,0.1,0.0,0.0,0.0,0.0],
  shopping:       [0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.2,0.5,0.7,0.9,1.0,1.0,1.0,0.9,0.8,0.7,0.6,0.5,0.4,0.2,0.1,0.0,0.0],
  safety:         [0.7,0.6,0.5,0.5,0.4,0.4,0.5,0.6,0.8,0.9,0.9,0.9,0.9,0.9,0.9,0.8,0.7,0.7,0.6,0.6,0.6,0.6,0.7,0.7],
  recreation:     [0.0,0.0,0.0,0.0,0.0,0.2,0.4,0.6,0.7,0.7,0.7,0.6,0.5,0.5,0.6,0.7,0.7,0.8,0.9,1.0,0.9,0.7,0.3,0.1],
  religion:       [0.0,0.0,0.0,0.0,0.0,0.0,0.5,0.8,0.9,0.7,0.3,0.1,0.1,0.1,0.1,0.1,0.1,0.1,0.3,0.4,0.3,0.1,0.0,0.0],
};

function activityAt(catId, hour) {
  const p = PROFILES[catId];
  if (!p) return 0.5;
  const h = Math.floor(hour) % 24;
  const next = (h + 1) % 24;
  const frac = hour - Math.floor(hour);
  return p[h] * (1 - frac) + p[next] * frac;
}

function skyGradient(hour) {
  if (hour < 5 || hour >= 23) return ['#020818', '#0D1B40'];
  if (hour < 7) return ['#1A0A2E', '#3D1A5C', '#FF6B35'];
  if (hour < 9) return ['#FF8C42', '#FFD166', '#5BBCFF'];
  if (hour < 17) return ['#1A73E8', '#5BBCFF', '#8DD7F7'];
  if (hour < 19) return ['#FF8C42', '#FF5F57', '#3D1A5C'];
  if (hour < 21) return ['#3D1A5C', '#1A0A2E', '#0D1B40'];
  return ['#080E1A', '#0D1B40'];
}

function timeLabel(hour) {
  const h = Math.floor(hour);
  const m = Math.round((hour - h) * 60);
  const mm = String(m).padStart(2, '0');
  const period = h < 12 ? 'AM' : 'PM';
  const h12 = h === 0 ? 12 : h > 12 ? h - 12 : h;
  return `${String(h12).padStart(2, '0')}:${mm} ${period}`;
}

function timeDesc(hour) {
  if (hour < 5) return 'Deep night — the city sleeps';
  if (hour < 7) return 'Early morning — the day stirs';
  if (hour < 9) return 'Morning rush — energy builds';
  if (hour < 12) return 'Late morning — fully awake';
  if (hour < 14) return 'Lunch hour — streets fill';
  if (hour < 17) return 'Afternoon — steady rhythm';
  if (hour < 19) return 'Evening rush — peak activity';
  if (hour < 21) return 'Evening — restaurants & parks';
  if (hour < 23) return 'Late night — winding down';
  return 'Midnight — quiet streets';
}

function activityText(activity) {
  if (activity < 0.2) return 'Quiet';
  if (activity < 0.5) return 'Low';
  if (activity < 0.75) return 'Active';
  if (activity < 0.9) return 'Busy';
  return 'Peak';
}

export function renderTimeMachine(container, score) {
  let hour = 9;

  function render() {
    const colors = skyGradient(hour);
    const gradient = `linear-gradient(to bottom, ${colors.join(', ')})`;

    container.innerHTML = `
      <div class="tm-sky" style="background:${gradient}">
        <div class="section-label" style="color:rgba(255,255,255,0.7)">ACTIVITY</div>
        <h2 class="ni-title">Time Machine</h2>
        <p class="ni-sub">See how your neighbourhood changes throughout the day.</p>
        <div class="tm-clock">
          <span class="tm-time">${timeLabel(hour)}</span>
          <span class="tm-desc">${timeDesc(hour)}</span>
        </div>
      </div>

      <div class="tm-body">
        <div class="tm-slider-wrap">
          <input type="range" id="tm-slider" class="tm-slider"
            min="0" max="23.99" step="0.25" value="${hour}">
          <div class="tm-ticks">
            <span>12am</span><span>6am</span><span>12pm</span><span>6pm</span><span>11pm</span>
          </div>
        </div>

        <div class="tm-bars">
          ${CATEGORIES.map(catId => {
            const cat = score.categories?.[catId];
            const catScore = cat?.score ?? 0;
            const activity = activityAt(catId, hour);
            const effective = (catScore / 100) * activity;
            const c = categoryColor(catId);
            return `
              <div class="tm-row">
                <span class="tm-emoji">${categoryEmoji(catId)}</span>
                <span class="tm-cat">${cat?.label || catId}</span>
                <div class="tm-bar-track">
                  <div class="tm-bar-fill" style="width:${effective * 100}%;background:${c}"></div>
                </div>
                <span class="tm-activity" style="color:${c}">${activityText(activity)}</span>
              </div>
            `;
          }).join('')}
        </div>
      </div>
    `;

    container.querySelector('#tm-slider').addEventListener('input', (e) => {
      hour = parseFloat(e.target.value);
      render();
    });
  }

  render();
}
