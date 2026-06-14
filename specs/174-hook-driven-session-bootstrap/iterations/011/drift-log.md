# Drift Log: Iteration 011

**Schema**: v1
**Spec**: [../../spec.md](../../spec.md)

Divergences between spec / plan / tasks and the implementation, each with the requirement citation and the
reconciliation path (lifecycle-discipline rule 4: drift is logged, not absorbed).

## D-001 — verdict-capture marker emission is Claude-only (descoped per-host rollout)

- **Status**: open (tracked residual)
- **Requirement**: FR-026 (verdict-integrity) + the T004 "require a packet boundary marker" decision
  (`f174-i011-verdict-authority-stop-hook`, maintainer-chosen tying strictness).
- **Divergence**: T004's hook verdict-capture ties the human's approval to a boundary ONLY via the packet's
  stable machine marker `<!-- SPECREW-VERDICT-BOUNDARY: <from> -> <to> -->`. The marker EMISSION is implemented
  in the Claude `specrew-gate-stop` skill (the Claude packet renderer). codex / copilot / cursor render the
  boundary packet via their own approved interaction path (refocus rule 9), which does NOT yet emit the marker.
  So on those three hooked hosts the reader returns `no-marker` and the hook does NOT auto-capture.
- **Why this is SAFE (not a regression)**: the capture machinery (recognizer + reader + wiring) is host-neutral
  and the failure mode is the designed one — no marker -> the gate stays un-authorized and the resume / `specrew
  where` surface "AWAITING YOUR VERDICT" (T006), so the human re-confirms. No fabrication, no false approval. The
  cost is liveness (the human re-confirms each boundary on those hosts), not integrity.
- **Reconciliation path**: carry the marker instruction into the HOST-NEUTRAL boundary-packet guidance (the
  launch contract / coordinator framing / the Rule 46 packet spec) so every host emits it, not just the Claude
  skill. Small doc rollout; best informed by the real-host re-dogfood (which validates the Claude path first).
- **Disposition**: deferred within F-174 iteration 011 as a fast-follow; does not block the verdict-integrity
  core (T004/T005/T006 are complete + proven on the Claude packet format). Recorded 2026-06-14.
