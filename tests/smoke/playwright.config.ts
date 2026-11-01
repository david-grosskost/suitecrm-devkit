// Smoke tests shared by every SuiteCRM project (make test@smoke).
// Run inside the Playwright image; nothing is written to the project folder.
import { defineConfig } from '@playwright/test';

export default defineConfig({
  testDir: '.',
  outputDir: '/tmp/test-results',
  reporter: 'list',
  timeout: 60_000,
  retries: 1,
  use: {
    baseURL: process.env.BASE_URL,
    ignoreHTTPSErrors: process.env.IGNORE_HTTPS_ERRORS === '1',
    locale: 'fr-FR',
    trace: 'off',
  },
  projects: [{ name: 'chromium', use: { browserName: 'chromium' } }],
});
