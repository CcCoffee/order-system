# Code Quality

This document describes how Java code quality is enforced in the backend.

## What Checkstyle does

Checkstyle is a deterministic, mechanical Java source style checker. It is part
of the Harness verification system and enforces objective rules that can be
judged as correct or incorrect, including:

* file and line length limits
* naming conventions (types, methods, fields, constants)
* import hygiene (no wildcard imports, no unused/redundant imports)
* basic structure (braces, empty blocks, modifier order, class visibility)
* whitespace consistency

Checkstyle is **not** a substitute for behavior verification. It does not check
architecture layering, business rules, transactions, concurrency, API behavior,
database correctness, or infrastructure health.

## Where the configuration lives

The single source of truth for backend Java style rules is:

```text
backend/checkstyle.xml
```

It is wired into Maven via the `maven-checkstyle-plugin` in the backend parent
`pom.xml` and bound to the `verify` phase.

## How to run it

Run the full backend lifecycle (tests + Checkstyle) from the repository root:

```bash
./scripts/verify-backend.sh
```

Or directly from the Maven reactor:

```bash
cd backend
mvn verify
```

Checkstyle runs as part of the `verify` phase, so both commands will fail if a
Java source file violates the configured rules.

To run Checkstyle only (no tests):

```bash
cd backend
mvn -pl order-service checkstyle:check
```

Job summary (default): the check applies to **production** Java source
(`src/main/java`). Test source is intentionally excluded because test code uses
deliberate conventions (protected injected fields, snake_case descriptive test
method names) that differ from production style.

## How to fix a failure

1. Read the violation message — it names the file, line, column, and rule.
2. Fix the Java source so it complies with the rule.
3. Re-run `mvn verify` (or `./scripts/verify-backend.sh`).
4. Re-run the canonical `./scripts/verify.sh`.

Do **not** bypass the check (for example with `-Dcheckstyle.skip=true`,
removing the plugin, or weakening the rules) to make verification pass.

If a rule genuinely conflicts with an explicit architecture or framework
requirement, investigate the rule and its intent before changing production
code.

## Responsibility boundaries

| Concern                               | Owner                                        |
| ------------------------------------- | -------------------------------------------- |
| Mechanical Java source style           | Checkstyle (`backend/checkstyle.xml`)        |
| Architecture layering                 | `scripts/verify-architecture.sh` + ArchUnit  |
| Business rules, state, transactions    | JUnit / integration tests                    |
| API contract                          | `scripts/verify-api.sh` + `docs/api/`        |
| Infrastructure (containers, DB, Redis) | `scripts/verify-infrastructure.sh`           |
| Repository-wide file size/conventions  | dedicated `verify-*` scripts (not Checkstyle) |
| Final canonical gate                   | `./scripts/verify.sh`                        |
