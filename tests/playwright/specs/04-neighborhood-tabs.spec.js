// Test: Neighborhood Intelligence – 5 tabs + Life Radius + DNA interactivity
import { test, expect } from '@playwright/test';
import { launchBrowser, openPopup, stopServer } from '../helpers/launch.js';
import { MOCK_HISTORY, MOCK_SETTINGS } from '../helpers/mock-data.js';

let browser;

test.beforeAll(async () => { browser = await launchBrowser(); });
test.afterAll(async () => { await browser.close(); await stopServer(); });

// Helper: page already at NI view
async function niPage() {
  const page = await openPopup(browser, { history: MOCK_HISTORY, settings: MOCK_SETTINGS });
  await page.locator('.history-tile').first().click();
  await expect(page.locator('#screen-results')).toHaveClass(/active/, { timeout: 5000 });
  await page.locator('#btn-view-ni').click();
  await expect(page.locator('#results-ni')).toHaveClass(/active/);
  return page;
}

// ── Tab navigation ────────────────────────────────────────────────────────────

test('DNA tab is active by default', async () => {
  const page = await niPage();
  await expect(page.locator('.ni-tab[data-tab="dna"]')).toHaveClass(/active/);
  await page.close();
});

test('all 5 neighborhood tabs are rendered', async () => {
  const page = await niPage();
  for (const id of ['dna', 'life-radius', 'time-machine', 'ai-story', 'future-score']) {
    await expect(page.locator(`.ni-tab[data-tab="${id}"]`)).toBeVisible();
  }
  await page.close();
});

// ── DNA tab ───────────────────────────────────────────────────────────────────

test('DNA tab: radar canvas renders', async () => {
  const page = await niPage();
  await expect(page.locator('#radar-canvas')).toBeVisible({ timeout: 3000 });
  await page.close();
});

test('DNA tab: score ring shows correct value', async () => {
  const page = await niPage();
  await expect(page.locator('#results-ni .ring-score')).toHaveText(
    String(Math.round(MOCK_HISTORY[0].score.overall))
  );
  await page.close();
});

test('DNA tab: legend rows rendered for each category', async () => {
  const page = await niPage();
  expect(await page.locator('.dna-legend-row').count()).toBeGreaterThan(0);
  await page.close();
});

test('DNA tab: clicking legend row marks it active', async () => {
  const page = await niPage();
  await page.locator('.dna-legend-row').first().click();
  await expect(page.locator('.dna-legend-row').first()).toHaveClass(/active/);
  await page.close();
});

test('DNA tab: clicking legend row expands detail card', async () => {
  const page = await niPage();
  await page.locator('.dna-legend-row').first().click();
  await expect(page.locator('.dna-detail-card').first()).toBeVisible({ timeout: 2000 });
  await page.close();
});

test('DNA tab: detail card shows numeric score and count', async () => {
  const page = await niPage();
  await page.locator('.dna-legend-row').first().click();
  await expect(page.locator('.dna-detail-num').first()).not.toBeEmpty();
  await page.close();
});

test('DNA tab: detail card shows closest place section', async () => {
  const page = await niPage();
  await page.locator('.dna-legend-row').first().click();
  await expect(page.locator('.dna-cat-detail[style*="block"] .dna-detail-closest')).toBeVisible();
  await page.close();
});

test('DNA tab: clicking same row collapses the card', async () => {
  const page = await niPage();
  const firstRow = page.locator('.dna-legend-row').first();
  await firstRow.click(); // open
  await firstRow.click(); // close
  await expect(firstRow).not.toHaveClass(/active/);
  await page.close();
});

test('DNA tab: only one detail card open at a time', async () => {
  const page = await niPage();
  await page.locator('.dna-legend-row').nth(0).click();
  await page.locator('.dna-legend-row').nth(1).click();
  await expect(page.locator('.dna-cat-detail[style*="block"]')).toHaveCount(1);
  await page.close();
});

// ── Life Radius tab ───────────────────────────────────────────────────────────

test('Life Radius: canvas renders', async () => {
  const page = await niPage();
  await page.locator('.ni-tab[data-tab="life-radius"]').click();
  await expect(page.locator('#lr-canvas')).toBeVisible({ timeout: 3000 });
  await page.close();
});

test('Life Radius: filter chips rendered', async () => {
  const page = await niPage();
  await page.locator('.ni-tab[data-tab="life-radius"]').click();
  expect(await page.locator('.lr-chip').count()).toBeGreaterThan(1);
  await page.close();
});

test('Life Radius: "All" chip active by default', async () => {
  const page = await niPage();
  await page.locator('.ni-tab[data-tab="life-radius"]').click();
  await expect(page.locator('.lr-chip[data-cat=""]')).toHaveClass(/active/);
  await page.close();
});

