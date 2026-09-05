import { expect, test } from '@playwright/test';
import { contrastRatio, createOrderViaForm, parseRgb, primaryButtonBg } from './helpers';

test.describe('Evaluation 005 — AC-1/AC-2/AC-3/AC-7 (light appearance)', () => {
  test('AC-1 system/SF font stack with bold, tightly-tracked headings', async ({ page }) => {
    await page.setViewportSize({ width: 1280, height: 800 });
    await page.goto('/');
    await expect(page.getByRole('heading', { name: 'Create Order' })).toBeVisible();
    // The "Add Items" h2 only renders once listProducts() resolves, so wait for
    // the loaded content before reading the heading hierarchy (deterministic).
    await expect(page.getByRole('heading', { name: 'Add Items' })).toBeVisible();

    // Body uses an Apple/SF-style system sans-serif stack.
    const bodyFont = await page.evaluate(() => getComputedStyle(document.body).fontFamily);
    expect(bodyFont).toMatch(
      /-apple-system|system-ui|BlinkMacSystemFont|SF Pro|Helvetica Neue|Helvetica|Arial|sans-serif/,
    );
    expect(await page.evaluate(() => getComputedStyle(document.body).fontSize)).toBe('17px');

    // Page title: large, bold, tightly-tracked.
    const h1 = await page.evaluate(() => {
      const s = getComputedStyle(document.querySelector('h1')!);
      return { fontSize: s.fontSize, fontWeight: s.fontWeight, letterSpacing: s.letterSpacing };
    });
    expect(h1.fontSize).toBe('48px');
    expect(h1.fontWeight).toBe('700');
    expect(parseFloat(h1.letterSpacing)).toBeLessThan(0); // tight (negative) tracking

    // Section heading hierarchy: smaller but still bold and tight.
    const h2 = await page.evaluate(() => {
      const s = getComputedStyle(document.querySelector('h2')!);
      return { fontSize: s.fontSize, fontWeight: s.fontWeight, letterSpacing: s.letterSpacing };
    });
    expect(h2.fontSize).toBe('32px');
    expect(h2.fontWeight).toBe('600');
    expect(parseFloat(h2.letterSpacing)).toBeLessThan(0);

    // Clear heading hierarchy: exactly one h1, followed by an h2.
    const order = await page.evaluate(() =>
      [...document.querySelectorAll('h1, h2')].map((h) => h.tagName),
    );
    expect(order).toEqual(['H1', 'H2']);
  });

  test('AC-2 centered column + refined shapes, no horizontal overflow', async ({ page }) => {
    await page.setViewportSize({ width: 1280, height: 800 });
    await page.goto('/');

    expect(await page.evaluate(() => getComputedStyle(document.querySelector('.app')!).maxWidth)).toBe(
      '980px',
    );
    expect(await page.evaluate(() => getComputedStyle(document.querySelector('.card')!).borderRadius)).toBe(
      '18px',
    );

    // Desktop: no accidental horizontal overflow.
    const desktop = await page.evaluate(() => ({
      scroll: document.documentElement.scrollWidth,
      client: document.documentElement.clientWidth,
      bodyScroll: document.body.scrollWidth,
      inner: window.innerWidth,
    }));
    expect(desktop.scroll).toBeLessThanOrEqual(desktop.client);
    expect(desktop.bodyScroll).toBeLessThanOrEqual(desktop.inner);

    // Mobile (375px): rounded corners preserved, responsive title, no overflow.
    await page.setViewportSize({ width: 375, height: 700 });
    await page.waitForTimeout(80);
    expect(await page.evaluate(() => getComputedStyle(document.querySelector('.card')!).borderRadius)).toBe(
      '18px',
    );
    expect(await page.evaluate(() => getComputedStyle(document.querySelector('h1')!).fontSize)).toBe(
      '34px',
    );
    const mobile = await page.evaluate(() => ({
      scroll: document.documentElement.scrollWidth,
      client: document.documentElement.clientWidth,
      bodyScroll: document.body.scrollWidth,
      inner: window.innerWidth,
    }));
    expect(mobile.scroll).toBeLessThanOrEqual(mobile.client);
    expect(mobile.bodyScroll).toBeLessThanOrEqual(mobile.inner);
  });

  test('AC-3 neutral light colors, Apple accent, and sufficient contrast', async ({ page }) => {
    await page.setViewportSize({ width: 1280, height: 800 });
    await page.goto('/');

    const body = await page.evaluate(() => {
      const s = getComputedStyle(document.body);
      return { bg: s.backgroundColor, color: s.color };
    });
    expect(body.bg).toBe('rgb(245, 245, 247)');
    expect(body.color).toBe('rgb(29, 29, 31)');

    expect(await page.evaluate(() => getComputedStyle(document.querySelector('.card')!).backgroundColor)).toBe(
      'rgb(255, 255, 255)',
    );

    // Enable the primary button, then assert the Apple-blue accent.
    await page.locator('#product').selectOption({ index: 0 });
    await page.locator('#quantity').fill('2');
    await page.getByRole('button', { name: 'Add' }).click();
    await expect.poll(primaryButtonBg(page, 'Create Order')).toBe('rgb(0, 113, 227)');
    const primaryColor = await page.evaluate(() => {
      const b = [...document.querySelectorAll('button')].find((x) => x.textContent.trim() === 'Create Order')!;
      return getComputedStyle(b).color;
    });
    expect(primaryColor).toBe('rgb(255, 255, 255)');

    // Secondary "Add" action uses the accent as its text color (in the resting,
    // non-hovered state). Move the cursor away first.
    await page.mouse.move(0, 0);
    await expect
      .poll(async () =>
        page.evaluate(() => getComputedStyle(document.querySelector('button.secondary')!).color),
      )
      .toBe('rgb(0, 113, 227)');

    // Link accent.
    const linkColor = await page.evaluate(() => getComputedStyle(document.querySelector('.brand')!).color);
    expect(linkColor).toBe('rgb(0, 102, 204)');

    // Manual WCAG AA contrast for body and interactive (link) text.
    const bodyContrast = contrastRatio(parseRgb(body.color), parseRgb(body.bg));
    const linkContrast = contrastRatio(parseRgb(linkColor), parseRgb(body.bg));
    expect(bodyContrast).toBeGreaterThanOrEqual(4.5);
    expect(linkContrast).toBeGreaterThanOrEqual(4.5);
  });

  test('AC-7 shared design tokens resolve to identical values across both pages', async ({ page }) => {
    await page.setViewportSize({ width: 1280, height: 800 });

    // Capture create-order page values (with the primary button enabled).
    await page.goto('/');
    // Wait for the loaded products before capturing the create-page tokens
    // (the "Add Items" h2 and the Create Order button render post-fetch).
    await expect(page.getByRole('heading', { name: 'Add Items' })).toBeVisible();
    await page.locator('#product').selectOption({ index: 0 });
    await page.locator('#quantity').fill('1');
    await page.getByRole('button', { name: 'Add' }).click();
    await expect.poll(primaryButtonBg(page, 'Create Order')).toBe('rgb(0, 113, 227)');
    const create = await page.evaluate(() => {
      const bodyFont = getComputedStyle(document.body).fontFamily;
      const cardRadius = getComputedStyle(document.querySelector('.card')!).borderRadius;
      const cardPadding = getComputedStyle(document.querySelector('.card')!).padding;
      const primary = [...document.querySelectorAll('button')].find(
        (x) => x.textContent.trim() === 'Create Order',
      )!;
      return { bodyFont, cardRadius, cardPadding, accent: getComputedStyle(primary).backgroundColor };
    });

    const orderId = await createOrderViaForm(page, { quantity: 1, productIndex: 0 });
    await expect(page).toHaveURL(new RegExp(`/orders/${orderId}`));
    // Wait for the loaded order detail (the cancel button only exists when the
    // rendered order is loaded and still cancellable).
    await expect(page.getByRole('button', { name: 'Cancel Order' })).toBeVisible();

    const detail = await page.evaluate(() => {
      const bodyFont = getComputedStyle(document.body).fontFamily;
      const cardRadius = getComputedStyle(document.querySelector('.card')!).borderRadius;
      const cardPadding = getComputedStyle(document.querySelector('.card')!).padding;
      const cancel = [...document.querySelectorAll('button')].find((x) =>
        x.textContent.includes('Cancel Order'),
      )!;
      return { bodyFont, cardRadius, cardPadding, accent: getComputedStyle(cancel).backgroundColor };
    });

    // The same shared tokens resolve to identical rendered values on both pages.
    expect(detail.bodyFont).toBe(create.bodyFont);
    expect(detail.cardRadius).toBe(create.cardRadius);
    // Spacing token: card padding must resolve to the same computed value on
    // both pages (shared spacing token, not divergent ad-hoc spacing).
    expect(detail.cardPadding).toBe(create.cardPadding);
    expect(detail.cardPadding).toMatch(/^\d+px$/); // a real resolved spacing value
    expect(detail.accent).toBe(create.accent);
    expect(detail.bodyFont).toMatch(
      /-apple-system|system-ui|BlinkMacSystemFont|SF Pro|Helvetica Neue|Helvetica|Arial|sans-serif/,
    );
    expect(detail.cardRadius).toBe('18px');
    expect(detail.accent).toBe('rgb(0, 113, 227)');

    // Restore inventory by cancelling the order created for inspection.
    await page.getByRole('button', { name: 'Cancel Order' }).click();
    await expect(page.locator('.status-badge')).toHaveText('CANCELLED');
  });
});
