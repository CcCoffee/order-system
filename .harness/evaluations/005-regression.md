# Evaluation 005 — Regression

## Objective

Verify that new changes do not break previously established behavior.

## Regression baseline

The following capabilities must continue to work:

- product lookup
- inventory lookup
- order creation
- order detail
- order cancellation
- valid order state transitions
- invalid order state transitions
- inventory reservation
- inventory release
- audit logging
- Redis integration
- frontend order creation
- frontend order detail
- frontend cancellation
- API contract
- architecture rules

## Required verification

The complete Harness verification suite must pass:

`./scripts/verify.sh`

## Forbidden shortcuts

The agent must not:

- delete tests
- weaken assertions
- disable architecture checks
- modify evaluation criteria
- bypass integration tests
- remove Redis usage
- change verification scripts merely to hide failures

## Success criteria

Regression evaluation passes only when all existing verification checks
continue to pass after the new implementation is introduced.
