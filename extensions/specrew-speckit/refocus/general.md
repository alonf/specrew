---
scope: general
sources:
  - extensions/specrew-speckit/squad-templates/coordinator/specrew-governance.md
  - docs/methodology/lifecycle-discipline.md
  - docs/methodology/review-instructions.md
reviewed_at: 2026-06-07
---
## Specrew refocus — always-true core

You are operating inside a Specrew-governed lifecycle. These rules hold at every stage, on every host:

1. **Boundary discipline.** Lifecycle boundaries (specify, clarify, plan, tasks, before-implement, implement, review-signoff, retro, iteration-closeout, feature-closeout) require explicit HUMAN authorization. One approval advances at most ONE boundary. No agent prose can simulate authorization; discussion is not approval.
2. **The spec is authoritative.** Drift between spec, plan, tasks, and implementation is a first-class event: record it in drift-log.md with a requirement citation. Never silently reconcile.
3. **Verdict shapes.** Recognized verdicts read "approved for <boundary>". Instruction-bearing verdicts carry the human's text into the work. If a verdict is ambiguous, ask — never infer scope from silence.
4. **Evidence over form.** A claim is true when runtime evidence proves it (a test run, a journal entry, live behavior) — never because a file exists or a table says so. Verify against the committed tree, not working-copy state.
5. **Boundary commits.** Every artifact write that closes a boundary gets a focused commit: `boundary(<stage>): ...`. Push per project discipline.
6. **file:/// references.** Every artifact, file, or directory named in human-visible prose uses the full file:/// URL form.
7. **Honest state.** state.md, task statuses, and capacity lines reflect disk truth, in canonical enums only. Count-claims must match artifacts.
8. **Preflight every gate.** Before emitting a boundary packet, run the stage's mechanical/validator checks and review your own output against the stage's requirements — self-send-back and repair BEFORE asking the human. The human approves verified work, not hope. After implement, the full reviewer discipline applies (review-instructions.md).
9. **At any gate, when in doubt: stop** and emit the six-section re-entry packet (What I Just Did / Why I Stopped / What Needs Your Review / What Happens Next / Discussion Prompts / What I Need From You).

Stage-scoped discipline: run `/specrew-refocus --boundary <stage>`.

Deep sources:

- {{project_root}}/docs/methodology/lifecycle-discipline.md
- {{project_root}}/docs/methodology/review-instructions.md
- {{project_root}}/.specify/extensions/specrew-speckit/squad-templates/coordinator/specrew-governance.md
