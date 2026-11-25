// The main screens of SuiteCRM still work with every installed extension.
// Each screen fails on: an uncaught JavaScript error, a server error (HTTP
// 5xx), a PHP error printed in the page, or a raw label key (LBL_…, LNK_…),
// the sign of a broken translation. The legacy screens (iframe) are checked
// too. Console errors that are not uncaught are listed, not failed: SuiteCRM
// logs some on its own.
import { test, expect, type Page } from '@playwright/test';

const user = process.env.ADMIN_USER ?? '';
const password = process.env.ADMIN_PASSWORD ?? '';

const RAW_LABEL = /\b(?:LBL|LNK|ERR|MSG|NTC)_[A-Z0-9_]{2,}\b/g;
const PHP_ERROR = /(?:Fatal error|Parse error|Warning|Notice|Deprecated):.{0,300}? on line \d+/g;

// Problems seen while a screen is open, reset by watch().
let problems: string[] = [];

function watch(page: Page): void {
  problems = [];
  page.on('pageerror', (error) => problems.push(`erreur JavaScript : ${error.message}`));
  page.on('response', (response) => {
    if (response.status() >= 500) {
      problems.push(`HTTP ${response.status()} : ${response.url()}`);
    }
  });
  page.on('console', (message) => {
    if (message.type() === 'error') {
      test.info().annotations.push({ type: 'console', description: message.text() });
    }
  });
}

async function login(page: Page): Promise<void> {
  await page.goto('/');
  await page.locator('input:not([type="password"]):not([type="hidden"])').first().fill(user);
  await page.locator('input[type="password"]').fill(password);
  await page.getByRole('button', { name: /se connecter|log in/i }).click();
  await expect(page).toHaveURL(/#\/home/, { timeout: 60_000 });
}

// Opens a screen and waits until SuiteCRM has stopped loading it.
async function open(page: Page, route: string): Promise<void> {
  await page.goto(route);
  await page.waitForLoadState('networkidle', { timeout: 60_000 }).catch(() => undefined);
}

// Checks the text of the page and of its legacy iframes, then the problems
// collected since the screen was opened.
async function expectClean(page: Page, screen: string): Promise<void> {
  const found = [...problems];
  for (const frame of page.frames()) {
    const text = await frame.locator('body').innerText({ timeout: 10_000 }).catch(() => '');
    for (const match of text.match(PHP_ERROR) ?? []) found.push(`erreur PHP : ${match}`);
    for (const match of new Set(text.match(RAW_LABEL) ?? [])) found.push(`libellé non traduit : ${match}`);
  }
  expect(found, `${screen} :\n  ${found.join('\n  ')}`).toEqual([]);
}

test.beforeEach(async ({ page }) => {
  test.skip(!user || !password, 'ADMIN_USER ou ADMIN_PASSWORD absent');
  await login(page);
  watch(page);
});

for (const [module, name] of [
  ['accounts', 'Comptes'],
  ['contacts', 'Contacts'],
  ['opportunities', 'Affaires'],
] as const) {
  test(`${name} : liste`, async ({ page }) => {
    await open(page, `/#/${module}`);
    await expect(page.locator('table').first()).toBeVisible({ timeout: 30_000 });
    await expectClean(page, `liste des ${name}`);
  });

  test(`${name} : fiche`, async ({ page }) => {
    await open(page, `/#/${module}`);
    const link = page.locator(`a[href*="/${module}/record/"]`).first();
    const exists = await link
      .waitFor({ state: 'visible', timeout: 15_000 })
      .then(() => true, () => false);
    test.skip(!exists, `aucun enregistrement dans ${name} : lancer « make db@seed »`);

    const title = (await link.innerText()).trim();
    await link.click();
    await expect(page).toHaveURL(new RegExp(`/${module}/record/`));
    await page.waitForLoadState('networkidle', { timeout: 60_000 }).catch(() => undefined);
    await expect(page.getByText(title, { exact: true }).first()).toBeVisible({ timeout: 30_000 });
    await expectClean(page, `fiche ${name}`);
  });

  test(`${name} : création`, async ({ page }) => {
    await open(page, `/#/${module}/edit`);
    await expect(page.getByRole('button', { name: /sauvegarder|enregistrer|save/i }).first()).toBeVisible({ timeout: 30_000 });
    await expectClean(page, `création ${name}`);
  });
}

test('Administration', async ({ page }) => {
  await open(page, '/#/administration');
  await expect(page.getByText(/paramètres système|system settings/i).filter({ visible: true }).first()).toBeVisible({ timeout: 30_000 });
  await expectClean(page, 'Administration');
});

test('Chargeur de module', async ({ page }) => {
  // The route is case-sensitive: the legacy action is UpgradeWizard.
  await open(page, '/#/administration/UpgradeWizard?view=module');
  await expect(
    page.frameLocator('iframe').first().getByText(/chargeur de module|module loader/i).first(),
  ).toBeVisible({ timeout: 30_000 });
  await expectClean(page, 'Chargeur de module');
});
