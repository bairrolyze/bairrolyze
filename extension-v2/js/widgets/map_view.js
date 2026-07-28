// NeighborLens – Map View Widget (Enhanced)
// Phase 1: Overpass POIs, SVG markers, rich popups, category filter bar, loading state
// Phase 4: Mode descriptions and visual legend
// Phase 6: Buyer intelligence must-have filter

import { fetchOverpassPOIs, mergeAmenities } from '../services/overpass.js';

// ── Constants ───────────────────────────────────────────────────────────────────

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

// SVG path data per category (24×24 viewport, stroke-based icons)
const CAT_SVG = {
  transportation: '<path d="M12 2L2 7l10 5 10-5-10-5zM2 17l10 5 10-5M2 12l10 5 10-5"/>',
  education:      '<path d="M22 10v6M2 10l10-3 10 3-10 3-10-3z"/><path d="M6 12v5c3 3 9 3 12 0v-5"/>',
  healthcare:     '<path d="M12 2a10 10 0 1 0 0 20A10 10 0 0 0 12 2z"/><path d="M12 8v8M8 12h8"/>',
  shopping:       '<path d="M6 2L3 6v14a2 2 0 002 2h14a2 2 0 002-2V6l-3-4z"/><path d="M3 6h18M16 10a4 4 0 01-8 0"/>',
  safety:         '<path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/>',
  religion:       '<path d="M18 8h1a4 4 0 010 8h-1M2 8h16v9a4 4 0 01-4 4H6a4 4 0 01-4-4V8zM6 1v3M10 1v3M14 1v3"/>',
  recreation:     '<path d="M17 22L12 2 7 22"/><path d="M3 9h18"/>',
};

const MODES = {
  all:          ['transportation','education','healthcare','shopping','safety','religion','recreation'],
  family:       ['education','healthcare','recreation','shopping'],
  investor:     ['transportation','shopping','recreation'],
  professional: ['transportation','recreation','shopping'],
  nature:       ['recreation'],
};

const MODE_DESCS = {
  all:          'Showing all 7 categories',
  family:       'Showing schools, health, parks & shops',
  investor:     'Showing transit, shops & recreation',
  professional: 'Showing transit, recreation & shops',
  nature:       'Showing parks & green spaces only',
};

const KEY_CATS = [
  { id: 'education',      emoji: '🎓', label: 'Nearest School' },
  { id: 'transportation', emoji: '🚇', label: 'Nearest Transit' },
  { id: 'healthcare',     emoji: '🏥', label: 'Nearest Hospital' },
  { id: 'recreation',     emoji: '🌳', label: 'Nearest Park' },
];

const BUYER_PREFS = [
  { id: 'school',    label: '🎓 School within 1km',    cat: 'education',      threshold: 1000 },
  { id: 'transit',   label: '🚇 Transit within 500m',  cat: 'transportation', threshold: 500  },
  { id: 'hospital',  label: '🏥 Hospital within 2km',  cat: 'healthcare',     threshold: 2000 },
  { id: 'park',      label: '🌳 Park within 500m',     cat: 'recreation',     threshold: 500  },
  { id: 'shopping',  label: '🛍 Shops within 1km',     cat: 'shopping',       threshold: 1000 },
];

// ── Public API ──────────────────────────────────────────────────────────────────

/**
 * Renders the interactive property intelligence map into `container`.
 * @param {HTMLElement} container
 * @param {object} result — API result object
 */
