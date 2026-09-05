# Task 006 — Regression Verification

Read:

- AGENTS.md
- .github/instructions/
- .github/agents/order-system.agent.md
- .harness/evaluations/006-regression.md

Run the complete Harness verification suite.

If failures occur:

1. Identify the root cause.
2. Determine whether the failure is caused by the current implementation.
3. Fix the implementation.
4. Re-run verification.

Do not:

- delete tests
- weaken assertions
- disable architecture checks
- modify evaluation criteria
- modify verification scripts to hide failures

The task is complete only when:

./scripts/verify.sh

returns exit code 0.
