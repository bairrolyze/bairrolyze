// Chrome API mock injected via page.addInitScript()
// Runs before any page scripts so chrome.storage.local is available
// when popup.js starts importing modules.

export const CHROME_MOCK_SCRIPT = `
(function() {
  // Pre-seeded data can be injected via a prior addInitScript setting window.__seed
  const _store = window.__seed ? JSON.parse(JSON.stringify(window.__seed)) : {};

  const storageMock = {
    get(keys, cb) {
      return new Promise(resolve => {
        const result = {};
        if (keys === null || keys === undefined) {
          Object.assign(result, _store);
        } else if (typeof keys === 'string') {
          result[keys] = _store[keys] !== undefined ? _store[keys] : null;
        } else if (Array.isArray(keys)) {
          keys.forEach(k => { result[k] = _store[k] !== undefined ? _store[k] : null; });
        } else {
          Object.keys(keys).forEach(k => {
            result[k] = _store[k] !== undefined ? _store[k] : keys[k];
          });
        }
        if (cb) cb(result);
        resolve(result);
      });
    },
    set(items, cb) {
      return new Promise(resolve => {
        Object.assign(_store, items);
        if (cb) cb();
        resolve();
      });
    },
    remove(keys, cb) {
      return new Promise(resolve => {
        const ks = Array.isArray(keys) ? keys : [keys];
        ks.forEach(k => delete _store[k]);
        if (cb) cb();
        resolve();
      });
    },
    clear(cb) {
      return new Promise(resolve => {
        Object.keys(_store).forEach(k => delete _store[k]);
        if (cb) cb();
        resolve();
      });
    },
    _dump() { return JSON.parse(JSON.stringify(_store)); },
  };

  window.chrome = {
    storage: { local: storageMock },
    runtime: {
      id: 'test-extension-id',
      lastError: null,
      onMessage: { addListener() {}, removeListener() {} },
      sendMessage() {},
    },
    tabs: {
      create(opts) { window.open(opts.url, '_blank'); },
      query(opts, cb) {
        const res = [];
        if (cb) cb(res);
        return Promise.resolve(res);
      },
    },
    sidePanel: {
      setPanelBehavior() { return Promise.resolve(); },
    },
    alarms: {
      create() {},
      onAlarm: { addListener() {} },
    },
  };

  // Expose for test helpers
  window.__dumpStorage = () => storageMock._dump();
})();
`;
