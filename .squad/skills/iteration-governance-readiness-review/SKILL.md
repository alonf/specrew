---
name: "iteration-governance-readiness-review"
description: "Review execution readiness by checking the live iteration artifacts against the contract and the live governance validator result"
domain: "governance"
confidence: "high"
source: "earned"
tools:
  - name: "view"
    description: "Read the plan, contract, workflow, and decision context"
    when: "When determining whether an iteration artifact is truly execution-ready"
  - name: "rg"
    description: "Find validator rules and contract fields quickly"
    when: "When mapping a reported failure back to the governing rule"
  - name: "powershell"
    description: "Run the validator against the live repo"
    when: "When readiness depends on whether the gate passes or fails cleanly"
---

## Context

Use this when reviewer findings claim an iteration is fixed or execution-ready and you need to verify the live repo state rather than trusting the narrative.

## Patterns

- Read the contract and the live artifact first; treat decision memos as supporting context, not proof.
- Run the validator and separate gate-health questions from artifact-quality questions.
- Accept a validator fix when it stops crashing and surfaces real contract failures.
- Reject execution readiness when the plan or other required artifacts still fail the live validator.
- If rejecting, name the next revision owner for each rejected artifact and respect author lockout rules.
- On re-review, check each previously cited defect directly in the live file and require the validator to clear the same artifact before flipping from NEEDS-WORK to PASS.
- Keep artifact readiness separate from broader coordination prerequisites; only fail the gate on approvals or consensus items when they are part of the governing requirement or prior rejection basis.

## Examples

- Validator previously crashed on collection shape under strict mode; after repair it reports `Started` missing in `plan.md`. Verdict: validator accepted, plan rejected.
- Decision note says "ready for execution," but `plan.md` still has blank required metadata. Verdict follows the file and gate result, not the note.
- Prior rejection named blank `Started` metadata and missing `Story` on `T-022`; re-review confirms both fixes on disk and the validator passes. Verdict: PASS, while separate Alon approval remains a coordination step rather than an artifact defect.

## Anti-Patterns

- Granting PASS because the failure mode changed from crash to readable output
- Treating a decision document as equivalent to the artifact under review
- Softening a rejection when the live validator still fails
