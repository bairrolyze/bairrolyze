// Test: Settings screen
import { test, expect } from '@playwright/test';
import { launchBrowser, openPopup, stopServer } from '../helpers/launch.js';
import { MOCK_SETTINGS } from '../helpers/mock-data.js';

let browser;

test.beforeAll(async () => { browser = await launchBrowser(); });
test.afterAll(async () => { await browser.close(); await stopServer(); });

async function settingsPage() {
  const page = await openPopup(browser, { settings: MOCK_SETTINGS });
  await page.locator('#btn-nav-settings').click();
  await expect(page.locator('#screen-settings')).toHaveClass(/active/);
  return page;
}

test('settings screen renders content', async () => {
  const page = await settingsPage();
  await expect(page.locator('#screen-settings')).not.toBeEmpty();
  await page.close();
});

test('settings has a back button', async () => {
  const page = await settingsPage();
  await expect(page.locator('#screen-settings .btn-back').first()).toBeVisible();
  await page.close();
});

test('settings back button returns to home', async () => {
  const page = await settingsPage();
  await page.locator('#screen-settings .btn-back').first().click();
  await expect(page.locator('#screen-home')).toHaveClass(/active/);
  await page.close();
});

test('settings: backend URL field is visible', async () => {
  const page = await settingsPage();
  await expect(page.locator('#backend-url, input[placeholder*="http"], input[name*="backend"]').first()).toBeVisible();
  await page.close();
});

test('settings: default country selector is visible', async () => {
  const page = await settingsPage();
  await expect(page.locator('#screen-settings select').first()).toBeVisible();
  await page.close();
});

test('settings: search radius control is visible', async () => {
  const page = await settingsPage();
  await expect(page.locator('#search-radius, input[type="range"], input[type="number"]').first()).toBeVisible();
  await page.close();
});

test('settings: save button is present and clickable without crashing', async () => {
  const page = await settingsPage();
  await page.locator('#screen-settings button:has-text("Save")').first().click();
  await expect(page.locator('#screen-settings')).toHaveClass(/active/);
  await page.close();
});

test('settings: backend URL change persists to storage on save', async () => {
  const page = await settingsPage();
  const urlInput = page.locator('#backend-url, input[placeholder*="http"]').first();
  await urlInput.clear();
  await urlInput.fill('http://localhost:9999');
  await page.locator('#screen-settings button:has-text("Save")').first().click();
  const stored = await page.evaluate(() => window.__dumpStorage());
  expect(stored.settings?.backendUrl).toBe('http://localhost:9999');
  await page.close();
});
