import { expect, test } from '@playwright/test';
import { createOrderViaForm } from './helpers';

test.describe('Evaluation 005 — AC-8 (workflow + API contract preserved)', () => {
  for (const scheme of ['light', 'dark'] as const) {
    test(`AC-8 full order workflow (create -> view -> cancel -> invalid cancel 409) in ${scheme}`, async ({
      page,
      context,
    }) => {
      await page.emulateMedia({ colorScheme: scheme });

      // Create an order through the real UI.
      const orderId = await createOrderViaForm(page, { quantity: 1, productIndex: 0 });
      await expect(page).toHaveURL(new RegExp(`/orders/${orderId}`));
      await expect(page.locator('.status-badge')).toHaveText('PENDING');
      await expect(page.getByText(/Total:/)).toBeVisible();

      // Cancel the order from a second real page in the same context so the
      // backend transitions to CANCELLED while this page still renders PENDING.
      const pageB = await context.newPage();
      await pageB.emulateMedia({ colorScheme: scheme });
      await pageB.goto(`/orders/${orderId}`);
      await expect(pageB.locator('.status-badge')).toHaveText('PENDING');
      await pageB.getByRole('button', { name: 'Cancel Order' }).click();
      await expect(pageB.locator('.status-badge')).toHaveText('CANCELLED');
      await expect(pageB.getByRole('button', { name: 'Cancel Order' })).toHaveCount(0);
      await pageB.close();

      // This page still offers the cancel action; submitting it against the
      // already-cancelled order must yield a 409 conflict surfaced as error.
      await page.getByRole('button', { name: 'Cancel Order' }).click();
      await expect(page.locator('.error')).toBeVisible();
      await expect(page.locator('.error')).toContainText(/cannot be cancelled in state/i);
      // The order status remains unchanged in the rendered view (still PENDING).
      await expect(page.locator('.status-badge')).toHaveText('PENDING');
    });
  }

  test('AC-8 detail error state renders for a missing order', async ({ page }) => {
    await page.goto('/orders/00000000-0000-0000-0000-000000000000');
    await expect(page.locator('.error')).toBeVisible();
    await expect(page.getByRole('link', { name: 'Back to orders' })).toBeVisible();
  });

  test('AC-8 empty state renders a controlled empty product catalog', async ({ page }) => {
    // AC-8 / Regression Requirements: the empty state must keep working. Use a
    // controlled network response (real browser fetch interception, not a fake
    // DOM) to simulate an empty product catalog, then assert the rendered
    // empty state and that the form is not rendered.
    await page.route('**/api/products', (route) =>
      route.fulfill({ status: 200, contentType: 'application/json', body: '[]' }),
    );

    await page.goto('/');
    await expect(page.getByRole('heading', { name: 'Create Order' })).toBeVisible();

    // The empty-state message is rendered visibly.
    await expect(page.locator('.empty-state')).toBeVisible();
    await expect(page.locator('.empty-state')).toHaveText('No products available.');

    // The empty state replaces the form: no product/quantity controls, no Add
    // button, and no "Add Items" form heading are rendered.
    await expect(page.getByRole('heading', { name: 'Add Items' })).toHaveCount(0);
    await expect(page.locator('#product')).toHaveCount(0);
    await expect(page.locator('#quantity')).toHaveCount(0);
    await expect(page.getByRole('button', { name: 'Add' })).toHaveCount(0);
  });
});
