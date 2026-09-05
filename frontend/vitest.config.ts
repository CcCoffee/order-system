import { defineConfig } from 'vitest/config';

export default defineConfig({
  test: {
    // Scope vitest to frontend unit tests under src/.
    // This prevents vitest from collecting the Playwright E2E spec in e2e/.
    include: ['src/**/*.{test,spec}.{ts,tsx}'],
    passWithNoTests: true,
  },
});
