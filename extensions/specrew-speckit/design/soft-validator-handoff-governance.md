# Soft Validator Design: Handoff Governance

## Purpose

This document defines the Iteration 002 implementation target for the coordinator handoff soft validator.

## Scope

The validator must inspect the final user-facing coordinator response and emit **soft quality warnings** when the response is structurally incomplete or jargon-first.

It must **not** hard-block response delivery.

## Detection Rules

### Rule 1: Missing Current Progress Status

Flag when the response does not explicitly state what is complete, changed, verified, open, or blocked.

### Rule 2: Missing Recommended Next Step

Flag when the response does not name one immediate next action, including `no further action needed` when appropriate.

### Rule 3: Jargon-First Lead

Scan the lead sentence of each handoff section. Flag when that lead contains three or more governance acronyms, lifecycle labels, or schema-field names **without** a plain-language paraphrase first.

This rule is the formalized acceptance-test seed from `.specrew/quality/known-traps.md` row 12 (`human-handoff`).

## Operational Definition

### Input Surface

- Final assembled user-facing coordinator response text
- Optional metadata that identifies the response mode (`lightweight`, `standard`, `full`) if already available

### Section Model

The validator should support both:

1. explicit three-section handoffs (`What I just did`, `Why I stopped`, `What I need from you`)
2. compact lightweight handoffs where both semantic fields appear in one paragraph

### Governance-Term Candidate Set

The Iteration 002 implementation should start with a configurable list that includes:

- `before-implement`
- `hardening-gate`
- `approval ref`
- `implementation approval`
- `traceability`
- `schema`
- `FR-`
- `TG-`
- `gate`
- `validator`

This list may expand, but the human-handoff trap examples above must be detectable without ambiguity.

## Pseudo-Code

```text
input = final coordinator response
normalized = normalize whitespace
sections = split into known handoff sections if headings exist
if no headings:
  sections = [normalized]

warnings = []

if not contains_explicit_progress_status(normalized):
  warnings += "soft-warning.missing-progress-status"

if not contains_explicit_next_step(normalized):
  warnings += "soft-warning.missing-next-step"

for each section in sections:
  lead = first sentence(section)
  governance_hits = count_governance_terms(lead)
  has_plain_language_paraphrase = detect_plain_language_paraphrase_before_formal_terms(lead)

  if governance_hits >= 3 and not has_plain_language_paraphrase:
    warnings += "soft-warning.jargon-first-lead"

if response_mentions_blocker_or_failed_or_skipped_checks(normalized) and
   not blocker_or_gap_is_plainly_disclosed(normalized):
  warnings += "soft-warning.hidden-blocker-or-risk"

return warnings
```

## Detection Notes

### `contains_explicit_progress_status`

Treat as present when the response explicitly communicates one or more of:

- completed work
- changed or reviewed artifacts
- verification run or no verification needed
- open blocker, risk, or remaining limitation

### `contains_explicit_next_step`

Treat as present when the response explicitly communicates one immediate next action, such as:

- review a file or change
- run a manual scenario
- approve or clarify a decision
- continue with the next implementation slice
- `no further action needed`

### `detect_plain_language_paraphrase_before_formal_terms`

Treat as true when the lead begins with a human-readable explanation of what is needed or what happened before the formal labels appear.

Compliant pattern:

> We need one human decision before moving forward: confirm the handoff wording is ready. Formal references: before-implement review, hardening-gate evidence.

Non-compliant pattern:

> before-implement gate, hardening-gate sign-off, implementation approval evidence reuse

## Integration Points

### 1. Post-Response Coordinator Output

Run after the coordinator assembles the final user-facing response and before the response is logged as final quality evidence.

### 2. Governance Surface Registration

Map warnings to the checklist surface in `extensions/specrew-speckit/checklists/coordinator-handoff-governance.md`.

### 3. Validation Lane Registration

Iteration 002 must add this validator to the authorized validation lane command set and document the exact command list in both plan and hardening-gate evidence.

## Expected Output Shape

The validator should emit machine-readable findings plus a short human-readable summary. Example:

```text
status: warn
findings:
  - soft-warning.jargon-first-lead
summary:
  - Rewrite the lead sentence in plain language before formal lifecycle references.
```

## Iteration 002 Implementation Sketch

1. Create `extensions/specrew-speckit/validators/handoff-governance-validator.ps1`.
2. Load the checklist rule names from the governance checklist surface or keep them in a shared rule table.
3. Accept coordinator response text as direct input or from the post-response path.
4. Emit warnings only; do not set a blocking exit code for handoff incompleteness alone.
5. Add integration tests that exercise the real validator runtime path with:
   - a jargon-first fixture that must warn
   - a plain-language-first fixture that must pass

## Acceptance Target

An Iteration 002 implementer should be able to build the runtime validator without guessing:

- what to scan
- which patterns to flag
- where to integrate it
- why the warnings stay soft instead of hard-blocking
