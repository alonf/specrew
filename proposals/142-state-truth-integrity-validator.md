---
proposal: 142
title: State-Truth Integrity Validator (Cross-Artifact Lifecycle Consistency Enforcement)
status: draft
phase: phase-2
estimated-sp: 3-7
priority-tier: 1
type: tooling
discussion: surfaced 2026-05-29 by second empirical instance of iteration-closeout state-artifact-truth gap within F-049 alone (instances 2 + 5 in [[cross-reviewer-3rd-empirical-instance-2026-05-28]]); cross-reviewer caught both via reading state-artifact contents but no tooling enforcement exists
composes-with:
  - 102  # Cross-Model Independent Reviewer — defense-in-depth layer 3
  - 120  # Handoff-Block Validator Enforcement — defense-in-depth layer parallel
  - 132  # Mirror-Parity Validator Enforcement — same pattern (cross-artifact consistency)
  - 140  # Reviewer Instruction Surface — defense-in-depth layer 2 (reviewer-charter discipline)
  - 172  # Hook-Driven Session Bootstrap — owns the resume/SessionStart write-path that FR-009 must guard
  - 193  # Unified Lifecycle Status Model — owns the reconstruct-on-bootstrap that FR-011 detection drives
audience: tooling
---

# State-Truth Integrity Validator (Cross-Artifact Lifecycle Consistency Enforcement)

## Why

Specrew has multiple durable state-truth artifacts that independently track lifecycle position:

- `specs/<feature>/iterations/<N>/state.md` — per-iteration phase + transitions + prose
- `.squad/identity/now.md` — Crew session-state frontmatter + focus_area + body prose
- `.specrew/start-context.json` — `boundary_enforcement.last_authorized_boundary` + `verdict_history` + `session_state` fields
- `.specrew/last-start-prompt.md` — session-state frontmatter + welcome-back snapshot
- `.squad/decisions.md` — routing + decision-entry log

These files are written on lifecycle transitions but updated INDEPENDENTLY by different code paths. Drift between them accumulates silently, and the cross-artifact inconsistency is invisible to substance-focused review (FR coverage, test pass, evidence audit).

### Empirical motivation: two state-truth integrity catches in F-049 alone

**Instance 1 (2026-05-28, F-049 iter-3 iteration-closeout)**: cross-reviewer (Codex) caught:

1. `review.md` line 7: "retro remains unopened pending fresh human authorization" while `state.md` / `retro.md` / `now.md` all said retro complete
2. `state.md` cited `b34de704` as reviewing→retro transition commit, but `b34de704` was the review-signoff state repair commit; actual retro-establishing commit was `2eba2a91`. **False lifecycle transition provenance baked into git-readable history.**
3. `.specrew/start-context.json` claimed `last_authorized_boundary: retro` but `verdict_history` was missing the corresponding review-signoff→retro entry

**Instance 2 (2026-05-29, F-049 iter-5 iteration-closeout)**: cross-reviewer (Codex, again) caught:

1. `state.md` line 18: "Next boundary is review-signoff (human gate); not auto-advanced." — stale text from end-of-implementation; we were past review-signoff + retro
2. `.squad/identity/now.md` `focus_area` + body prose: "Iteration 005 planning package... awaiting explicit human planning review/approval before implementation." Stale by 4 boundaries (past planning, before-implement, implement, review-signoff, retro)
3. `.specrew/start-context.json` `last_authorized_boundary: iteration-closeout` — **falsely claimed the boundary was already crossed** while we were AT the gate FOR it

Both instances:

- Were caught by cross-reviewer reading state-artifact contents — NOT by single-reviewer Pillar 5 form check or substance audit
- Were caught at iteration-closeout — the boundary class where lifecycle-state is the PRIMARY shipping artifact (no code ships; state-sync ships)
- Required human-discipline reviewer-charter additions to catch durably (per memory `[[cross-reviewer-3rd-empirical-instance-2026-05-28]]` Instance 5 conclusion)

**Two empirical instances of the same failure mode in the same feature warrants tooling enforcement.** Reviewer-charter discipline (Proposal 140) is the human-side fix; this proposal is the mechanical-side fix that runs even without a cross-reviewer.

### F-051 addendum: Iteration 2a review-remediation evidence

F-051 Iteration 2a added a third high-signal production data point on 2026-06-01. Across three review-remediation rounds, reviewers caught:

- push parity drift where the reviewed boundary commit existed only locally;
- uncommitted `.squad/decisions.md` boundary evidence;
- stale `state.md`, `plan.md`, and `.squad/identity/now.md` lifecycle prose after review acceptance;
- `hardening-gate.md` gate-level status drift from post-implementation evidence;
- stale `review-report.yml` finding history after round-N remediation;
- duplicate `state.md` scaffold-residue headers.

