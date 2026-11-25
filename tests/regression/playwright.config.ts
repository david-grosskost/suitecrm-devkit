// Regression tests shared by every SuiteCRM project (make test@regression).
// Run inside the Playwright image; nothing is written to the project folder.
import { defineConfig } from '@playwright/test';

// Set by test@regression when Traefik runs on this machine: Chromium sends
// the site's name straight to it (it would resolve *.localhost to itself).
const hostResolverRules = process.env.HOST_RESOLVER_RULES;

export default defineConfig({
  testDir: '.',
  outputDir: '/tmp/test-results',
  reporter: 'list',
  // One screen after the other, as one administrator: SuiteCRM's first
  // requests after a repair rebuild its caches and are slow.
  workers: 1,
  timeout: 90_000,
  retries: 0,
  use: {
    baseURL: process.env.BASE_URL,
    ignoreHTTPSErrors: process.env.IGNORE_HTTPS_ERRORS === '1',
    locale: 'fr-FR',
    trace: 'off',
    launchOptions: hostResolverRules
      ? { args: [`--host-resolver-rules=${hostResolverRules}`] }
      : {},
  },
  projects: [{ name: 'chromium', use: { browserName: 'chromium' } }],
});
