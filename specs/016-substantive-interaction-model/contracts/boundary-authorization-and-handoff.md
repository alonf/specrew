# Contract: Boundary Authorization and Handoff

**Feature**: 016 Substantive Interaction Model  
**Requirements**: FR-001–FR-015  
**Date**: 2026-05-13

---

## Overview

This contract defines the human-facing interaction boundary for Feature 016:

1. how Squad records boundary authorization in `.squad/decisions.md`
2. how Squad renders a final boundary-stop handoff
3. what the human can rely on when approving the next lifecycle step

Feature 017 visual-artifact behaviour is out of scope.

---

## Boundary Authorization Contract

### Single-Boundary Advance Rule

- One human authorization advances **at most one boundary**
- `"continue"` means: advance to the **next single boundary stop**, then halt and ask again
- Squad must not emit multiple boundary commits without intervening explicit authorization

### Canonical Authorization Entry Shape

```markdown
## YYYY-MM-DDTHH:MM:SSZ — Authorization: <boundary-name>

- **Decision ID**: authorization-feature-016-iter-<NNN>-<boundary-name>
- **Type**: authorization | sign-off
- **Boundary**: <boundary-name>
- **Approving Human**: <name>
- **Recorded At**: <ISO 8601 UTC timestamp>
- **Commit Reference**: <pending | short-hash>
- **Authorization Text**: <verbatim authorization phrase from user>
```

### Timestamp Precision Rule

- `Recorded At` uses canonical UTC ISO 8601 **seconds precision** for Feature 016 authored entries
- fractional seconds are not part of the canonical authoring contract for this feature
- if broader parser support is ever needed, it must be authorized explicitly in a later feature

### Commit Reference Lifecycle

- `Commit Reference: pending` is allowed only as a temporary boundary-time placeholder
- the same post-commit verification cycle must replace `pending` with the actual boundary commit hash
- a boundary is not verification-ready while the matching authorization entry still carries `pending`

### Paired Authorization Rule

When one pasted authorization covers both hardening-gate sign-off and implementation
authorization:

- Squad auto-generates **two distinct entries**
- both entries preserve the same verbatim authorization text
- the user may review or override metadata during boundary inspection
- Squad must **not** collapse the pair into one combined multi-boundary record

---

## Boundary Handoff Contract

### Response Type

For a real human-blocked lifecycle stop, Squad must emit the existing three-section final stop
message:

1. **What I just did**
2. **Why I stopped**
3. **What I need from you**

### Post-Commit Verification Rule

For boundaries that end with a commit and a human-blocked handoff:

1. synchronize the matching authorization entry to the real commit hash
2. confirm the cited `file:///` references still resolve on the exact committed tree
3. rerun the governed verification commands on that exact committed tree before claiming readiness
4. state any remaining defer explicitly instead of implying the post-commit checks already happened

### Section Semantics

#### 1. What I just did

- names concrete work performed
- for planning / implementation / review / retro: includes at least 3 specific identifiers **and**
  at least 50 words
- for iteration-closeout / feature-closeout: includes at least 3 identifiers **or** at least
  50 words

Accepted identifiers:

- commit hashes
- `file:///` artifact URIs
- `FR-###` references
- task identifiers
- authorization or decision references

#### 2. Why I stopped

- explicitly names the boundary being entered
- states the real reason Squad cannot safely continue without a human decision

#### 3. What I need from you

- names the exact boundary being authorized
- cites the inspection target(s), using `file:///` links where applicable
- states the verdict required

---

## Click-Through Navigation Rule

- Squad-authored artifact references in boundary handoffs must use `file:///` URI form
- bare paths are forbidden outside approved exemption contexts
- `file:///` references should point to files that actually exist

---

## Exempt Path Contexts

These contexts are exempt from bare-path enforcement:

- fenced code blocks
- inline code spans
- shell-command arguments
- log output
- JSON literal values
- YAML literal values
- regex patterns
- file glob arguments
- existing URL contexts
- project-specific approved extensions recorded in `.specrew/config.yml` with approver name and
  rationale

---

## Worked Examples

### Compliant Single-Boundary Authorization

```text
User: Continue.
Outcome: Squad advances to the next single boundary stop only, records the matching authorization,
and halts again for the next boundary.
```

### Compliant Paired Authorization Recording

```text
User paste authorizes both hardening-gate sign-off and implementation authorization.
Outcome: Squad creates two `.squad/decisions.md` entries:
1. hardening-gate-signoff
2. implementation
```

### Compliant Boundary Handoff

```text
What I just did
I updated feature 016, substantive interaction model, across file:///C:/Dev/Specrew/.github/agents/squad.agent.md,
file:///C:/Dev/Specrew/extensions/specrew-speckit/scripts/validate-governance.ps1, and FR-006 through FR-013,
and I verified the planning-boundary stop message now names the next boundary explicitly, preserves the
paired authorization-recording shape, keeps validator scope limited to Squad-authored handoffs, and
retains the approved Iteration 1 soft-warning rollout for bare-path handling before any later
Iteration 2 promotion path is allowed.

Why I stopped
I stopped at the review-boundary because the next lifecycle step requires explicit human review of the
governance wording before another boundary commit can be emitted.

What I need from you
Review file:///C:/Dev/Specrew/specs/016-substantive-interaction-model/plan.md and approve or reject the
review-boundary wording for the next step.
```

### Compliant Post-Commit Verification Note

```text
Post-commit verification
- Updated Commit Reference from pending to 59f1b21 in file:///C:/Dev/Specrew/.squad/decisions.md
- Rechecked cited artifacts and confirmed file:///C:/Dev/Specrew/specs/016-substantive-interaction-model/quickstart.md still resolves
- Re-ran file:///C:/Dev/Specrew/extensions/specrew-speckit/scripts/validate-governance.ps1 on the exact committed tree before requesting the next verdict
```

### Non-Compliant Bundled Advance

```text
Squad records review-boundary, retro-boundary, and iteration-closeout commits after one "continue"
authorization.
```

Expected result: invalid; must be rejected by validator and guidance.

---

## Stability Guarantee

Feature 016 preserves the existing three-section stop-message format and extends its content rules.
It does not redefine the lifecycle, does not authorize Feature 017 visual work, and does not broaden
validation into user-authored transcript text.
