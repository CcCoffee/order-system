# Task 006 — Web UI Redesign (Apple Design Language)

Read:

- AGENTS.md
- .github/instructions/frontend.instructions.md
- .github/agents/order-system.agent.md
- .harness/evaluations/006-web-ui-redesign.md

Redesign the React frontend into a single, consistent design system that
follows Apple's public web design language.

The work is **presentation-only**. Do not change the API contract, backend
behavior, or business rules. The backend must remain the source of truth for
order state and cancellation rules.

## Design system

Concentrate typography, color, spacing, control radii, and motion into a
single token source of truth (CSS custom properties on the root, or a typed
token module) and reference those tokens from all components.

Use Apple-style tokens including (at minimum):

- Apple system font stack
  `-apple-system, BlinkMacSystemFont, "SF Pro Display", "SF Pro Text", "Helvetica Neue", Helvetica, Arial, sans-serif`
- near-white page/panel backgrounds (`#FFFFFF`, `#F5F5F7`)
- near-black primary text (`#1D1D1F`)
- accent blue for primary actions/links (approximately `#0071E3`)
- pill-shaped primary buttons with label text and visible hover/active states
- centered constrained column with generous, consistent spacing

Apply the same tokens consistently to the Create Order page and the Order
Detail page.

## Tests

Provide executable evidence for the Evaluation acceptance criteria:

1. Design token unit test asserting the full token set is defined and
   exported from the single source of truth.
2. Computed-style E2E test (Playwright) asserting the rendered typography,
   color palette, pill buttons, and layout on both pages.
3. Consistency test applying shared style assertions across both pages.
4. Accessibility test verifying WCAG AA contrast and accessible,
   focusable interactive elements.
5. Responsive E2E test confirming the layout is usable at mobile and
   desktop viewport widths.
6. Order-flow E2E regression test (create -> view -> cancel) with
   loading/error-state assertions and the cancel action still gated by the
   backend-provided order status.

Do not weaken, delete, or skip existing tests.

Do not modify Evaluation criteria.

Do not modify verification scripts merely to make them pass.

Do not add or duplicate backend business-rule logic in the frontend.

Verify the UI in a real browser using Playwright.

## Verification

Run:

```
./scripts/verify.sh
```

If it fails:

1. read the failure
2. determine the root cause
3. fix the implementation
4. run verification again

Repeat until the complete Harness verification suite passes.

The task is complete only when `./scripts/verify.sh` exits with code 0.
