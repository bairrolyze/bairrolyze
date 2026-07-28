// HomeScope – App State
// Lightweight observable store replacing Riverpod.

const listeners = {};

const state = {
  screen: 'home',       // home | loading | results | history | settings | explorer | docs | tutorial
  niTab: 'dna',         // dna | life-radius | time-machine | ai-story | future-score
  resultsView: 'dashboard', // dashboard | neighborhood
  analysisStatus: 'idle',   // idle | loading | done | error
  statusMessage: '',
  address: null,        // raw address string entered
  result: null,         // full API response
  settings: null,       // loaded from storage
  history: [],
};

export function getState() {
  return { ...state };
}

export function setState(partial) {
  Object.assign(state, partial);
  emit('change', { ...state });
  if ('screen' in partial) emit('screen', state.screen);
  if ('niTab' in partial) emit('niTab', state.niTab);
  if ('resultsView' in partial) emit('resultsView', state.resultsView);
  if ('analysisStatus' in partial) emit('analysisStatus', state.analysisStatus);
}

export function on(event, handler) {
  if (!listeners[event]) listeners[event] = [];
  listeners[event].push(handler);
  return () => { listeners[event] = listeners[event].filter(h => h !== handler); };
}

function emit(event, data) {
  (listeners[event] || []).forEach(h => h(data));
}
