---
applyTo: "**/*Test.java,**/*.test.ts,**/*.test.tsx,**/*.spec.ts,**/*.spec.tsx"
---

# Testing Rules

Tests are part of the Harness.

Never:

- delete tests to make verification pass
- weaken assertions to make verification pass
- skip failing tests without a documented environmental reason
- modify verification scripts to hide failures
- modify evaluation criteria to redefine success

When a defect is discovered:

1. reproduce it
2. add or update a regression test
3. fix the implementation
4. run verification again