export function renderMapView(container, result) {
  const lat = result?.address?.lat;
  const lng = result?.address?.lng;

  if (!lat || !lng) {
    container.innerHTML = `
      <div class="mv-screen">
        <div class="mv-no-loc">
          <div style="font-size:32px;margin-bottom:10px">📍</div>
          <div style="font-size:14px;font-weight:600;color:var(--text2)">No location data</div>
          <div style="font-size:12px;color:var(--text3);margin-top:4px">GPS coordinates were not returned for this address.</div>
        </div>
      </div>`;
    return;
  }

  let activeMode   = 'all';
  let activeRadius = 500;
  let allMarkers   = [];
  let circleLayer  = null;
  let mapInstance  = null;
  let isLeaflet    = false;
  let activeCatFilters = new Set(Object.keys(CAT_COLORS)); // all on by default

  // ── Render shell HTML ────────────────────────────────────────────────────────
  container.innerHTML = `
    <div class="mv-screen">
      <div class="mv-modes" id="mv-modes">
        <button class="mv-mode active" data-mode="all">All</button>
        <button class="mv-mode" data-mode="family">🏠 Family</button>
        <button class="mv-mode" data-mode="investor">📈 Investor</button>
        <button class="mv-mode" data-mode="professional">☕ Pro</button>
        <button class="mv-mode" data-mode="nature">🌳 Nature</button>
      </div>
      <div class="mv-mode-desc" id="mv-mode-desc">${MODE_DESCS.all}</div>
      <div class="mv-radius-row" id="mv-radius-row">
        <span class="mv-radius-label">Show within</span>
        <button class="mv-radius-btn active" data-r="500">500m</button>
        <button class="mv-radius-btn" data-r="1000">1 km</button>
        <button class="mv-radius-btn" data-r="2000">2 km</button>
      </div>
      <div class="mv-cat-filters" id="mv-cat-filters"></div>
      <div id="mv-map" class="mv-map" style="position:relative;">
        <div class="mv-loading" id="mv-loading" style="display:none">
          <div class="mv-spinner"></div>
        </div>
      </div>
      <div class="mv-intel" id="mv-intel"></div>
      <div class="mv-buyer-prefs" id="mv-buyer-prefs">
        <div class="mv-section-label">MUST HAVE NEARBY</div>
        <div class="mv-pref-row">
          ${BUYER_PREFS.map(p => `
            <label class="mv-pref-toggle">
              <input type="checkbox" data-pref="${p.id}"> ${p.label}
            </label>`).join('')}
        </div>
        <div class="mv-match-score" id="mv-match-score"></div>
      </div>
    </div>`;

  // ── Detect library ───────────────────────────────────────────────────────────
  const hasMapLibre = typeof maplibregl !== 'undefined';
  const hasLeaflet  = typeof L !== 'undefined';
  isLeaflet = !hasMapLibre && hasLeaflet;

  if (!hasMapLibre && !hasLeaflet) {
    container.querySelector('#mv-map').innerHTML =
      '<div class="mv-no-loc">Map library not available.</div>';
    return;
  }

  // ── Init map ─────────────────────────────────────────────────────────────────
  if (hasMapLibre) {
    mapInstance = _initMapLibre(lat, lng);
  } else {
    mapInstance = _initLeaflet(lat, lng);
  }

  // ── Initial intel panel ──────────────────────────────────────────────────────
  _renderIntel(container.querySelector('#mv-intel'), result, activeRadius, []);

  // ── Load Overpass data and merge with backend data ───────────────────────────
  const loadOverpassData = async () => {
    const loadingEl = container.querySelector('#mv-loading');
    if (loadingEl) loadingEl.style.display = 'flex';

    let mergedAmenities = result.amenities || [];

    try {
      const overpassPOIs = await fetchOverpassPOIs(lat, lng, Math.max(activeRadius, 1000));
      mergedAmenities = mergeAmenities(result.amenities, overpassPOIs);
    } catch (err) {
      console.warn('[NeighborLens] Overpass fetch failed, using backend data only:', err.message);
    }

    if (loadingEl) loadingEl.style.display = 'none';

    // Enrich result with merged data for this widget session
    const enrichedResult = { ...result, amenities: mergedAmenities };

    // Place markers
    if (hasMapLibre) {
      const onLoad = () => {
        _placeHomeMarkerMapLibre(mapInstance, lat, lng);
        allMarkers = _placeAmenityMarkersMapLibre(mapInstance, enrichedResult, lat, lng);
        _drawRadiusMapLibre(mapInstance, lat, lng, activeRadius);
        _applyFilters(allMarkers, activeMode, activeCatFilters, false);
        _renderCatFilters(container, enrichedResult, activeCatFilters, (cat, on) => {
          if (on) activeCatFilters.add(cat);
          else activeCatFilters.delete(cat);
          _applyFilters(allMarkers, activeMode, activeCatFilters, isLeaflet);
        });
        _renderIntel(container.querySelector('#mv-intel'), enrichedResult, activeRadius, mergedAmenities);
      };

      if (mapInstance.loaded()) {
        onLoad();
      } else {
        mapInstance.on('load', onLoad);
      }
    } else {
      // Leaflet is synchronous
      _placeHomeMarkerLeaflet(mapInstance, lat, lng);
      allMarkers = _placeAmenityMarkersLeaflet(mapInstance, enrichedResult, lat, lng);
      circleLayer = _drawRadiusLeaflet(mapInstance, lat, lng, activeRadius);
      _applyFilters(allMarkers, activeMode, activeCatFilters, true);
      _renderCatFilters(container, enrichedResult, activeCatFilters, (cat, on) => {
        if (on) activeCatFilters.add(cat);
        else activeCatFilters.delete(cat);
        _applyFilters(allMarkers, activeMode, activeCatFilters, isLeaflet);
      });
      _renderIntel(container.querySelector('#mv-intel'), enrichedResult, activeRadius, mergedAmenities);
    }

    // Wire buyer prefs against enriched data
    _wireBuyerPrefs(container, enrichedResult);
  };

  // Trigger Overpass load
  loadOverpassData();

  // ── Resize after layout settles ──────────────────────────────────────────────
  setTimeout(() => {
    if (hasMapLibre) mapInstance.resize();
    else mapInstance.invalidateSize();
  }, 250);

  // ── Mode buttons ─────────────────────────────────────────────────────────────
  container.querySelector('#mv-modes').addEventListener('click', e => {
    const btn = e.target.closest('.mv-mode');
    if (!btn) return;
    activeMode = btn.dataset.mode;
    container.querySelectorAll('.mv-mode').forEach(b => b.classList.toggle('active', b === btn));
    container.querySelector('#mv-mode-desc').textContent = MODE_DESCS[activeMode] || '';
    _applyFilters(allMarkers, activeMode, activeCatFilters, isLeaflet);
  });

  // ── Radius buttons ───────────────────────────────────────────────────────────
  container.querySelector('#mv-radius-row').addEventListener('click', e => {
    const btn = e.target.closest('.mv-radius-btn');
    if (!btn) return;
    activeRadius = parseInt(btn.dataset.r, 10);
    container.querySelectorAll('.mv-radius-btn').forEach(b => b.classList.toggle('active', b === btn));

    if (hasMapLibre) {
      _updateRadiusMapLibre(mapInstance, lat, lng, activeRadius);
    } else {
      if (circleLayer) mapInstance.removeLayer(circleLayer);
      circleLayer = _drawRadiusLeaflet(mapInstance, lat, lng, activeRadius);
    }

    // Re-render intel with current merged amenities (pull from markers)
    const currentAmenities = allMarkers.map(m => m.amenity);
    _renderIntel(container.querySelector('#mv-intel'), result, activeRadius, currentAmenities);
  });
}

