---
scope: general
sources:
  - extensions/specrew-speckit/squad-templates/coordinator/specrew-governance.md
  - docs/methodology/lifecycle-discipline.md
  - docs/methodology/review-instructions.md
  - extensions/specrew-speckit/squad-templates/skills/gate-stop.md
reviewed_at: 2026-06-08
---
## Specrew refocus — always-true core

Inside Specrew, these rules hold at every stage and on every host:

The governed subject is the project resolved at `{{project_root}}`; Specrew is the methodology tool, never the project being specified or implemented.

1. **Boundaries.** Every boundary needs explicit HUMAN authorization. One approval advances at most ONE boundary; discussion is not approval.
2. **Spec truth.** The spec is authoritative. Drift between spec, plan, tasks, and code is first-class: record it in drift-log.md with a requirement citation.
3. **Verdicts.** Recognized verdicts read "approved for <boundary>". Instruction-bearing verdicts carry the human's text. Ask if ambiguous.
4. **Evidence.** Claims need runtime evidence (test, journal, live behavior), not file existence. Verify the committed tree.
5. **Boundary commits.** Every artifact write that closes a boundary gets a focused `boundary(<stage>): ...` commit.
6. **file:/// references.** Every artifact, file, or directory named in human-visible prose uses full bare file:/// URL form.
7. **Honest state.** state.md, task statuses, and capacity lines reflect disk truth in canonical enums; count-claims must match artifacts.
8. **Gate preflight.** Before any boundary packet, reconstruct from artifacts, run validator/parity/dirty-state/artifact/stale-phrase/packet/evidence checks, fix or classify failures, rerun, then present. review-signoff gets the full structured review.
9. **Re-entry packets.** Render the six-section packet (What I Just Did / Why I Stopped / What Needs Your Review / What Happens Next / Discussion Prompts / What I Need From You) when at a boundary gate, after material work, or after a long/disconnected work turn. Quick discussion with no code, tests, files, commits, or gate stays conversational; length alone does not count. Clarify-stage ambiguity questions are NOT packet stops, and workshop questions keep their normal picker/question path. Never collapse the packet into a picker/menu. Boundary stops include numbered verdict options and the final `SPECREW-VERDICT-BOUNDARY` marker. After `sync-boundary-state.ps1`, `.specrew/runtime/pending-verdict-stop.md` is authoritative for the boundary, approval phrase, and marker; use its exact values and do not infer the marker from the next phase. Use your host's approved interaction path for verdict stops, or render directly when no dedicated surface exists. Within-phase checkpoints have no verdict options/marker.

Deep sources:

- {{project_root}}/docs/methodology/lifecycle-discipline.md
