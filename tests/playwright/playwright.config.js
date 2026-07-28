// @ts-check
import { defineConfig } from '@playwright/test';

export default defineConfig({
  testDir: './specs',
  timeout: 30_000,
  retries: 0,
  workers: 1, // serial: each spec gets its own page but shared server
  reporter: [
    ['list'],
    ['html', { outputFolder: 'playwright-report', open: 'never' }],
    ['json', { outputFile: 'playwright-report/results.json' }],
  ],
  use: {
    headless: false,
    viewport: { width: 420, height: 680 },
    screenshot: 'only-on-failure',
    video: 'off',
  },
});