// ── SVG Marker creation ─────────────────────────────────────────────────────────

/**
 * Create a styled HTML marker element for a category.
 * @param {string} category
 * @param {string} name
 * @returns {HTMLElement}
 */
function createMarkerEl(category, name) {
  const color = CAT_COLORS[category] || '#888';
  const svgPath = CAT_SVG[category] || '<circle cx="12" cy="12" r="5"/>';
  const el = document.createElement('div');
  el.className = 'mv-marker';
  el.style.cssText = `--mc:${color}`;
  el.innerHTML = `
    <div class="mv-marker-bubble">
      <svg viewBox="0 0 24 24" fill="none" stroke="white" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
        ${svgPath}
      </svg>
    </div>
    <div class="mv-marker-tail"></div>`;
  el.setAttribute('title', name);
  return el;
}

/**
 * Build the HTML for a rich popup.
 */
function buildPopupHTML(amenity) {
  const color   = CAT_COLORS[amenity.category] || '#888';
  const emoji   = CAT_EMOJI[amenity.category] || '📍';
  const catLabel = CAT_LABELS[amenity.category] || amenity.category;
  const name    = amenity.name || amenity.type || 'Place';
  const dist    = amenity.distance_meters != null ? `${amenity.distance_meters}m` : '—';
  const walk    = amenity.walking_minutes != null ? `${amenity.walking_minutes} min` : '—';
  const tags    = amenity.tags || {};

  return `
    <div class="mv-popup">
      <div class="mv-popup-header" style="border-left:3px solid ${color};padding-left:8px">
        <span class="mv-popup-emoji">${emoji}</span>
        <div>
          <div class="mv-popup-name">${_esc(name)}</div>
          <div class="mv-popup-cat">${_esc(catLabel)}</div>
        </div>
      </div>
      <div class="mv-popup-stats">
        <span>📏 ${dist}</span>
        <span>🚶 ${walk}</span>
      </div>
      ${tags.opening_hours ? `<div class="mv-popup-hours">🕐 ${_esc(tags.opening_hours)}</div>` : ''}
      ${tags.website ? `<a href="${_esc(tags.website)}" target="_blank" rel="noopener" class="mv-popup-link">Visit website ↗</a>` : ''}
    </div>`;
}

