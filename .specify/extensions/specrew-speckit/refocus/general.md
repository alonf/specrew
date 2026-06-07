---
scope: general
sources:
  - extensions/specrew-speckit/squad-templates/coordinator/specrew-governance.md
  - docs/methodology/lifecycle-discipline.md
  - docs/methodology/review-instructions.md
  - proposals/145-structured-multi-phase-reviewer.md
  - extensions/specrew-speckit/squad-templates/skills/gate-stop.md
reviewed_at: 2026-06-07
---
## Specrew refocus — always-true core

You are operating inside a Specrew-governed lifecycle. These rules hold at every stage, on every host:

1. **Boundary discipline.** Every lifecycle boundary requires explicit HUMAN authorization. One approval advances at most ONE boundary. No agent prose can simulate authorization; discussion is not approval.
2. **The spec is authoritative.** Drift between spec, plan, tasks, and implementation is a first-class event: record it in drift-log.md with a requirement citation. Never silently reconcile.
3. **Verdict shapes.** Recognized verdicts read "approved for <boundary>". Instruction-bearing verdicts carry the human's text into the work. If a verdict is ambiguous, ask — never infer scope from silence.
4. **Evidence over form.** A claim is true when runtime evidence proves it (test run, journal entry, live behavior), never because a file exists or a table says so. Verify against the committed tree, not working copy.
5. **Boundary commits.** Every artifact write that closes a boundary gets a focused commit: `boundary(<stage>): ...`. Push per project discipline.
6. **file:/// references.** Every artifact, file, or directory named in human-visible prose uses the full file:/// URL form.
7. **Honest state.** state.md, task statuses, and capacity lines reflect disk truth, in canonical enums only. Count-claims must match artifacts.
8. **Preflight every gate (two-tier model).** Before ANY boundary packet: reconstruct state from artifacts (never memory), then run the preflight — scoped validator, branch/upstream parity, dirty-state classification, required artifacts, stale-phrase scan, packet-vs-artifact consistency, boundary evidence. On failure: record → fix or classify → RERUN → only then present. review-signoff gets the full structured review (review-instructions.md).
9. **At any gate, when in doubt: stop** and render the six-section re-entry packet. At a **verdict** stop invoke the `specrew-gate-stop` skill — it disables `AskUserQuestion` so the packet renders as prose, not collapsed into the picker (F-165). Never deliver a verdict via it; workshop/clarify questions keep it.

Stage-scoped discipline: run `/specrew-refocus --boundary <stage>`.

Deep sources:

- {{project_root}}/docs/methodology/lifecycle-discipline.md
- {{project_root}}/.specify/extensions/specrew-speckit/squad-templates/coordinator/specrew-governance.md
