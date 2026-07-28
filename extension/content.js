// HomeScope – Content Script
// Injected on every toolbar click. Splits the window 70% page / 30% sidebar.

(function () {
  const FRAME_ID = '__homescope_sidebar__';
  const SIDEBAR_PCT = 30; // % of viewport width

  // ── Helpers ────────────────────────────────────────────────────────────────
  function sidebarWidth() {
    // At least 320px, at most 520px, otherwise 30vw
    const vw = window.innerWidth;
    return Math.min(520, Math.max(320, Math.round(vw * SIDEBAR_PCT / 100)));
  }

  function shrinkPage(px) {
    const html = document.documentElement;
    // padding-right + border-box shrinks the usable content area to (100% - px)
    // so the page reflows into the left 70% and never goes under the sidebar.
    html.style.setProperty('box-sizing',      'border-box',   'important');
    html.style.setProperty('padding-right',   px + 'px',      'important');
    html.style.setProperty('transition',      'padding-right 240ms ease', 'important');
    html.style.setProperty('overflow-x',      'hidden',       'important');
  }

  function restorePage() {
    const html = document.documentElement;
    html.style.setProperty('padding-right', '0px', 'important');
    // Clean up after transition
    setTimeout(() => {
      html.style.removeProperty('box-sizing');
      html.style.removeProperty('padding-right');
      html.style.removeProperty('transition');
      html.style.removeProperty('overflow-x');
    }, 260);
  }

  // ── Toggle if sidebar already exists ──────────────────────────────────────
  const existing = document.getElementById(FRAME_ID);
  if (existing) {
    const isVisible = existing.style.display !== 'none';
    if (isVisible) {
      existing.style.display = 'none';
      restorePage();
    } else {
      existing.style.display = 'block';
      shrinkPage(sidebarWidth());
    }
    return;
  }

  // ── First open: create the iframe ──────────────────────────────────────────
  const px = sidebarWidth();

  const iframe = document.createElement('iframe');
  iframe.id  = FRAME_ID;
  iframe.src = chrome.runtime.getURL('sidebar.html');

  Object.assign(iframe.style, {
    position:  'fixed',
    top:       '0',
    right:     '0',
    width:     px + 'px',
    height:    '100vh',
    border:    'none',
    zIndex:    '2147483647',
    boxShadow: '-6px 0 32px rgba(0,0,0,0.55)',
    borderLeft:'1px solid #1A2845',
    colorScheme:'dark',
  });

  document.documentElement.appendChild(iframe);
  shrinkPage(px);

  // ── Listen for close from sidebar ──────────────────────────────────────────
  window.addEventListener('message', (e) => {
    if (e.data !== 'homescope:close') return;
    iframe.style.display = 'none';
    restorePage();
  });

  // ── Keep sidebar width in sync on resize ───────────────────────────────────
  window.addEventListener('resize', () => {
    if (iframe.style.display === 'none') return;
    const newPx = sidebarWidth();
    iframe.style.width = newPx + 'px';
    shrinkPage(newPx);
  });
})();
