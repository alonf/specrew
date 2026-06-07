# Data Model: Retire Top-Level Evaluation Surface

**Feature**: 170-retire-evaluation-surface
**Date**: 2026-06-06
**Purpose**: Define entities, attributes, relationships, and validation rules for the retired evaluation surface and its preserved test-support scorer.

No persisted product data. This feature moves test infrastructure and deletes
stale repository artifacts; the only data shapes are transient test inputs and
outputs.

## Entity: ProcessQualityScore

**Purpose**: Transient result object computed by the scorer for a project's iterations.

### Attributes

| Attribute | Type | Required | Validation Rules | Description |
| --- | --- | --- | --- | --- |
| evaluated_at | datetime (UTC) | yes | ISO-8601 | When the scoring ran |
| project_path | string | yes | resolved absolute path | Project under evaluation |
| overall | number | yes | 0-100 | Aggregate process-quality score |
| summary | object | yes | per-criterion totals | Rollup across iterations |
| criteria | array | yes | known criterion ids | Artifact/phase-adherence criteria |
| iterations | array | yes | canonical statuses only (`planning, executing, reviewing, retro, complete, abandoned`) | Per-iteration scores |

### Lifecycle / Relationships

Created in-memory per scorer invocation; emitted as JSON (default) or a
PSCustomObject (`-PassThru`); never persisted by the scorer itself unless
`-WriteReport` is set.

## Entity: GeneratedProcessQualityReport

**Purpose**: Optional markdown rendering of a ProcessQualityScore.

### Attributes

| Attribute | Type | Required | Validation Rules | Description |
| --- | --- | --- | --- | --- |
| report_path | string | yes | defaults to `<project>/test-results/process-quality-report.md`; MUST resolve outside tracked top-level surfaces | Where the markdown lands |
| content | markdown | yes | UTF-8 no BOM | Human-readable score report |

### Lifecycle / Relationships

Written only on `-WriteReport`; the parent directory is created on demand
(missing-scratch-directory edge case). Treated as disposable test output —
never committed (FR-004).
