# Iteration State: 003

**Schema**: v1
**Last Completed Task**: T014
**Tasks Remaining**: T015, T016, T017, T018, T019, T030, T031, T032, T033, T034b
**In Progress**: T015 (next)
**Baseline Ref**: 2d475962 (before-implement authorization commit)
**Updated**: 2026-07-11T18:40:00Z

<!--
  Current Phase / Iteration Status are set canonically by the sync
  machinery (Proposal 090) once execution begins — omitted at planning
  scaffold time to match the sanctioned shape (iteration 002 precedent),
  never hand-authored with a non-canonical value.
-->

## Execution Summary

- T034a done: the Devin shared-engine seam is recorded
  (research/devin-seam-inspection.md) — the strict design-context
  resolution (cca79708) in the orchestrator, exec-bit restoration
  (ec90e1b6) in the digest, and design-ref plumbing — mapped against
  T013/T014/T017 with the compose-not-collide rules and the semantic-vs-
  mechanical conflict doctrine. Devin authorization deferred to
  post-T034b-verification from a scratch dir; reviewer-hosts.json untouched.
- Co-review catch before T013 code (run 1446b84c, blocking): the shipped
  FR-020 tracker honesty check (T010, iteration 002) had a fail-OPEN —
  extract-and-ignore on state.md, non-canonical statuses accepted —
  contradicting its own TrackerClaims data model. Fixed in place
  (canonical enums, recognized shapes, injected-claim rejection); 5 paired
  tests added; recorded as DRIFT-198-I003-001. Suite green,
  signoff-gate wiring 9/9.
- T013 done (FR-008/SC-002): the reviewer worktree already materialized
  in system temp; T013 ENFORCES it with a containment guard that refuses
  an EphemeralRoot at or under the origin root (a nested worktree would let
  the confined reviewer walk up into the real project). Composes with the
  Devin seam (this is the materializer; their strict-resolution is in the
  orchestrator). Paired test worktree-containment.Tests.ps1 3/3: outside
  origin + no upward-walk resolves origin; inside-origin and origin-itself
  refused.
- T020 done (pulled forward, maintainer-directed execution-order
  adjustment, NOT scope drift): the review-loop spend allowance. A
  RESOLVED-AGAINST-DISK disposition clears the sticky blocking round-state
  - resets the round so a fixed finding can neither re-escalate nor keep
  consuming allowance (the four session incidents c894a74b/970a8d7c/
  efbbb98d/e4e88cb0 as the regression class) - and it REQUIRES committed
  fix evidence (an ancestor of HEAD; a bare claim is refused - no
  false-green). Two-budget accounting (provider spend vs round allowance:
  preflight-before-invocation consumes neither; invoked records spend +
  round). Consumer-legible halt text (N-of-M, reset command,
  resolved-vs-open, zero internal identifiers). CLI: --remediate
  resolved-against-disk --fix-evidence-ref. Proof suite 8/8;
  escalation-latch + degraded-gate regression 23/23; parse-clean.
- NFR-007 enforcement gap CLOSED (maintainer-directed, before resuming
  T014): the F-198 paired honesty tests were manual-only (no CI ran
  tests/unit or tests/continuous-co-review). Wired a bounded, EXPLICIT
  registry runner (tests/f198-regression-suite.ps1 - never a glob;
  per-test timeout + clear failure output) covering the ratchet, spend
  allowance, containment, tracker honesty, verdict-capture, budget, and
  signoff-gate regressions, and added it as a blocking CI step in the
  self-host lane (.github/workflows/specrew-ci.yml, timeout 15m). All 8
  suites green locally. This closes the iteration's own NFR-007
  enforcement - NOT T021 distribution work (T021 later generalizes/
  deploys the mechanism to consumers).
- T014 done (FR-009/SC-002): the reviewer-visible context leaked the
  origin location via file:/// origin URLs in the copied state/plan/spec/
  design snapshots. New ConvertTo-ContinuousCoReviewOriginRelativized
  relativizes origin-absolute paths (file:/// URLs + both separator forms,
  case-insensitive, multi-root) to <project> in the process-context copies,
  the generated process-context.md, and the design-context copies - the
  path STRUCTURE stays reviewable, only the origin PREFIX is neutralized.
  Composes with the Devin design-ref plumbing (relativize, never drop); the
  change-set diff itself (real content under review) is untouched. Paired
  test origin-path-hygiene.Tests.ps1 5/5; added to the F-198 CI registry.
- Co-review 8d3f5a6b (2 blocking): (1) T020 two-budget accounting was a
  standalone classifier with no caller - REAL; now WIRED into the
  orchestrator (preflight: a missing changes.diff fails before model
  invocation, consuming neither budget; post-invocation: an invoked
  invalid result records provider spend + consumes a round + a
  failed-invocation disposition), end-to-end fixtures proving both.
  (2) exec-bit strip on bin/specrew* - REFUTED: HEAD modes are 100755,
  byte-and-mode-identical to origin/main (git diff --summary empty,
  core.filemode=false); the reviewer worktree fabricates the phantom
  because the Devin exec-bit-restoration fix (ec90e1b6) isn''t integrated
  until T034b - the DRIFT-198-I001-001 class. Also fixed a pre-existing
  T012 regression the fix surfaced: the orchestrator crashed under
  StrictMode on a host object lacking independence_source (test mocks) -
  now defensive; four shared-engine F-197 suites added to the F-198 CI
  registry so this class is caught (the NFR-007 gap that let it slip).
- T015 (confinement contract + REQUIRED bounded in-worktree verification)
  is next in the Option B order.

## Notes

- Update this file after each task completes.
- Keep task identifiers aligned to plan.md.
