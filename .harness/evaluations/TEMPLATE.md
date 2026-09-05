# Evaluation XXXX —

## Objective
Describe the capability being evaluated.

## Scenario
Describe the initial state and important conditions.

## Acceptance Criteria

### AC-1
Describe the required behavior.

### AC-2
Describe the required behavior.

## Required Evidence
Every acceptance criterion MUST have corresponding evidence.

| Criterion | Required Evidence |
|---|---|
| AC-1 |  |
| AC-2 |  |

## Required Tests
List the tests required to produce the evidence.

## Architecture Constraints
Describe only architecture constraints relevant to correctness,
maintainability, or explicit project design.

## Regression Requirements
Describe related existing behavior that must remain intact.

## Verification
The repository must pass:

```
./scripts/verify.sh
```
Repository verification does not substitute for missing Evaluation
evidence.

## Forbidden Shortcuts

- Weakening tests
- Deleting tests
- Skipping failures
- Replacing required integration tests with mocks
- Replacing required concurrency with sequential execution
- Modifying Evaluation criteria to reduce requirements
- Modifying verification scripts to hide failures
- Hard-coding test-specific production behavior

## Completion Rule
The Evaluation is satisfied only when:

1. Every acceptance criterion has sufficient evidence.
2. Required tests pass.
3. Relevant regression tests pass.
4. Architecture constraints are satisfied.
5. `./scripts/verify.sh` passes.