These are not isolated prose nits. They are durable state-truth and artifact-coherence defects that created additional human review loops after the substantive implementation had already passed. Proposal 142 should therefore expand beyond the original five state-artifact checks to include scaffold-residue detection and review-report remediation-history coherence where those artifacts exist.

### F-184 iter-002 addendum: resume re-scaffolded a CLOSED iteration (2026-06-17)

A third, more severe class surfaced during F-184 iteration 002: the resume/SessionStart machinery did not merely let drift accumulate — it *actively corrupted committed truth*. On a session switch (codex → Claude), `.specrew/start-context.json` `session_state` still pointed at the already-CLOSED iteration 001 (`iteration_number: 001` / `boundary_type: iteration-closeout`, predating the iter-001 close `abf18b99` and the iter-002 specify `2d65f3ed`). The resume machinery trusted that stale cursor and re-scaffolded the closed iteration — `iterations/001/state.md` was reset from `complete` back to `not-started`, plus a spurious all-pending `tasks-progress.yml`. It was reverted from committed truth, but only because the next session happened to check.

This is a different failure mode than instances 1–2: not cross-artifact drift caught at validate-time, but the resume write-path silently REVERTING a committed, closed iteration from a stale cursor. Detection-after-the-fact is insufficient here — an unattended or cron resume would corrupt closed-iteration history and never notice. The write-path itself needs a guard, and the cursor needs validating against committed reality before any resume acts on it. It is also model-independent: a codex session left the stale cursor; a Claude session caught it — but the fix cannot depend on a strong model happening to check.

### Why prose-rule-only is insufficient

Same pattern as `[[proposal-132-mirror-parity-validator-enforcement]]` (mirror parity prose rule → mechanical validator backfill) and `[[proposal-105-host-native-hook-deployment]]`'s "if a prompt says X you have a request; if a hook blocks it you have a boundary" framing. State-truth integrity today is a discipline expectation with no mechanical enforcement.

## What

A validator rule that runs at boundary-recording time (and at each `validate-governance.ps1` invocation) and FAILS with named delta if state-truth artifacts are inconsistent.

### Functional requirements

- **FR-001**: Validator MUST cross-check `state.md` "Current Phase" field against `state.md` prose claims (Execution Summary, Notes section). Inconsistency = FAIL with the conflicting text passages cited.
- **FR-002**: Validator MUST cross-check `.squad/identity/now.md` `focus_area` and body prose against `state.md` Current Phase. If focus_area names a different lifecycle position than state.md says, FAIL with both quoted.
- **FR-003**: Validator MUST cross-check `.specrew/start-context.json` `boundary_enforcement.last_authorized_boundary` against `verdict_history[-1].to_boundary`. Mismatch = FAIL (claims boundary crossed without supporting verdict entry).
- **FR-004**: Validator MUST cross-check `.specrew/start-context.json` `session_state.boundary_type` against `boundary_enforcement.last_authorized_boundary`. Drift = WARN (allows mid-transition states but flags long-lived inconsistency).
- **FR-005**: Validator MUST cross-check `.specrew/last-start-prompt.md` frontmatter session-state fields against `.specrew/start-context.json` session_state. If they diverge, WARN (regenerated artifact may catch up; failure to converge over time = FAIL).
- **FR-006**: At iteration-closeout boundary specifically, validator MUST execute all five checks above as a HARD-BLOCK precondition. iteration-closeout cannot record without state-truth consistency.
- **FR-007 (added 2026-06-01)**: Validator SHOULD detect duplicate lifecycle scaffold headings in `state.md` and `plan.md` when duplicate headings carry generic template residue next to iteration-specific content. At minimum WARN; FAIL at closeout if the duplicate creates contradictory lifecycle meaning.
- **FR-008 (added 2026-06-01)**: When `review-report.yml` exists, validator SHOULD cross-check round-N remediation history against durable review artifacts: fixed finding counts, verdict string, and finding statuses must reflect the latest committed remediation round.
- **FR-009 (added 2026-06-17)**: The resume / SessionStart / scaffold write-path MUST NOT overwrite or re-scaffold the state artifacts of a CLOSED iteration (one whose committed `state.md` is `complete` and/or which is listed in `.specrew/closed-iterations.yml`). If the resume cursor resolves to a closed iteration, the machinery MUST refuse the write, reconcile the cursor to the actual active position, and emit a named integrity event — it MUST NEVER silently revert committed truth. This is the write-path guard; detection alone (FR-001…FR-008) does not prevent the corruption.
- **FR-010 (added 2026-06-17)**: On resume, the machinery MUST cross-check `.specrew/start-context.json` `session_state` (iteration_number / boundary_type) against committed lifecycle reality — `.specrew/closed-iterations.yml` plus the latest iteration's committed `state.md` — and FAIL (not WARN) if the cursor points at a closed or superseded iteration, so a lagged cursor cannot drive a resume. This escalates the FR-004 `session_state` drift check from WARN to FAIL for the closed/superseded-iteration case.
- **FR-011 (added 2026-06-30)**: The COMPLEMENT of FR-009/FR-010 (stale cursor) — the EMPTY/MISSING cursor case. On resume, if `.specrew/start-context.json` is empty/absent (a fresh clone or machine switch — it and `.specrew/runtime/` are gitignored per-machine and do NOT travel) but the latest committed `state.md` indicates an active in-flight iteration, the machinery MUST RECONSTRUCT the cursor (`last_authorized_boundary` + `verdict_history` with commit refs) from committed reality — the `state.md` "Current Phase" + the `boundary(<stage>): ...` commit trail + downstream phase commits — rather than leaving it blank. A blank cursor silently breaks downstream consumers: in the F-197 desktop→laptop dogfood (2026-06-29/30) the co-review navigator stage gate no-op'd dark every Stop, and a `sync-boundary-state` repair attempt drove a spurious `intake -> specify` verdict demand. The reconstruction logic is owned by Proposal 193 (its deterministic primitive's reconstruct-on-bootstrap mode); 142's contribution is the DETECTION — FAIL or trigger-reconstruct when an empty cursor coexists with a committed in-flight iteration, never a silent no-op.