test('Life Radius: info bar shows place count', async () => {
  const page = await niPage();
  await page.locator('.ni-tab[data-tab="life-radius"]').click();
  await expect(page.locator('#lr-info-text')).toContainText('places');
  await page.close();
});

test('Life Radius: clicking category chip makes it active', async () => {
  const page = await niPage();
  await page.locator('.ni-tab[data-tab="life-radius"]').click();
  const catChip = page.locator('.lr-chip:not([data-cat=""])').first();
  await catChip.click();
  await expect(catChip).toHaveClass(/active/);
  await expect(page.locator('.lr-chip[data-cat=""]')).not.toHaveClass(/active/);
  await page.close();
});

test('Life Radius: category place list appears after filter chip click', async () => {
  const page = await niPage();
  await page.locator('.ni-tab[data-tab="life-radius"]').click();
  await page.locator('.lr-chip:not([data-cat=""])').first().click();
  await expect(page.locator('.lr-catlist-card')).toBeVisible({ timeout: 2000 });
  await page.close();
});

test('Life Radius: category list rows show name and distance', async () => {
  const page = await niPage();
  await page.locator('.ni-tab[data-tab="life-radius"]').click();
  await page.locator('.lr-chip:not([data-cat=""])').first().click();
  await expect(page.locator('.lr-catlist-row').first().locator('.lr-catlist-name')).not.toBeEmpty();
  await expect(page.locator('.lr-catlist-row').first().locator('.lr-catlist-dist')).not.toBeEmpty();
  await page.close();
});

test('Life Radius: clicking list row highlights it', async () => {
  const page = await niPage();
  await page.locator('.ni-tab[data-tab="life-radius"]').click();
  await page.locator('.lr-chip:not([data-cat=""])').first().click();
  const firstRow = page.locator('.lr-catlist-row').first();
  await firstRow.click();
  await expect(firstRow).toHaveClass(/active/);
  await page.close();
});

test('Life Radius: clicking active list row deselects it', async () => {
  const page = await niPage();
  await page.locator('.ni-tab[data-tab="life-radius"]').click();
  await page.locator('.lr-chip:not([data-cat=""])').first().click();
  const firstRow = page.locator('.lr-catlist-row').first();
  await firstRow.click();
  await firstRow.click();
  await expect(firstRow).not.toHaveClass(/active/);
  await page.close();
});

test('Life Radius: "All" chip clears category list', async () => {
  const page = await niPage();
  await page.locator('.ni-tab[data-tab="life-radius"]').click();
  await page.locator('.lr-chip:not([data-cat=""])').first().click();
  await expect(page.locator('.lr-catlist-card')).toBeVisible();
  await page.locator('.lr-chip[data-cat=""]').click();
  await expect(page.locator('#lr-cat-list')).toBeEmpty({ timeout: 2000 });
  await page.close();
});

test('Life Radius: canvas click does not crash the page', async () => {
  const page = await niPage();
  await page.locator('.ni-tab[data-tab="life-radius"]').click();
  const box = await page.locator('#lr-canvas').boundingBox();
  if (box) await page.mouse.click(box.x + box.width / 2, box.y + box.height / 2);
  await expect(page.locator('#lr-canvas')).toBeVisible();
  await page.close();
});

// ── Other tabs ────────────────────────────────────────────────────────────────

test('Time Machine tab: renders content without crash', async () => {
  const page = await niPage();
  await page.locator('.ni-tab[data-tab="time-machine"]').click();
  await page.waitForTimeout(500);
  expect(await page.locator('#ni-content').evaluate(el => el.children.length)).toBeGreaterThan(0);
  await page.close();
});

test('AI Story tab: renders content without crash', async () => {
  const page = await niPage();
  await page.locator('.ni-tab[data-tab="ai-story"]').click();
  await page.waitForTimeout(500);
  expect(await page.locator('#ni-content').evaluate(el => el.children.length)).toBeGreaterThan(0);
  await page.close();
});

test('Future Score tab: renders content without crash', async () => {
  const page = await niPage();
  await page.locator('.ni-tab[data-tab="future-score"]').click();
  await page.waitForTimeout(500);
  expect(await page.locator('#ni-content').evaluate(el => el.children.length)).toBeGreaterThan(0);
  await page.close();
});

// ── Tab state persistence ─────────────────────────────────────────────────────

test('NI tab selection persists when switching views and back', async () => {
  const page = await niPage();
  await page.locator('.ni-tab[data-tab="life-radius"]').click();
  await page.locator('#btn-view-dash').click();
  await page.locator('#btn-view-ni').click();
  await expect(page.locator('.ni-tab[data-tab="life-radius"]')).toHaveClass(/active/);
  await page.close();
});
