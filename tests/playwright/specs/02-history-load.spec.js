// Test: Loading cached results from history tiles — THE PRIMARY BUG REPORT
import { test, expect } from '@playwright/test';
import { launchBrowser, openPopup, mockApiSuccess, stopServer } from '../helpers/launch.js';
import { MOCK_HISTORY, MOCK_RESULT, MOCK_CACHE_KEY } from '../helpers/mock-data.js';

let browser;

test.beforeAll(async () => { browser = await launchBrowser(); });
test.afterAll(async () => { await browser.close(); await stopServer(); });

// Helper: open and return page with history seeded and history screen visible
async function historyTilePage() {
  return openPopup(browser, { history: MOCK_HISTORY });
}

// ── HOME SCREEN: clicking a recent history tile ───────────────────────────────

test('[BUG CHECK] clicking home history tile navigates to results screen', async () => {
  const page = await historyTilePage();
  await page.locator('.history-tile').first().click();
  await expect(page.locator('#screen-results')).toHaveClass(/active/, { timeout: 5000 });
  await page.close();
});

test('[BUG CHECK] results address header shows the history entry address', async () => {
  const page = await historyTilePage();
  await page.locator('.history-tile').first().click();
  await expect(page.locator('#screen-results')).toHaveClass(/active/, { timeout: 5000 });
  await expect(page.locator('#results-address')).toContainText('Rua Augusta');
  await page.close();
});

test('[BUG CHECK] dashboard tab is active by default when loading from history', async () => {
  const page = await historyTilePage();
  await page.locator('.history-tile').first().click();
  await expect(page.locator('#screen-results')).toHaveClass(/active/, { timeout: 5000 });
  await expect(page.locator('#results-dash')).toHaveClass(/active/);
  await page.close();
});

test('[BUG CHECK] dashboard renders the score ring with correct value', async () => {
  const page = await historyTilePage();
  await page.locator('.history-tile').first().click();
  await expect(page.locator('#screen-results')).toHaveClass(/active/, { timeout: 5000 });
  const expected = String(Math.round(MOCK_HISTORY[0].score.overall));
  // Scope to dashboard view; NI view also has .ring-score
  await expect(page.locator('#results-dash .ring-score')).toHaveText(expected, { timeout: 3000 });
  await page.close();
});

test('[BUG CHECK] dashboard content is not blank', async () => {
  const page = await historyTilePage();
  await page.locator('.history-tile').first().click();
  await expect(page.locator('#screen-results')).toHaveClass(/active/, { timeout: 5000 });
  const childCount = await page.locator('#dash-content').evaluate(el => el.children.length);
  expect(childCount).toBeGreaterThan(0);
  await page.close();
});

test('[BUG CHECK] neighborhood tab renders from history data (not blank)', async () => {
  const page = await historyTilePage();
  await page.locator('.history-tile').first().click();
  await expect(page.locator('#screen-results')).toHaveClass(/active/, { timeout: 5000 });
  await page.locator('#btn-view-ni').click();
  const childCount = await page.locator('#ni-content').evaluate(el => el.children.length);
  expect(childCount).toBeGreaterThan(0);
  await page.close();
});

test('[BUG CHECK] DNA radar canvas renders from history data', async () => {
  const page = await historyTilePage();
  await page.locator('.history-tile').first().click();
  await expect(page.locator('#screen-results')).toHaveClass(/active/, { timeout: 5000 });
  await page.locator('#btn-view-ni').click();
  await expect(page.locator('#radar-canvas')).toBeVisible({ timeout: 3000 });
  await page.close();
});

test('[BUG CHECK] life radius canvas renders from history data', async () => {
  const page = await historyTilePage();
  await page.locator('.history-tile').first().click();
  await expect(page.locator('#screen-results')).toHaveClass(/active/, { timeout: 5000 });
  await page.locator('#btn-view-ni').click();
  await page.locator('.ni-tab[data-tab="life-radius"]').click();
  await expect(page.locator('#lr-canvas')).toBeVisible({ timeout: 3000 });
  await page.close();
});

test('back button from results returns to home', async () => {
  const page = await historyTilePage();
  await page.locator('.history-tile').first().click();
  await expect(page.locator('#screen-results')).toHaveClass(/active/, { timeout: 5000 });
  await page.locator('#btn-results-back').click();
  await expect(page.locator('#screen-home')).toHaveClass(/active/);
  await page.close();
});

// ── HISTORY SCREEN ────────────────────────────────────────────────────────────

test('history screen tile click loads results', async () => {
  const page = await historyTilePage();
  await page.locator('#btn-nav-history').click();
  await expect(page.locator('#screen-history')).toHaveClass(/active/);
  await page.locator('.history-full-tile').first().click();
  await expect(page.locator('#screen-results')).toHaveClass(/active/, { timeout: 5000 });
  await page.close();
});

test('history screen shows all entries', async () => {
  const page = await historyTilePage();
  await page.locator('#btn-nav-history').click();
  await expect(page.locator('.history-full-tile')).toHaveCount(MOCK_HISTORY.length);
  await page.close();
});

test('history screen shows correct address and score', async () => {
  const page = await historyTilePage();
  await page.locator('#btn-nav-history').click();
  await expect(page.locator('.history-full-tile').first().locator('.hft-address'))
    .toHaveText(MOCK_HISTORY[0].address);
  await expect(page.locator('.history-full-tile').first().locator('.hft-score'))
    .toHaveText(String(Math.round(MOCK_HISTORY[0].score.overall)));
  await page.close();
});

test('delete button removes entry from list', async () => {
  const page = await historyTilePage();
  await page.locator('#btn-nav-history').click();
  const count = await page.locator('.history-full-tile').count();
  await page.locator('.hft-delete').first().click();
  await expect(page.locator('.history-full-tile')).toHaveCount(count - 1, { timeout: 3000 });
  await page.close();
});

test('clear all history shows empty state', async () => {
  const page = await historyTilePage();
  await page.locator('#btn-nav-history').click();
  page.once('dialog', d => d.accept());
  await page.locator('#btn-clear-all').click();
  await expect(page.locator('.empty-state')).toBeVisible({ timeout: 3000 });
  await expect(page.locator('.history-full-tile')).toHaveCount(0);
  await page.close();
});

test('history back button returns to home', async () => {
  const page = await historyTilePage();
  await page.locator('#btn-nav-history').click();
  await page.locator('#btn-back').click();
  await expect(page.locator('#screen-home')).toHaveClass(/active/);
  await page.close();
});

// ── Cache hit ─────────────────────────────────────────────────────────────────

test('[BUG CHECK] re-analyzing a cached address skips loading and shows results', async () => {
  const seed = { [MOCK_CACHE_KEY]: { payload: MOCK_RESULT, expiresAt: Date.now() + 86400000 } };
  const page = await openPopup(browser, seed);
  await page.locator('#address-input').fill('Rua Augusta 42, Lisbon, Portugal');
  await page.locator('.chip[data-profile="default"]').click();
  await page.locator('#analyze-btn').click();
  await expect(page.locator('#screen-results')).toHaveClass(/active/, { timeout: 5000 });
  await page.close();
});
