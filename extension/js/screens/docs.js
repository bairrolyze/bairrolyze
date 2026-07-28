// HomeScope – Docs / Guides Screen
import { setState } from '../state.js';

const ARTICLES = [
  {
    id: 'getting-started',
    title: 'Getting Started',
    subtitle: 'Search your first address and get insights in 30 seconds',
    icon: '🚀',
    color: '#3B82F6',
    category: 'Getting Started',
    sections: [
      { body: 'HomeScope analyses any address and scores it across 7 key dimensions of liveability — so you can make confident property decisions backed by data.' },
      { heading: 'Step 1 — Type an address', body: 'Tap the search field and type any address, neighbourhood name, or city. Select your country and profile, then click Analyze Address.' },
      { tip: 'You can search by street name, postcode, or neighbourhood — e.g. "Bairro Alto, Lisboa" or "Rua Augusta".' },
      { heading: 'Step 2 — Read your report', body: 'The report shows your overall score, a category breakdown, an AI-written summary, and a Life Radius walkability map. Tap any tab to explore further.' },
    ],
  },
  {
    id: 'reading-report',
    title: 'Reading Your Report',
    subtitle: 'Understand every section of the Neighbourhood Report',
    icon: '📊',
    color: '#10B981',
    category: 'Getting Started',
    sections: [
      { body: 'The Neighbourhood Report gives you a complete picture of any location across 7 scored dimensions.' },
      { heading: 'Overall Score', body: 'A single score out of 100 summarising all 7 dimensions. 80+ is excellent, 60–79 is good, below 60 suggests trade-offs worth investigating.' },
      { heading: 'The 7 Dimensions', table: [
        ['🚇 Transport',   'Metro, bus, rail, and cycling access'],
        ['🎓 Education',   'Schools, universities, and libraries'],
        ['🏥 Health',      'Hospitals, clinics, and pharmacies'],
        ['🛡 Safety',      'Emergency services and safety indicators'],
        ['🛍 Lifestyle',   'Restaurants, cafés, shops, and culture'],
        ['🌳 Nature',      'Parks, green spaces, and recreation'],
        ['💼 Investment',  'Property trend signals and market data'],
      ]},
      { heading: 'AI Summary', body: 'An AI-generated paragraph describing the neighbourhood\'s character — the feel of the area, not just numbers.' },
    ],
  },
  {
    id: 'life-radius',
    title: 'Life Radius Map',
    subtitle: 'See exactly what\'s walkable from your address',
    icon: '🗺',
    color: '#F59E0B',
    category: 'Features',
    sections: [
      { body: 'The Life Radius tab shows a circular radar centred on the analysed address. Each ring represents a walk-time band — 5, 10, 20 and 30 minutes.' },
      { heading: 'Reading the map', body: 'Coloured dots represent nearby amenities. Each colour corresponds to a dimension category. Click any dot to see the name, type, and estimated walking time.' },
      { heading: 'Filter by category', body: 'Use the category chips below the map to focus on what matters — schools, transport, parks, etc.' },
      { tip: 'A dense inner ring (many dots within the 5-min circle) is a strong indicator of genuine walkability.' },
    ],
  },
  {
    id: 'explore',
    title: 'Explore Neighbourhoods',
    subtitle: 'Browse curated areas without searching',
    icon: '🧭',
    color: '#F59E0B',
    category: 'Features',
    sections: [
      { body: 'The Explore screen gives you a curated list of notable neighbourhoods across Portugal — great for discovering areas you haven\'t considered yet.' },
      { heading: 'Filter by category', body: 'Use the filter chips at the top to narrow down by what matters: Transport, Family, Investment, Nature, or Culture.' },
      { heading: 'Open a neighbourhood', body: 'Tap any card to trigger a full analysis of that area — same score breakdown, AI summary, and Life Radius as a manual search.' },
      { tip: 'Explore is great for investors: filter by Investment to see which areas have the strongest property signals.' },
    ],
  },
  {
    id: 'profiles',
    title: 'Choosing a Profile',
    subtitle: 'Personalise the score to your situation',
    icon: '🎯',
    color: '#8B5CF6',
    category: 'Features',
    sections: [
      { body: 'Your profile re-weights the 7 dimension scores around what matters most to you. Select it on the home screen or in Settings.' },
      { heading: 'Available profiles', table: [
        ['Default',       'Balanced across all dimensions'],
        ['Family',        'Weights Education and Safety higher'],
        ['Student',       'Weights Transport and Lifestyle'],
        ['Professional',  'Weights Transport and Investment'],
        ['Retired',       'Weights Nature, Health, and Safety'],
        ['Investor',      'Weights Investment and Transport'],
      ]},
      { tip: 'Switch profiles on the same address to see how priorities shift the overall score.' },
    ],
  },
  {
    id: 'settings',
    title: 'Settings & Configuration',
    subtitle: 'Customise HomeScope to match your workflow',
    icon: '⚙️',
    color: '#EF4444',
    category: 'Settings',
    sections: [
      { heading: 'Backend URL', body: 'The URL of your HomeScope FastAPI server. Update this if you\'re running the backend on a custom domain or port.' },
      { heading: 'Default Country', body: 'Sets the country filter for address search. Affects which OpenStreetMap region is queried.' },
      { heading: 'Search Radius', body: 'Controls how wide an area HomeScope scans for amenities. Drag the slider between 500m and 5km. A larger radius suits rural areas; smaller suits dense cities.' },
      { heading: 'AI Summary', body: 'Toggle the AI Neighbourhood Summary on or off. When on, OpenAI generates a paragraph describing the area\'s character.' },
      { heading: 'Data', body: 'Clear Cache removes stored analysis results so fresh data is fetched next time. Clear History removes your search log from local storage.' },
    ],
  },
  {
    id: 'data-privacy',
    title: 'Data & Privacy',
    subtitle: 'What\'s stored and where',
    icon: '🔒',
    color: '#06B6D4',
    category: 'Settings',
    sections: [
      { body: 'HomeScope is designed with privacy in mind. Here\'s exactly what happens to your data.' },
      { heading: 'What\'s stored locally', body: 'Your search history, cached results, and settings are stored in your browser\'s local extension storage. They never leave your device.' },
      { heading: 'What\'s sent to the server', body: 'When you run an analysis, the address, country code, profile, and search radius are sent to the HomeScope API. This is the minimum needed to perform the location lookup.' },
      { tip: 'To remove all stored data, use Clear Cache and Clear History in Settings.' },
    ],
  },
  {
    id: 'accuracy',
    title: 'Data Sources & Accuracy',
    subtitle: 'Where the data comes from',
    icon: '📡',
    color: '#22C55E',
    category: 'Settings',
    sections: [
      { body: 'HomeScope uses OpenStreetMap — a global, continuously updated geographic database with over 8 billion data points.' },
      { heading: 'How scores are calculated', body: 'Each dimension counts nearby amenities of the relevant type within your chosen search radius. Closer amenities contribute more to the score. Your profile then re-weights the final total.' },
      { heading: 'Limitations', body: 'Scores reflect what is mapped in OpenStreetMap. Some amenities in rural or less-mapped areas may be missing. Data is generally more complete in urban centres.' },
      { tip: 'If a known amenity is missing from a score, it may not yet be in OpenStreetMap. You can contribute by adding it at openstreetmap.org.' },
    ],
  },
];

