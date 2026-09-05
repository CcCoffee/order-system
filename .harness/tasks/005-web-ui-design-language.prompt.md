# Task 005 — Implement Apple-style Web UI Design Language

Read:

- AGENTS.md
- .github/instructions/
- .github/agents/frontend.agent.md
- .github/skills/huashu-design/SKILL.md
- .github/skills/playwright-cli/SKILL.md
- .harness/evaluations/005-web-ui-design-language.md

Implement the presentation changes needed to satisfy the paired Evaluation 005.

Restyle the Order System frontend (order creation, order detail, and the shared
layout) to reference Apple's official website design language: SF/system
typography with large bold tightly-tracked titles, a centered column with
generous whitespace, light neutral backgrounds with refined borders and subtle
elevation, an Apple-style blue accent, a coherent dark appearance, smooth
interactions with visible focus and disabled/loading states, and consistent,
accessible presentation.

## Scope

You may modify:

- `frontend/`
- frontend tests

You may not modify:

- backend production code
- `.harness/evaluations/`
- `.harness/tasks/`
- `scripts/verify.sh` or `scripts/verify-*.sh`
- the typed API client or the API contract

## Implementation Guidance

Keep the existing React + TypeScript + Vite + plain-CSS stack. Do not introduce a
new UI framework.

Apply the design language through a centralized, reused definition (for example,
CSS custom properties) rather than ad-hoc per-component values.

Do not change order business rules, order state transitions, or the backend. The
backend remains authoritative; the frontend controls presentation only.

Preserve the existing page structure, the class-based selectors used by the
current tests, order status semantics, and the loading/empty/success/error
states.

## Testing

Implement or update the tests needed to produce the evidence defined in
Evaluation 005. Pay particular attention to its rendered-browser, dark
appearance, interaction, accessibility, and full-order-workflow regression
requirements.

Use a real browser for visual and interaction verification (`playwright-cli` for
development inspection, Playwright E2E for formal evidence). A source-only or
screenshot-only check is not sufficient evidence.

## Constraints

Do not modify:

- evaluation criteria
- verification scripts
- the backend or order business logic
- the typed API client / API contract
- unrelated production areas

## Verification

Run the frontend verification (`npm run lint`, `npm run test`, `npm run build`,
`npm run e2e`) and then the repository verification contract:

```
./scripts/verify.sh
```

until the complete Harness verification suite passes.

## Completion

Implementation is complete only when the required tests and repository
verification pass and the implementation satisfies the paired Evaluation 005.
