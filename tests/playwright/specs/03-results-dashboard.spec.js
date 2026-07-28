// Test: Results screen – Dashboard view, fresh analysis flow
import { test, expect } from '@playwright/test';
import { launchBrowser, openPopup, mockApiSuccess, mockApiError, stopServer } from '../helpers/launch.js';
import { MOCK_HISTORY, MOCK_RESULT, MOCK_SETTINGS } from '../helpers/mock-data.js';

let browser;

test.beforeAll(async () => {
  browser = await launchBrowser();
});

test.afterAll(async () => {
  await browser.close();
  await stopServer();
});

// Helper: open popup already at the results dashboard
async function resultsPage() {
  const page = await openPopup(browser, { history: MOCK_HISTORY, settings: MOCK_SETTINGS });
  await page.locator('.history-tile').first().click();
  await expect(page.locator('#screen-results')).toHaveClass(/active/, { timeout: 5000 });
  await page.locator('#btn-view-dash').click();
  return page;
}

// ── Results header ────────────────────────────────────────────────────────────

test('results header shows address', async () => {
  const page = await resultsPage();
  await expect(page.locator('#results-address')).not.toBeEmpty();
  await page.close();
});

test('view toggle buttons are present', async () => {
  const page = await resultsPage();
  await expect(page.locator('#btn-view-dash')).toBeVisible();
  await expect(page.locator('#btn-view-ni')).toBeVisible();
  await page.close();
});

test('Dashboard tab is active by default', async () => {
  const page = await resultsPage();
  await expect(page.locator('#results-dash')).toHaveClass(/active/);
  await expect(page.locator('#btn-view-dash')).toHaveClass(/active/);
  await page.close();
});

test('Neighborhood toggle switches to NI view', async () => {
  const page = await resultsPage();
  await page.locator('#btn-view-ni').click();
  await expect(page.locator('#results-ni')).toHaveClass(/active/);
  await expect(page.locator('#results-dash')).not.toHaveClass(/active/);
  await page.close();
});

test('Dashboard toggle switches back from NI view', async () => {
  const page = await resultsPage();
  await page.locator('#btn-view-ni').click();
  await page.locator('#btn-view-dash').click();
  await expect(page.locator('#results-dash')).toHaveClass(/active/);
  await page.close();
});

// ── Dashboard content ─────────────────────────────────────────────────────────

test('score ring SVG is visible', async () => {
  const page = await resultsPage();
  await expect(page.locator('#results-dash .ring-svg')).toBeVisible();
  await page.close();
});

test('overall score renders correctly', async () => {
  const page = await resultsPage();
  const score = String(Math.round(MOCK_HISTORY[0].score.overall));
  // Scope to dashboard view to avoid strict mode violation (NI also has .ring-score)
  await expect(page.locator('#results-dash .ring-score')).toHaveText(score);
  await page.close();
});

test('address block is visible', async () => {
  const page = await resultsPage();
  await expect(page.locator('#results-dash .dash-address-block').first()).toBeVisible();
  await page.close();
});

test('dashboard has rendered child content', async () => {
  const page = await resultsPage();
  const count = await page.locator('#dash-content').evaluate(el => el.children.length);
  expect(count).toBeGreaterThan(0);
  await page.close();
});

test('back button returns to home screen', async () => {
  const page = await resultsPage();
  await page.locator('#btn-results-back').click();
  await expect(page.locator('#screen-home')).toHaveClass(/active/);
  await page.close();
});

// ── Fresh analysis via API ────────────────────────────────────────────────────

test('fresh analysis shows loading screen then results on API success', async () => {
  const page = await openPopup(browser, { settings: MOCK_SETTINGS });
  await mockApiSuccess(page, MOCK_RESULT);
  await page.locator('#address-input').fill('Rua Augusta 42, Lisbon, Portugal');
  await page.locator('#analyze-btn').click();
  await expect(page.locator('#screen-loading')).toHaveClass(/active/, { timeout: 5000 });
  await expect(page.locator('#screen-results')).toHaveClass(/active/, { timeout: 30000 });
  await page.close();
});

test('after fresh analysis result header shows analyzed address', async () => {
  const page = await openPopup(browser, { settings: MOCK_SETTINGS });
  await mockApiSuccess(page, MOCK_RESULT);
  await page.locator('#address-input').fill('Rua Augusta 42, Lisbon, Portugal');
  await page.locator('#analyze-btn').click();
  await expect(page.locator('#screen-results')).toHaveClass(/active/, { timeout: 30000 });
  await expect(page.locator('#results-address')).toContainText('Rua Augusta');
  await page.close();
});

test('after fresh analysis result is saved to history', async () => {
  const page = await openPopup(browser, { settings: MOCK_SETTINGS });
  await mockApiSuccess(page, MOCK_RESULT);
  await page.locator('#address-input').fill('Rua Augusta 42, Lisbon, Portugal');
  await page.locator('#analyze-btn').click();
  await expect(page.locator('#screen-results')).toHaveClass(/active/, { timeout: 30000 });
  const storage = await page.evaluate(() => window.__dumpStorage());
  expect(storage.history?.length ?? 0).toBeGreaterThan(0);
  await page.close();
});

test('API error returns user to home screen', async () => {
  const page = await openPopup(browser, { settings: MOCK_SETTINGS });
  await mockApiError(page, 500, 'Internal server error');
  await page.locator('#address-input').fill('Bad Address Test');
  await page.locator('#analyze-btn').click();
  await expect(page.locator('#screen-home')).toHaveClass(/active/, { timeout: 20000 });
  await page.close();
});
