// HomeScope – AI Story Widget
// Mirrors ai_story_widget.dart. Uses backend ai_summary + local persona templates.

import { scoreLabel, scoreColor, categoryColor, categoryEmoji } from '../utils.js';

const PERSONAS = [
  { id: 'overview',      label: 'Overview',     emoji: '🏠' },
  { id: 'family',        label: 'Family',       emoji: '👨‍👩‍👧' },
  { id: 'professional',  label: 'Professional', emoji: '💼' },
  { id: 'student',       label: 'Student',      emoji: '🎓' },
  { id: 'retired',       label: 'Retired',      emoji: '🌅' },
  { id: 'investor',      label: 'Investor',     emoji: '📈' },
];

function getStory(persona, result) {
  const score = result.score;
  const overall = Math.round(score?.overall ?? 0);
  const cats = score?.categories || {};
  const address = result.address?.display_name || 'this address';

  const catScore = (id) => Math.round(cats[id]?.score ?? 0);
  const highest = Object.entries(cats).sort((a,b) => b[1].score - a[1].score)[0];
  const lowest  = Object.entries(cats).sort((a,b) => a[1].score - b[1].score)[0];
  const highCat = highest?.[1]?.label || 'category';
  const lowCat  = lowest?.[1]?.label || 'category';

  if (persona === 'overview') {
    return result.ai_summary ||
      `${address} scores ${overall}/100 overall — rated ${scoreLabel(overall)}. ` +
      `The strongest point is ${highCat} (${catScore(highest?.[0])}), ` +
      `while ${lowCat} (${catScore(lowest?.[0])}) has the most room to improve. ` +
      `With ${score?.categories ? Object.keys(cats).length : 0} livability dimensions evaluated, ` +
      `this area offers a ${overall >= 60 ? 'solid' : 'developing'} urban experience.`;
  }

  const stories = {
    family: `For a family, ${address} scores ${overall}/100. ` +
      `Education access is ${catScore('education') >= 60 ? 'strong' : 'limited'} at ${catScore('education')}/100, ` +
      `and safety is rated ${catScore('safety')}/100. ` +
      `${catScore('recreation') >= 60 ? 'Parks and recreational areas are within reach, great for kids.' : 'Recreational options are limited — worth factoring in.'}` +
      ` Healthcare is ${catScore('healthcare') >= 60 ? 'well served' : 'less accessible'} at ${catScore('healthcare')}/100.`,

    professional: `For professionals, this location scores ${overall}/100. ` +
      `Transport links score ${catScore('transportation')}/100 — ` +
      `${catScore('transportation') >= 70 ? 'commuting should be smooth.' : 'commute times may be a consideration.'} ` +
      `Shopping and dining convenience is rated ${catScore('shopping')}/100. ` +
      `Safety scores ${catScore('safety')}/100, ` +
      `making this ${catScore('safety') >= 60 ? 'a reassuring' : 'a manageable'} choice for work-life balance.`,

    student: `Students would find ${address} scores ${overall}/100. ` +
      `Education proximity is ${catScore('education') >= 70 ? 'excellent' : 'moderate'} at ${catScore('education')}/100 — ` +
      `${catScore('education') >= 70 ? 'campus access looks solid.' : 'may need to factor in travel time.'} ` +
      `Transport options (${catScore('transportation')}/100) and recreation (${catScore('recreation')}/100) ` +
      `${catScore('transportation') + catScore('recreation') >= 120 ? 'round out a vibrant student lifestyle.' : 'leave some room for improvement.'}`,

    retired: `Retirees would rate ${address} at ${overall}/100. ` +
      `Healthcare access scores ${catScore('healthcare')}/100 — ` +
      `${catScore('healthcare') >= 70 ? 'reassuring proximity to medical care.' : 'worth checking specific facilities.'} ` +
      `Safety (${catScore('safety')}/100) and recreation (${catScore('recreation')}/100) ` +
      `${catScore('safety') >= 60 ? 'create a comfortable, secure environment.' : 'could be better for a peaceful retirement.'} ` +
      `Transport score of ${catScore('transportation')}/100 means ` +
      `${catScore('transportation') >= 60 ? 'getting around remains easy without a car.' : 'a car may still be needed.'}`,

    investor: `From an investment perspective, ${address} scores ${overall}/100. ` +
      `Transport infrastructure (${catScore('transportation')}/100) and shopping density (${catScore('shopping')}/100) ` +
      `are key demand drivers. Education (${catScore('education')}/100) supports family-rental demand. ` +
      `Safety (${catScore('safety')}/100) ${catScore('safety') >= 60 ? 'bolsters long-term appeal.' : 'may impact premium positioning.'} ` +
      `Overall, this location represents a ${overall >= 70 ? 'strong' : overall >= 50 ? 'moderate' : 'speculative'} investment proposition.`,
  };

  return stories[persona] || stories.overview;
}

export function renderAiStory(container, result) {
  let activePersna = 'overview';

  function render() {
    const story = getStory(activePersna, result);
    const score = result.score?.overall ?? 0;
    const color = scoreColor(score);

    container.innerHTML = `
      <div class="ai-story-screen">
        <div class="section-label" style="color:rgba(255,255,255,0.5)">NARRATIVE</div>
        <h2 class="ni-title">AI Story</h2>
        <p class="ni-sub" style="margin-bottom:20px">Your neighbourhood through different eyes.</p>

        <div class="persona-row">
          ${PERSONAS.map(p => `
            <button class="persona-chip ${p.id === activePersna ? 'active' : ''}"
              data-persona="${p.id}" title="${p.label}">
              ${p.emoji}
            </button>
          `).join('')}
        </div>

        <div class="story-card">
          <div class="story-persona">
            ${PERSONAS.find(p => p.id === activePersna)?.emoji}
            <span>${PERSONAS.find(p => p.id === activePersna)?.label}</span>
          </div>
          <p class="story-text">${story}</p>
        </div>

        <div class="story-scores">
          ${Object.values(result.score?.categories || {}).map(cat => `
            <div class="story-score-chip" style="border-color:${categoryColor(cat.id)}22">
              <span>${categoryEmoji(cat.id)}</span>
              <span style="color:${categoryColor(cat.id)}">${Math.round(cat.score)}</span>
            </div>
          `).join('')}
        </div>
      </div>
    `;

    container.querySelectorAll('.persona-chip').forEach(btn => {
      btn.addEventListener('click', () => {
        activePersna = btn.dataset.persona;
        render();
      });
    });
  }

  render();
}