### Validator rule shape

```text
RULE state-truth-iteration-closeout (severity: FAIL):
  CONTEXT: iteration is at retro → iteration-closeout gate
  CHECK 1: state.md "Current Phase" matches state.md prose claims
  CHECK 2: now.md focus_area matches current lifecycle position
  CHECK 3: start-context.json last_authorized_boundary == verdict_history[-1].to_boundary
  CHECK 4: start-context.json session_state.boundary_type aligned (WARN if drift)
  CHECK 5: last-start-prompt.md frontmatter aligned (WARN if drift)
  ON FAIL: emit named delta with quoted text passages from each conflicting artifact
```

### Out of scope

- Auto-repair of *existing* drift (the validator surfaces inconsistency; agent or human repairs it). Note: the FR-009 resume-path guard is *prevention* — it refuses a corrupting write and reconciles the cursor — not auto-repair of pre-existing drift, and it IS in scope.
- Cross-feature state-truth checks (this proposal is per-iteration scoped)
- Squad-side state files outside `.squad/identity/now.md` (decisions.md, team.md, routing.md have their own validators or no validator)
- Validator for lifecycle artifacts that don't have explicit "Current Phase" semantics (plan.md, tasks.md, retro.md — those carry implicit state but not the same way)

## How

Add a new rule to `validate-governance.ps1` (and `shared-governance.ps1` for cross-feature checks).

| Component | File | Effort |
|---|---|---|
| Rule implementation | `extensions/specrew-speckit/scripts/validate-governance.ps1` (new function `Test-StateArtifactTruthIntegrity`) | 1-2 SP |
| Mirror to `.specify/extensions/specrew-speckit/scripts/` | byte-identical copy per FR-014 (Proposal 132 pattern) | 0.2 SP |
| Unit tests for the rule | `tests/governance/state-truth-integrity.tests.ps1` covering: consistent (PASS), state.md prose drift (FAIL), now.md focus_area drift (FAIL), verdict_history mismatch (FAIL), boundary_type drift (WARN), last-start-prompt drift (WARN) | 1-2 SP |
| Integration into iteration-closeout hard-block | `sync-boundary-state.ps1` integration so iteration-closeout fails if validator emits FAIL | 0.3 SP |
| Documentation | `docs/methodology/lifecycle-discipline.md` add State-Truth Integrity section | 0.5 SP |

**Total estimate**: 3-5 SP for a single iteration.

## Composition

### With Proposal 120 (Handoff-Block Validator Enforcement)

120 enforces handoff-block STRUCTURE at validator level. This proposal enforces CROSS-ARTIFACT CONSISTENCY at validator level. Both are mechanical enforcement of disciplines previously prose-only. Could fold this proposal in as Proposal 120 Pillar 6 if 120 hasn't shipped yet; ships standalone otherwise.

### With Proposal 132 (Mirror-Parity Validator Enforcement)

