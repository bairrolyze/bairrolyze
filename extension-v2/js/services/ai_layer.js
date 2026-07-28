/**
 * AI Layer — Future Integration Architecture
 *
 * This module defines the interface for AI-powered features.
 * Implementations can be swapped in without changing callers.
 * All methods are async and return null if not implemented.
 *
 * Usage:
 *   import { aiLayer } from '../services/ai_layer.js';
 *   const summary = await aiLayer.generateNeighborhoodSummary(result);
 *   if (summary) { ... } // null means "not yet implemented"
 *
 * To enable a real backend:
 *   Replace the `export const aiLayer = new AILayer()` line with:
 *   export const aiLayer = new OpenAILayer({ apiKey: ... });
 */

export class AILayer {
  /**
   * Generate a neighborhood summary from POI data.
   *
   * Future implementation: call OpenAI/Anthropic with a prompt that
   * includes the top amenities, scores, and address context.
   * Returns a 2-3 sentence human-readable summary.
   *
   * @param {object} result — full API result object
   * @returns {Promise<string|null>}
   */
  async generateNeighborhoodSummary(result) {
    return null;
  }

  /**
   * Score a property for investment potential (0-100).
   *
   * Future implementation: ML model trained on historical price data
   * correlated with amenity density, transit access, and development trends.
   *
   * @param {object} result — full API result object
   * @returns {Promise<{score: number, rationale: string}|null>}
   */
  async investmentScore(result) {
    return null;
  }

  /**
   * Generate a demand heatmap grid for an area.
   *
   * Future implementation: aggregate anonymised search history and
   * listing view counts across a grid, returning cells with demand intensity.
   *
   * @param {number} lat
   * @param {number} lng
   * @param {number} radiusKm
   * @returns {Promise<Array<{lat, lng, intensity}>>|null>}
   */
  async demandHeatmap(lat, lng, radiusKm) {
    return null;
  }

  /**
   * Calculate commute isochrones from a point.
   *
   * Future implementation: integrate OSRM or Valhalla routing API
   * to compute reachable area within N minutes by foot, bike, transit, car.
   *
   * @param {number} lat
   * @param {number} lng
   * @param {number} minutes — travel time budget
   * @param {'foot'|'bike'|'transit'|'car'} [mode='foot']
   * @returns {Promise<GeoJSON.Feature|null>}
   */
  async commuteIsochrone(lat, lng, minutes, mode = 'foot') {
    return null;
  }

  /**
   * Match buyer preferences to a property and return a detailed score.
   *
   * Future implementation: weighted scoring model that maps buyer
   * priorities (school proximity, transit, parks, etc.) onto the
   * property's actual amenity data.
   *
   * @param {object} result — full API result object
   * @param {object} preferences — { school, transit, hospital, park, shopping }
   * @returns {Promise<{pct: number, matched: number, total: number, reasons: string[]}|null>}
   */
  async buyerMatch(result, preferences) {
    return null;
  }

  /**
   * Recommend similar neighborhoods by DNA profile similarity.
   *
   * Future implementation: vector similarity search over pre-computed
   * neighborhood DNA embeddings (7-dim score vectors + amenity density).
   *
   * @param {object} result — full API result object
   * @returns {Promise<Array<{name, similarity, score, address}>>|null>}
   */
  async similarNeighborhoods(result) {
    return null;
  }
}

// Default no-op implementation — safe to use anywhere, returns null everywhere
export const aiLayer = new AILayer();

// ── Future replacements ────────────────────────────────────────────────────────
// Uncomment and implement one of the following when a backend is ready:
//
// import { OpenAILayer } from './ai_layer_openai.js';
// export const aiLayer = new OpenAILayer({ apiKey: chrome.storage... });
//
// import { AnthropicLayer } from './ai_layer_anthropic.js';
// export const aiLayer = new AnthropicLayer({ apiKey: ... });
