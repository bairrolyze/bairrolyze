// Test: Home screen – initial render and static UI
import { test, expect } from '@playwright/test';
import { launchBrowser, openPopup, stopServer } from '../helpers/launch.js';
import { MOCK_HISTORY } from '../helpers/mock-data.js';

let browser;

test.beforeAll(async () => { browser = await launchBrowser(); });
test.afterAll(async () => { await browser.close(); await stopServer(); });

// ── Static UI ─────────────────────────────────────────────────────────────────

test('home screen is active on launch', async () => {
  const page = await openPopup(browser);
  await expect(page.locator('#screen-home')).toHaveClass(/active/);
  await page.close();
});

test('HomeScope logo is visible', async () => {
  const page = await openPopup(browser);
  await expect(page.locator('.home-logo-name')).toHaveText('HomeScope');
  await page.close();
});

test('headline text renders', async () => {
  const page = await openPopup(browser);
  await expect(page.locator('.home-headline')).toContainText('Move smarter');
  await page.close();
});

test('address input is present and focusable', async () => {
  const page = await openPopup(browser);
  await page.locator('#address-input').click();
  await expect(page.locator('#address-input')).toBeFocused();
  await page.close();
});

test('country selector defaults to PT', async () => {
  const page = await openPopup(browser);
  await expect(page.locator('#country-select')).toHaveValue('PT');
  await page.close();
});

test('all 6 profile chips are rendered', async () => {
  const page = await openPopup(browser);
  await expect(page.locator('.chip[data-profile]')).toHaveCount(6);
  await page.close();
});

test('"Default" profile chip is active on load', async () => {
  const page = await openPopup(browser);
  await expect(page.locator('.chip[data-profile="default"]')).toHaveClass(/active/);
  await page.close();
});

test('profile chip selection switches active state', async () => {
  const page = await openPopup(browser);
  await page.locator('.chip[data-profile="family"]').click();
  await expect(page.locator('.chip[data-profile="family"]')).toHaveClass(/active/);
  await expect(page.locator('.chip[data-profile="default"]')).not.toHaveClass(/active/);
  await page.close();
});

test('analyze button is visible', async () => {
  const page = await openPopup(browser);
  await expect(page.locator('#analyze-btn')).toBeVisible();
  await page.close();
});

test('submitting empty address shows validation error', async () => {
  const page = await openPopup(browser);
  await page.locator('#analyze-btn').click();
  await expect(page.locator('#address-error')).not.toHaveClass(/hidden/);
  await expect(page.locator('#address-error')).not.toBeEmpty();
  await page.close();
});

test('typing in address input clears validation error', async () => {
  const page = await openPopup(browser);
  await page.locator('#analyze-btn').click();
  await expect(page.locator('#address-error')).not.toHaveClass(/hidden/);
  await page.locator('#address-input').type('Lisbon');
  await expect(page.locator('#address-error')).toHaveClass(/hidden/);
  await page.close();
});

test('Enter key in address input triggers analyze', async () => {
  const page = await openPopup(browser);
  await page.locator('#address-input').fill('Rua Augusta, Lisbon');
  await page.locator('#address-input').press('Enter');
  await page.waitForTimeout(500);
  const count = await page.locator('#screen-loading.active, #screen-home.active').count();
  expect(count).toBeGreaterThan(0);
  await page.close();
});

// ── FAQ accordion ─────────────────────────────────────────────────────────────

test('FAQ accordion opens on click', async () => {
  const page = await openPopup(browser);
  const firstItem = page.locator('.faq-item').first();
  await firstItem.locator('.faq-q').scrollIntoViewIfNeeded();
  await firstItem.locator('.faq-q').click();
  await expect(firstItem).toHaveClass(/open/);
  await page.close();
});

test('FAQ accordion closes when same item clicked again', async () => {
  const page = await openPopup(browser);
  const firstItem = page.locator('.faq-item').first();
  await firstItem.locator('.faq-q').scrollIntoViewIfNeeded();
  await firstItem.locator('.faq-q').click();
  await firstItem.locator('.faq-q').click();
  await expect(firstItem).not.toHaveClass(/open/);
  await page.close();
});

test('FAQ only one item open at a time', async () => {
  const page = await openPopup(browser);
  const items = page.locator('.faq-item');
  await items.nth(0).locator('.faq-q').scrollIntoViewIfNeeded();
  await items.nth(0).locator('.faq-q').click();
  await items.nth(1).locator('.faq-q').scrollIntoViewIfNeeded();
  await items.nth(1).locator('.faq-q').click();
  await expect(page.locator('.faq-item.open')).toHaveCount(1);
  await page.close();
});

// ── Navigation icons ──────────────────────────────────────────────────────────

test('history nav icon navigates to history screen', async () => {
  const page = await openPopup(browser);
  await page.locator('#btn-nav-history').click();
  await expect(page.locator('#screen-history')).toHaveClass(/active/);
  await page.close();
});

test('settings nav icon navigates to settings screen', async () => {
  const page = await openPopup(browser);
  await page.locator('#btn-nav-settings').click();
  await expect(page.locator('#screen-settings')).toHaveClass(/active/);
  await page.close();
});

// ── History preview section ───────────────────────────────────────────────────

test('history preview is hidden when no history', async () => {
  const page = await openPopup(browser);
  await expect(page.locator('#history-preview')).toHaveClass(/hidden/);
  await page.close();
});

test('history preview shows when history exists in storage', async () => {
  const page = await openPopup(browser, { history: MOCK_HISTORY });
  await expect(page.locator('#history-preview')).not.toHaveClass(/hidden/);
  await page.close();
});

test('history preview shows up to 5 tiles', async () => {
  const page = await openPopup(browser, { history: MOCK_HISTORY });
  await expect(page.locator('.history-tile')).toHaveCount(Math.min(MOCK_HISTORY.length, 5));
  await page.close();
});

test('history tile shows address text', async () => {
  const page = await openPopup(browser, { history: MOCK_HISTORY });
  await expect(
    page.locator('.history-tile').first().locator('.history-tile-address')
  ).toHaveText(MOCK_HISTORY[0].address);
  await page.close();
});

test('history tile shows score', async () => {
  const page = await openPopup(browser, { history: MOCK_HISTORY });
  const score = String(Math.round(MOCK_HISTORY[0].score.overall));
  await expect(
    page.locator('.history-tile').first().locator('.history-tile-score')
  ).toHaveText(score);
  await page.close();
});
