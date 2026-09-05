# Task 002 — Implement / Harden Order Cancellation

Read:

- AGENTS.md
- .github/instructions/
- .github/agents/order-system.agent.md
- .harness/evaluations/002-order-cancellation.md

Implement or harden the order cancellation flow according to the evaluation.

Do not modify the evaluation criteria.

Do not weaken or remove existing tests.

Do not modify verification scripts merely to make the task pass.

Use the following loop:

1. Inspect existing implementation.
2. Inspect existing tests.
3. Implement the smallest correct change.
4. Run ./scripts/verify.sh.
5. Analyze failures.
6. Fix root causes.
7. Run verification again.

The task is complete only when:

./scripts/verify.sh

returns exit code 0.
