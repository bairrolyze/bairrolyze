// HomeScope – Sidebar Orchestrator
// Extends popup.js logic with close-button and postMessage back to content script.

import { getState, setState, on } from './js/state.js';
import { ApiService, ApiError } from './js/api.js';
import { getCached, setCached, cacheKey, addToHistory, getSettings } from './js/storage.js';
import { renderHome } from './js/screens/home.js';
import { renderNeighborhood } from './js/screens/neighborhood.js';
import { renderHistory } from './js/screens/history.js';
import { renderSettings } from './js/screens/settings.js';
import { uuid } from './js/utils.js';

// ── DOM ────────────────────────────────────────────────────────────────────────
const screens = {
  home:     document.getElementById('screen-home'),
  loading:  document.getElementById('screen-loading'),
  results:  document.getElementById('screen-results'),
  history:  document.getElementById('screen-history'),
  settings: document.getElementById('screen-settings'),
};

const loadingMsg      = document.getElementById('loading-message');
const resultsContent  = document.getElementById('results-content');
const backFromResults = document.getElementById('btn-results-back');
const resultAddress   = document.getElementById('results-address');

// ── Screen Router ──────────────────────────────────────────────────────────────
on('screen', showScreen);

function showScreen(name) {
  Object.entries(screens).forEach(([key, el]) => {
    el.classList.toggle('active', key === name);
  });
  const state = getState();
  switch (name) {
    case 'home':
      renderHome(screens.home);
      break;
    case 'results':
      if (state.result) showResults(state.result);
      break;
    case 'history':
      renderHistory(screens.history);
      break;
    case 'settings':
      renderSettings(screens.settings);
      break;
  }
}

// ── Results View ───────────────────────────────────────────────────────────────
function showResults(result) {
  resultAddress.textContent = result.address?.display_name || getState().address || '';
  renderNeighborhood(resultsContent, result);
}

backFromResults?.addEventListener('click', () => setState({ screen: 'home' }));

// ── Analysis ───────────────────────────────────────────────────────────────────
document.addEventListener('homescope:analyze', async (e) => {
  await runAnalysis(e.detail.address, e.detail.countryCode, e.detail.profile);
});

document.addEventListener('homescope:load-history', (e) => {
  const entry = e.detail;
  setState({
    result: {
      id: entry.id,
      analyzed_at: entry.analyzedAt,
      address: entry.addressObj || { display_name: entry.address },
      score: entry.score,
      amenities: entry.amenities || [],
      ai_summary: entry.ai_summary || null,
      _address: entry.address,
    },
    screen: 'results',
  });
});

async function runAnalysis(address, countryCode, profile) {
  const settings = await getSettings();
  const api = new ApiService(settings.backendUrl);

  const key    = cacheKey(address, profile);
  const cached = await getCached(key);
  if (cached) {
    setState({ result: cached, settings, screen: 'results' });
    return;
  }

  setState({ screen: 'loading', analysisStatus: 'loading' });
  setLoadingMsg('Locating address…');

  try {
    const t1 = setTimeout(() => setLoadingMsg('Analysing neighbourhood…'), 3000);
    const t2 = setTimeout(() => setLoadingMsg('Calculating scores…'), 7000);
    const t3 = setTimeout(() => setLoadingMsg('Generating insights…'), 12000);

    const result = await api.analyzeAddress({ address, countryCode, profile, radius: settings.searchRadius });
    clearTimeout(t1); clearTimeout(t2); clearTimeout(t3);

    if (result.address && !result.address.display_name) {
      result.address.display_name = address;
    }
    result._address = address;

    await setCached(key, result);
    await addToHistory({
      id: result.id || uuid(),
      address,
      addressObj: result.address,
      score: result.score,
      amenities: result.amenities,
      ai_summary: result.ai_summary,
      profile,
      analyzedAt: result.analyzed_at || new Date().toISOString(),
    });

    setState({ result, settings, analysisStatus: 'done', screen: 'results' });
  } catch (err) {
    console.error('[HomeScope]', err);
    setState({ analysisStatus: 'error', screen: 'home' });
    showError(err instanceof ApiError ? err.message : 'Analysis failed. Please try again.');
  }
}

function setLoadingMsg(msg) {
  if (loadingMsg) loadingMsg.textContent = msg;
}

function showError(msg) {
  setState({ screen: 'home' });
  requestAnimationFrame(() => {
    let banner = screens.home.querySelector('.error-banner');
    if (!banner) {
      banner = document.createElement('div');
      banner.className = 'error-banner';
      screens.home.querySelector('.home-screen')?.prepend(banner);
    }
    banner.textContent = msg;
    banner.classList.add('visible');
    setTimeout(() => banner?.classList.remove('visible'), 6000);
  });
}

// ── Boot ───────────────────────────────────────────────────────────────────────
async function boot() {
  const settings = await getSettings();
  setState({ settings, screen: 'home' });
}

boot();
