# Frontend Engineering Rules

## Stack

- React
- TypeScript
- Vite
- Playwright

## Rules

- TypeScript strict mode.
- Avoid `any`.
- Reuse existing components.
- Keep business logic outside presentation components where practical.
- API communication must use the shared API client.
- Do not manually duplicate API contracts.
- Handle loading, empty, error and success states.
- User-visible critical flows require E2E coverage.

## Verification

Run:

npm run lint
npm run test
npm run build

For user flows:

npm run e2e

