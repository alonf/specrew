---
scope: general
sources:
  - extensions/specrew-speckit/squad-templates/coordinator/specrew-governance.md
  - docs/methodology/lifecycle-discipline.md
  - docs/methodology/review-instructions.md
  - proposals/145-structured-multi-phase-reviewer.md
  - extensions/specrew-speckit/squad-templates/skills/gate-stop.md
reviewed_at: 2026-06-08
---
## Specrew refocus — always-true core

Inside Specrew, these rules hold at every stage and on every host:

1. **Boundary discipline.** Every boundary requires explicit HUMAN authorization. One approval advances at most ONE boundary. Discussion is not approval.
2. **The spec is authoritative.** Drift between spec, plan, tasks, and implementation is first-class: record it in drift-log.md with a requirement citation. Never silently reconcile.
3. **Verdict shapes.** Recognized verdicts read "approved for <boundary>". Instruction-bearing verdicts carry the human's text. If ambiguous, ask.
4. **Evidence over form.** Claims need runtime evidence (test, journal, live behavior), not file existence. Verify the committed tree, not the working copy.
5. **Boundary commits.** Every artifact write that closes a boundary gets a focused commit: `boundary(<stage>): ...`. Push per project discipline.
6. **file:/// references.** Every artifact, file, or directory named in human-visible prose uses the full file:/// URL form.
7. **Honest state.** state.md, task statuses, and capacity lines reflect disk truth, in canonical enums only. Count-claims must match artifacts.
8. **Preflight every gate (two-tier model).** Before ANY boundary packet: reconstruct from artifacts, then run validator, upstream parity, dirty-state, artifact, stale-phrase, packet-consistency, and evidence checks. On failure: record, fix/classify, RERUN, then present. review-signoff gets the full structured review.
9. **At any gate, when in doubt: stop** and render the six-section re-entry packet. At a **verdict** stop on the Claude host, invoke the `specrew-gate-stop` skill (F-165). On non-Claude hosts, render the full packet directly using that host's approved interaction path; do not invoke `specrew-gate-stop`. Workshop/clarify questions keep their normal path; never use the skill to deliver a verdict.

Deep sources:

- {{project_root}}/docs/methodology/lifecycle-discipline.md
