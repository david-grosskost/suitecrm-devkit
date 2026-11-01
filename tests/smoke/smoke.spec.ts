// SuiteCRM answers, shows its login page and lets the administrator in.
// Run after every deployment: a failure means the instance is not usable.
import { test, expect } from '@playwright/test';

const user = process.env.ADMIN_USER ?? '';
const password = process.env.ADMIN_PASSWORD ?? '';

test('la page de connexion s’affiche', async ({ page }) => {
  await page.goto('/');

  await expect(page.locator('input[type="password"]')).toBeVisible();
  await expect(page.getByRole('button', { name: /se connecter|log in/i })).toBeVisible();
});

test('l’administrateur peut se connecter', async ({ page }) => {
  test.skip(!user || !password, 'ADMIN_USER ou ADMIN_PASSWORD absent');

  await page.goto('/');
  await page.locator('input:not([type="password"]):not([type="hidden"])').first().fill(user);
  await page.locator('input[type="password"]').fill(password);
  await page.getByRole('button', { name: /se connecter|log in/i }).click();

  await expect(page).toHaveURL(/#\/home/, { timeout: 30_000 });
});
