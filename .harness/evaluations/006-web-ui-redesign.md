# Evaluation 006 — Web UI Redesign (Apple Design Language)

## Objective

Rework the frontend into a single, consistent design system that follows
Apple's public web design language. The redesign must be presentation-only:
it must not change the API contract, business rules, or backend behavior.

The capability being evaluated is a tokenized, accessible, and visually
consistent design system — not merely "make it look like Apple." A design
system is correct only when the rendered UI consistently reflects the
defined Apple-style tokens across every page and passes accessibility and
regression checks.

## Scenario

The existing React frontend provides order creation, order detail, and
order cancellation using a generic blue/gray theme. A new design system is
introduced that emulates Apple's public web design conventions. The redesign
touches presentation only.

## Design System Reference

The following is the observable design-language contract. These values are
the specification, not optional guidance.

### Typography

- Base font stack (SF Pro / Apple system UI):
  `-apple-system, BlinkMacSystemFont, "SF Pro Display", "SF Pro Text", "Helvetica Neue", Helvetica, Arial, sans-serif`
- Headline style: large font size, heavy weight (>= 600), negative letter-spacing (approx -0.02em).
- Body style: comfortable size (~17px), relaxed line-height (~1.4).
- Headings and body text must both use the base font stack.

### Color

- Page background: near-white (`#FFFFFF` for content panels, `#F5F5F7` for page/canvas).
- Primary text: near-black (`#1D1D1F`).
- Primary action / link accent: Apple blue (approximately `#0071E3`).
- Secondary text where used: muted gray (approximately `#6E6E73`).

### Layout

- Content is centered in a constrained column (max-width around 980px).
- Generous vertical and horizontal spacing; a consistent spacing scale.
- Consistent section padding across pages.

### Controls

- Primary buttons are pill-shaped (fully rounded caps), filled with the
  accent color, white label text, and visible hover/active states.
- Links and secondary actions use the accent color with clear affordance.

### Motion

- Interactive elements have subtle, non-distracting transition states.

## Acceptance Criteria

### AC-1 Apple-style typography is applied system-wide
The base font stack resolves to the Apple system font stack, and headings
use the Apple headline style (large size, heavy weight, negative
letter-spacing). Body text uses the base stack with a comfortable size and
line-height.

### AC-2 Apple-style color palette is applied consistently
The page uses the near-white background, near-black primary text, and the
Apple accent blue for primary actions and links.

### AC-3 Primary controls use Apple-style pill buttons
Primary buttons are pill-shaped, filled with the accent color, use white
label text, and have visible hover/active states.

### AC-4 Layout uses Apple-style whitespace and centered columns
Primary content is centered in a constrained column with generous,
consistent vertical and horizontal spacing.

### AC-5 Design tokens are centralized and consistently referenced
Color, typography, and spacing values are defined in a single source of
truth (CSS custom properties or a typed token module), and components
reference these tokens rather than hardcoding ad-hoc values.

### AC-6 The design language is consistent across all pages
Create Order and Order Detail pages resolve to the same typography, color,
control, and spacing tokens and are visually consistent.

### AC-7 The UI is accessible
Text contrast meets WCAG AA for body and heading text, and interactive
elements have accessible labels and focus states.

### AC-8 The order flow remains functional after redesign
Creating and viewing an order, and cancelling a PENDING order, continue to
work with loading, success, and error states. The cancel action remains
gated by the backend-provided order state.

### AC-9 The redesign is presentation-only
The redesign does not change the API contract, does not add or move
business-rule logic into the frontend, and the backend remains the source
of truth for order state and cancellation rules.

## Required Evidence

Every acceptance criterion MUST have corresponding evidence.

| Criterion | Required Evidence |
|---|---|
| AC-1 | Computed-style assertion on the rendered DOM (body font-family, heading font-weight/size) via Playwright |
| AC-2 | Computed-style assertion on background, text, and accent (background-color, color) via Playwright + token unit test |
| AC-3 | Computed-style assertion on primary button border-radius, background, color, and transition |
| AC-4 | Computed-style assertion on container max-width and spacing + token unit test |
| AC-5 | Unit/static test asserting the token set is defined and components reference tokens; no ad-hoc hardcoded color/spacing in components |
| AC-6 | Shared computed-style assertions applied to both Create Order and Order Detail pages |
| AC-7 | Contrast assertions (WCAG AA) + accessible-name/focus assertions via Playwright |
| AC-8 | Existing and updated order-flow E2E test (create -> view -> cancel), plus loading/error-state assertions and cancel-gating by backend state |
| AC-9 | `./scripts/verify.sh` PASS (API contract, backend, architecture checks) + review that frontend contains no new business-rule logic |

## Required Tests

At minimum:

1. **Design token unit test** asserting the full token set (typography,
   color, spacing, control radii/motion) is defined and exported from the
   single source of truth.
2. **Computed-style E2E test** (Playwright) asserting the rendered styling
   for AC-1 through AC-4 on both pages.
3. **Consistency E2E test** applying shared style assertions across the
   Create Order and Order Detail pages (AC-6).
4. **Accessibility test** verifying WCAG AA contrast and accessible
   interactive elements (AC-7).
5. **Responsive E2E test** confirming the layout remains usable at
   mobile and desktop viewport widths.
6. **Order-flow E2E regression test** (create -> view -> cancel) and
   loading/error-state assertions (AC-8). Keep the existing cancel button
   gating driven by backend order state.

## Architecture Constraints

Frontend only. The redesign must:

- Keep responsibilities separated: UI component -> UI state -> API client
  -> backend API.
- Keep the API client typed and unchanged where the contract is unchanged.
- Not duplicate backend business rules (e.g., cancellation validity must
  come from the backend-provided order status, not a re-implemented rule).
- Use a single design-token source of truth (CSS custom properties on the
  root, or a typed token module) referenced by all components.
- Preserve loading, success, error, and disabled states for important
  operations.

## Regression Requirements

All previously established frontend behavior must remain intact:

- Order creation, order detail, and order cancellation continue to work.
- Invalid cancellation is still prevented at the UI (no cancel control when
  the backend state does not allow it).
- Loading, error, and success states are preserved for all important
  operations.
- The API contract and backend layering remain unchanged.

## Verification

The repository must pass:

```
./scripts/verify.sh
```

Repository verification does not substitute for missing Evaluation
evidence.

## Forbidden Shortcuts

- Flattening the design system into a single hardcoded stylesheet with no
  tokens, while passing only by asserting CSS file existence.
- Asserting a token value from source without verifying the rendered
  computed style.
- Mocking/injecting computed styles to make the style assertions pass.
- Replacing real visual verification with a brittle pixel-perfect snapshot
  that is tuned, rather than a real design system, to pass.
- Changing the API contract or duplicating backend business rules in the
  frontend.
- Deleting or weakening existing order-flow tests.
- Removing loading/error/disabled states during the redesign.
- Modifying Evaluation criteria or verification scripts to make the
  evaluation pass.

## Completion Rule

The Evaluation is satisfied only when:

1. Every acceptance criterion has sufficient evidence.
2. The design-token set is centralized and referenced consistently.
3. Computed-style and accessibility tests pass on the rendered UI.
4. The order-flow regression test passes.
5. `./scripts/verify.sh` passes.
