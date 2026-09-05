import { expect, test } from '@playwright/test';
import { primaryButtonBg } from './helpers';

test.describe('Evaluation 005 — AC-5 (interaction feedback)', () => {
  test('keyboard focus-visible states are visible', async ({ page }) => {
    await page.setViewportSize({ width: 1280, height: 800 });
    await page.goto('/');
    await expect(page.getByRole('heading', { name: 'Create Order' })).toBeVisible();
    await expect(page.locator('#product')).toBeVisible();

    // Tab 1 -> brand link, 2 -> product select, 3 -> quantity, 4 -> Add button.
    for (let i = 0; i < 4; i++) {
      await page.keyboard.press('Tab');
    }
    const focused = await page.evaluate(() => {
      const el = document.activeElement as HTMLElement;
      const s = getComputedStyle(el);
      return {
        tag: el.tagName,
        text: (el.textContent || '').trim(),
        outlineWidth: s.outlineWidth,
        outlineStyle: s.outlineStyle,
        outlineColor: s.outlineColor,
        outlineOffset: s.outlineOffset,
      };
    });
    expect(focused.tag).toBe('BUTTON');
    expect(focused.text).toBe('Add');
    expect(focused.outlineStyle).toBe('solid');
    expect(focused.outlineWidth).toBe('2px');
    expect(focused.outlineColor).toBe('rgb(0, 113, 227)');
    expect(focused.outlineOffset).toBe('2px');
  });

  test('focus ring on form controls and transitions are present', async ({ page }) => {
    await page.setViewportSize({ width: 1280, height: 800 });
    await page.goto('/');
    await expect(page.locator('#product')).toBeVisible();

    // Focus the product select (2 tabs).
    await page.keyboard.press('Tab');
    await page.keyboard.press('Tab');
    const selectState = await page.evaluate(() => {
      const el = document.activeElement as HTMLElement;
      const s = getComputedStyle(el);
      return { tag: el.tagName, id: el.id, boxShadow: s.boxShadow, transition: s.transition };
    });
    expect(selectState.tag).toBe('SELECT');
    expect(selectState.id).toBe('product');
    expect(selectState.transition).toContain('border-color');
    expect(selectState.transition).toContain('box-shadow');
    // A focus ring must be visible once the 0.2s transition settles (accent
    // tinted box-shadow spread), not none.
    await expect
      .poll(async () =>
        page.evaluate(() => getComputedStyle(document.activeElement as HTMLElement).boxShadow),
      )
      .toMatch(/0,\s*113,\s*227/);

    // Buttons transition their background/transform/opacity.
    const buttonTransition = await page.evaluate(
      () => getComputedStyle(document.querySelector('button.secondary')!).transition,
    );
    expect(buttonTransition).toContain('background-color');
    expect(buttonTransition).toContain('transform');

    // Links transition their color.
    const linkTransition = await page.evaluate(
      () => getComputedStyle(document.querySelector('.brand')!).transition,
    );
    expect(linkTransition).toContain('color');
  });

  test('disabled and loading states during order submission and cancellation', async ({ page }) => {
    await page.setViewportSize({ width: 1280, height: 800 });
    await page.goto('/');

    // Initially, with an empty cart, the Create Order button is disabled.
    const createBtn = page.getByRole('button', { name: 'Create Order' });
    await expect(createBtn).toBeDisabled();
    const disabled = await page.evaluate(() => {
      const b = [...document.querySelectorAll('button')].find((x) => x.textContent.trim() === 'Create Order')!;
      const s = getComputedStyle(b);
      return { bg: s.backgroundColor, color: s.color, opacity: s.opacity };
    });
    expect(disabled.bg).toBe('rgb(210, 210, 215)');
    expect(disabled.color).toBe('rgb(134, 134, 139)');
    expect(disabled.opacity).toBe('0.6');

    // Add an item -> the button becomes enabled with the accent colour.
    await page.locator('#product').selectOption({ index: 0 });
    await page.locator('#quantity').fill('1');
    await page.getByRole('button', { name: 'Add' }).click();
    await expect(createBtn).toBeEnabled();
    await expect.poll(primaryButtonBg(page, 'Create Order')).toBe('rgb(0, 113, 227)');

    // Delay the real create request so we can capture the loading/disabled state.
    await page.route('**/api/orders', async (route) => {
      if (route.request().method() === 'POST') {
        await new Promise((r) => setTimeout(r, 600));
      }
      await route.continue();
    });
    await createBtn.click();
    await expect(page.getByRole('button', { name: 'Creating...' })).toBeDisabled();
    // While in-flight, the button falls back to the disabled palette.
    await expect.poll(primaryButtonBg(page, 'Creating...')).toBe('rgb(210, 210, 215)');

    // Navigate to the detail page.
    await expect(page).toHaveURL(/\/orders\//);
    await expect(page.locator('.status-badge')).toHaveText('PENDING');

    // Delay the real cancel request and capture the loading/disabled state.
    await page.route('**/api/orders/*/cancel', async (route) => {
      await new Promise((r) => setTimeout(r, 600));
      await route.continue();
    });
    await page.getByRole('button', { name: 'Cancel Order' }).click();
    await expect(page.getByRole('button', { name: 'Cancelling...' })).toBeDisabled();
    await expect(page.locator('.status-badge')).toHaveText('CANCELLED');
  });
});
