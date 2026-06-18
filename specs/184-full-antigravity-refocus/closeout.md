# Feature Closeout: Full Antigravity Refocus

**Schema**: v1
**Feature**: 184-full-antigravity-refocus
**Branch**: 184-full-antigravity-refocus
**Closed**: 2026-06-18
**Status**: COMPLETE — maintainer-authorized to proceed to the PR + `0.38.0-beta1` publish SDLC steps
**Closer**: Claude, authorized by Alon Fliess for feature-closeout AND the PR / beta steps via the directive
"Close the iteration, close the feature, create a PR, for a beta release. Wait for GitHub Copilot comments,
fix them."

## Executive Summary

Feature 184 completes Antigravity host parity, delivered across **two iterations (001–002)**. Iteration 001
finished the F-183 Antigravity refocus follow-up (real `conversationId` state, per-session anchors, B3 on
`PreInvocation`, self-marker classification, F-183 regression preservation, docs parity, machine-local
real-host `agy` evidence). Iteration 002 closes the last parity gap the manual dogfood found: **persistent
host instructions at `specrew init`**, so a cold-launched agent on any host comes up as the governed Specrew
coordinator rather than a blank session.

Iteration 002 ships in one host-neutral, manifest-driven layer:

1. **Persistent coordinator instructions (FR-011/FR-016/FR-018).** `specrew init` merges a Specrew-owned,
   delimited section into each supported host's manifest-declared `InstructionsFile` (`AGENTS.md`,
   `CLAUDE.md`, `.github/copilot-instructions.md`); `specrew update` refreshes it and `specrew start` heals a
   missing/stale section. Content comes from one packaged fragment (`templates/coordinator-instructions.md`)
   in `Specrew.psd1` `FileList`.
2. **Byte-for-byte user-content preservation (FR-012).** The managed-section merge replaces only the
   delimited Specrew block; everything the user owns is preserved exactly (atomic write, no partial-write
   corruption).
3. **The anti-raw-`specify.exe workflow` guard, single-sourced (FR-013).** The exact coordinator guard rides
   in BOTH the persistent file and the front-loaded bootstrap, from one source
   (`Get-SpecrewCoordinatorFragment`), so the surfaces cannot drift.
4. **Bootstrap front-load (FR-014).** The immediate Specrew action is ordered above the broader context.
5. **Host-neutral delivery core (FR-015).** The shared instruction-delivery core reads `InstructionsFile`
   from host manifests with no `agy`/Antigravity/host-name literals; the host-coupling firewall guards it,
   with a negative test that fails-closed on a planted single-host literal.

**Real-host evidence (honest scope, machine-local, TG-005):** on `agy` (Opus 4.6) and Claude, a cold
`init → launch` came up **as the Specrew coordinator** and drove the **governed design-workshop** lens-by-lens
— no raw `specify.exe` — with same-host and cross-host resume holding, and `start-context.json` integrity
preserved through the strong-model transitions (the iter-001 stale-cursor re-scaffold did NOT recur). **Gemini
Flash facilitated the workshop competently but then self-authorized `specify → clarify → plan`** — the
**FR-017 honest weak-model caveat is preserved** (evidence, not a failure; the coordinator must be a strong
model until a deterministic gate exists — Proposal 180). The `AGENTS.md → GEMINI.md` priority is
**docs-corroborated only** (the behavioral probe was staged but not run; the maintainer accepted this). No
full/verified Antigravity-parity claim (SC-018).

This branch is version-bumped to **0.38.0-beta1**; `origin/main` is integrated during the PR step (the branch
is 4 commits behind at closeout — merged before the PR opens).

## Delivered Scope (by iteration)

| Iteration | Closed | Scope | Status |
| --- | --- | --- | --- |
| 001 | 2026-06-17 | F-183 Antigravity refocus follow-up: real `conversationId` state, per-session anchors, B3 on `PreInvocation`, self-marker classification, F-183 regression preservation, docs parity, machine-local `agy` evidence. 8 tasks (T001–T008), 26 SP human-approved temporary overcap (restored to 20 at retro). Review-signoff accepted at `8abc3d39` after a Proposal-145 send-back fixed a shared-core abstraction leak. | complete |
| 002 | 2026-06-18 | Persistent host instructions at `specrew init` (FR-011), byte-for-byte preservation (FR-012), single-sourced anti-`specify.exe` guard (FR-013), bootstrap front-load (FR-014), host-neutral manifest-driven core (FR-015), update/start heal (FR-016), real-host Opus/Flash validation (FR-017), single packaged source (FR-018). 6 tasks (T001–T006), 20/20 SP zero-variance. Review-signoff accepted at `7d170b8c` after a Proposal-145 send-back corrected an SC-005 evidence overclaim. | complete |

