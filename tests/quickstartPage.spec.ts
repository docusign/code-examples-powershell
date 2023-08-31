import { test, expect } from '@playwright/test';

test('has title', async ({ page }) => {
  await page.goto('https://developers.docusign.com/docs/esign-rest-api/quickstart/');

  // Expect a title "to contain" a substring.
  await expect(page).toHaveTitle(/Quickstart/);
});

test('get started link', async ({ page }) => {
  await page.goto('https://developers.docusign.com/docs/esign-rest-api/quickstart/');

  // Click the get started link.
  await page.getByRole('link', { name: 'Log in' }).click();

  // Expects page to have a heading with the name of Installation.
  await expect(page.getByRole('heading', { name: 'Log In' })).toBeVisible();
});
