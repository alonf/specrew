# Contract: Boundary Authorization Prompt Truth Public Surface

**Feature**: 139-boundary-authorization-prompt-truth
**Stability**: pre-1.0

## `specrew start` Generated State and Prompt

`specrew start` is the public user-facing command that generates `.specrew/start-context.json` and `.specrew/last-start-prompt.md`. This feature changes the contract for those generated artifacts, not the lifecycle boundary model itself.

### Public Surface

| Surface | Signature / Shape | Purpose | Errors |
| --- | --- | --- | --- |
| `specrew start` | `specrew start [--host <host>] [--autonomous] <feature request>` | Starts or resumes Specrew lifecycle coordination. | Must not silently understate human-judgment boundaries. |
| `boundary_enforcement.policy_classes` | JSON object in `.specrew/start-context.json` | Auditable resolved snapshot of boundary policy classes from `.specrew/config.yml`. | Missing or incomplete snapshot is non-compliant. |
| `last-start-prompt.md` lifecycle guidance | Markdown generated prompt section | Teaches host agents which boundaries require human judgment. | Must not contain beta2-bad four-gate-only or auto-chain guidance. |
| Human re-entry packet contract | Markdown generated prompt instructions | Defines required six-section stop packet. | Missing section or thin approval-only guidance is non-compliant. |

### Invariants

- `.specrew/config.yml` is the authoritative boundary policy source.
- `boundary_enforcement.policy_classes` is a resolved snapshot for auditability.
- A boundary transition whose policy class is `human-judgment-required` requires explicit human authorization unless autonomous mode or an explicit recorded authorization applies.
- `clarify -> plan` requires human authorization under the default policy.
- One approval advances at most one lifecycle boundary.
- Free-form discussion or feedback is not approval unless the human explicitly authorizes the next boundary.

## Human Re-entry Packet

Every human-judgment boundary stop must render the canonical six sections.

### Packet Sections

| Section | Required Content |
| --- | --- |
| `What I just did` | Meaningful past outcome, artifacts created/changed, committed evidence, decisions, assumptions, scope changes, risks/uncertainties. |
| `Why I stopped` | Exact lifecycle boundary and concrete reason human judgment is needed. |
| `What needs your review` | Bare `file:///` links, exact sections, high-impact choices, assumptions, uncertainties, and safe-skim guidance. |
| `What happens next` | Next phase, artifacts, code/planning status, harder-to-change decisions, and next boundary stop. |
| `Discussion prompts` | One to three contextual, proactive, decision-reducing prompts; or the general no-known-dilemma review question. |
| `What I need from you` | Allowed response shapes and explicit approval requirement. |

### Invariants

- A stop packet without `Why I stopped` is non-compliant.
- A stop packet asking only `approve?` without discussion prompts is non-compliant.
- Targeted discussion prompts require context unless there is no known dilemma and the general review question is used.
- Review targets use bare `file:///` links.
- The future generated packet is the primary stop contract and must not require duplicate legacy `=== SPECREW HANDOFF ===` output for the same stop.
- Discussion prompts are shown together with the guidance: "You can answer any prompt that should change direction, or approve with the defaults."
- Response options include approve as-is, approve with instructions, send back, and discuss prompt `#N`.
- `discuss prompt #N` enters a short discussion loop for that item only, then requires the agent to summarize the decision and request explicit boundary approval again.

## Narrow Status Approval Check

The feature adds a narrow check for fabricated approval semantics.

### Public Surface

| Surface | Signature / Shape | Purpose | Errors |
| --- | --- | --- | --- |
| Feature artifact status check | `Status: Approved` in feature artifacts plus verdict evidence lookup | Detects agent-authored approval wording without human authorization. | Flags when no matching `.squad/decisions.md` or `boundary_enforcement.verdict_history` approval exists. |

### Invariants

- `Status: Ready for Planning` or equivalent non-approval readiness wording is allowed.
- `Status: Approved` requires matching human verdict evidence.
- The check is narrow; it does not implement broad historical Proposal 151 migration.

## Smoke Evidence

Release promotion requires committed beta3 smoke evidence.

### Required Fields

| Field | Purpose |
| --- | --- |
| Tested version | Proves which beta build was exercised. |
| Fresh project path | Proves the run used a clean downstream project. |
| Stop boundary | Proves the run stopped at `clarify -> plan`. |
| `plan.md` pre-approval state | Proves planning did not run early. |
| Human re-entry packet excerpt | Proves six-section packet behavior. |
| PASS/FAIL | Records the release decision evidence. |
