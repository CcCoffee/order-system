# Frontend Engineering Rules

This directory contains the React frontend.

---

# Stack

- React
- TypeScript
- Vite
- Playwright

---

# Rules

Use TypeScript strict mode.

Avoid `any`.

Reuse existing components.

Do not introduce a new UI framework without approval.

API contracts must follow OpenAPI.

Do not invent backend API shapes.

---

# State

Follow the existing project state-management architecture.

Do not introduce another state-management library without explicit justification.

---

# UI

Every important user flow should handle:

- loading
- success
- empty
- error

---

# E2E

Critical user-visible flows should have Playwright coverage.

---

# Verification

Run:

    npm run lint

    npm run test

    npm run build

    npm run e2e
