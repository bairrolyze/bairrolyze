/**
 * Overpass API service — fetches real-world POIs around a coordinate.
 * Results are cached in chrome.storage.local for 24 hours.
 */

const OVERPASS_ENDPOINT = 'https://overpass-api.de/api/interpreter';
const CACHE_TTL_MS = 24 * 60 * 60 * 1000; // 24 hours

const OVERPASS_QUERY = (lat, lng, radius) => `
[out:json][timeout:20];
(
  node["amenity"~"school|hospital|pharmacy|restaurant|cafe|fast_food|supermarket|gym|university|bus_stop|clinic|dentist|library|theatre|cinema|bank|atm|parking|police|fire_station|community_centre|place_of_worship"](around:${radius},${lat},${lng});
  node["shop"~"supermarket|convenience|bakery|clothes|electronics|mall"](around:${radius},${lat},${lng});
  node["leisure"~"park|fitness_centre|sports_centre|swimming_pool|playground|garden"](around:${radius},${lat},${lng});
  node["railway"~"station|subway_entrance|tram_stop"](around:${radius},${lat},${lng});
);
out body;`;

/**
 * Map OSM tags to our 7 categories. Returns null if no match.
 * @param {object} tags — OSM element tags
 * @returns {string|null}
 */
function osmToCategory(tags) {
  const a = tags.amenity || '';
  const l = tags.leisure || '';
  const s = tags.shop || '';
  const r = tags.railway || '';

  if (/school|university|library|college/.test(a)) return 'education';
  if (/hospital|clinic|dentist|pharmacy|doctors/.test(a)) return 'healthcare';
  if (/restaurant|cafe|fast_food|bar|food_court/.test(a) || /supermarket|convenience|bakery|mall/.test(s)) return 'shopping';
  if (/bus_stop|taxi/.test(a) || /station|subway_entrance|tram_stop/.test(r)) return 'transportation';
  if (/park|fitness_centre|sports_centre|playground|swimming_pool|garden/.test(l) || a === 'gym') return 'recreation';
  if (/place_of_worship|community_centre|social_facility/.test(a)) return 'religion';
  if (/police|fire_station/.test(a)) return 'safety';
  return null;
}

/**
 * Haversine distance between two lat/lng points, in meters.
 */
function haversine(lat1, lng1, lat2, lng2) {
  const R = 6371000; // Earth radius in meters
  const toRad = deg => deg * Math.PI / 180;
  const dLat = toRad(lat2 - lat1);
  const dLng = toRad(lng2 - lng1);
  const a =
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos(toRad(lat1)) * Math.cos(toRad(lat2)) *
    Math.sin(dLng / 2) * Math.sin(dLng / 2);
  return Math.round(R * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a)));
}

/**
 * Estimate walking minutes from distance in meters (average 80m/min).
 */
function walkingMinutes(meters) {
  return Math.max(1, Math.round(meters / 80));
}

/**
 * Derive a human-readable name from an OSM element.
 */
function osmName(el) {
  const t = el.tags || {};
  if (t.name) return t.name;
  const a = t.amenity || t.shop || t.leisure || t.railway || '';
  return a.replace(/_/g, ' ').replace(/\b\w/g, c => c.toUpperCase());
}

/**
 * Read from chrome.storage.local cache.
 * @param {string} key
 * @returns {Promise<any|null>}
 */
async function _cacheGet(key) {
  try {
    const d = await chrome.storage.local.get(key);
    const entry = d[key];
    if (!entry) return null;
    const parsed = JSON.parse(entry);
    if (Date.now() - parsed.ts > CACHE_TTL_MS) return null;
    return parsed.data;
  } catch {
    return null;
  }
}

/**
 * Write to chrome.storage.local cache.
 * @param {string} key
 * @param {any} data
 */
async function _cacheSet(key, data) {
  try {
    await chrome.storage.local.set({ [key]: JSON.stringify({ ts: Date.now(), data }) });
  } catch {
    // non-fatal
  }
}

/**
 * Fetch POIs from Overpass API for a given centre point and radius.
 * Results are cached for 24 hours.
 *
 * @param {number} lat
 * @param {number} lng
 * @param {number} radiusMeters
 * @returns {Promise<Array<{name,type,category,lat,lng,distance_meters,walking_minutes,tags}>>}
 */
export async function fetchOverpassPOIs(lat, lng, radiusMeters) {
  const cacheKey = `overpass_${lat.toFixed(4)}_${lng.toFixed(4)}_${radiusMeters}`;

  // 1. Try cache first
  const cached = await _cacheGet(cacheKey);
  if (cached) return cached;

  // 2. Fetch from Overpass
  const query = OVERPASS_QUERY(lat, lng, radiusMeters);
  const body = `data=${encodeURIComponent(query)}`;

  const response = await fetch(OVERPASS_ENDPOINT, {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body,
  });

  if (!response.ok) {
    throw new Error(`Overpass HTTP ${response.status}`);
  }

  const json = await response.json();
  const elements = json.elements || [];

  // 3. Map to our format
  const pois = [];
  for (const el of elements) {
    if (el.type !== 'node' || !el.lat || !el.lon) continue;
    const tags = el.tags || {};
    const category = osmToCategory(tags);
    if (!category) continue;

    const dist = haversine(lat, lng, el.lat, el.lon);

    pois.push({
      name: osmName(el),
      type: tags.amenity || tags.shop || tags.leisure || tags.railway || 'place',
      category,
      lat: el.lat,
      lng: el.lon,
      distance_meters: dist,
      walking_minutes: walkingMinutes(dist),
      tags,
    });
  }

  // Sort by distance
  pois.sort((a, b) => a.distance_meters - b.distance_meters);

  // 4. Cache and return
  await _cacheSet(cacheKey, pois);
  return pois;
}

/**
 * Merge backend amenities with Overpass POIs.
 * Backend data takes priority; Overpass POIs within 30m of a backend entry are deduped.
 *
 * @param {Array} backendAmenities — result.amenities
 * @param {Array} overpassPOIs    — from fetchOverpassPOIs
 * @returns {Array}
 */
export function mergeAmenities(backendAmenities, overpassPOIs) {
  const backend = backendAmenities || [];
  const overpass = overpassPOIs || [];

  // Build a set of (category, approx-lat, approx-lng) from backend for dedup
  const dedupSet = new Set(
    backend.map(a => `${a.category}_${Math.round((a.lat || 0) * 333)}_${Math.round((a.lng || 0) * 333)}`)
  );

  const extras = overpass.filter(p => {
    const key = `${p.category}_${Math.round(p.lat * 333)}_${Math.round(p.lng * 333)}`;
    return !dedupSet.has(key);
  });

  return [...backend, ...extras];
}