function _esc(str) {
  return String(str || '').replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;').replace(/"/g,'&quot;');
}

// ── Category filter bar ─────────────────────────────────────────────────────────

/**
 * Render the category filter pill bar.
 */
function _renderCatFilters(container, result, activeCatFilters, onToggle) {
  const amenities = result.amenities || [];
  const filterEl = container.querySelector('#mv-cat-filters');
  if (!filterEl) return;

  // Count per category
  const counts = {};
  for (const a of amenities) {
    counts[a.category] = (counts[a.category] || 0) + 1;
  }

  const cats = Object.keys(CAT_COLORS).filter(c => (counts[c] || 0) > 0);
  if (cats.length === 0) {
    filterEl.style.display = 'none';
    return;
  }

  filterEl.innerHTML = cats.map(cat => {
    const color = CAT_COLORS[cat];
    const emoji = CAT_EMOJI[cat];
    const label = CAT_LABELS[cat];
    const count = counts[cat] || 0;
    const isActive = activeCatFilters.has(cat);
    return `
      <button class="mv-cat-btn ${isActive ? 'active' : ''}" data-cat="${cat}" style="--cf:${color}">
        ${emoji} ${label} <span class="mv-cat-count">${count}</span>
      </button>`;
  }).join('');

  filterEl.addEventListener('click', e => {
    const btn = e.target.closest('.mv-cat-btn');
    if (!btn) return;
    const cat = btn.dataset.cat;
    const nowActive = !btn.classList.contains('active');
    btn.classList.toggle('active', nowActive);
    onToggle(cat, nowActive);
  });
}

// ── Buyer intelligence ──────────────────────────────────────────────────────────

function _wireBuyerPrefs(container, result) {
  const prefsEl = container.querySelector('#mv-buyer-prefs');
  if (!prefsEl) return;

  prefsEl.querySelectorAll('input[type=checkbox]').forEach(cb => {
    cb.addEventListener('change', () => {
      const checked = [...prefsEl.querySelectorAll('input[type=checkbox]:checked')]
        .map(i => i.dataset.pref);
      _renderMatchScore(container.querySelector('#mv-match-score'), result, checked);
    });
  });
}

/**
 * Calculate how many must-have preferences are satisfied.
 */
function _calcMatchScore(result, checkedPrefIds) {
  const cats = result.score?.categories || {};
  const amenities = result.amenities || [];
  let matched = 0;
  const total = checkedPrefIds.length;

  for (const prefId of checkedPrefIds) {
    const pref = BUYER_PREFS.find(p => p.id === prefId);
    if (!pref) continue;

    // Check closest in score.categories first
    const catData = cats[pref.cat];
    if (catData?.closest?.distance_meters != null &&
        catData.closest.distance_meters <= pref.threshold) {
      matched++;
      continue;
    }

    // Fall back to amenities array
    const nearest = amenities
      .filter(a => a.category === pref.cat)
      .sort((a, b) => a.distance_meters - b.distance_meters)[0];
    if (nearest && nearest.distance_meters <= pref.threshold) {
      matched++;
    }
  }

  return { matched, total, pct: total > 0 ? Math.round((matched / total) * 100) : 0 };
}

function _renderMatchScore(matchEl, result, checkedPrefIds) {
  if (!matchEl) return;
  if (checkedPrefIds.length === 0) {
    matchEl.textContent = '';
    return;
  }
  const { matched, total, pct } = _calcMatchScore(result, checkedPrefIds);
  const icon = pct >= 80 ? '✅' : pct >= 50 ? '⚠️' : '❌';
  matchEl.textContent = `${icon} ${matched}/${total} must-haves matched (${pct}%)`;
  matchEl.style.color = pct >= 80 ? '#22C55E' : pct >= 50 ? '#F59E0B' : '#EF4444';
}

// ── MapLibre implementation ─────────────────────────────────────────────────────

function _initMapLibre(lat, lng) {
  if (chrome?.runtime?.getURL) {
    maplibregl.workerUrl = chrome.runtime.getURL('lib/maplibre-gl.js');
  }
  return new maplibregl.Map({
    container: 'mv-map',
    style: 'https://tiles.openfreemap.org/styles/liberty',
    center: [lng, lat],
    zoom: 14,
  });
}

