import AxeBuilder from '@axe-core/playwright';
import { expect, test } from '@playwright/test';
import { createOrderViaForm } from './helpers';

test.describe('Evaluation 005 — AC-6 (accessibility)', () => {
  test('light create page: roles, heading hierarchy, labels, a11y snapshot and no trap', async ({ page }) => {
    await page.setViewportSize({ width: 1280, height: 800 });
    await page.goto('/');
    await expect(page.getByRole('heading', { name: 'Create Order' })).toBeVisible();

    // Semantic landmarks.
    await expect(page.getByRole('banner')).toBeVisible();
    await expect(page.getByRole('main')).toBeVisible();

    // Labelled form controls.
    await expect(page.getByLabel('Product')).toBeVisible();
    await expect(page.getByLabel('Quantity')).toBeVisible();
    await expect(page.locator('#product')).toBeVisible();

    // Meaningful heading hierarchy: exactly one h1 before an h2.
    const headings = await page.evaluate(() =>
      [...document.querySelectorAll('h1, h2')].map((h) => ({ level: h.tagName, text: h.textContent })),
    );
    expect(headings).toEqual([
      { level: 'H1', text: 'Create Order' },
      { level: 'H2', text: 'Add Items' },
    ]);

    // Accessibility-tree snapshot must expose the semantic roles.
    const aria = await page.locator('body').ariaSnapshot();
    expect(aria).toContain('heading "Create Order"');
    expect(aria).toContain('main');
    expect(aria).toContain('button "Add"');
    expect(aria).toContain('combobox');

    // No keyboard trap: tabbing through every focusable control must move focus.
    const focusable = await page.evaluate(
      () =>
        [
          ...document.querySelectorAll(
            'a[href], button:not([disabled]), select, input, [tabindex]:not([tabindex="-1"])',
          ),
        ].map((el) => `${el.tagName}:${el.id || ((el as HTMLElement).textContent || '').trim()}`),
    );
    expect(focusable.length).toBeGreaterThanOrEqual(4);
    let prev = '';
    for (let i = 0; i < focusable.length; i++) {
      await page.keyboard.press('Tab');
      const cur = await page.evaluate(() => {
        const e = document.activeElement as HTMLElement;
        return e === document.body ? 'BODY' : `${e.tagName}:${e.id || (e.textContent || '').trim()}`;
      });
      expect(cur).not.toBe(prev); // focus must not be trapped on a single element
      prev = cur;
    }
    // After the last control, focus must move on (not stay trapped).
    await page.keyboard.press('Tab');
    const after = await page.evaluate(() => {
      const e = document.activeElement as HTMLElement;
      return e === document.body ? 'BODY' : `${e.tagName}:${e.id || (e.textContent || '').trim()}`;
    });
    expect(after).not.toBe(prev);

    // Axe: the light create page must have no accessibility violations.
    const results = await new AxeBuilder({ page }).analyze();
    expect(results.violations).toEqual([]);
  });

  test('order detail page passes axe in light and dark with correct hierarchy', async ({ page }) => {
    const orderId = await createOrderViaForm(page, { quantity: 1, productIndex: 0 });
    await expect(page).toHaveURL(new RegExp(`/orders/${orderId}`));
    await expect(page.locator('.status-badge')).toHaveText('PENDING');

    for (const scheme of ['light', 'dark'] as const) {
      await page.emulateMedia({ colorScheme: scheme });
      await page.goto(`/orders/${orderId}`);
      // Wait for the loaded order detail before reading headings (it starts in
      // a loading state with no h1).
      await expect(page.getByRole('heading', { level: 1 })).toBeVisible();

      const headings = await page.evaluate(() =>
        [...document.querySelectorAll('h1, h2')].map((h) => ({ level: h.tagName, text: h.textContent })),
      );
      expect(headings[0].level).toBe('H1');
      expect(headings[0].text).toContain('Order');
      expect(headings[1].level).toBe('H2');
      expect(headings[1].text).toBe('Order Items');

      // Table headers are semantically exposed.
      await expect(page.getByRole('columnheader', { name: 'Product' })).toBeVisible();
      await expect(page.getByRole('columnheader', { name: 'Line Total' })).toBeVisible();

      const results = await new AxeBuilder({ page }).analyze();
      expect(results.violations).toEqual([]);
    }

    // Restore inventory.
    await page.emulateMedia({ colorScheme: 'light' });
    await page.goto(`/orders/${orderId}`);
    await page.getByRole('button', { name: 'Cancel Order' }).click();
    await expect(page.locator('.status-badge')).toHaveText('CANCELLED');
  });

  test('dark create page passes axe (color contrast)', async ({ page }) => {
    await page.emulateMedia({ colorScheme: 'dark' });
    await page.setViewportSize({ width: 1280, height: 800 });
    await page.goto('/');
    await page.locator('#product').selectOption({ index: 0 });
    await page.locator('#quantity').fill('1');
    await page.getByRole('button', { name: 'Add' }).click();

    const results = await new AxeBuilder({ page }).analyze();
    const contrastFailures = results.violations.filter((v) => v.id === 'color-contrast');
    expect(results.violations).toEqual([]);
    expect(contrastFailures).toEqual([]);
  });
});
