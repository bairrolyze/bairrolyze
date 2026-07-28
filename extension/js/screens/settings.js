// HomeScope – Settings Screen
import { setState } from '../state.js';
import { getSettings, saveSettings, clearCache, clearHistory } from '../storage.js';

export async function renderSettings(container) {
  const settings = await getSettings();

  container.innerHTML = `
    <div class="settings-screen">
      <div class="screen-header">
        <button id="btn-back" class="btn-back">← Back</button>
        <h2 class="screen-title">Settings</h2>
      </div>

      <div class="settings-body">
        <!-- Backend URL -->
        <div class="settings-group">
          <label class="settings-label">Backend URL</label>
          <input id="backend-url" class="settings-input" type="url"
            value="${settings.backendUrl}" placeholder="http://localhost:8000"/>
          <p class="settings-hint">URL of your HomeScope FastAPI server.</p>
        </div>

        <!-- Default Country -->
        <div class="settings-group">
          <label class="settings-label">Default Country</label>
          <select id="default-country" class="settings-select">
            <option value="PT" ${settings.defaultCountry==='PT'?'selected':''}>🇵🇹 Portugal</option>
            <option value="ES" ${settings.defaultCountry==='ES'?'selected':''}>🇪🇸 Spain</option>
            <option value="GB" ${settings.defaultCountry==='GB'?'selected':''}>🇬🇧 United Kingdom</option>
            <option value="FR" ${settings.defaultCountry==='FR'?'selected':''}>🇫🇷 France</option>
            <option value="DE" ${settings.defaultCountry==='DE'?'selected':''}>🇩🇪 Germany</option>
          </select>
        </div>

        <!-- Default Profile -->
        <div class="settings-group">
          <label class="settings-label">Default Profile</label>
          <select id="default-profile" class="settings-select">
            <option value="default"      ${settings.profile==='default'?'selected':''}>Default</option>
            <option value="family"       ${settings.profile==='family'?'selected':''}>Family</option>
            <option value="student"      ${settings.profile==='student'?'selected':''}>Student</option>
            <option value="professional" ${settings.profile==='professional'?'selected':''}>Professional</option>
            <option value="retired"      ${settings.profile==='retired'?'selected':''}>Retired</option>
            <option value="investor"     ${settings.profile==='investor'?'selected':''}>Investor</option>
          </select>
        </div>

        <!-- Search Radius -->
        <div class="settings-group">
          <label class="settings-label">Search Radius: <span id="radius-val">${settings.searchRadius}m</span></label>
          <input type="range" id="search-radius" class="settings-slider"
            min="500" max="5000" step="250" value="${settings.searchRadius}">
          <div class="settings-slider-labels">
            <span>500m</span><span>2500m</span><span>5km</span>
          </div>
        </div>

        <!-- AI Summary toggle -->
        <div class="settings-group settings-row">
          <label class="settings-label">Show AI Summary</label>
          <label class="toggle">
            <input type="checkbox" id="show-ai" ${settings.showAiSummary ? 'checked' : ''}>
            <span class="toggle-slider"></span>
          </label>
        </div>

        <button id="btn-save" class="btn-primary" style="margin-top:8px">Save Settings</button>

        <!-- Danger zone -->
        <div class="settings-divider"></div>
        <div class="settings-group">
          <label class="settings-label" style="color:#EF4444">Data</label>
          <div class="danger-row">
            <button id="btn-clear-cache" class="btn-danger">Clear Cache</button>
            <button id="btn-clear-hist" class="btn-danger">Clear History</button>
          </div>
        </div>

        <!-- Help -->
        <div class="settings-divider"></div>
        <div class="settings-group">
          <label class="settings-label">Help</label>
          <div class="help-row">
            <button id="btn-guides" class="btn-ghost help-btn">
              <span>📚</span> Guides &amp; Help
            </button>
            <button id="btn-tutorial" class="btn-ghost help-btn">
              <span>▶</span> Quick Tour
            </button>
          </div>
        </div>

        <div id="settings-msg" class="settings-msg hidden"></div>
      </div>
    </div>
  `;

  // Radius slider live label
  const radiusSlider = container.querySelector('#search-radius');
  const radiusVal = container.querySelector('#radius-val');
  radiusSlider.addEventListener('input', () => {
    radiusVal.textContent = `${radiusSlider.value}m`;
  });

  container.querySelector('#btn-back').addEventListener('click', () => setState({ screen: 'home' }));

  container.querySelector('#btn-save').addEventListener('click', async () => {
    await saveSettings({
      backendUrl:    container.querySelector('#backend-url').value.trim(),
      defaultCountry: container.querySelector('#default-country').value,
      profile:       container.querySelector('#default-profile').value,
      searchRadius:  parseInt(radiusSlider.value),
      showAiSummary: container.querySelector('#show-ai').checked,
    });
    showMsg(container, '✓ Settings saved.', 'success');
  });

  container.querySelector('#btn-clear-cache').addEventListener('click', async () => {
    await clearCache();
    showMsg(container, '✓ Cache cleared.', 'success');
  });

  container.querySelector('#btn-clear-hist').addEventListener('click', async () => {
    if (confirm('Clear all history?')) {
      await clearHistory();
      showMsg(container, '✓ History cleared.', 'success');
    }
  });

  container.querySelector('#btn-guides')?.addEventListener('click', () => setState({ screen: 'docs' }));
  container.querySelector('#btn-tutorial')?.addEventListener('click', () => setState({ screen: 'tutorial' }));
}

function showMsg(container, text, type) {
  const el = container.querySelector('#settings-msg');
  el.textContent = text;
  el.className = `settings-msg ${type}`;
  setTimeout(() => el.classList.add('hidden'), 3000);
}
