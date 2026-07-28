// Chrome extension test helpers using HTTP server + chrome API mock
import { chromium } from '@playwright/test';
import http from 'http';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import { CHROME_MOCK_SCRIPT } from './chrome-mock.js';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
export const EXTENSION_PATH = path.resolve(__dirname, '../../../extension');

// ── Simple static file server for the extension directory ─────────────────────

const MIME = {
  '.html': 'text/html',
  '.js':   'application/javascript',
  '.css':  'text/css',
  '.json': 'application/json',
  '.png':  'image/png',
  '.svg':  'image/svg+xml',
};

let _server = null;
let _port   = null;

export async function startServer() {
  if (_server) return _port;
  return new Promise((resolve, reject) => {
    _server = http.createServer((req, res) => {
      const url = req.url.split('?')[0];
      const filePath = path.join(EXTENSION_PATH, url === '/' ? '/popup.html' : url);
      fs.readFile(filePath, (err, data) => {
        if (err) { res.writeHead(404); res.end('Not found: ' + filePath); return; }
        const ext = path.extname(filePath);
        res.writeHead(200, {
          'Content-Type': MIME[ext] || 'application/octet-stream',
          'Access-Control-Allow-Origin': '*',
        });
        res.end(data);
      });
    });
    _server.listen(0, '127.0.0.1', () => { _port = _server.address().port; resolve(_port); });
    _server.on('error', reject);
  });
}

export async function stopServer() {
  if (!_server) return;
  await new Promise(r => _server.close(r));
  _server = null; _port = null;
}

// ── Open a fresh popup page with optional pre-seeded storage ──────────────────
// seed data is injected via addInitScript BEFORE any page modules load,
// so chrome.storage.local already has the data when popup.js calls getHistory().

export async function openPopup(browser, seedData = {}) {
  const port = await startServer();
  const page = await browser.newPage();

  // 1) Inject seed data into a global BEFORE the chrome mock runs
  await page.addInitScript((data) => { window.__seed = data; }, seedData);
  // 2) Inject chrome mock (reads window.__seed to populate the storage)
  await page.addInitScript(CHROME_MOCK_SCRIPT);

  await page.goto(`http://127.0.0.1:${port}/popup.html`, { waitUntil: 'networkidle' });
  return page;
}

export async function launchBrowser() {
  return chromium.launch({ headless: false });
}

// Reopen popup with new seed data (closes old page, opens new one with pre-seeded storage)
export async function seedStorage(page, browser, seedData) {
  const url = page.url();
  await page.close();
  const newPage = await browser.newPage();
  await newPage.addInitScript((data) => { window.__seed = data; }, seedData);
  await newPage.addInitScript(CHROME_MOCK_SCRIPT);
  await newPage.goto(url, { waitUntil: 'networkidle' });
  return newPage;
}

// Clear storage and reopen
export async function clearStorage(page, browser) {
  return seedStorage(page, browser, {});
}

// ── API mock (intercept fetch calls to localhost:8000) ────────────────────────

export async function mockApiSuccess(page, payload) {
  await page.route('**/api/v1/analyze', async route => {
    await route.fulfill({
      status: 200,
      contentType: 'application/json',
      body: JSON.stringify(payload),
    });
  });
}

export async function mockApiError(page, status = 500, message = 'Server error') {
  await page.route('**/api/v1/analyze', async route => {
    await route.fulfill({ status, contentType: 'application/json', body: JSON.stringify({ detail: message }) });
  });
}
