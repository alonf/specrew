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

The governed subject is the project at `{{project_root}}`; Specrew is the methodology tool, never the project being built.

1. **Boundaries.** Every boundary needs explicit HUMAN authorization. One approval advances at most ONE boundary; discussion is not approval. A captured approval is the instruction: begin the next stage in this turn; do not ask the human to start it. A verdict typed while no crossing is pending authorizes nothing and is not pending authority.
2. **Spec truth.** The spec is authoritative. Drift between spec, plan, tasks and code is recorded in drift-log.md with a requirement citation.
3. **Verdicts.** Recognized verdicts read "approved for <boundary>"; instruction-bearing verdicts carry the human's text. Ask if ambiguous.
4. **Evidence.** Claims need runtime evidence (test, journal, live behavior), not file existence; verify the committed tree.
5. **Boundary commits.** Every artifact write closing a boundary gets a focused `boundary(<stage>): ...` commit.
6. **file:/// references.** Every artifact, file or directory named in human-visible prose uses the bare file:/// form.
7. **Honest state.** state.md, task statuses and capacity lines reflect disk truth in canonical enums; counts match artifacts.
8. **Gate preflight.** Before any boundary packet, reconstruct from artifacts, run validator/parity/dirty-state/artifact/stale-phrase/packet/evidence checks, fix or classify failures, rerun, then present; review-signoff gets the full structured review.
9. **Re-entry packets.** At a boundary gate or after material work, render the six sections: What I Just Did / Why I Stopped / What Needs Your Review / What Happens Next / Discussion Prompts / What I Need From You. Boundary stops offer the four typed verdicts as sendable lines - never a list, picker or menu - and end with the exact `SPECREW-VERDICT-BOUNDARY` marker; a stop whose stage owes unproduced artifacts offers no options or marker and names what is owed. After the sync, `.specrew/runtime/pending-verdict-stop.md` is authoritative: use its exact values; do not infer the marker from the next phase. Use your host's approved interaction path or render directly. In-phase checkpoints carry no options/marker; quick discussion without material work: omit the packet. Clarify-stage ambiguity questions are NOT packet stops; workshop questions keep their flow.
