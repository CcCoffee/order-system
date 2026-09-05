# Task 004 — Implement Order Idempotency

Read:

- AGENTS.md
- .github/instructions/
- .github/agents/order-system.agent.md
- .harness/evaluations/004-order-idempotency.md

Implement or harden order creation idempotency.

Redis should provide meaningful idempotency coordination/state.

The implementation must handle concurrent duplicate requests.

Do not weaken or delete tests.

Do not modify evaluation criteria.

Do not modify verification scripts merely to make them pass.

Document the idempotency design.

Run:

./scripts/verify.sh

until the complete Harness verification suite passes.

The task is complete only when the command exits with code 0.
