# Contract: Interaction-Model Validator Rules

**Feature**: 016 Substantive Interaction Model  
**Requirements**: FR-006–FR-024  
**Date**: 2026-05-13

---

## Overview

This contract defines the validator-facing interface for Feature 016. It specifies rule IDs,
severities, scopes, rollout behaviour, and output expectations for the interaction-model checks
added to `validate-governance.ps1`.

---

## Scope Contract

Feature 016 validator rules inspect only:

- commit subject history
- `.squad/decisions.md`
- Squad-authored boundary handoffs
- Squad-authored narration and artifact references
- governed artifacts updated by Squad

Feature 016 validator rules do **not** inspect:

- raw conversation transcripts
- user-typed authorization text directly
- arbitrary repository prose unrelated to Squad-authored handoffs/artifacts
- general-purpose parser normalization for non-canonical timestamp formats unless separately authorized

---

## Rule Catalog

| Rule ID | Severity | Iteration Behaviour | Input Scope |
| --- | --- | --- | --- |
| `validation-fail.bundled-boundary-advance` | hard fail | active in Iteration 1+ | commit history + decisions ledger |
| `soft-warning.thin-what-i-just-did` | soft warning | active in Iteration 1+ | boundary handoffs |
| `soft-warning.unspecific-stop-boundary` | soft warning | active in Iteration 1+ | boundary handoffs |
| `soft-warning.unactionable-user-request` | soft warning | active in Iteration 1+ | boundary handoffs |
| `soft-warning.bare-path-in-boundary-handoff` | soft warning | Iteration 1 only | boundary handoffs |
| `validation-fail.bare-path-in-boundary-handoff` | hard fail | Iteration 2 after proof | boundary handoffs |
| `soft-warning.bare-path-in-narration` | soft warning | active in Iteration 1+ | Squad-authored narration |
| `soft-warning.broken-file-url-reference` | soft warning | active in Iteration 1+ | `file:///` references |

---

## Output Contract

### Hard Fail Shape

Hard failures must:

- emit structured FAIL output
- return non-zero exit status
- name the offending commit pair / boundary gap / missing authorization where relevant
- include iteration or feature scope
- include a remediation hint

### Soft Warning Shape

Soft warnings must:

- remain advisory only
- preserve successful exit status when no hard failures are present
- name the triggering phrase/pattern where practical
- name the affected boundary or narration surface

### Single-Warning Aggregation Rule

`soft-warning.unactionable-user-request` emits **one warning per handoff** and must list each
missing component from:

- `boundary-name`
- `inspection-target`
- `verdict-required`

---

## Bare-Path Rollout Contract

### Detector Behaviour

The detector identifies bare path references in Squad-authored boundary handoffs that are outside
approved exemption contexts.

### Rollout Guarantee

- **Iteration 1**: emit `soft-warning.bare-path-in-boundary-handoff`
- **Iteration 2**: emit `validation-fail.bare-path-in-boundary-handoff`
- The detector logic is the same in both iterations; rollout changes by configuration/rule-table
  severity flip rather than rewrite

### Promotion Prerequisite

The severity flip may occur only after exemption-list integration tests show bounded false
positives.

### Post-Commit Verification Constraint

The Iteration 002 plan also requires proof on the **exact committed tree**:

- Commit Reference placeholders must be synchronized before the boundary is considered verified
- canonical `Recorded At` authoring uses UTC seconds precision
- stale-reference scans are mandatory after boundary commits even if no dedicated new validator rule
  is added in this slice

---

## Exemption Contract

Paths in the following contexts are exempt from bare-path findings:

- fenced code blocks
- inline code
- shell-command arguments
- log output
- JSON and YAML literals
- regex patterns
- file glob arguments
- existing URLs
- human-approved project-specific extension contexts in `.specrew/config.yml`

Project-specific exemption extensions are valid only when they include:

- approver name
- rationale
- recorded human approval

---

## File URL Contract

When Squad uses `file:///` references:

- the path must be formatted as a clickable file URI
- the file must exist
- non-existent file URLs emit `soft-warning.broken-file-url-reference`

---

## Proof Contract

Feature 016 proof must include:

- violating fixtures that emit the expected warning or FAIL
- compliant fixtures that emit no finding
- exemption-list fixtures demonstrating bounded false positives
- historical corpus cross-references for the new rows introduced in Iteration 2
- post-commit verification evidence showing commit-reference synchronization and exact-tree reruns

---

## Stability Guarantee

Feature 016 adds new rule IDs and extends existing governance validation, but it must not:

1. change the scope boundary to include raw user text
2. hard-fail Pillar 2 handoff-substance rules
3. bypass grandfathering for pre-Feature-016 history
4. rewrite the bare-path detector between Iteration 1 and Iteration 2
5. silently expand the decisions-ledger timestamp parser instead of documenting the canonical authoring format

---

## Traceability

- **US-1 / FR-006–FR-009**: bundled-boundary detection and authorization-shape fidelity
- **US-2 / FR-010–FR-014**: handoff-substance warning rules
- **US-3 / FR-015–FR-019**: `file:///` navigation, bare-path warnings/failures, exemption handling
- **FR-020–FR-024**: corpus rows, replay proof, documentation updates, historical cross-references
