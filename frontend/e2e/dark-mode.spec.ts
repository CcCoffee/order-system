import { expect, test } from '@playwright/test';
import { contrastRatio, parseRgb, primaryButtonBg } from './helpers';

test.describe('Evaluation 005 — AC-4 (dark appearance)', () => {
  test('coherent dark background, legible text, preserved layout and accent', async ({ page }) => {
    await page.emulateMedia({ colorScheme: 'dark' });
    await page.setViewportSize({ width: 1280, height: 800 });
    await page.goto('/');
    await expect(page.getByRole('heading', { name: 'Create Order' })).toBeVisible();
    // Wait for the loaded products before reading the product select / controls
    // (they render only once listProducts() resolves in dark mode too).
    await expect(page.getByRole('heading', { name: 'Add Items' })).toBeVisible();

    // The OS-requested dark color-scheme must flip the coherent dark palette.
    const body = await page.evaluate(() => {
      const s = getComputedStyle(document.body);
      return {
        bg: s.backgroundColor,
        color: s.color,
        colorScheme: getComputedStyle(document.documentElement).colorScheme,
      };
    });
    expect(body.colorScheme).toBe('dark');
    expect(body.bg).toBe('rgb(0, 0, 0)');
    expect(body.color).toBe('rgb(245, 245, 247)');

    // Same layout/typography, dark legible text.
    expect(await page.evaluate(() => getComputedStyle(document.querySelector('h1')!).fontSize)).toBe(
      '48px',
    );
    expect(await page.evaluate(() => getComputedStyle(document.querySelector('h1')!).color)).toBe(
      'rgb(245, 245, 247)',
    );

    const card = await page.evaluate(() => {
      const s = getComputedStyle(document.querySelector('.card')!);
      return { bg: s.backgroundColor, border: s.border, radius: s.borderRadius };
    });
    expect(card.bg).toBe('rgb(29, 29, 31)');
    expect(card.border).toBe('1px solid rgb(66, 66, 69)');
    expect(card.radius).toBe('18px');

    const select = await page.evaluate(() => {
      const s = getComputedStyle(document.querySelector('#product')!);
      return { bg: s.backgroundColor, color: s.color };
    });
    expect(select.bg).toBe('rgb(29, 29, 31)');
    expect(select.color).toBe('rgb(245, 245, 247)');

    // Primary action keeps the Apple-blue accent with white text.
    await page.locator('#product').selectOption({ index: 0 });
    await page.locator('#quantity').fill('1');
    await page.getByRole('button', { name: 'Add' }).click();
    await expect.poll(primaryButtonBg(page, 'Create Order')).toBe('rgb(0, 113, 227)');
    const primaryColor = await page.evaluate(() => {
      const b = [...document.querySelectorAll('button')].find((x) => x.textContent.trim() === 'Create Order')!;
      return getComputedStyle(b).color;
    });
    const primaryBg = await page.evaluate(() => {
      const b = [...document.querySelectorAll('button')].find((x) => x.textContent.trim() === 'Create Order')!;
      return getComputedStyle(b).backgroundColor;
    });
    expect(primaryColor).toBe('rgb(255, 255, 255)');

    // Manual AA contrast for the primary interactive text in dark.
    const primaryContrast = contrastRatio(parseRgb(primaryColor), parseRgb(primaryBg));
    expect(primaryContrast).toBeGreaterThanOrEqual(4.5);

    // No accidental horizontal overflow at desktop or mobile in dark.
    expect(
      await page.evaluate(() => document.documentElement.scrollWidth <= document.documentElement.clientWidth),
    ).toBe(true);
    await page.setViewportSize({ width: 375, height: 700 });
    await page.waitForTimeout(80);
    expect(
      await page.evaluate(() => document.documentElement.scrollWidth <= document.documentElement.clientWidth),
    ).toBe(true);
  });

  test('key interactions work in dark (create -> view -> cancel)', async ({ page }) => {
    await page.emulateMedia({ colorScheme: 'dark' });
    await page.goto('/');
    await page.locator('#product').selectOption({ index: 0 });
    await page.locator('#quantity').fill('1');
    await page.getByRole('button', { name: 'Add' }).click();
    await page.getByRole('button', { name: 'Create Order' }).click();
    await expect(page).toHaveURL(/\/orders\//);
    await expect(page.locator('.status-badge')).toHaveText('PENDING');
    await expect(page.getByText(/Total:/)).toBeVisible();
    await page.getByRole('button', { name: 'Cancel Order' }).click();
    await expect(page.locator('.status-badge')).toHaveText('CANCELLED');
    await expect(page.getByRole('button', { name: 'Cancel Order' })).toHaveCount(0);
  });
});
