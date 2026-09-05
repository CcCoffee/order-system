import { Page, expect } from '@playwright/test';

/**
 * Drives the real create-order form and returns the created order id.
 */
export async function createOrderViaForm(
  page: Page,
  options: { quantity?: number; productIndex?: number } = {},
): Promise<string> {
  const { quantity = 1, productIndex = 0 } = options;
  await page.goto('/');
  const productSelect = page.locator('#product');
  await expect(productSelect).toBeVisible();
  await expect(page.locator('#product option')).toHaveCount(3);
  await productSelect.selectOption({ index: productIndex });
  await page.locator('#quantity').fill(String(quantity));
  await page.getByRole('button', { name: 'Add' }).click();
  await page.getByRole('button', { name: 'Create Order' }).click();
  await expect(page).toHaveURL(/\/orders\//);
  return page.url().split('/').pop() ?? '';
}

/**
 * Clicks the Cancel Order button on the current (PENDING) detail page and
 * waits for the rendered status to become CANCELLED.
 */
export async function cancelOrderViaUi(page: Page): Promise<void> {
  await page.getByRole('button', { name: 'Cancel Order' }).click();
  await expect(page.locator('.status-badge')).toHaveText('CANCELLED');
  await expect(page.getByRole('button', { name: 'Cancel Order' })).toHaveCount(0);
}

/**
 * Reads the computed background-color of the primary (non-secondary) action
 * button whose text is `label`. Used to wait for the 0.2s color transition to
 * settle before asserting the accent / disabled palette.
 */
export function primaryButtonBg(page: Page, label: string): () => Promise<string> {
  return () =>
    page.evaluate((text) => {
      const b = [...document.querySelectorAll('button')].find((x) => x.textContent.trim() === text);
      return b ? getComputedStyle(b).backgroundColor : '';
    }, label);
}

export function parseRgb(s: string): [number, number, number] {
  const m = s.match(/rgba?\((\d+),\s*(\d+),\s*(\d+)/);
  if (!m) {
    throw new Error(`Cannot parse color: ${s}`);
  }
  return [+m[1], +m[2], +m[3]];
}

export function luminance(rgb: [number, number, number]): number {
  const [r, g, b] = rgb.map((v) => {
    const c = v / 255;
    return c <= 0.03928 ? c / 12.92 : Math.pow((c + 0.055) / 1.055, 2.4);
  });
  return 0.2126 * r + 0.7152 * g + 0.0722 * b;
}

export function contrastRatio(a: [number, number, number], b: [number, number, number]): number {
  const l1 = luminance(a);
  const l2 = luminance(b);
  const hi = Math.max(l1, l2);
  const lo = Math.min(l1, l2);
  return (hi + 0.05) / (lo + 0.05);
}
