// NeighborLens – Neighborhood Timeline Widget
// Lets users explore the neighbourhood through 6 themed lenses.
// Each theme tells a contextual story: top places, key stats, and a score.

const COLORS = {
  transportation: '#29B6F6',
  education:      '#66BB6A',
  healthcare:     '#EF5350',
  shopping:       '#FFA726',
  safety:         '#AB47BC',
  religion:       '#8D6E63',
  recreation:     '#26C6DA',
};

// ── Theme definitions ───────────────────────────────────────────────────────────

const THEMES = [
  {
    id:      'education',
    emoji:   '🏫',
    label:   'Education',
    color:   '#66BB6A',
    cats:    ['education'],
    tagline: 'Learning within reach',
    insight: s =>
      s >= 80 ? 'Excellent school access — ideal for families with children.' :
      s >= 60 ? 'Good access to schools and education.' :
                'Fewer nearby education options — worth checking school catchment areas.',
    typeLabels: {
      school: 'School', university: 'University', library: 'Library',
      kindergarten: 'Daycare', college: 'College',
    },
  },
  {
    id:      'transportation',
    emoji:   '🚇',
    label:   'Transport',
    color:   '#29B6F6',
    cats:    ['transportation'],
    tagline: 'Getting around',
    insight: s =>
      s >= 80 ? 'Excellent connectivity — car-free living is very practical here.' :
      s >= 60 ? 'Good public transport links for most journeys.' :
                'Limited transit nearby — a car may be necessary for daily life.',
    typeLabels: {
      bus_stop: 'Bus Stop', station: 'Station', subway_entrance: 'Metro',
      tram_stop: 'Tram', parking: 'Parking',
    },
  },
  {
    id:      'shopping',
    emoji:   '🛍️',
    label:   'Shopping',
    color:   '#FFA726',
    cats:    ['shopping'],
    tagline: 'Daily essentials',
    insight: s =>
      s >= 80 ? 'Everything within easy reach — superb for everyday convenience.' :
      s >= 60 ? 'Good access to shops and daily essentials.' :
                'Fewer shops close by — you may need to travel for grocery runs.',
    typeLabels: {
      supermarket: 'Supermarket', convenience: 'Convenience Store',
      pharmacy: 'Pharmacy', mall: 'Shopping Mall',
      restaurant: 'Restaurant', cafe: 'Café',
    },
  },
  {
    id:      'lifestyle',
    emoji:   '🌳',
    label:   'Lifestyle',
    color:   '#26C6DA',
    cats:    ['recreation'],
    tagline: 'Quality of life',
    insight: s =>
      s >= 80 ? 'Vibrant and active neighbourhood — great outdoors and social life.' :
      s >= 60 ? 'A decent mix of parks, dining and leisure options.' :
                'Fewer leisure spots in the immediate area.',
    typeLabels: {
      park: 'Park', gym: 'Gym', fitness_centre: 'Fitness Centre',
      restaurant: 'Restaurant', cafe: 'Café', theatre: 'Theatre',
      playground: 'Playground', sports_centre: 'Sports Centre',
    },
  },
  {
    id:      'healthcare',
    emoji:   '🏥',
    label:   'Healthcare',
    color:   '#EF5350',
    cats:    ['healthcare'],
    tagline: 'Health & wellbeing',
    insight: s =>
      s >= 80 ? 'Excellent healthcare access — peace of mind for all life stages.' :
      s >= 60 ? 'Solid access to medical care and pharmacies.' :
                'Limited healthcare nearby — check distance to the nearest hospital.',
    typeLabels: {
      hospital: 'Hospital', clinic: 'Clinic', pharmacy: 'Pharmacy',
      dentist: 'Dentist', doctors: 'GP / Doctor',
    },
  },
  {
    id:      'investment',
    emoji:   '💼',
    label:   'Investment',
    color:   '#6C63FF',
    cats:    ['transportation', 'education', 'shopping', 'recreation'],
    tagline: 'Growth potential',
    insight: s =>
      s >= 80 ? 'Strong fundamentals across all key drivers — high rental demand likely.' :
      s >= 60 ? 'Solid investment indicators — good long-term potential.' :
                'Developing area — monitor price trends carefully before committing.',
    typeLabels: {},
    isInvestment: true,
  },
];

// ── Public API ──────────────────────────────────────────────────────────────────

