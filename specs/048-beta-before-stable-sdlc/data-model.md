# Data Model: Beta-Before-Stable SDLC Discipline

**Feature**: `048-beta-before-stable-sdlc`  
**Date**: 2026-05-26  
**Purpose**: Define release lifecycle, handoff, and audit-trail entities for
F-048.

## Entity: ReleaseLifecycleStep

**Purpose**: A numbered release action from Step 5 through Step 14.

### Attributes

| Attribute | Type | Required | Validation Rules | Description |
| --- | --- | --- | --- | --- |
| `step_number` | integer | yes | Must be 5-14 | Canonical SDLC step number. |
| `actor` | enum | yes | `agent` or `human` | Owner of the action or verdict. |
| `action` | string | yes | Non-empty | Plain-language action. |
| `required_evidence` | string | yes | Non-empty for publish/verdict steps | Evidence needed before advancing. |
| `next_on_success` | integer/string | yes | Step number or `stop` | Next step after success. |
| `next_on_failure` | integer/string | no | Step number or status | Failure path, especially Step 12. |

### Lifecycle / Relationships

Lifecycle steps are static policy data embedded in the coordinator handoff and
release discipline documentation. They are not persisted as mutable runtime
state, but release audit records reference the completed beta/stable steps.

## Entity: FeatureCloseoutHandoff

**Purpose**: The user-visible handoff block emitted at feature-closeout.

### Attributes

| Attribute | Type | Required | Validation Rules | Description |
| --- | --- | --- | --- | --- |
| `agent_next_action` | string/list | yes | Must include Steps 5-14 | Agent-owned SDLC execution row. |
| `human_action_needed` | string/list | yes | Must include approvals and Step 11 PASS/FAIL | Human-owned approval/verdict row. |
| `boundary` | string | yes | `feature-closeout` | Lifecycle boundary. |
| `resume_instruction` | string | yes | Non-empty | How the user resumes after the pause. |

### Lifecycle / Relationships

Generated from coordinator prompt templates. Tests validate that it includes
the ownership split and all release steps before implementation can close.

## Entity: ReleaseAuditRecord

**Purpose**: Structured release evidence for one feature.

### Attributes

| Attribute | Type | Required | Validation Rules | Description |
| --- | --- | --- | --- | --- |
| `schema` | string | yes | `specrew.release-audit.v1` | Schema identifier. |
| `feature_ref` | string | yes | Matches feature directory ref | Released feature. |
| `pr_number` | integer | yes | Positive integer | Feature PR number. |
| `merge_sha` | string | yes | Git SHA-like string | Merge commit SHA. |
| `version` | string | yes | SemVer core | Release version. |
| `beta_attempts` | list | yes | At least one for runtime releases | Beta publish/verdict attempts. |
| `stable_tag` | string | conditional | Required only after PASS | Stable tag. |
| `stable_verification` | string | conditional | Required only after stable publish | Stable package verification. |
| `audit_mode` | enum | yes | `trailing-pr` or `direct-main` | Capture mode. |
| `status` | enum | yes | `incomplete`, `failed`, `complete` | Audit completion state. |

### Lifecycle / Relationships

Created after feature PR merge and updated after beta/stable publication. It is
stored inside the front matter of one per-feature audit narrative file.

## Entity: BetaAttempt

**Purpose**: One prerelease publish and human validation attempt.

### Attributes

| Attribute | Type | Required | Validation Rules | Description |
| --- | --- | --- | --- | --- |
| `tag` | string | yes | `vX.Y.Z-beta.N` | Beta tag pushed by the agent. |
| `published` | boolean | yes | Must be true before verdict | Whether PSGallery publication was verified. |
| `verification` | string | yes | Non-empty | Package verification command/output summary. |
| `human_verdict` | enum | yes | `PASS` or `FAIL` | Manual prerelease test verdict. |
| `evidence` | string | yes | Non-empty | Human or agent evidence summary. |

### Lifecycle / Relationships

Each failed beta creates another BetaAttempt with incremented `beta.N`. Stable
release is valid only after the latest relevant attempt has `PASS`.

## Entity: ReleaseAuditNarrative

**Purpose**: Human-readable release timeline for one feature.

### Attributes

| Attribute | Type | Required | Validation Rules | Description |
| --- | --- | --- | --- | --- |
| `path` | string | yes | `docs/releases/<feature-ref>.md` | Artifact path. |
| `front_matter` | ReleaseAuditRecord | yes | Valid schema | Structured record. |
| `summary` | markdown | yes | Non-empty | Release narrative. |
| `timeline` | markdown | yes | Includes beta and stable steps | Ordered release events. |

### Lifecycle / Relationships

Committed after stable publication. Locked-main repositories use a trailing
one-file PR containing this file; direct-main repositories may commit it
directly when explicitly configured.

## Entity: ReleaseAuditConfig

**Purpose**: Project-level behavior switch for audit capture.

### Attributes

| Attribute | Type | Required | Validation Rules | Description |
| --- | --- | --- | --- | --- |
| `release_audit_direct_to_main` | boolean | no | Defaults false | Allows direct-main audit commit when true. |

### Lifecycle / Relationships

Read from `.specrew/config.yml`. Missing or false uses protected-main friendly
trailing PR behavior.
