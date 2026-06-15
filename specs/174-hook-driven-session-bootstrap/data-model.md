# Data Model: Hook-Driven Session Bootstrap

**Feature**: 174-hook-driven-session-bootstrap
**Date**: 2026-06-08
**Purpose**: Entities, attributes, and validation rules for the bootstrap.

No new persisted store is introduced. The handover and session-state files are owned or
extended per Proposal 130 and F-171; this feature adds an advisory, local-only SessionStart
marker plus the in-memory directive and journal-record contracts.

## Entity: Bootstrap Directive

**Purpose**: the hook-injected, data-oriented instruction the agent consumes (transient
`PSCustomObject`, never persisted).

| Attribute | Type | Required | Validation | Description |
| --- | --- | --- | --- | --- |
| `mode` | enum | yes | `full` / `welcome-back` / `cleared-anchor` | bootstrap mode |
| `sources` | object | yes | — | handover/anchor/marker presence + validity |
| `required_reads` | string[] | no | paths exist | files the agent must read (handover) |
| `render_first` | bool | yes | always `true` | prose-before-picker contract (FR-004/020) |
| `menu_intent` | enum | yes | resume/new/pick set | which menu to render |
| `validation_findings` | string[] | no | — | why full-not-resume; what was cleared |
| `dedupe_key` | string | yes | non-empty | one bootstrap per session (FR-007) |

## Entity: Session Anchor

**Purpose**: saved lifecycle pointer. **Resumable only when** project-local, active, not
merged/closed, and portable.

| Attribute | Type | Required | Validation | Description |
| --- | --- | --- | --- | --- |
| `feature_ref` | string | yes | resolves project-locally (never absolute path) | the feature |
| `boundary` | enum | yes | canonical boundary | lifecycle position |
| `iteration` / `task` | string | no | — | finer position |
| `recorded_at` | timestamp | yes | — | when written |
| `source_path` | string | no | re-resolved if absolute (FR-015) | non-authoritative |

## Entity: Handover Record (Proposal 130-owned)

`.md` + index. Carries timestamp, last message, recommended next step. **Read-validated**
against current project state before it is treated as authoritative resume (FR-017).

## Entity: SessionStart Marker (advisory, local-only, NOT committed)

| Attribute | Type | Required | Description |
| --- | --- | --- | --- |
| `started_at` | timestamp | yes | freshness window default 1h, configurable (FR-019) |
| `host` | string | yes | which host launched |
| `project_root` | string | yes | for portability checks |
| `branch` | string | yes | current branch |
| `head_commit` | string | yes | for unclean-exit diff (marker newer than handover) |

## Entity: Bootstrap Mode

Classification result: `full` (fresh/cleared) · `welcome-back` (valid active recent) ·
`cleared-anchor` (anchor invalid → cleared, full menu with a reason line).