export function renderNeighborhoodTimeline(container, result) {
  const amenities = result.amenities || [];
  const cats      = result.score?.categories || {};
  const overall   = result.score?.overall ?? 0;

  let activeTheme = THEMES[0].id;

  container.innerHTML = `
    <div class="nt-screen">

      <!-- Theme selector strip -->
      <div class="nt-themes" id="nt-themes">
        ${THEMES.map(t => `
          <button class="nt-theme-btn ${t.id === activeTheme ? 'active' : ''}"
            data-theme="${t.id}" style="--tc:${t.color}">
            <span class="nt-theme-emoji">${t.emoji}</span>
            <span class="nt-theme-label">${t.label}</span>
          </button>`).join('')}
      </div>

      <!-- Theme panel (swaps on selection) -->
      <div id="nt-panel" class="nt-panel"></div>

    </div>`;

  const panel = container.querySelector('#nt-panel');

  function renderTheme(themeId) {
    const theme = THEMES.find(t => t.id === themeId);
    if (!theme) return;

    // Collect amenities for this theme
    const places = amenities
      .filter(a => theme.cats.includes(a.category))
      .sort((a, b) => a.distance_meters - b.distance_meters);

    // Score: average of category scores for this theme
    const themeScores = theme.cats
      .map(c => cats[c]?.score)
      .filter(s => s != null);
    const themeScore = themeScores.length
      ? Math.round(themeScores.reduce((a, b) => a + b, 0) / themeScores.length)
      : 0;

    const nearest = places[0];
    const nearestWalk = nearest?.walking_minutes;

    panel.innerHTML = `
      <!-- Hero header -->
      <div class="nt-hero" style="--tc:${theme.color}">
        <div class="nt-hero-left">
          <div class="nt-hero-emoji">${theme.emoji}</div>
          <div>
            <div class="nt-hero-label">${theme.label}</div>
            <div class="nt-hero-tagline">${theme.tagline}</div>
          </div>
        </div>
        <div class="nt-hero-right">
          <div class="nt-hero-count">${places.length}</div>
          <div class="nt-hero-count-sub">places</div>
        </div>
      </div>

      <!-- Score bar -->
      <div class="nt-score-row">
        <div class="nt-score-track">
          <div class="nt-score-fill" style="width:${themeScore}%;background:${theme.color}"></div>
        </div>
        <span class="nt-score-val" style="color:${theme.color}">${themeScore}</span>
      </div>

      <!-- Contextual insight -->
      <div class="nt-insight" style="border-left:3px solid ${theme.color}">
        ${theme.insight(themeScore)}
      </div>

      ${theme.isInvestment
        ? _buildInvestmentPanel(cats, overall, theme.color)
        : _buildPlacesList(places, theme, nearest, nearestWalk)}
    `;

    // Animate score bar in
    requestAnimationFrame(() => {
      const fill = panel.querySelector('.nt-score-fill');
      if (fill) { fill.style.width = '0'; requestAnimationFrame(() => { fill.style.width = `${themeScore}%`; }); }
    });
  }

  // Initial render
  renderTheme(activeTheme);

  // Theme switcher
  container.querySelector('#nt-themes').addEventListener('click', e => {
    const btn = e.target.closest('.nt-theme-btn');
    if (!btn) return;
    activeTheme = btn.dataset.theme;
    container.querySelectorAll('.nt-theme-btn').forEach(b => b.classList.toggle('active', b === btn));
    panel.classList.add('nt-panel--fade');
    setTimeout(() => {
      renderTheme(activeTheme);
      panel.classList.remove('nt-panel--fade');
    }, 120);
  });
}

// ── Places list (used by all non-investment themes) ────────────────────────────

