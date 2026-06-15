# Coverage Evidence: Iteration 009

**Schema**: v1
**Reviewed**: 2026-06-11

## Test Coverage

| Task | Requirement | Test evidence |
| ---- | ----------- | ------------- |
| T001-T006 | FR-009 / FR-010 / FR-021 / SC-004 | `tests/bootstrap/HandoverHookPrimary.Tests.ps1`: section ownership, delta, accumulation, boundary reset, `from_host`, agent-preserve, atomic `.old`, multi-source (direct core + provider `--source workshop` + provider `PostToolUse` event), clean-tree gate-skip, deploy-registers-`PostToolUse`. Full bootstrap suite 21/21. |
| T007 | FR-010, FR-022 | `tests/bootstrap/HandoverHookPrimary.Tests.ps1` block (f): the user file surfaces in `user_files`, the `.claude/` managed file is excluded, `managed_file_count >= 1`, the prioritized list LEADS with the user file, and the rendered bullet reports "changed user file(s)" + the user file + "Specrew-managed" by count. 7 assertions pass. |

## Runtime Evidence (the live cross-host dogfood, 2026-06-11)

- **PostToolUse mid-turn refresh CONFIRMED on Claude** — PostToolUse bullets (16:51:43 / 16:51:49 / 16:54:02)
  interleaved with Stops; the handover refreshed mid-workshop, not frozen.
- **Cross-host hand-off CONFIRMED** — `from_host` flips codex <-> claude <-> copilot; SessionStart
  `mode=welcome-back`, `handover_valid=True`, `placeholder=False` on re-entry (bootstrap-journal).
- **De-noise CONFIRMED live** — the activity bullet went from "53 uncommitted [.agents/, .claude/, ...]" to
  "7 changed user file(s) [.../spec.md, .../workshop/product-domain.md, ...] (+499 Specrew-managed)".

## Gaps

- The codex array-shape self-heal (`ec08752f`, a chore) carries its committed regression test to iteration
  010 with the resume-reconciliation; recorded in review.md Phase 5 + the retro (Improvement Action 4).
