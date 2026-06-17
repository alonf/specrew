# Proposal 197 disposition fixture semantics (T030, TG-011)

This fixture note documents the editor disposition vocabulary used by the Proposal 197 continuous co-review blackboard. It is test data and maintainer documentation for `specs/197-continuous-co-review/implementation-rules.yml`.

Trace: FR-005, FR-014, SC-004, SC-008, TG-011.

## Disposition meanings

| Fixture semantic | Contract state | Required evidence |
| --- | --- | --- |
| accept-and-fix | `accepted_fix_pending` | A `fix_evidence_ref` to changed diff evidence; checkpoint remains blocked until verification marks the finding resolved. |
| reject-with-rationale | `rejected_with_rationale` | A non-empty `rationale`; rejection is an auditable editor decision, not silent deletion of the finding. |
| mark-resolved | `resolved` | A `fix_evidence_ref` to changed diff, reviewer re-check evidence, or approved human decision evidence. |
| escalate-to-human | `escalated_to_human` | An `escalation_ref` or disposition trail entry showing why the reviewer/editor loop cannot converge locally. |

## Non-convergence cap

Iteration 001 allows the initial review plus one fix-verification round. If the same blocking finding remains unresolved after that second round, the inline gate must stop checkpoint advancement and escalate to a human instead of allowing indefinite editor-reviewer ping-pong.

## Proposal 145 review-signoff backstop

Proposal 197 continuous co-review supplements the existing Proposal 145 final review-signoff boundary. It does not replace it. The final aggregate review-signoff remains the backstop for deferred, rejected, escalated, or ambiguous findings before feature closeout.