function _buildPlacesList(places, theme, nearest, nearestWalk) {
  if (!places.length) {
    return `
      <div class="nt-empty">
        <div class="nt-empty-icon">${theme.emoji}</div>
        <div class="nt-empty-title">None found nearby</div>
        <div class="nt-empty-sub">No ${theme.label.toLowerCase()} places were found within the search radius.</div>
      </div>`;
  }

  // Nearest highlight card
  const nearestCard = nearest ? `
    <div class="nt-nearest" style="--tc:${theme.color}">
      <div class="nt-nearest-label">NEAREST</div>
      <div class="nt-nearest-name">${nearest.name || nearest.type || theme.label}</div>
      <div class="nt-nearest-meta">
        <span style="color:${theme.color}">${nearest.distance_meters}m</span>
        <span>·</span>
        <span>${nearestWalk != null ? nearestWalk + ' min walk' : '—'}</span>
      </div>
    </div>` : '';

  // Top places (up to 10)
  const rows = places.slice(0, 10).map((p, i) => {
    const dist = p.distance_meters < 1000
      ? `${p.distance_meters}m`
      : `${(p.distance_meters / 1000).toFixed(1)}km`;
    const walk = p.walking_minutes != null ? `${p.walking_minutes} min` : '—';
    const typeLabel = theme.typeLabels[p.type] || _titleCase(p.type || p.category);
    return `
      <div class="nt-place ${i === 0 ? 'nt-place--first' : ''}">
        <div class="nt-place-rank" style="color:${theme.color}">${i + 1}</div>
        <div class="nt-place-body">
          <div class="nt-place-name">${p.name || typeLabel}</div>
          <div class="nt-place-type">${typeLabel}</div>
        </div>
        <div class="nt-place-meta">
          <span class="nt-place-dist" style="color:${theme.color}">${dist}</span>
          <span class="nt-place-walk">${walk}</span>
        </div>
      </div>`;
  }).join('');

  const moreCount = places.length > 10 ? places.length - 10 : 0;

  return `
    <div class="nt-places">
      ${nearestCard}
      <div class="nt-places-header">TOP PLACES</div>
      ${rows}
      ${moreCount > 0 ? `<div class="nt-places-more">+${moreCount} more nearby</div>` : ''}
    </div>`;
}

// ── Investment panel ────────────────────────────────────────────────────────────

function _buildInvestmentPanel(cats, overall, color) {
  const drivers = [
    { label: 'Transit',     id: 'transportation', weight: 'High',   reason: 'Proximity to public transport strongly correlates with rental demand.' },
    { label: 'Education',   id: 'education',      weight: 'High',   reason: 'Good schools sustain property values and attract family tenants.' },
    { label: 'Shopping',    id: 'shopping',       weight: 'Medium', reason: 'Daily retail access reduces tenant turnover.' },
    { label: 'Recreation',  id: 'recreation',     weight: 'Medium', reason: 'Green space and leisure improve quality-of-life scores and desirability.' },
    { label: 'Healthcare',  id: 'healthcare',     weight: 'Low',    reason: 'Healthcare access matters most for long-term and retired tenants.' },
  ];

  const rows = drivers.map(d => {
    const score = cats[d.id]?.score ?? 0;
    const color = COLORS[d.id] || '#888';
    const badge = d.weight === 'High' ? 'nt-badge--high' : d.weight === 'Medium' ? 'nt-badge--mid' : 'nt-badge--low';
    return `
      <div class="nt-inv-driver">
        <div class="nt-inv-driver-top">
          <span class="nt-inv-driver-label">${d.label}</span>
          <span class="nt-badge ${badge}">${d.weight} impact</span>
          <span class="nt-inv-score" style="color:${color}">${Math.round(score)}</span>
        </div>
        <div class="nt-inv-bar-track">
          <div class="nt-inv-bar-fill" style="width:${score}%;background:${color}"></div>
        </div>
        <div class="nt-inv-reason">${d.reason}</div>
      </div>`;
  }).join('');

  const verdict = overall >= 80 ? 'Strong Buy Signal' : overall >= 65 ? 'Solid Fundamentals' : overall >= 50 ? 'Moderate Potential' : 'Needs Research';
  const verdictColor = overall >= 80 ? '#10B981' : overall >= 65 ? '#22C55E' : overall >= 50 ? '#F59E0B' : '#EF4444';

  return `
    <div class="nt-investment">
      <div class="nt-inv-verdict" style="border-color:${verdictColor}">
        <div class="nt-inv-verdict-score" style="color:${verdictColor}">${Math.round(overall)}</div>
        <div>
          <div class="nt-inv-verdict-label" style="color:${verdictColor}">${verdict}</div>
          <div class="nt-inv-verdict-sub">Overall neighbourhood score</div>
        </div>
      </div>
      <div class="nt-inv-section-label">KEY INVESTMENT DRIVERS</div>
      ${rows}
      <div class="nt-inv-disclaimer">
        Investment scoring is based on OpenStreetMap amenity data.
        Market prices and future development require separate research.
      </div>
    </div>`;
}

// ── Helpers ─────────────────────────────────────────────────────────────────────

function _titleCase(str) {
  return str ? str.replace(/_/g, ' ').replace(/\b\w/g, c => c.toUpperCase()) : '—';
}
