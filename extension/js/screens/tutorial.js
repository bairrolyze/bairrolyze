// HomeScope – Tutorial Screen (5-step onboarding)
import { setState } from '../state.js';

const PAGES = [
  {
    icon: '🏠',
    color: '#3B82F6',
    badge: 'WELCOME',
    title: 'Welcome to HomeScope',
    subtitle: 'The smarter way to research any address — 7 dimensions of liveability, AI insights, real-time data.',
    features: [
      { icon: '📍', text: 'Analyse any address in seconds' },
      { icon: '🤖', text: 'AI-powered neighbourhood summary' },
      { icon: '🗺', text: 'Life Radius walkability map' },
    ],
  },
  {
    icon: '🔍',
    color: '#10B981',
    badge: 'SEARCH',
    title: 'Search Any Address',
    subtitle: 'Type a street, postcode, or neighbourhood. Select your profile to personalise the score.',
    features: [
      { icon: '⚡', text: 'Results in under 20 seconds' },
      { icon: '🎯', text: '6 profiles: Family, Investor, Student…' },
      { icon: '🌍', text: 'Portugal, Spain, UK, France, Germany' },
    ],
  },
  {
    icon: '📊',
    color: '#8B5CF6',
    badge: 'RESULTS',
    title: 'Your Neighbourhood Report',
    subtitle: 'A full breakdown across 7 scored dimensions — from transport links to green spaces.',
    features: [
      { icon: '🎓', text: 'Education & healthcare proximity' },
      { icon: '🚇', text: 'Transport connections scored' },
      { icon: '💼', text: 'Investment signal & property trends' },
    ],
  },
  {
    icon: '🧭',
    color: '#F59E0B',
    badge: 'EXPLORE',
    title: 'Explore Neighbourhoods',
    subtitle: 'Browse curated areas across Portugal — filter by what matters most to you.',
    features: [
      { icon: '🌊', text: 'Hand-picked Lisboa & Porto areas' },
      { icon: '🔖', text: 'Filter: Family, Investment, Culture…' },
      { icon: '🚀', text: 'Tap any card to get instant insights' },
    ],
  },
  {
    icon: '⚙️',
    color: '#6C63FF',
    badge: 'SETTINGS',
    title: 'Customise & Control',
    subtitle: 'Set your default country, profile, and search radius. Access guides anytime from Settings.',
    features: [
      { icon: '📚', text: 'Guides & Help — 8 full articles' },
      { icon: '🛡', text: 'History stored locally, never uploaded' },
      { icon: '🔧', text: 'Configure radius 500m–5km' },
    ],
  },
];

export function renderTutorial(container) {
  let page = 0;
  container.innerHTML = tutorialHTML(page);
  bindTutorial(container, () => { page = currentPage(container); });
}

function tutorialHTML(page) {
  const p = PAGES[page];
  const isLast = page === PAGES.length - 1;

  return `
    <div class="tutorial-screen">
      <div class="tutorial-topbar">
        <button class="btn-back" id="btn-tutorial-skip">Skip</button>
        <div class="tutorial-dots">
          ${PAGES.map((_, i) => `<div class="tutorial-dot ${i === page ? 'active' : ''}"></div>`).join('')}
        </div>
        <div style="width:40px"></div>
      </div>

      <div class="tutorial-content">
        <div class="tutorial-icon" style="background:${p.color}22;border-color:${p.color}44">
          <span style="font-size:36px">${p.icon}</span>
        </div>

        <div class="tutorial-badge" style="color:${p.color};background:${p.color}18;border-color:${p.color}33">
          ${p.badge}
        </div>

        <h2 class="tutorial-title">${p.title}</h2>
        <p class="tutorial-subtitle">${p.subtitle}</p>

        <div class="tutorial-features">
          ${p.features.map(f => `
            <div class="tutorial-feature">
              <span class="tutorial-feature-icon">${f.icon}</span>
              <span class="tutorial-feature-text">${f.text}</span>
            </div>
          `).join('')}
        </div>
      </div>

      <div class="tutorial-footer">
        <button class="tutorial-page-data hidden" data-page="${page}"></button>
        <button class="btn-primary" id="btn-tutorial-next">
          ${isLast ? 'Get Started' : 'Next →'}
        </button>
      </div>
    </div>
  `;
}

function currentPage(container) {
  return parseInt(container.querySelector('.tutorial-page-data')?.dataset.page ?? '0');
}

function bindTutorial(container, onPageChange) {
  container.querySelector('#btn-tutorial-skip')
    .addEventListener('click', () => setState({ screen: 'home' }));

  container.querySelector('#btn-tutorial-next')
    .addEventListener('click', () => {
      const page = currentPage(container);
      if (page >= PAGES.length - 1) {
        setState({ screen: 'home' });
      } else {
        container.innerHTML = tutorialHTML(page + 1);
        bindTutorial(container, onPageChange);
      }
    });
}
