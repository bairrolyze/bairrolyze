// HomeScope – History Screen
import { setState } from '../state.js';
import { getHistory, removeFromHistory, clearHistory } from '../storage.js';
import { scoreColor, scoreLabel, relativeTime } from '../utils.js';

export async function renderHistory(container) {
  const history = await getHistory();

  container.innerHTML = `
    <div class="history-screen">
      <div class="screen-header">
        <button id="btn-back" class="btn-back">← Back</button>
        <h2 class="screen-title">Search History</h2>
        ${history.length ? `<button id="btn-clear-all" class="btn-danger-sm">Clear All</button>` : ''}
      </div>

      ${!history.length ? `
        <div class="empty-state">
          <div class="empty-icon">⏱</div>
          <div class="empty-text">No searches yet.</div>
          <div class="empty-sub">Analyzed addresses will appear here.</div>
        </div>
      ` : `
        <div class="history-full-list">
          ${history.map(h => {
            const score = h.score?.overall ?? 0;
            const color = scoreColor(score);
            return `
              <div class="history-full-tile" data-id="${h.id}">
                <div class="hft-score" style="color:${color}">${Math.round(score)}</div>
                <div class="hft-body">
                  <div class="hft-address">${h.address}</div>
                  <div class="hft-meta">
                    ${scoreLabel(score)} · ${h.profile || 'default'} · ${relativeTime(h.analyzedAt)}
                  </div>
                </div>
                <button class="hft-delete" data-id="${h.id}" title="Remove">✕</button>
              </div>
            `;
          }).join('')}
        </div>
      `}
    </div>
  `;

  container.querySelector('#btn-back').addEventListener('click', () => setState({ screen: 'home' }));

  container.querySelector('#btn-clear-all')?.addEventListener('click', async () => {
    if (confirm('Clear all search history?')) {
      await clearHistory();
      renderHistory(container);
    }
  });

  container.querySelectorAll('.history-full-tile').forEach(tile => {
    tile.addEventListener('click', (e) => {
      if (e.target.classList.contains('hft-delete')) return;
      const id = tile.dataset.id;
      const entry = history.find(h => h.id === id);
      if (entry) {
        document.dispatchEvent(new CustomEvent('homescope:load-history', { detail: entry }));
      }
    });
  });

  container.querySelectorAll('.hft-delete').forEach(btn => {
    btn.addEventListener('click', async (e) => {
      e.stopPropagation();
      await removeFromHistory(btn.dataset.id);
      renderHistory(container);
    });
  });
}
