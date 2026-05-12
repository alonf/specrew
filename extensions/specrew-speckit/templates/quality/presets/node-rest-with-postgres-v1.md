# Stack Preset: node-rest-with-postgres v1.0.0

| Field | Value |
| --- | --- |
| Preset ID | `node-rest-with-postgres` |
| Version | `v1.0.0` |
| Phase Scope | `phase-1-first-slice` |
| Intent | Reviewable Phase 1 quality baseline for a public Node.js REST API backed by PostgreSQL. |

## Supported Stack Signals

| Signal | Match Examples | Why it qualifies |
| --- | --- | --- |
| `package.json` | API/service manifest | Establishes Node.js runtime and package workflow. |
| REST API surface | Express/Fastify route handlers or documented HTTP resources | Indicates public request/response boundaries. |
| PostgreSQL dependency | `pg`, query builder, or ORM targeting Postgres | Activates persistence and data-integrity review. |

## Required Quality Dimensions

| Dimension | Activation Rule | Phase 1 Expectation |
| --- | --- | --- |
| `security` | The service accepts public input and reaches a database. | Validate boundary checks, auth assumptions, and safe data access patterns. |
| `robustness` | Request processing depends on networked storage and failure semantics. | Make timeout, error handling, and resource ownership explicit. |
| `maintainability` | API, domain, and persistence layers must remain reviewable. | Keep transport and data-access concerns clearly separated. |

## Required Mechanical Checks

| Check | Required Configuration | Blocking Expectation |
| --- | --- | --- |
| `dead-field` | Review request DTOs, response models, and persistence fields for unused members. | Remove dead transport or storage fields before they become drift. |
| `anti-pattern` | Flag unsafe retry/transaction handling and ambiguous partial writes. | API and database failure behavior stays explicit and predictable. |
| `test-integrity` | Require assertions for response contracts and persisted outcomes. | Tests prove external API behavior and storage side effects. |

## Required Lens Checklist References

| Lens | Version | Activation Rationale |
| --- | --- | --- |
| `security-baseline` | `v1.0.0` | Public request boundaries and database access require explicit security review. |
| `robustness-baseline` | `v1.0.0` | Storage failures, retries, and cleanup semantics are material to API reliability. |
| `test-integrity` | `v1.0.0` | API and persistence tests must prove meaningful outcomes. |

## Toolchain / Evidence Expectations

| Area | Concrete Selection | Evidence Expectation |
| --- | --- | --- |
| Package + test workflow | `npm` with `npm test` | Tests cover response behavior and database-facing scenarios. |
| API verification | Contract or route integration tests | Evidence proves request validation and response semantics. |
| Persistence verification | Postgres-backed integration coverage | Evidence proves data writes/reads and failure handling. |
| Static feedback lane | Repo-standard Node lint/static-analysis command | Findings remain visible in reviewable evidence. |

## Upgrade Guidance

1. Revisit the preset when transaction, migration, or database access patterns change materially.
2. Upgrade lens references independently when only checklist coverage changes.
3. Keep later-phase hardening or mixed-stack behavior out of this Phase 1 preset unless a future reviewed version expands scope.

## Change Log

| Version | Date | Change | Review Notes |
| --- | --- | --- | --- |
| `v1.0.0` | 2026-05-07 | Initial Phase 1 preset for Node REST services with PostgreSQL persistence. | Establishes public API plus storage expectations without coupling preset versioning to lens updates. |
