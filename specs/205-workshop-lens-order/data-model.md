# Data Model: Workshop Lens Order

**Feature**: 205-workshop-lens-order
**Date**: 2026-11-10
**Purpose**: Define the entities this feature adds or changes, their attributes, validation rules and relationships.

This feature adds no new persisted runtime state. The data is the lens catalog and the lens files, and a confirmed
agenda record keeps its existing shape (FR-013: no new field).

## Entity: LensCatalogEntry (`index.yml` → `lenses[]`)

**Purpose**: one lens, its position in the single order, and its space.

### Attributes

| Attribute | Type | Required | Validation Rules | Description |
| --- | --- | --- | --- | --- |
| `id` | string | yes | `^[a-z][a-z0-9-]{1,63}$`, unique | lens id |
| `file` | string | yes | `<id>.md` exists beside `index.yml` | lens file |
| `space` | enum | yes (new) | one of problem, solution, both; must agree with the sub-headings the file fills (FR-005 check c) | the lens's question space |
| `default_phase` | string | yes | unchanged | existing metadata |
| `categories` | string[] | yes | unchanged | existing metadata |
| (position) | int | implicit | list order | **the order**; there is no separate order field to drift |

### Lifecycle / Relationships

`index.yml` changes only when a maintainer edits it. Two readers use it:

- `confirm-workshop-agenda.ps1` reads it at runtime, for coverage and relative order.
- The parity test reads it and compares every order surface and every lens file against it.

Each entry owns exactly one LensFile.

## Entity: LensFile (`design-lenses/<id>.md`)

**Purpose**: the lens's questions, tagged by space.

### Attributes

| Attribute | Type | Required | Validation Rules | Description |
| --- | --- | --- | --- | --- |
| `## Design Decision Points` | section | yes | still present (the extractor and the skill read it) | container |
| `### Problem questions` | sub-section | yes | list items, or one line `No problem questions: <reason>` | problem-space questions |
| `### Solution questions` | sub-section | yes | list items, or one line `No solution questions: <reason>` | solution-space questions |
| decision point | list item (bullet or numbered) | at least 1 overall | sits under exactly one sub-heading (FR-005 check b) | one question |

### Lifecycle / Relationships

`Get-SpecrewLensDecisionPoints` returns the bullets under both sub-headings. Its regex stops at `^##\s+`, not at
`###`. The counts are fixed by SC-002, and product-domain's numbered list stays at 0 (DRIFT-003).

## Entity: OrderSurface (internal to the test)

**Purpose**: a shipped-text location that lists lenses.

### Attributes

| Attribute | Type | Required | Validation Rules | Description |
| --- | --- | --- | --- | --- |
| `path` | string | yes | tracked, inside the sweep scope | file |
| `kind` | enum | yes | full (named in the test) or partial (any other run) | rule applied |
| `ids` | string[] | yes | full: exactly the `index.yml` order and membership; partial: relative order | lens ids found |
| `line` | int | yes | first line of the block | reported location |

### Lifecycle / Relationships

Each OrderSurface is built fresh on every test run from the block rules in plan.md, and nothing is persisted.

## Entity: Exemption (internal to the test)

**Purpose**: a run that must differ from `index.yml`.

### Attributes

| Attribute | Type | Required | Validation Rules | Description |
| --- | --- | --- | --- | --- |
| `path` and line pattern | string | yes | must match an actual run, otherwise the test fails (no stale exemptions) | which run |
| `reason` | string | yes | non-empty | why it must differ |

### Lifecycle / Relationships

The list ships empty. Any entry the implementation needs is brought to the maintainer before it is added.

## Entity: ProblemGapEntry (`iterations/001/problem-gap-list.md`)

**Purpose**: iteration 2's input, one entry per lens.

### Attributes

| Attribute | Type | Required | Validation Rules | Description |
| --- | --- | --- | --- | --- |
| `lens` | id | yes | all 11 lenses present | lens |
| `gaps` | text | yes | a gap description, `none seen`, or `n/a (solution lens)` | problem-side gaps |

### Lifecycle / Relationships

The tagging task writes it once. Iteration 2's workshop reads it, and no lens question changes because of it in
iteration 1.
