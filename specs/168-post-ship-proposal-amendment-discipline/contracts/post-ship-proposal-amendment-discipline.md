# Contract: Post-Ship Proposal Amendment Discipline Public Surface

**Feature**: 168-post-ship-proposal-amendment-discipline
**Stability**: pre-1.0

## Proposal Markdown Contract

Shipped and superseded proposals may carry a structured `Post-Ship Amendments` section. Candidate and draft proposals continue to evolve normally. Active proposals use active-feature amendment flow and are not governed by the post-ship amendment section in this slice.

### Amendment Fields

| Field | Type | Required | Purpose | Errors |
| --- | --- | --- | --- | --- |
| `amendment-id` | string | yes | Stable local id such as `A1`. | Missing or duplicate ids produce malformed-amendment findings. |
| `date` | date/string | yes | Date the delta was recorded. | Missing dates produce malformed-amendment findings. |
| `status` | enum | yes | Amendment lifecycle state. | Unknown statuses produce malformed-amendment findings. |
| `delta-summary` | string | yes | States the delta from shipped behavior. | Missing summaries produce malformed-amendment findings. |
| `implementation-owner` | string | yes | Follow-up owner or `none-yet`. | Missing owners produce malformed-amendment findings. |
| `preserve` | string/list | yes | Shipped behavior that must not regress. | Missing preserve data blocks delta-based review. |
| `tests-required` | string/list | yes | Characterization or regression tests needed. | Missing test data blocks delta-based review. |

### Invariants

- Shipped and superseded normative deltas must be represented as amendments or new/superseding proposals.
- Typo, broken link, historical errata, and supersession-pointer edits may remain direct edits.
- Implemented amendments remain in the original proposal and are surfaced by index/status.
- This slice does not create a generated amendment index.

## Validator Finding Contract

Governance validation emits warning-first findings for unsafe shipped or superseded proposal edits and separate findings for malformed amendment records.

### Findings

| Symbol | Severity | Purpose | Errors |
| --- | --- | --- | --- |
| `WARN [post-ship-proposal] normative-body-edit` | warning | Warns that a shipped/superseded proposal appears to have normative body edits outside `Post-Ship Amendments`. | Does not hard-fail in this slice. |
| `WARN [post-ship-proposal] malformed-amendment` | warning | Identifies missing required fields or invalid amendment statuses. | Kept separate from unsafe body edits. |
| `post-ship-amendment-backlog-visible` | evidence/status assertion | Confirms unimplemented amendments are visible in status output. | Missing visibility fails focused tests if implemented as an assertion. |

### Invariants

- Candidate and draft body edits do not trigger shipped/superseded amendment warnings.
- Active proposals do not use the post-ship amendment enforcement path.
- Valid amendment-section edits do not trigger body-edit warnings solely because the proposal is shipped.
- The validator does not attempt full semantic diffing.

## Review Evidence Contract

Review signoff for amendment implementation must prove the work is delta-based.

### Required Evidence

| Symbol | Signature | Purpose | Errors |
| --- | --- | --- | --- |
| `amendment_ref` | amendment id or proposal ref | Identifies the delta being implemented. | Missing reference blocks review signoff. |
| `delta_summary` | string | Describes delivered delta. | Must not restate the whole shipped proposal as scope. |
| `preserved_behavior` | string/list | Names shipped behavior that stayed intact. | Missing preserve list blocks review signoff. |
| `tests_evidence` | path/list | Cites characterization or regression tests. | Smoke-only evidence is insufficient for behavior deltas. |
| `final_disposition` | enum | Records `implemented` or `superseded` at closeout. | Required before amendment closeout. |

### Invariants

- Review compares implementation against the amendment delta, not the whole shipped proposal body.
- Review rejects unrelated shipped-scope reimplementation unless explicitly approved and recorded as a new delta.
- Any touched shipped proposal must include a review explanation of why the touch was allowed.

## Index and Status Contract

Proposal index/status surfaces show unimplemented post-ship amendment backlog without creating a new generated amendment index.

### Output Shape

| Field | Required | Purpose |
| --- | --- | --- |
| Proposal number/title | yes | Identifies the historical proposal. |
| Proposal status | yes | Shows shipped or superseded baseline state. |
| Amendment id | yes for unimplemented amendments | Routes follow-up work. |
| Amendment status | yes for unimplemented amendments | Shows `accepted-unimplemented` or `active`. |

### Invariants

- `implemented`, `rejected`, and `superseded` amendments remain in the proposal but do not appear as unimplemented backlog.
- Multiple unimplemented amendments are all visible.
- The status surface remains derived from source proposal files.
