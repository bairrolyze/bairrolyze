// HomeScope – Main Popup Orchestrator
// Replaces Riverpod + GoRouter with a lightweight event-driven state machine.

import { getState, setState, on } from './js/state.js';
import { ApiService, ApiError } from './js/api.js';
import { getCached, setCached, cacheKey, addToHistory, getSettings } from './js/storage.js';
import { renderHome } from './js/screens/home.js';
import { renderDashboard } from './js/screens/dashboard.js';
import { renderNeighborhood } from './js/screens/neighborhood.js';
import { renderHistory } from './js/screens/history.js';
import { renderSettings } from './js/screens/settings.js';
import { uuid } from './js/utils.js';

// ── DOM References ─────────────────────────────────────────────────────────────
const screens = {
  home:         document.getElementById('screen-home'),
  loading:      document.getElementById('screen-loading'),
  results:      document.getElementById('screen-results'),
  history:      document.getElementById('screen-history'),
  settings:     document.getElementById('screen-settings'),
};

const loadingMsg   = document.getElementById('loading-message');
const dashContent  = document.getElementById('dash-content');
const niContent    = document.getElementById('ni-content');
const viewToggleDash = document.getElementById('btn-view-dash');
const viewToggleNI   = document.getElementById('btn-view-ni');
const dashView       = document.getElementById('results-dash');
const niView         = document.getElementById('results-ni');
const backFromResults = document.getElementById('btn-results-back');
const resultAddress  = document.getElementById('results-address');

// ── Screen Router ──────────────────────────────────────────────────────────────
on('screen', (screen) => showScreen(screen));

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
      if (state.result) showResults(state.result, state.settings);
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
function showResults(result, settings) {
  const addr = result.address?.display_name || getState().address || '';
  resultAddress.textContent = addr;

  renderDashboard(dashContent, result, settings);
  renderNeighborhood(niContent, result);

  // Show dashboard by default
  activateResultsView('dashboard');
}

function activateResultsView(view) {
  const isDash = view === 'dashboard';
  dashView.classList.toggle('active', isDash);
  niView.classList.toggle('active', !isDash);
  viewToggleDash.classList.toggle('active', isDash);
  viewToggleNI.classList.toggle('active', !isDash);
  setState({ resultsView: view });
}

viewToggleDash?.addEventListener('click', () => activateResultsView('dashboard'));
viewToggleNI?.addEventListener('click', () => activateResultsView('neighborhood'));
backFromResults?.addEventListener('click', () => setState({ screen: 'home' }));

// ── Analysis Orchestration ─────────────────────────────────────────────────────
document.addEventListener('homescope:analyze', async (e) => {
  const { address, countryCode, profile } = e.detail;
  await runAnalysis(address, countryCode, profile);
});

document.addEventListener('homescope:load-history', (e) => {
  const entry = e.detail;
  // Reconstruct a result-like object from history entry
  const result = {
    id: entry.id,
    analyzed_at: entry.analyzedAt,
    address: entry.addressObj || { display_name: entry.address },
    score: entry.score,
    amenities: entry.amenities || [],
    ai_summary: entry.ai_summary || null,
    _address: entry.address,
  };
  setState({ result, screen: 'results' });
});

async function runAnalysis(address, countryCode, profile) {
  const settings = await getSettings();
  const api = new ApiService(settings.backendUrl);

  // Check cache
  const key = cacheKey(address, profile);
  const cached = await getCached(key);
  if (cached) {
    setState({ result: cached, settings, screen: 'results' });
    return;
  }

  // Show loading
  setState({ screen: 'loading', analysisStatus: 'loading' });
  setLoadingMessage('Locating address…');

  let result;
  try {
    setTimeout(() => setLoadingMessage('Analysing neighbourhood…'), 3000);
    setTimeout(() => setLoadingMessage('Calculating scores…'), 7000);
    setTimeout(() => setLoadingMessage('Generating insights…'), 12000);

    result = await api.analyzeAddress({
      address,
      countryCode,
      profile,
      radius: settings.searchRadius,
    });

    // Normalise address field
    if (result.address && !result.address.display_name && result.address.display_name !== '') {
      result.address.display_name = result.address.display_name || address;
    }
    result._address = address;

    // Cache result
    await setCached(key, result);

    // Save to history
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
    console.error('[HomeScope] Analysis failed:', err);
    setState({ analysisStatus: 'error', screen: 'home' });
    showError(err instanceof ApiError ? err.message : 'Analysis failed. Please try again.');
  }
}

function setLoadingMessage(msg) {
  if (loadingMsg) loadingMsg.textContent = msg;
}

function showError(msg) {
  // Re-render home and show error banner
  const homeEl = screens.home;
  setState({ screen: 'home' });
  requestAnimationFrame(() => {
    let banner = homeEl.querySelector('.error-banner');
    if (!banner) {
      banner = document.createElement('div');
      banner.className = 'error-banner';
      homeEl.querySelector('.home-screen')?.prepend(banner);
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
