// HomeScope – Dashboard Screen (mirrors DashboardScreen)
import { scoreColor, scoreLabel, categoryColor, categoryEmoji, formatDistance,
         formatWalkTime, streetViewUrl, CATEGORIES } from '../utils.js';

export function renderDashboard(container, result, settings) {
  const { score, amenities, ai_summary, address } = result;
  const overall = score?.overall ?? 0;
  const color = scoreColor(overall);
  const label = scoreLabel(overall);

  container.innerHTML = `
    <div class="dashboard-screen">
      <!-- Score header -->
      <div class="dash-header" style="--accent:${color}">
        <div class="dash-score-ring">
          <svg viewBox="0 0 120 120" class="ring-svg">
            <circle cx="60" cy="60" r="50" class="ring-bg"/>
            <circle cx="60" cy="60" r="50" class="ring-fill"
              style="stroke:${color};stroke-dasharray:${314 * overall / 100} 314"/>
          </svg>
          <div class="ring-inner">
            <div class="ring-score" style="color:${color}">${Math.round(overall)}</div>
            <div class="ring-label">${label}</div>
          </div>
        </div>
        <div class="dash-address-block">
          <div class="dash-address">${address?.display_name || result._address || '—'}</div>
          <div class="dash-meta">${score.profile} profile · ${CATEGORIES.length} categories</div>
          ${address?.lat ? `
            <a href="${streetViewUrl(address.lat, address.lng)}" target="_blank" class="street-view-link">
              📷 Street View
            </a>` : ''}
        </div>
      </div>

      <!-- Category scores -->
      <div class="dash-section">
        <div class="section-label">CATEGORY SCORES</div>
        <div class="cat-grid">
          ${CATEGORIES.map(catId => {
            const cat = score.categories?.[catId];
            if (!cat) return '';
            const s = cat.score ?? 0;
            const c = categoryColor(catId);
            return `
              <div class="cat-card">
                <div class="cat-top">
                  <span class="cat-emoji">${categoryEmoji(catId)}</span>
                  <span class="cat-name">${cat.label || catId}</span>
                  <span class="cat-score" style="color:${c}">${Math.round(s)}</span>
                </div>
                <div class="cat-bar-bg">
                  <div class="cat-bar" style="width:${s}%;background:${c}"></div>
                </div>
                ${cat.closest ? `
                  <div class="cat-closest">
                    📍 ${cat.closest.name} · ${formatDistance(cat.closest.distance_meters)}
                  </div>` : ''}
              </div>
            `;
          }).join('')}
        </div>
      </div>

      <!-- AI Summary -->
      ${(settings?.showAiSummary !== false) && ai_summary ? `
        <div class="dash-section">
          <div class="section-label">AI SUMMARY</div>
          <div class="ai-card">
            <div class="ai-icon">✨</div>
            <p class="ai-text">${ai_summary}</p>
          </div>
        </div>
      ` : ''}

      <!-- Nearby amenities -->
      ${amenities?.length ? `
        <div class="dash-section">
          <div class="section-label">NEARBY (TOP 10)</div>
          <div class="amenity-list">
            ${amenities.slice(0, 10).map(a => `
              <div class="amenity-row">
                <span class="amenity-emoji">${categoryEmoji(a.category)}</span>
                <div class="amenity-info">
                  <div class="amenity-name">${a.name || a.type}</div>
                  <div class="amenity-dist">${formatDistance(a.distance_meters)} · ${formatWalkTime(a.walking_minutes)}</div>
                </div>
              </div>
            `).join('')}
          </div>
        </div>
      ` : ''}
    </div>
  `;
}
