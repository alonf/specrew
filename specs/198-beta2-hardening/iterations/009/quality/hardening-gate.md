# Hardening Gate: Iteration 009

**Schema**: v1
**Status**: approved
**Capacity**: 20.0/20 story_points

## Concern Review

| Concern | Status | Required proof |
| --- | --- | --- |
| Candidate/source identity | required | One canonical included-path set drives digest, candidate, diff, and manifest. |
| Ignored/runtime contamination | required | Gitignored build/runtime/local-host files are absent; untracked non-ignored source remains. |
| Human exclusion authority | required | Persisted exclusion applies at candidate-build time and remains auditable. |
| Reviewer independence | preserved | No change to reviewer selection, authorization, or containment. |
| False-green resistance | preserved | Missing/invalid candidate or result evidence remains blocking. |
| Verification performance | bounded | W1/W2 preserve complete-registry membership and evidence semantics. |
| Provider spend | bounded | Codex valid file-primary result never causes a second invocation. |
| Consumer repository safety | required | Article Amplifier is never modified; copies only. |

## Fail-Direction Requirements

- A candidate/diff mismatch fails closed.
- An unreadable ignore/exclusion decision fails with actionable evidence; it
  does not silently widen or narrow the candidate.
- Parallel runner infrastructure failure reports the affected suite and fails
  the complete registry.
- Selected/partial registry execution cannot produce signoff evidence.
- Version mismatch cannot silently dispatch the stale engine.

## Value Preservation

Iteration 009 changes what is reviewed, not how substantive findings are
judged. It must increase candidate fidelity without weakening independent
review, escalation latching, drift-ledger discipline, or test-integrity
enforcement.