Same pattern (cross-artifact consistency check) on different surface (mirror parity vs. state truth). 132 ships first as the smaller / simpler shape; this proposal follows the same architecture.

### With Proposal 140 (Reviewer Instruction Surface)

140 ships reviewer-charter discipline to catch what tooling misses (semantic claims). This proposal ships tooling to catch what reviewer-discipline misses (mechanical inconsistencies humans skim past). Defense-in-depth across the two layers.

### With Proposal 102 (Cross-Model Independent Reviewer)

102's empirical motivation INCLUDES the same instances this proposal addresses. Once 102 ships, cross-reviewers will catch these gaps as a backup. This proposal makes the catch mechanical and consistent rather than dependent on reviewer attentiveness.

## Risks

- **Validator-friction-against-mid-transition states**: state files are written sequentially during a boundary transition; momentarily inconsistent state is normal. Mitigation: FAIL only at iteration-closeout (final state-sync moment); WARN during in-flight transitions.
- **False-positive on legitimate stale-but-pending content**: e.g., a retro.md that says "(to be filled in)" might trip a prose check. Mitigation: validator is structured-fields-aware; doesn't free-text-grep arbitrary prose.
- **Tooling defect on edge-case state files**: e.g., `last-start-prompt.md` regenerated by `specrew-start` may briefly diverge before convergence. Mitigation: that check is WARN not FAIL; persistent divergence over multiple runs would warrant escalation but not block.

## Empirical motivation captured

- **2026-05-28 F-049 iter-3 iteration-closeout** — Codex cross-reviewer caught 3 state-artifact integrity gaps (review.md stale text + state.md false transition-commit provenance + start-context verdict_history missing entry); single-reviewer Pillar 5 form check missed all three; repair landed at `e85a5ced`
- **2026-05-29 F-049 iter-5 iteration-closeout** — Codex cross-reviewer caught 3 state-artifact integrity gaps AGAIN at same boundary class (state.md prose stale, now.md focus_area stale, start-context.json `last_authorized_boundary` false-already-crossed claim); single-reviewer (Claude in this session) Pillar 5 + substance audit missed all three; repair in progress at proposal draft time

Two empirical instances of the same failure mode in the same feature = strong evidence the boundary class has a specific tooling gap. Iteration-closeout's failure mode is **state-artifact-truth inconsistency**, not substance error.

## Status history

- **2026-05-29** — Drafted as direct response to F-049 iter-5 iteration-closeout state-truth gap (2nd in F-049 alone). Maintainer raised the question "Why can't we enforce the methodology?" The most leveraged single answer is a validator rule at boundary-recording time. This proposal codifies that rule. Ships as draft because empirical motivation is concrete, ~3-5 SP scope is small, and shipping captures immediate methodology lift across all in-flight features.
- **2026-06-01** — Partially promoted ahead of remaining F-051 iterations after Iteration 2a required three review-remediation rounds for state-truth, scaffold-residue, and review-report coherence gaps. Scope expanded with FR-007 and FR-008.
- **2026-06-17** — F-184 iteration 002 surfaced a third, more severe instance: the resume/SessionStart write-path re-scaffolded a CLOSED iteration (iter-001 `complete`→`not-started` + a spurious `tasks-progress.yml`) from a stale `.specrew/start-context.json` cursor on a codex→Claude session switch. Reverted from committed truth; recorded in `specs/184-full-antigravity-refocus/iterations/002/drift-log.md`. Scope extended with FR-009 (resume write-path guard: never silently revert a closed iteration) and FR-010 (resume-time cursor-vs-committed-truth validation), elevating 142 from detect-only to a write-path guard. Surfaced via the F-184 iter-002 plan-boundary review; the file-don't-blind-fix discipline kept the fix out of that boundary and here in the proposal instead.
- **2026-06-30** — F-197's desktop→laptop dogfood surfaced the EMPTY-cursor complement to FR-009/FR-010: a gitignored `start-context.json` does not travel across machines, so a fresh `specrew start` minted a blank cursor while the committed `state.md` said `implement`. The F-197 co-review auto-fire no-op'd dark every Stop (`not-implement-stage`), and a `sync-boundary-state` repair drove a spurious `intake -> specify` verdict demand. Added FR-011 (empty/missing-cursor detection → reconstruct-or-FAIL, never silent no-op) composing with Proposal 193's reconstruct-on-bootstrap. Recorded in `specs/197-continuous-co-review/iterations/009/drift-log.md` D-197-I009-008. Surfaced during a live dogfood; the file-don't-blind-fix discipline kept the fix in the proposal/backlog rather than hand-patched into the running session.
