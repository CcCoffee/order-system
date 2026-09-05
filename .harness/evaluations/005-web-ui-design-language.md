# Evaluation 005 — Web UI Design Language

## Objective

Apply Apple's official website design language to the Order System frontend,
making the order creation and order detail pages clean, minimal, polished, and
consistent, while preserving every existing order workflow and the established
API contract.

The redesign is presentation-only. The backend, the API, and the order business
rules must remain unchanged.

## Context / Scenario

The Order System frontend currently renders order creation and order detail with
a generic default style: a plain card layout, a generic blue button, system
default form controls, and default spacing. The requirement is to restyle the
frontend to reference Apple's official website design language:

- SF/system-style sans-serif typography, with large, bold, tightly-tracked titles
  and a clear heading hierarchy.
- a centered content column with generous whitespace and refined spacing.
- light, neutral backgrounds with refined borders and subtle elevation.
- an Apple-style blue accent for primary actions and links.
- a coherent dark appearance when the OS prefers dark mode.
- smooth transitions, visible keyboard focus states, and clear disabled/loading
  states while requests are in progress.
- a consistent, accessible presentation that is defined once and reused.

The existing page structure, order status semantics, and order workflows must
remain fully functional.

## Acceptance Criteria

### AC-1 Apple-style typography is applied
The UI uses a system/SF-style sans-serif font stack, and page titles use large,
bold, tightly-tracked type with a clear heading hierarchy.

### AC-2 Layout uses a centered column with generous whitespace and refined shapes
Content is laid out in a centered column with generous spacing, and cards/panels
use consistent rounded corners with subtle, refined borders and elevation, with
no accidental horizontal overflow at desktop and mobile widths.

### AC-3 Neutral light color system with an Apple-style accent
Backgrounds are light and neutral; primary interactive elements (buttons, links,
focus rings) use an Apple-style blue accent; body and interactive text maintain
sufficient color contrast.

### AC-4 Dark appearance is supported
When the OS requests a dark appearance, the UI renders a coherent dark
background with legible text and appropriate contrast while preserving the same
layout, hierarchy, and interactions.

### AC-5 Interaction feedback is present
Interactive elements provide visible keyboard focus states, smooth transitions,
hover feedback, and clear disabled/loading states while requests are in
progress.

### AC-6 Accessibility is preserved
The redesigned UI keeps a meaningful heading hierarchy, labelled form controls,
semantic landmarks and status indication, and does not degrade keyboard or
screen-reader accessibility.

### AC-7 The design language is centralized and consistent
The visual language is defined once and reused, so the create-order and
order-detail pages resolve shared design tokens (font family, radii, spacing,
accent color) to the same values rather than carrying divergent ad-hoc styling.

### AC-8 Existing order workflows and API contract are preserved
Product/inventory lookup, order creation, order detail, order cancellation,
invalid-cancellation rejection, and loading/empty/success/error states continue
to work after the redesign, in both light and dark appearance, and the typed API
client and the API contract remain unchanged.

## Required Evidence

Every acceptance criterion MUST have corresponding evidence. Rendered-browser
evidence is required; source inspection alone is insufficient.

| Criterion | Required Evidence | Test / Verification |
|-----------|-------------------|---------------------|
| AC-1 | Browser-computed `font-family`, heading `font-size`/`font-weight`/`letter-spacing` on the rendered order pages | Playwright E2E computed-style assertions |
| AC-2 | Browser-computed content max-width/spacing and `border-radius` on cards/panels; no horizontal overflow at desktop and mobile viewports | Playwright E2E computed-style + viewport assertions |
| AC-3 | Browser-computed background and accent colors; measured color contrast for body and interactive text | Playwright computed-style + contrast/axe assertions |
| AC-4 | Browser-computed dark background/text colors under forced `prefers-color-scheme: dark`; re-run of key interactions | Playwright E2E with dark color-scheme emulation |
| AC-5 | Browser-computed focus-visible outline/box-shadow, transition property, and disabled/loading visual state on real interaction | Playwright keyboard/interaction assertions |
| AC-6 | Role/heading/label accessibility assertions and an accessibility-tree snapshot; no keyboard traps on the order pages | Playwright accessibility assertions (axe or a11y snapshot) |
| AC-7 | Create-order and order-detail pages resolve shared tokens (font, radius, spacing, accent) to identical computed values | Playwright computed-style comparison across pages |
| AC-8 | Full order workflow (create → view → cancel → invalid cancel) completes in a real browser in light and dark; frontend build/lint, API-contract, and architecture checks pass | Playwright E2E + frontend verification + API/architecture checks |

## Required Tests

At minimum:

1. Playwright E2E asserting computed typography, layout/shape, and color on both
   order pages in the light appearance.
2. Playwright E2E under forced `prefers-color-scheme: dark` asserting a coherent
   dark appearance, legible contrast, and working interactions.
3. Playwright keyboard/interaction test asserting focus-visible states,
   transitions, and disabled/loading states during order submission and cancel.
4. Playwright accessibility assertions (roles, heading hierarchy, labelled
   controls, accessibility-tree snapshot) on both order pages.
5. Playwright E2E regression of the complete order workflow
   (create → view → cancel → invalid-cancel) in both light and dark.
6. Existing frontend verification (`npm run lint`, `npm run test`, `npm run build`,
   `npm run e2e`) and the repository API-contract/OpenAPI checks continue to pass.

## Architecture Constraints

- The redesign is presentation-only and lives under `frontend/`.
- Keep the existing React + TypeScript + Vite + plain-CSS stack. Do not introduce
  a new UI framework (Tailwind, MUI, Bootstrap, etc.) without approval.
- The typed API client (`frontend/src/api/client.ts`, `frontend/src/api/types.ts`)
  and the API contract must remain unchanged.
- Order and order state-transition rules remain authoritative in the backend;
  the frontend may only control presentation.
- The visual language should be defined once (for example via CSS custom
  properties) and reused consistently, not duplicated ad-hoc per component.

## Regression Requirements

The following existing behavior must remain intact after the redesign:

- Product and inventory lookup.
- Order creation (atomic, with loading/success/error states).
- Order detail retrieval and status display.
- Order cancellation (only when valid, with loading/success/error states).
- Invalid-cancellation handling (conflict/error feedback).
- Empty and error states on the order pages.
- The existing Playwright order-flow E2E and the frontend build.

## Verification

The repository must pass:

```
./scripts/verify.sh
```

Repository verification does not substitute for missing Evaluation evidence. The
specific rendered-browser evidence in the Required Evidence table is mandatory.

## Forbidden Shortcuts

- Replacing rendered-browser evidence with source-code inspection (for example,
  checking that a CSS variable, class, or token name exists).
- Adding CSS variables/tokens that are never used by the rendered UI.
- Asserting only that a test file exists or that the build passes.
- Using mocked accessibility or fake browser state as proof of rendered behavior.
- Screenshot-only acceptance without real interaction or computed-style evidence.
- Introducing a new UI framework or changing the API contract to make styling
  easier.
- Weakening or deleting existing tests to pass.
- Changing evaluation criteria or verification scripts to hide failures.
- Modifying backend or order business rules for visual reasons.
- Hard-coding values only to satisfy specific tests.

## Completion Criteria

The Evaluation is satisfied only when:

1. Every acceptance criterion has sufficient rendered-browser evidence.
2. The required tests pass (light and dark, interaction, accessibility, regression).
3. Relevant regression tests pass.
4. Architecture constraints are satisfied (presentation-only, no API/framework change).
5. `./scripts/verify.sh` passes.
