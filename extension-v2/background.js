// HomeScope – Background Service Worker (MV3)

// ── Open side panel automatically when toolbar icon is clicked ────────────────
chrome.sidePanel.setPanelBehavior({ openPanelOnActionClick: true }).catch(console.error);

// ── Cache-expiry cleanup (alarms permission required) ─────────────────────────
chrome.runtime.onInstalled.addListener(() => {
  if (chrome.alarms) {
    chrome.alarms.create('hs-cache-cleanup', { periodInMinutes: 60 });
  }
});

if (chrome.alarms) {
  chrome.alarms.onAlarm.addListener(async (alarm) => {
    if (alarm.name !== 'hs-cache-cleanup') return;
    const data = await chrome.storage.local.get(null);
    const now  = Date.now();
    const stale = Object.keys(data).filter(
      k => k.startsWith('cache::') && data[k]?.expiresAt < now
    );
    if (stale.length) await chrome.storage.local.remove(stale);
  });
}
