// Shared mock data used across all test specs

export const MOCK_RESULT = {
  id: 'test-result-001',
  analyzed_at: new Date().toISOString(),
  address: {
    display_name: 'Rua Augusta 42, Lisbon, Portugal',
    lat: 38.7098,
    lng: -9.1395,
    district: 'Santa Maria Maior',
    city: 'Lisbon',
    postal_code: '1100-053',
  },
  score: {
    overall: 82,
    categories: {
      transportation: {
        id: 'transportation', label: 'Transportation', score: 91, count: 15,
        closest: { name: 'Baixa-Chiado', type: 'subway_entrance', distance_meters: 120, walking_minutes: 2 },
      },
      education: {
        id: 'education', label: 'Education', score: 68, count: 8,
        closest: { name: 'Escola Básica', type: 'school', distance_meters: 450, walking_minutes: 6 },
      },
      healthcare: {
        id: 'healthcare', label: 'Healthcare', score: 65, count: 5,
        closest: { name: 'Farmácia Central', type: 'pharmacy', distance_meters: 200, walking_minutes: 3 },
      },
      shopping: {
        id: 'shopping', label: 'Shopping', score: 96, count: 30,
        closest: { name: 'Mercado da Baixa', type: 'marketplace', distance_meters: 80, walking_minutes: 1 },
      },
      safety: {
        id: 'safety', label: 'Safety', score: 72, count: 3,
        closest: { name: 'PSP Lisboa', type: 'police', distance_meters: 600, walking_minutes: 8 },
      },
      religion: {
        id: 'religion', label: 'Community', score: 60, count: 4,
        closest: { name: 'Igreja de São Nicolau', type: 'place_of_worship', distance_meters: 150, walking_minutes: 2 },
      },
      recreation: {
        id: 'recreation', label: 'Recreation', score: 77, count: 12,
        closest: { name: 'Praça do Comércio', type: 'park', distance_meters: 200, walking_minutes: 3 },
      },
    },
  },
  amenities: [
    { category: 'transportation', name: 'Baixa-Chiado', type: 'subway_entrance', distance_meters: 120, walking_minutes: 2 },
    { category: 'transportation', name: 'Cais do Sodré', type: 'train_station', distance_meters: 350, walking_minutes: 5 },
    { category: 'shopping', name: 'Mercado da Baixa', type: 'marketplace', distance_meters: 80, walking_minutes: 1 },
    { category: 'shopping', name: 'Supermercado Pingo Doce', type: 'supermarket', distance_meters: 180, walking_minutes: 2 },
    { category: 'shopping', name: 'Farmácia Barata', type: 'pharmacy', distance_meters: 220, walking_minutes: 3 },
    { category: 'recreation', name: 'Praça do Comércio', type: 'park', distance_meters: 200, walking_minutes: 3 },
    { category: 'recreation', name: 'Jardim da Cerca da Graça', type: 'park', distance_meters: 900, walking_minutes: 12 },
    { category: 'healthcare', name: 'Farmácia Central', type: 'pharmacy', distance_meters: 200, walking_minutes: 3 },
    { category: 'education', name: 'Escola Básica', type: 'school', distance_meters: 450, walking_minutes: 6 },
    { category: 'safety', name: 'PSP Lisboa', type: 'police', distance_meters: 600, walking_minutes: 8 },
    { category: 'religion', name: 'Igreja de São Nicolau', type: 'place_of_worship', distance_meters: 150, walking_minutes: 2 },
  ],
  ai_summary: 'Rua Augusta is one of Lisbon\'s most iconic pedestrian streets. Excellent public transport access with Baixa-Chiado metro just 2 minutes away. Outstanding retail density and a vibrant community atmosphere make this a top-scoring location for urban living.',
};

export const MOCK_HISTORY = [
  {
    id: 'hist-001',
    address: 'Rua Augusta 42, Lisbon, Portugal',
    addressObj: MOCK_RESULT.address,
    score: MOCK_RESULT.score,
    amenities: MOCK_RESULT.amenities,
    ai_summary: MOCK_RESULT.ai_summary,
    profile: 'default',
    analyzedAt: new Date(Date.now() - 1 * 60 * 60 * 1000).toISOString(),
  },
  {
    id: 'hist-002',
    address: 'Avenida da Liberdade 120, Lisbon',
    addressObj: { display_name: 'Avenida da Liberdade 120, Lisbon', lat: 38.7185, lng: -9.1434 },
    score: { overall: 75, categories: {} },
    amenities: [],
    ai_summary: null,
    profile: 'family',
    analyzedAt: new Date(Date.now() - 24 * 60 * 60 * 1000).toISOString(),
  },
  {
    id: 'hist-003',
    address: 'Príncipe Real, Lisbon',
    addressObj: { display_name: 'Príncipe Real, Lisbon', lat: 38.716, lng: -9.148 },
    score: { overall: 68, categories: {} },
    amenities: [],
    ai_summary: null,
    profile: 'professional',
    analyzedAt: new Date(Date.now() - 3 * 24 * 60 * 60 * 1000).toISOString(),
  },
];

export const MOCK_CACHE_KEY = `cache::rua augusta 42, lisbon, portugal::default`;

export const MOCK_SETTINGS = {
  profile: 'default',
  defaultCountry: 'PT',
  searchRadius: 2000,
  showAiSummary: true,
  backendUrl: 'http://localhost:8000',
};
