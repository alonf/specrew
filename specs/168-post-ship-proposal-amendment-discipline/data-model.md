# Data Model: Post-Ship Proposal Amendment Discipline

**Feature**: 168-post-ship-proposal-amendment-discipline
**Date**: 2026-06-06
**Purpose**: Define entities, attributes, relationships, and validation rules for post-ship proposal amendment discipline.

## Entity: ProposalRecord

**Purpose**: Represents one proposal markdown file and its governance front matter.

### Attributes

| Attribute | Type | Required | Validation Rules | Description |
| --- | --- | --- | --- | --- |
| `path` | string | yes | Must point to a proposal markdown file or synthetic fixture. | Source file being evaluated. |
| `proposal` | string | yes | Must match the proposal number convention in real proposal files. | Stable proposal number. |
| `title` | string | yes | Non-empty. | Human-readable proposal title. |
| `status` | enum | yes | One of `candidate`, `draft`, `active`, `shipped`, `superseded`, `withdrawn`, plus existing legacy statuses handled explicitly. | Mutability source of truth. |
| `normative_sections` | list | no | Derived from markdown headings. | Sections whose edits may change behavior or obligations. |
| `post_ship_amendments` | list | no | Only applies to shipped or superseded proposals. | Structured post-ship amendment entries. |

### Lifecycle / Relationships

A `ProposalRecord` is read from markdown front matter and body text during validation or status rendering. It owns zero or more `PostShipAmendment` records. Its `status` determines the `ProposalMutabilityClass` used by docs, validation, and review.

## Entity: ProposalMutabilityClass

**Purpose**: Defines how normative proposal edits are interpreted for a proposal status.

### Attributes

| Attribute | Type | Required | Validation Rules | Description |
| --- | --- | --- | --- | --- |
| `status` | enum | yes | Must map to a known proposal status. | Proposal status being interpreted. |
| `allowed_normative_edits` | string | yes | Must describe maintainer behavior. | Whether body text may change freely, needs coordination, or is historical. |
| `requires_post_ship_amendment` | boolean | yes | True only for shipped and superseded normative deltas. | Whether new normative behavior must be delta-tracked. |
| `allowed_direct_edits` | list | yes | Includes typo, broken link, errata, and supersession metadata where applicable. | Direct edits that do not create new scope. |

### Lifecycle / Relationships

The mutability class is derived from `ProposalRecord.status`. It controls whether validator checks inspect body changes for amendment discipline and how reviewer guidance interprets proposal-touching commits.

## Entity: PostShipAmendment

**Purpose**: Records a structured delta from shipped or superseded proposal behavior.

### Attributes

| Attribute | Type | Required | Validation Rules | Description |
| --- | --- | --- | --- | --- |
| `amendment-id` | string | yes | Stable local id such as `A1`; unique within a proposal. | Identifier used by tasks, review, and closeout evidence. |
| `date` | date | yes | ISO date preferred. | Date the delta was recorded. |
| `status` | enum | yes | `proposed`, `accepted-unimplemented`, `active`, `implemented`, `rejected`, or `superseded`. | Current amendment lifecycle state. |
| `delta-summary` | string | yes | Non-empty and phrased as a delta from shipped behavior. | What changed. |
| `implementation-owner` | string | yes | Follow-up proposal, feature, debt entry, or `none-yet`. | Where implementation responsibility lives. |
| `preserve` | list/string | yes | Must identify shipped behavior that must not regress. | Compatibility requirements. |
| `tests-required` | list/string | yes | Must identify characterization or regression test expectations. | Evidence required before implementation can close. |

### Lifecycle / Relationships

A `PostShipAmendment` belongs to one shipped or superseded `ProposalRecord`. Accepted but unimplemented states feed proposal index/status surfacing. Implemented or superseded states remain in the original proposal and are not copied into a generated amendment index in this slice.

## Entity: ProposalDiffFinding

**Purpose**: Represents a validator observation about unsafe proposal mutation or malformed amendment data.

### Attributes

| Attribute | Type | Required | Validation Rules | Description |
| --- | --- | --- | --- | --- |
| `finding_id` | string | yes | Stable validator id. | Machine-readable finding name. |
| `severity` | enum | yes | Warning for shipped/superseded normative body edits in this slice. | Validation severity. |
| `proposal_path` | string | yes | Must identify the affected proposal or fixture. | File that produced the finding. |
| `changed_area` | string | no | Required for normative edit findings. | Heading or area that appears unsafe. |
| `message` | string | yes | Must explain expected amendment path. | Human-readable warning. |

### Lifecycle / Relationships

`ProposalDiffFinding` instances are emitted by governance validation. Malformed amendment records produce separate findings from unsafe normative body edits so maintainers can repair the right problem.

## Entity: AmendmentStatusSurface

**Purpose**: Represents human-visible proposal index or status output for unimplemented amendments.

### Attributes

| Attribute | Type | Required | Validation Rules | Description |
| --- | --- | --- | --- | --- |
| `proposal` | string | yes | Matches source proposal. | Proposal number/title shown in status output. |
| `proposal_status` | enum | yes | Usually shipped or superseded for amendment surfacing. | Baseline proposal state. |
| `amendment_id` | string | yes | Matches source amendment id. | Visible amendment reference. |
| `amendment_status` | enum | yes | Shows `accepted-unimplemented` or `active` backlog states. | Work-routing state. |

### Lifecycle / Relationships

The status surface reads from original proposal files. It shows unimplemented amendments but does not create a second generated amendment index.

## Entity: DeltaImplementationEvidence

**Purpose**: Captures review and closeout proof that amendment implementation stayed delta-based.

### Attributes

| Attribute | Type | Required | Validation Rules | Description |
| --- | --- | --- | --- | --- |
| `amendment_ref` | string | yes | Amendment id or superseding proposal reference. | Delta source. |
| `delta_summary` | string | yes | Must match or summarize source amendment. | Implemented change. |
| `preserved_behavior` | string/list | yes | Must identify shipped behavior preserved. | Regression guard. |
| `tests_evidence` | string/list | yes | Must cite tests or characterization evidence. | Verification. |
| `final_disposition` | enum | yes | `implemented` or `superseded` for closed amendment work. | Closeout state. |

### Lifecycle / Relationships

`DeltaImplementationEvidence` is produced during review and closeout, not during initial proposal parsing. It links implementation work back to the amendment and preserves shipped behavior explicitly.
