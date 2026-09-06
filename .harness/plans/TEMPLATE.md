# Implementation Plan

> Persistent Harness artifact.
> This is the canonical location for Planner output.
> Downstream Backend / Frontend / Test / Reviewer agents read this file as the
> implementation handoff contract. Copilot Chat history is NOT a Harness artifact.

## Task

- Task ID: `<evaluation-id>-<task-slug>`
- Task file: `.harness/tasks/<evaluation-id>-<task-slug>.prompt.md`

## Evaluation

- Evaluation ID: `<evaluation-id>`
- Evaluation file: `.harness/evaluations/<evaluation-id>-<slug>.md`
- Objective: <one-line objective>

## Objective

<Describe what this plan is intended to achieve, aligned with the Evaluation.>

## Scope

<What is in scope / out of scope. If not applicable: "Not applicable.">

## Acceptance Criteria Mapping

### AC-1

#### Requirement

<Quote or paraphrase the Evaluation AC-1 requirement.>

#### Implementation

<Concrete implementation work for AC-1.>

#### Evidence

<How AC-1 will be proven.>

#### Tests

<Tests that will produce the evidence.>

### AC-2

#### Requirement

#### Implementation

#### Evidence

#### Tests

<!-- Repeat the AC block for every Acceptance Criterion in the Evaluation. -->

## Architecture Impact

<Affected layers / components. If not applicable: "Not applicable.">

## Backend Changes

<Concrete backend work items. If not applicable: "Not applicable.">

## Frontend Changes

<Concrete frontend work items. If not applicable: "Not applicable.">

## Test Changes

<Test work mapped to evidence. If not applicable: "Not applicable.">

## Documentation Changes

<Docs to update. If not applicable: "Not applicable.">

## Files To Modify

- ...

## Files To Create

- ...

## Files Not To Modify

- ...

## Verification

- Evaluation evidence: <matrix or reference>
- Repository: `./scripts/verify.sh`

## Risks / Assumptions

- ...

## Implementation Order

1. ...
