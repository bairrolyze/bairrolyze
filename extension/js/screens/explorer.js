// HomeScope – Explorer Screen
import { setState } from '../state.js';

const NEIGHBOURHOODS = [
  { id: 'bairro-alto',     name: 'Bairro Alto',        city: 'Lisboa',  tag: 'Nightlife & Culture',  emoji: '🎭', color: '#8B5CF6', filters: ['Culture', 'Lifestyle'] },
  { id: 'alfama',          name: 'Alfama',              city: 'Lisboa',  tag: 'Historic & Authentic',  emoji: '🏛', color: '#F59E0B', filters: ['Culture'] },
  { id: 'parque-nacoes',   name: 'Parque das Nações',   city: 'Lisboa',  tag: 'Modern & Family',       emoji: '🌊', color: '#3B82F6', filters: ['Family', 'Nature'] },
  { id: 'chiado',          name: 'Chiado',              city: 'Lisboa',  tag: 'Cafés & Shopping',      emoji: '☕', color: '#10B981', filters: ['Lifestyle', 'Culture'] },
  { id: 'belem',           name: 'Belém',               city: 'Lisboa',  tag: 'Heritage & Parks',      emoji: '🗺', color: '#06B6D4', filters: ['Nature', 'Culture'] },
  { id: 'principe-real',   name: 'Príncipe Real',       city: 'Lisboa',  tag: 'Boutique & Trendy',     emoji: '🌿', color: '#22C55E', filters: ['Lifestyle'] },
  { id: 'estrela',         name: 'Estrela',             city: 'Lisboa',  tag: 'Quiet & Residential',   emoji: '🏡', color: '#EF4444', filters: ['Family'] },
  { id: 'marvila',         name: 'Marvila',             city: 'Lisboa',  tag: 'Up-and-coming',         emoji: '📈', color: '#6C63FF', filters: ['Investment'] },
  { id: 'baixa',           name: 'Baixa-Chiado',        city: 'Lisboa',  tag: 'Central & Connected',   emoji: '🚇', color: '#3B82F6', filters: ['Transport', 'Investment'] },
  { id: 'campo-ourique',   name: 'Campo de Ourique',    city: 'Lisboa',  tag: 'Village Feel',          emoji: '🧺', color: '#F59E0B', filters: ['Family', 'Lifestyle'] },
  { id: 'ribeira',         name: 'Ribeira',             city: 'Porto',   tag: 'Waterfront & Historic', emoji: '🌉', color: '#F59E0B', filters: ['Culture', 'Lifestyle'] },
  { id: 'foz',             name: 'Foz do Douro',        city: 'Porto',   tag: 'Seaside & Upmarket',    emoji: '🏖', color: '#06B6D4', filters: ['Nature', 'Investment'] },
  { id: 'bonfim',          name: 'Bonfim',              city: 'Porto',   tag: 'Creative & Affordable', emoji: '🎨', color: '#8B5CF6', filters: ['Investment', 'Culture'] },
  { id: 'boavista',        name: 'Boavista',            city: 'Porto',   tag: 'Business District',     emoji: '💼', color: '#3B82F6', filters: ['Transport', 'Investment'] },
  { id: 'cedofeita',       name: 'Cedofeita',           city: 'Porto',   tag: 'Indie & Artsy',         emoji: '🎸', color: '#EF4444', filters: ['Culture', 'Lifestyle'] },
];

const FILTERS = ['All', 'Transport', 'Family', 'Investment', 'Nature', 'Culture', 'Lifestyle'];

export function renderExplorer(container) {
  container.innerHTML = explorerHTML();
  bindExplorer(container);
}

function explorerHTML() {
  return `
    <div class="explorer-screen">
      <div class="screen-header">
        <button id="btn-explorer-back" class="btn-back">← Back</button>
        <h2 class="screen-title">Explore</h2>
      </div>

      <div class="explorer-intro">
        <p class="explorer-intro-text">Browse curated neighbourhoods across Portugal — tap any to get insights instantly.</p>
      </div>

      <div class="explorer-filters" id="explorer-filters">
        ${FILTERS.map((f, i) => `
          <button class="chip ${i === 0 ? 'active' : ''}" data-filter="${f}">${f}</button>
        `).join('')}
      </div>

      <div class="explorer-grid" id="explorer-grid">
        ${renderCards('All')}
      </div>
    </div>
  `;
}

function renderCards(activeFilter) {
  const items = activeFilter === 'All'
    ? NEIGHBOURHOODS
    : NEIGHBOURHOODS.filter(n => n.filters.includes(activeFilter));

  if (!items.length) {
    return `<div class="explorer-empty">No neighbourhoods match this filter.</div>`;
  }

  return items.map(n => `
    <div class="explorer-card" data-id="${n.id}" data-name="${n.name}, ${n.city}" style="--nc:${n.color}">
      <div class="explorer-card-bar"></div>
      <div class="explorer-card-body">
        <span class="explorer-card-emoji">${n.emoji}</span>
        <div class="explorer-card-info">
          <div class="explorer-card-name">${n.name}</div>
          <div class="explorer-card-city">${n.city}</div>
          <div class="explorer-card-tag">${n.tag}</div>
        </div>
        <div class="explorer-card-arrow">›</div>
      </div>
    </div>
  `).join('');
}

function bindExplorer(container) {
  container.querySelector('#btn-explorer-back')
    .addEventListener('click', () => setState({ screen: 'home' }));

  const filtersEl = container.querySelector('#explorer-filters');
  const gridEl = container.querySelector('#explorer-grid');

  filtersEl.addEventListener('click', e => {
    const chip = e.target.closest('.chip[data-filter]');
    if (!chip) return;
    filtersEl.querySelectorAll('.chip').forEach(c => c.classList.remove('active'));
    chip.classList.add('active');
    gridEl.innerHTML = renderCards(chip.dataset.filter);
    bindCards(container);
  });

  bindCards(container);
}

function bindCards(container) {
  container.querySelectorAll('.explorer-card').forEach(card => {
    card.addEventListener('click', () => {
      const address = card.dataset.name;
      document.dispatchEvent(new CustomEvent('homescope:analyze', {
        detail: { address, countryCode: 'PT', profile: 'default' }
      }));
    });
  });
}
