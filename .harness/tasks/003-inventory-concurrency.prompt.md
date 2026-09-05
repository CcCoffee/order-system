# Task 003 — Harden Inventory Concurrency

Read:

- AGENTS.md
- .github/instructions/
- .github/agents/order-system.agent.md
- .harness/evaluations/003-inventory-concurrency.md

Implement or harden inventory concurrency behavior.

The implementation must guarantee that inventory cannot become negative
under concurrent order creation.

Use real PostgreSQL integration tests.

Do not rely only on mocks.

Do not weaken existing tests.

Do not modify Harness evaluation criteria.

Do not modify verification scripts merely to hide failures.

Run:

./scripts/verify.sh

until all verification checks pass.

The task is complete only when the command exits with code 0.