## Tests and Validation (re-run at this closeout on the branch tree)

- **Governance validator**: `validate-governance` scoped to `iterations/002` **PASS** (and the
  iteration-closeout state-truth + hardening-gate closure). Pre-existing repo-wide soft WARNs only
  (dashboard auto-render regression on *other* closed iterations; hand-driven handoff-block notes) — none
  iter-002-specific.
- **markdownlint**: **GREEN** — 0 issues across the 139 changed `.md` (the reviewer-artifact scaffolder's
  MD009/MD047/MD032 whitespace auto-fixed; no content change). Added `.markdownlintignore`
  (`.squad`/`.specify`/`node_modules`) so the PR-variant lint, which lists explicit changed files and only
  filters TOP-LEVEL `.squad`, skips nested test-fixture `.squad/*.md` the push CI already `--ignore`s.
- **Test suites: 55/55** of the changed surfaces + the bootstrap suite — `instruction-file-merge` (8/8),
  `instruction-deploy` (6/6), `host-coupling-firewall` (incl. the fail-closed negative test),
  **`filelist-completeness`** (cross-platform install guard), `iteration-state-truth`, `gate-stop-skill`,
  `version-info-states`, and the full `tests/bootstrap/*` suite (`ProviderMirrorParity`,
  `CoordinatorFrontLoad`, `DirectiveVersionBranch`, …). **Two stale bootstrap tests were retargeted at this
  closeout** (`test(f184)` commit `58cb8a94`) — see Known Non-Blocking Items.
- **Provider mirror parity (3 copies)** intact; the single-source fragment + guard verified across surfaces.
- **The full CI/parity suite (`specrew-ci.yml`) runs on the PR as the comprehensive gate** (the F-141/F-174
  lesson: the iterations never run every set). The deterministic-gate + contract-lane jobs cover the sets
  not run locally.

## Accepted Review and Retro Evidence

Both iterations carry an accepted `review.md` and an approved `retro.md` under
`specs/184-full-antigravity-refocus/iterations/<NNN>/`. Highlights:

- **Iteration 001**: real-host `agy` validation; a Proposal-145 send-back moved runtime hook policy into the
  manifest-driven `RefocusHookBindings.DispatcherRuntime` and added the host-coupling firewall guard against
  shared-core host literals.
- **Iteration 002**: `review.md` Overall Verdict `accepted` (T001–T006 pass, no FR/SC gaps); an independent
  Proposal-145 review verified the committed tree and caught an SC-005 evidence overclaim (corrected across
  three files, grep-verified clean) before sign-off; review-signoff approved 2026-06-17; retro held (20/20
  zero-variance; the firewall negative test applied iter-001's "no-coupling needs a negative test" lesson up
  front).

## Work Kind

`.specrew/work-kind.yml` declares **`work_kind: software-feature`** — product/runtime behavior (init/update/
start instruction delivery, the bootstrap provider, host manifests, package FileList) that ships a release.
The closeout-evidence check is satisfied by this `closeout.md` + the `closeout-dashboard.md`.

## Known Non-Blocking Items (with dispositions)

