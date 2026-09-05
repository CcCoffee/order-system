# Evaluation Authoring Checklist

## Specification

- Objective is specific
- Scenario defines important initial state
- Acceptance criteria are independently testable
- Acceptance criteria describe behavior rather than implementation

## Evidence

- Every AC has evidence
- Evidence can detect an incorrect implementation
- Evidence verifies important state
- Evidence verifies failure paths
- Evidence verifies side effects where relevant

## Concurrency
If concurrency is involved:

- Real concurrent execution is required
- Independent transactions are used where appropriate
- Real database is used when persistence behavior matters
- No sequential substitute is accepted
- Final state is asserted
- Success and failure are both verified

## Transactions
If transactions are involved:

- Atomicity is specified
- Rollback behavior is specified
- Partial state is checked
- Integration-level evidence is required

## Idempotency
If idempotency is involved:

- Duplicate execution is tested
- Duplicate business side effects are checked
- Final state is checked
- Concurrent duplicates are considered where relevant

## Architecture

- Business logic boundaries are clear
- Controller/repository constraints are meaningful
- No unnecessary implementation restrictions

## Anti-Gaming

- No weakening tests
- No deleting tests
- No mocks replacing required real integrations
- No sequential replacement for concurrency
- No test-specific production behavior
- No modification of Evaluation to lower requirements
- No modification of verification scripts to hide failures

## Final

- Required tests are explicit
- Verification is explicit
- Forbidden shortcuts are explicit
