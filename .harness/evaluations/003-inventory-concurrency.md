# Evaluation 003 — Inventory Concurrency

## Objective

Verify that the order system behaves correctly when multiple requests attempt
to reserve the same inventory concurrently.

## Scenario

Assume:

- Product A has inventory quantity = 10.
- Multiple concurrent order requests attempt to purchase Product A.
- The total requested quantity is greater than 10.

## Required behavior

The system must guarantee:

1. Inventory can never become negative.
2. Successful orders never exceed available inventory.
3. Failed orders do not leave partially reserved inventory.
4. Database state remains consistent.
5. Concurrent requests do not bypass inventory validation.

## Example

Initial inventory:

10

Ten concurrent requests each buying:

1

Expected successful reservations:

10

Expected remaining inventory:

0

An additional request must fail.

## Stronger scenario

Run concurrent requests where:

- request A buys 6
- request B buys 6

Only one request may successfully reserve all 6 units.

The other request must fail.

## Required tests

Use integration tests with real PostgreSQL.

The test must exercise actual transaction/concurrency behavior rather than
only testing mocked services.

## Architecture constraints

Concurrency control must belong to the persistence/application boundary,
not the HTTP controller.

## Verification

The evaluation passes only when:

`./scripts/verify.sh`

returns exit code `0`.