let _currentArticle = null;

export function renderDocs(container) {
  _currentArticle = null;
  container.innerHTML = docsListHTML();
  bindDocsList(container);
}

function docsListHTML() {
  const categories = {};
  for (const a of ARTICLES) {
    if (!categories[a.category]) categories[a.category] = [];
    categories[a.category].push(a);
  }

  return `
    <div class="docs-screen">
      <div class="screen-header">
        <button id="btn-docs-back" class="btn-back">← Back</button>
        <h2 class="screen-title">Guides & Help</h2>
      </div>

      <div class="docs-intro">
        <div class="docs-intro-icon">📚</div>
        <div>
          <div class="docs-intro-title">Everything you need to know</div>
          <div class="docs-intro-sub">${ARTICLES.length} guides covering every feature</div>
        </div>
      </div>

      <div class="docs-list">
        ${Object.entries(categories).map(([cat, articles]) => `
          <div class="docs-category-label">${cat.toUpperCase()}</div>
          ${articles.map(a => `
            <div class="docs-article-row" data-id="${a.id}" style="--ac:${a.color}">
              <div class="docs-article-icon">${a.icon}</div>
              <div class="docs-article-info">
                <div class="docs-article-title">${a.title}</div>
                <div class="docs-article-subtitle">${a.subtitle}</div>
              </div>
              <div class="docs-article-arrow">›</div>
            </div>
          `).join('')}
        `).join('')}
      </div>
    </div>
  `;
}

function bindDocsList(container) {
  container.querySelector('#btn-docs-back')
    .addEventListener('click', () => setState({ screen: 'settings' }));

  container.querySelectorAll('.docs-article-row').forEach(row => {
    row.addEventListener('click', () => {
      const article = ARTICLES.find(a => a.id === row.dataset.id);
      if (article) showArticle(container, article);
    });
  });
}

function showArticle(container, article) {
  _currentArticle = article;
  container.innerHTML = articleHTML(article);
  bindArticle(container, article);
}

function articleHTML(article) {
  return `
    <div class="docs-screen">
      <div class="screen-header">
        <button id="btn-article-back" class="btn-back">← Guides</button>
        <h2 class="screen-title" style="color:${article.color}">${article.category}</h2>
      </div>

      <div class="docs-article-hero" style="--ac:${article.color}">
        <div class="docs-article-hero-icon">${article.icon}</div>
        <div class="docs-article-badge" style="color:${article.color};background:${article.color}18;border-color:${article.color}33">
          ${article.category.toUpperCase()}
        </div>
        <h2 class="docs-article-title-lg">${article.title}</h2>
        <p class="docs-article-subtitle-lg">${article.subtitle}</p>
      </div>

      <div class="docs-article-body">
        ${article.sections.map(s => sectionHTML(s, article.color)).join('')}
      </div>
    </div>
  `;
}

function sectionHTML(s, color) {
  if (s.heading && !s.body && !s.tip && !s.table) {
    return `<div class="docs-section-heading" style="color:${color}">${s.heading}</div>`;
  }
  if (s.tip) {
    return `
      <div class="docs-tip" style="background:${color}0D;border-color:${color}38">
        <span class="docs-tip-icon" style="color:${color}">💡</span>
        <span class="docs-tip-text">${s.tip}</span>
      </div>`;
  }
  if (s.table) {
    return `
      <div class="docs-table">
        ${s.table.map(([k, v]) => `
          <div class="docs-table-row">
            <span class="docs-table-key">${k}</span>
            <span class="docs-table-val">${v}</span>
          </div>
        `).join('')}
      </div>`;
  }
  return `
    <div class="docs-body-block">
      ${s.heading ? `<div class="docs-section-heading-inline" style="color:${color}">${s.heading}</div>` : ''}
      ${s.body ? `<p class="docs-body-text">${s.body}</p>` : ''}
    </div>`;
}

function bindArticle(container, article) {
  container.querySelector('#btn-article-back')
    .addEventListener('click', () => {
      container.innerHTML = docsListHTML();
      bindDocsList(container);
    });
}
