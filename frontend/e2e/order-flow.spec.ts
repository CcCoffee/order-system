import { expect, test } from '@playwright/test';

test('create, view, cancel and verify an order', async ({ page }) => {
  await page.goto('/');

  await expect(page.getByRole('heading', { name: 'Create Order' })).toBeVisible();

  const productSelect = page.locator('#product');
  await expect(productSelect).toBeVisible();
  await expect(page.locator('#product option')).toHaveCount(3);

  await productSelect.selectOption({ index: 0 });
  await page.locator('#quantity').fill('2');
  await page.getByRole('button', { name: 'Add' }).click();

  await page.getByRole('button', { name: 'Create Order' }).click();

  await expect(page.locator('.status-badge')).toHaveText('PENDING');
  await expect(page.getByText(/Total:/)).toBeVisible();

  await page.getByRole('button', { name: 'Cancel Order' }).click();

  await expect(page.locator('.status-badge')).toHaveText('CANCELLED');
  await expect(page.getByRole('button', { name: 'Cancel Order' })).toHaveCount(0);
});
