---
name: Test Standards
description: Apply testing rules to test code.
applyTo: "**/*.{test,spec}.{ts,tsx,java}"
---

# Test Standards

Tests must verify behavior rather than implementation details.

Do not weaken assertions merely to make a test pass.

When fixing a failing test:

1. Determine whether implementation or test is incorrect.
2. Fix the root cause.
3. Preserve meaningful assertions.