function _placeHomeMarkerMapLibre(map, lat, lng) {
  const el = document.createElement('div');
  el.className = 'mv-home-pin';
  el.innerHTML = '🏠';
  el.title = 'Your property';
  new maplibregl.Marker({ element: el, anchor: 'bottom' })
    .setLngLat([lng, lat])
    .setPopup(new maplibregl.Popup({ offset: 25 }).setHTML('<b>Your Property</b>'))
    .addTo(map);
}

function _placeAmenityMarkersMapLibre(map, result, homeLat, homeLng) {
  const amenities = (result.amenities || []).filter(a => a.lat && a.lng);
  return amenities.map(amenity => {
    const el = createMarkerEl(amenity.category, amenity.name || amenity.type);

    const popup = new maplibregl.Popup({ offset: [0, -30], closeButton: false, maxWidth: '260px' })
      .setHTML(buildPopupHTML(amenity));

    const marker = new maplibregl.Marker({ element: el, anchor: 'bottom' })
      .setLngLat([amenity.lng, amenity.lat])
      .setPopup(popup)
      .addTo(map);

    el.addEventListener('click', () => marker.togglePopup());

    return { markerObj: marker, amenity, element: el, isLeaflet: false };
  });
}

function _drawRadiusMapLibre(map, lat, lng, radiusMeters) {
  const geojson = _circleGeoJSON(lat, lng, radiusMeters);
  if (map.getSource('mv-radius')) {
    map.getSource('mv-radius').setData(geojson);
    return;
  }
  map.addSource('mv-radius', { type: 'geojson', data: geojson });
  map.addLayer({
    id: 'mv-radius-fill',
    type: 'fill',
    source: 'mv-radius',
    paint: { 'fill-color': '#6C63FF', 'fill-opacity': 0.08 },
  });
  map.addLayer({
    id: 'mv-radius-border',
    type: 'line',
    source: 'mv-radius',
    paint: { 'line-color': '#6C63FF', 'line-width': 1.5, 'line-opacity': 0.5 },
  });
}

function _updateRadiusMapLibre(map, lat, lng, radiusMeters) {
  if (map.getSource('mv-radius')) {
    map.getSource('mv-radius').setData(_circleGeoJSON(lat, lng, radiusMeters));
  } else {
    map.once('idle', () => _drawRadiusMapLibre(map, lat, lng, radiusMeters));
  }
}

function _circleGeoJSON(lat, lng, radiusMeters) {
  const coords = [];
  for (let i = 0; i <= 64; i++) {
    const angle = (i / 64) * 2 * Math.PI;
    const dLat = (radiusMeters / 111320) * Math.cos(angle);
    const dLng = (radiusMeters / (111320 * Math.cos(lat * Math.PI / 180))) * Math.sin(angle);
    coords.push([lng + dLng, lat + dLat]);
  }
  return { type: 'Feature', geometry: { type: 'Polygon', coordinates: [coords] } };
}

// ── Leaflet implementation ──────────────────────────────────────────────────────

function _initLeaflet(lat, lng) {
  const map = L.map('mv-map').setView([lat, lng], 14);
  L.tileLayer('https://tile.openstreetmap.org/{z}/{x}/{y}.png', {
    attribution: '© <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors',
    maxZoom: 19,
  }).addTo(map);
  return map;
}

function _placeHomeMarkerLeaflet(map, lat, lng) {
  const homeIcon = L.divIcon({
    html: '<div class="mv-home-pin">🏠</div>',
    iconSize: [30, 30],
    iconAnchor: [15, 30],
    className: '',
  });
  L.marker([lat, lng], { icon: homeIcon })
    .addTo(map)
    .bindPopup('<b>Your Property</b>');
}

function _placeAmenityMarkersLeaflet(map, result, homeLat, homeLng) {
  const amenities = (result.amenities || []).filter(a => a.lat && a.lng);
  return amenities.map(amenity => {
    const color = CAT_COLORS[amenity.category] || '#888';
    const marker = L.circleMarker([amenity.lat, amenity.lng], {
      radius: 7,
      fillColor: color,
      color: '#ffffff',
      weight: 1.5,
      opacity: 0.9,
      fillOpacity: 0.85,
    }).addTo(map)
      .bindPopup(buildPopupHTML(amenity));

    return { markerObj: marker, amenity, isLeaflet: true };
  });
}

