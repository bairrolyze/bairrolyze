// HomeScope – Storage Service
// Wraps chrome.storage.local. Mirrors Hive + SharedPreferences behaviour.

const CACHE_TTL_MS = 24 * 60 * 60 * 1000; // 24 hours
const MAX_HISTORY = 20;

// ── Cache ──────────────────────────────────────────────────────────────────────

export function cacheKey(address, profile) {
  return `cache::${address.toLowerCase().trim()}::${profile}`;
}

export async function getCached(key) {
  const data = await get(key);
  if (!data) return null;
  if (data.expiresAt < Date.now()) {
    await chrome.storage.local.remove(key);
    return null;
  }
  return data.payload;
}

export async function setCached(key, payload, ttlMs = CACHE_TTL_MS) {
  await set(key, { payload, expiresAt: Date.now() + ttlMs });
}

export async function clearCache() {
  const all = await chrome.storage.local.get(null);
  const keys = Object.keys(all).filter(k => k.startsWith('cache::'));
  if (keys.length) await chrome.storage.local.remove(keys);
}

// ── Search History ─────────────────────────────────────────────────────────────

export async function getHistory() {
  return (await get('history')) || [];
}

export async function addToHistory(entry) {
  // entry: { id, address, score, analyzedAt }
  let history = await getHistory();
  history = history.filter(h => h.id !== entry.id);
  history.unshift(entry);
  if (history.length > MAX_HISTORY) history = history.slice(0, MAX_HISTORY);
  await set('history', history);
}

export async function removeFromHistory(id) {
  let history = await getHistory();
  history = history.filter(h => h.id !== id);
  await set('history', history);
}

export async function clearHistory() {
  await chrome.storage.local.remove('history');
}

// ── Settings ───────────────────────────────────────────────────────────────────

const DEFAULTS = {
  profile: 'default',
  defaultCountry: 'PT',
  searchRadius: 2000,
  showAiSummary: true,
  backendUrl: 'http://localhost:8000',
};

export async function getSettings() {
  const saved = (await get('settings')) || {};
  return { ...DEFAULTS, ...saved };
}

export async function saveSettings(partial) {
  const current = await getSettings();
  await set('settings', { ...current, ...partial });
}

// ── Internal ───────────────────────────────────────────────────────────────────

function get(key) {
  return new Promise((resolve) => {
    chrome.storage.local.get(key, (result) => resolve(result[key] ?? null));
  });
}

function set(key, value) {
  return new Promise((resolve) => {
    chrome.storage.local.set({ [key]: value }, resolve);
  });
}