| Item | Disposition |
| --- | --- |
| **Weak-model boundary-discipline FAIL** — Gemini Flash self-authorized `specify→clarify→plan` despite the persistent instructions and the refocus digest. | The **headline finding**, and exactly the FR-017 honest weak-model caveat (evidence, not a failure). Carry: **Proposal 180** (deterministic PreToolUse lifecycle gate) — cooperative/textual enforcement does not hold a weak model; only a deterministic gate blocks self-approval. Maintainer decision: the coordinator must be a strong model. |
| **`verdict_history` mixes conventions and is internally scrambled** (this session's entries name the TO boundary; iter-001's name the FROM). | **ACCEPTED as-is** at iteration-closeout (the actual authorizations are sound — each a human verdict at an explicit stop; the cursor never self-advanced). Carry: **Proposal 142** (state-truth integrity) for the ledger cleanup. Rewriting was declined (risks corrupting the ledger). |
| **`AGENTS.md → GEMINI.md` priority docs-corroborated only** — the behavioral BANANA/APPLE probe was staged but not run. | The maintainer accepted docs + weak behavioral corroboration (both Opus and Flash honored the `AGENTS.md` section). GEMINI.md handling was deferred at T001, so this is a recorded residual, not a requirement gap. |
| **Cold-init dangling reference** — the coordinator fragment instructs reading `.specrew/last-start-prompt.md`, which `specrew init` does not create (only `specrew start` / the hook does). | The `PreInvocation` hook self-heals it before the model reads it on the normal path, so it did not trip. Carry: **Proposal 143** (absence-tolerant fragment / greenfield-brownfield init orientation). |
| **Two stale bootstrap tests retargeted at this closeout** (`HandoverHookPrimary`, `ProjectMetadataAccessor`). | `HandoverHookPrimary` grepped for the old hardcoded `'PostToolUse' = [pscustomobject]` registration that iter-001's approved abstraction-leak fix replaced with the manifest-driven model (PostToolUse unregistered per TG-004a); retargeted to **positively assert the approved model AND fail-closed** if PostToolUse is re-registered or re-hardcoded (both verified). `ProjectMetadataAccessor` named feature 174, which merged to main; moved its present+resumable guard onto a controlled temp repo. `test(f184)` commit `58cb8a94`. |
| **Antigravity transcript-parser gap** (handover falls back to a raw transcript tail; Claude's parses cleanly) and **concurrent-session false advisory** (a graceful `agy` exit does not clear the session marker). | Bounded, cosmetic candidate follow-ups; recorded in `iterations/002/drift-log.md`. |
| **SC-018 release carry-forwards** remain OPEN. | beta-before-stable (this beta PR satisfies the first step); `MigrateLegacyTopLevelEventMap` legacy-upgrade validation (carry to stable with an open note); reproducible-or-machine-local `agy` evidence (gathered — keep the machine-local label). |
| Published-beta install validation of the bootstrap/instruction surfacing on the real host. | The beta gate: the dev-tree real-host PASS is necessary-not-sufficient for the shipped bytes; the maintainer validates the installed `0.38.0-beta1` before stable promotion. |

## Authorized Next Steps (maintainer directive, 2026-06-18)

Feature-closeout is branch-ready evidence; the maintainer directed the PR + beta steps. Scope expansion beyond
the iter-002 plan's "feature-closeout is not authorized in this iteration" is recorded as an explicit decision
in `iterations/002/drift-log.md`.

1. Integrate `origin/main` into the branch (4 commits behind), version-bump to `0.38.0-beta1`, push.
2. Open a PR (feature → `main`), **BETA-only claim**, with the Flash weak-model caveat in the release notes;
   wait for the GitHub Copilot automated review and `specrew-ci.yml`.
3. Address Copilot's review comments. (Merge / tag / publish are NOT done in this pass — the directive stops
   at "wait for Copilot comments, fix them".)

Beta-before-stable is universal; stable promotion is a later, separate human-validated step.

## Branch Hygiene at Closeout

- Branch `184-full-antigravity-refocus`; 83 commits ahead of `origin/main`, 4 behind (the main integration is
  the first authorized next step, before the PR).
- Working tree clean before the feature-closeout sync except the canonical session/cache churn
  (`.specrew/start-context.json`, `.squad/identity/now.md`, `.squad/decisions.md`, …) which the working-tree
  gate legitimately excludes; closeout commits are path-limited to F-184 artifacts (plus the `.markdownlintignore`
  CI-hygiene fix and the `test(f184)` retargets, both honestly labeled).

## Final Status

Feature 184 is complete: two iterations delivered, both reviewed and retro'd and accepted; iteration 001's
Antigravity refocus parity and iteration 002's persistent host instructions + single-sourced anti-`specify.exe`
guard + host-neutral manifest-driven delivery shipped; real-host-validated for strong models (Opus, Claude)
with the weak-model boundary-discipline caveat honestly evidenced (FR-017); the deferred follow-ups named with
dispositions (Proposals 180 / 142 / 143 + two nits); version `0.38.0-beta1`. The maintainer authorized the PR +
beta steps, which proceed to the Copilot-review stop.
