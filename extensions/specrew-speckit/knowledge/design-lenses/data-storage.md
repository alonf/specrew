# Data And Storage Lens

## Lens ID

`data-storage`

## Purpose

Expose persistence, ownership, consistency, migration, and lifecycle choices
before the plan assumes a database or silently avoids one.

## Applicability Signals

- The feature stores user, project, audit, workflow, cache, telemetry, or
  configuration data.
- The feature reads from or writes to an existing database, file, queue, blob,
  event log, cache, search index, or external data provider.
- Multiple components need the same data.
- Data correctness, reporting, privacy, retention, or migration matters.

## Design Decision Points

### Problem questions

- Is persistent storage required, or is derived/transient state enough?
- What owns each data type?
- How is retention handled?
- What data exists? — Light: recommend "the data the spec's entities name" (already in the spec) → spec.md Problem Context: Data inventory
- How sensitive is it? — Light: recommend "as product-domain's regime implies; no sensitive data stated when the regime is none" (the regime is already answered) → spec.md Problem Context: Data inventory
- How much is there, and how fast does it grow? — Light: recommend "not stated" (nothing to infer it from) → spec.md Problem Context: Data inventory

### Solution questions

- Which storage model fits: file, relational database, document store, key-value
  store, cache, blob, search index, queue, event stream, or hybrid?
- What consistency model is required: strong, eventual, transactional, or
  compensating?
- How are schema changes, migrations, backup, and restore handled?
- How does the design avoid services talking directly to another service's
  private database?

## Handed Forward From Product-Domain

Shown at every depth as recommendation lines, in this lens's one recommendation list. Each line reads the answer
from the feature's product-domain record (`areas.<key>`) and shows it as "product-domain: <answer>", or
"product-domain: not stated" when that is the answer. The human accepts it or changes it for this lens.

- product-domain `data_residency` — recommend "product-domain: <its answer, or not stated>" (already answered in product-domain; not asked again here) → spec.md Problem Context: Data residency
- product-domain `carry_over` — recommend "product-domain: <its answer, or not stated>" (already answered in product-domain; not asked again here) → spec.md Problem Context: Systems and data carried over

## Workshop Conduct

- **Diagram for this lens**: ERD (relational) or NoSQL document relations (references by JSON-path of identities) — render it as **console ASCII inline** so the human sees it in the conversation (a fenced mermaid block is source text, not a picture, on a terminal host); any mermaid/svg/html file is an *additional* artifact whose clickable `file:///` link you surface in the same message.
- **Facilitate, do not dictate**: raise the Design Decision Points above as a discussion, draw the ERD or document relations as ASCII and agree entities, keys, and per-service ownership, capture the human's decisions and explicit agreement, iterate until they say "move on" (and when a reply is NOT that phrase, open your next message with one line naming what you recorded and that the lens stays open until they type "move on" or "skip" - never leave the human to infer it from a repeated question), and record the agreement (never leave it only in the chat scrollback).
- **Re-invoke the `specrew-design-workshop` skill** before moving to the next lens.

## Question Bank

- What data must survive process restart, update, rollback, or uninstall?
- Who creates, reads, updates, deletes, exports, and audits the data?
- Is this system of record, projection, cache, or disposable working state?
- What is the expected data volume and growth pattern?
- What queries, reports, sorting, filtering, or aggregations are needed?
- Are ACID transactions required, or is BASE/eventual consistency acceptable?
- What happens when concurrent users update the same entity?
- What retention, deletion, residency, encryption, and PII rules apply?
- How will test fixtures prove migration and compatibility?

## Alternative Dimensions

- **Simplest**: local file or in-memory state with clear limits.
- **Reasonable**: explicit repository/accessor, migrations, ownership, and
  backup/restore story for the selected store.
- **By the book**: domain-owned persistence, schemas/contracts, migration
  tests, retention rules, audit model, consistency trade-off record, and
  reporting/projection strategy.

## Plan Obligations

- State whether storage is required and why.
- Name storage technology candidates and rejected options.
- Record ownership, schema/migration approach, consistency model, and data
  lifecycle.
- Include tests for producer/consumer compatibility, migration, or rollback
  when data shape changes.

## Validation Signals

- Tests exercise real serialization or migration paths where possible.
- Review confirms the chosen store matches query, consistency, and retention
  needs.
- Cross-service database access is explicitly absent or justified.

## Source Notes

- Book Chapters 2, 4, and 6.
- Course Modules 2 and 5.