function _drawRadiusLeaflet(map, lat, lng, radiusMeters) {
  return L.circle([lat, lng], {
    radius: radiusMeters,
    color: '#6C63FF',
    weight: 1.5,
    opacity: 0.5,
    fillColor: '#6C63FF',
    fillOpacity: 0.08,
  }).addTo(map);
}

// ── Shared: filter markers ──────────────────────────────────────────────────────

/**
 * Apply mode + category filter toggles to markers.
 * A marker is visible if its category is in the mode's allowed list
 * AND is toggled on in the cat filter.
 */
function _applyFilters(allMarkers, mode, activeCatFilters, leaflet) {
  const modeAllowed = MODES[mode] || MODES.all;
  for (const { markerObj, amenity } of allMarkers) {
    const visible = modeAllowed.includes(amenity.category) && activeCatFilters.has(amenity.category);
    if (leaflet) {
      markerObj.setStyle({ opacity: visible ? 0.9 : 0, fillOpacity: visible ? 0.85 : 0 });
    } else {
      const el = markerObj.getElement();
      if (el) el.style.display = visible ? '' : 'none';
    }
  }
}

// ── Property Intelligence panel ─────────────────────────────────────────────────

function _renderIntel(intelEl, result, radiusMeters, mergedAmenities) {
  if (!intelEl) return;
  intelEl.innerHTML = _buildIntelPanel(result, radiusMeters, mergedAmenities);
}

function _buildIntelPanel(result, radiusMeters, mergedAmenities) {
  const backendAmenities = result.amenities || [];
  const allAmenities     = (mergedAmenities && mergedAmenities.length > 0) ? mergedAmenities : backendAmenities;
  const cats             = result.score?.categories || {};

  const inRadius = allAmenities.filter(a => a.distance_meters <= radiusMeters);
  const radiusLabel = radiusMeters >= 1000
    ? `${(radiusMeters / 1000).toFixed(radiusMeters % 1000 === 0 ? 0 : 1)} km`
    : `${radiusMeters}m`;

  // Key category cards
  const cards = KEY_CATS.map(({ id, emoji, label }) => {
    const cat     = cats[id];
    const closest = cat?.closest;
    if (!closest) {
      return `
        <div class="mv-intel-card">
          <div class="mv-intel-card-emoji">${emoji}</div>
          <div class="mv-intel-card-label">${label}</div>
          <div class="mv-intel-card-value" style="color:var(--text3)">—</div>
        </div>`;
    }
    const dist = closest.distance_meters < 1000
      ? `${closest.distance_meters}m`
      : `${(closest.distance_meters / 1000).toFixed(1)}km`;
    const walk = closest.walking_minutes != null ? `${closest.walking_minutes} min walk` : '';
    return `
      <div class="mv-intel-card">
        <div class="mv-intel-card-emoji">${emoji}</div>
        <div class="mv-intel-card-label">${label}</div>
        <div class="mv-intel-card-value" style="color:${CAT_COLORS[id]}">${dist}</div>
        ${walk ? `<div class="mv-intel-card-sub">${walk}</div>` : ''}
      </div>`;
  });

  // Radius count card
  const radiusCard = `
    <div class="mv-intel-card mv-intel-card--wide">
      <div class="mv-intel-card-emoji">📍</div>
      <div class="mv-intel-card-label">Within ${radiusLabel}</div>
      <div class="mv-intel-card-value" style="color:var(--accent2)">${inRadius.length} places</div>
    </div>`;

  // Per-category counts
  const catCounts = {};
  for (const a of inRadius) {
    catCounts[a.category] = (catCounts[a.category] || 0) + 1;
  }
  const catCountsHTML = Object.entries(catCounts).length > 0 ? `
    <div class="mv-intel-cats">
      ${Object.entries(catCounts).map(([catId, count]) => `
        <div class="mv-intel-cat-item" style="--cc:${CAT_COLORS[catId] || '#888'}">
          <span>${CAT_EMOJI[catId] || '📍'} ${CAT_LABELS[catId] || catId}</span>
          <b style="color:${CAT_COLORS[catId] || '#888'}">${count} within ${radiusLabel}</b>
        </div>`).join('')}
    </div>` : '';

  return `
    <div class="mv-intel-grid">
      ${cards.join('')}
      ${radiusCard}
    </div>
    ${catCountsHTML}`;
}
