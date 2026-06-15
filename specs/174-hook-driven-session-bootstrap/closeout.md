# Feature Closeout: Hook-Driven Session Bootstrap

**Schema**: v1
**Feature**: 174-hook-driven-session-bootstrap
**Branch**: 174-hook-driven-session-bootstrap
**Closed**: 2026-06-15
**Status**: COMPLETE — maintainer-authorized to proceed to the PR + `0.37.0-beta1` publish SDLC steps
**Closer**: Claude, authorized by Alon Fliess for feature-closeout AND the PR / beta-publish steps (standing
mandate, 2026-06-15: "create a PR, wait for GH Copilot, fix the review comments … then validate the fix with
proposal 145, then if all ok, merge the PR and run the action that issues the beta to the PSGallery").

## Executive Summary

Feature 174 replaces Specrew's stateless, `specrew start`-driven entry with **hook-driven session bootstrap**
and **cross-session, cross-host continuity**, delivered across **twelve iterations (001–012; 007 was closed
abandoned-superseded)** from 2026-06-08 to 2026-06-15. It implements the 28 functional requirements
(FR-001..028) and the success criteria (SC-001..022) of `spec.md`; every iteration was reviewed and retro'd,
all accepted.

The feature ships in six capability layers:

1. **SessionStart hook → dispatcher → providers.** `specrew init` deploys a host-appropriate SessionStart
   hook; on launch the dispatcher (`specrew-hook-dispatcher.ps1`) runs the bootstrap provider (orientation
   banner + governed contract + resume) and the handover provider, fail-open, on every hook-capable host.
2. **Per-host delivery (pointer vs inline).** Claude + Codex receive a compact POINTER (the 45 KB contract is
   referenced, not inlined, to live under the host's hook-output cap); Copilot + Cursor receive the INLINE
   contract; Antigravity is hookless and keeps `specrew start`.
3. **Rolling handover with cross-host auto-resume.** A host-agnostic rolling handover
   (`.specrew/handover/session-handover.md`: `schema: v1` frontmatter + eight fixed `##` sections + atomic
   `.old` crash backup, gitignored, overwrite-in-place) lets you stop in one host and resume in another.
4. **Verdict integrity on resume.** Committed ≠ authorized: a resumed session that lands at an unapproved
   boundary stops and surfaces "awaiting your verdict" — it never advances on a bare `continue`, and one
   approval advances at most one boundary.
5. **New commands.** `specrew handover author` (`--from`/`--stdin`/`--feature`/`--boundary`/`--host`) and
   `specrew hooks status | install | remove [--host]`.
6. **Documentation reconciliation (iteration 012).** The six user-facing surfaces, the handover file schema,
   and the new commands are documented to the shipped model, with honest, evidence-scoped host-confirmation
   claims.

**Real-host evidence (honest scope):** confirmed on **Claude, Codex, and Copilot** for hook bootstrap,
governed orientation/resume, and rolling handover read/write (including Codex→Claude and Codex→Copilot on
disk). **Cursor is pending live validation.** **Rich boundary-packet capture + automatic verdict capture
remain Claude-only** (the marker is Claude-scoped; D-001 is the host-neutral fast-follow); a non-Claude resume
at a boundary safely degrades to "awaiting your verdict".

This branch is integrated with `origin/main` (Feature 182 / 0.36.0 base, merge `727a1a9b`) and version-bumped
to **0.37.0-beta1**.

## Delivered Scope (by iteration)

| Iteration | Closed | Scope | Status |
| --- | --- | --- | --- |
| 001–003 | 2026-06-08 | Foundation: SessionStart hook + dispatcher + bootstrap/handover provider scaffolding, deploy/remove, hook-capable-host detection. | complete |
| 004–006 | 2026-06-09/10 | Provider content + per-host delivery model + the rolling-handover write/read round-trip; `Get-StartPrompt` relocated to `scripts/internal/launch-contract.ps1`. | complete |
| 007 | 2026-06-14 | Closed **abandoned-superseded** (folded into the 011 fix-plan). | abandoned |
| 008–010 | 2026-06-11/13 | Cross-host resume + multi-host dogfood (DF-3/4/5/7 discovery), per-host framing, refocus integration. | complete |
| 011 | 2026-06-14 | DF-3/4/5/7 boundary-authoring + verdict-integrity cluster + FR-028 hook hardening; the real-host acceptance gate found + fixed a host-delivery/packaging cluster (P1 clean-install resolver, P2 10K hook-output cap drop, a StrictMode `$null.Count` crash); banner confirmed surfacing on Claude. Cap-revert obligation discharged. | complete |
| 012 | 2026-06-15 | User-facing documentation reconciliation (DR-1..DR-10 / SC-1..SC-6); the F-182 merge reconciliation (D-009 cap, D-010 forge sweep, D-011 specify.md gate-stop); `0.37.0-beta1` release-prep. | complete |

## Tests and Validation (re-run at this closeout on the integrated tree)

- **Governance validator**: `validate-governance` PASS — full unscoped scan (41 iterations validated) AND the
  iter-012 scoped run; iteration-012 PASS including the post-F-182 retro schema. Pre-existing repo-wide soft
  WARNs only (hand-driven handoff-block notes; pr-review soft-warnings on *other* features).
- **F-174 focused lanes (green at review-signoff, the verification gate for iter-012):** DirectiveDeliveryCap
  (+ the new 4b resume-floor guard: handover ≥ 380, reconciliation ≥ 300), HostDeliveryPolicy,
  HandoverHookPrimary, HookPacketCapture, HookVerdictCapture, refocus-channels, refocus-digests,
  refocus-engine, forge-neutralization-sweep. Bootstrap suite + contract-parity guards (47).
- **markdownlint**: clean on all iter-012 artifacts and the touched user-facing docs (two pre-existing MD038
  errors in the spec artifacts fixed at iteration-closeout).
- **Provider mirror parity (3 copies) + refocus digest parity (2 copies)** intact; both edited scripts parse
  clean.
- **The full CI/parity suite (`specrew-ci.yml`) runs on the PR as the comprehensive gate** (the F-141 lesson:
  the iterations never ran every set). Merge is gated on CI green per the standing mandate.

## Accepted Review and Retro Evidence

Every iteration carries an accepted `review.md` and an approved `retro.md` under
`specs/174-hook-driven-session-bootstrap/iterations/<NNN>/`. Highlights:

- **Iteration 011**: real-host re-dogfood acceptance gate; second Proposal-145 review (5 confirmed / 6 refuted,
  all addressed); the verdict-integrity core held under host switches even while the bootstrap *surfacing* was
  briefly broken; all defects fixed and banner confirmed live.
- **Iteration 012**: `review.md` Overall Verdict `accepted` (T001–T007 pass); maintainer close review
  turn-by-turn; an adversarial doc-consistency sweep returned zero residual defects after the four
  maintainer-named findings were fixed; review-signoff approved 2026-06-15; retro held.

## Main-Integration Reconciliation (F-182 merge + handoffs received)

`origin/main` (Feature 182 / 0.36.0 base) was merged into this branch mid-iteration-012 via `727a1a9b`. The
F-182 closeout routed three handoffs to F-174, all **received and reconciled** here:

- **DF-006 (session-start/state)** — owned by this feature's bootstrap/resume rewrite.
- **DF-005 source / `launch-contract.ps1`** — the relocated `scripts/internal/launch-contract.ps1` was added to
  F-182's widened forge-neutralization sweep's positive-assertion list (drift D-010).
- **DF-010 (release-train)** — rebased onto post-F-182 main preserving F-182's neutralized sources; the
  `specrew-start.ps1` conflict resolved in favor of its deletion.

Reconciliation drift recorded in `iterations/012/drift-log.md`: D-009 (SessionStart 10K-cap headroom — the
reconciliation floor reverted, headroom recovered from refocus, resume-floor guard added), D-010 (forge
sweep), D-011 (specify.md gate-stop host-scoping, pre-existing).

## Work Kind

`.specrew/work-kind.yml` declares **`work_kind: software-feature`** — product/runtime behavior (hooks,
dispatcher, providers, new commands) that ships a release. The work-kind validator's `software-feature` scope
(`**`) covers the runtime + docs + spec change set; its closeout-evidence check is satisfied by this closeout
(`closeout-dashboard.md` present). `docs-only` would have been wrong (it produces no release and rejects
runtime files).

## Known Non-Blocking Items (with dispositions)

| Item | Disposition |
| --- | --- |
| **D-007 / CAP-1** (SessionStart payload size) stays open as the architectural parent. | Carry: the durable reduction is **Proposal 191** (in-flight-digest lead pilot — write the digest to `.specrew/runtime/resume-now.md` + a tiny anchor; ~700–850 char reclaim, supersedes iter-012's interim refocus trim) + **Proposal 179** (dispatcher fragment-priority drop). Current verdict-worst headroom ~106 chars: adequate for the beta, sequence the fix after it. |
| Rich boundary-packet + automatic verdict capture are **Claude-only**. | Carry: **D-001** host-neutral verdict-marker emission (fast-follow). Documented accurately; non-Claude hosts degrade safely to "awaiting your verdict". |
| **Cursor** not yet live-dogfooded. | Carry: pending live validation; mechanical bootstrap/resume expected for hook-capable hosts. |
| Published-beta install validation of bootstrap surfacing on the real host. | The beta gate: the dev-tree real-host PASS (iter-011) is necessary-not-sufficient for the shipped bytes; the maintainer validates the installed `0.37.0-beta1` before stable promotion. |
| Pre-existing repo-wide validator soft WARNs (hand-driven handoff-block notes; other-feature pr-review soft-warnings). | Pre-existing on main, outside F-174; the validator PASSES for F-174's iterations. |
| `specify.md`-style host-scoping in the other boundary digests. | Carry (candidate): D-011 was pre-existing; sweep the remaining digests for the same F-165 gap. |
| Velocity snapshot (`closeout-dashboard.md`) is a stale early capture (2026-06-08, committed at iter-004 review-signoff; predates iterations 005–012). | Preserved per its own "must not overwrite" historical notice and the F-182 precedent; the feature-closeout scaffolder leaves an existing dashboard untouched. **This `closeout.md` is the authoritative twelve-iteration record;** the fresh `iterations/012/dashboard.md` (iteration-closeout snapshot, 2026-06-15) is the current velocity capture. |

## Authorized Next Steps (maintainer standing mandate, 2026-06-15)

Feature-closeout is branch-ready evidence; the following steps are **separately authorized** by the standing
mandate and proceed autonomously, stopping only if a review fix requires manual/on-host testing or a problem
prevents the beta:

1. Push the branch to `origin`.
2. Open a PR (feature → `main`); wait for the GitHub Copilot automated review and for `specrew-ci.yml` green.
3. Address review comments — autonomously if docs/comments/test-only/inert; **stop for the maintainer** if a
   fix touches bootstrap/hook/dispatcher/refocus/directive-delivery behavior (= "requires a manual test").
4. Run `specrew refocus`, then validate the change with a Proposal-145 review of the PR diff.
5. If CI is green, 145 is clean, and Copilot is addressed/absent: merge with a merge commit.
6. Tag the merged `main` commit `v0.37.0-beta1` (dry-run first) and publish the prerelease to the PowerShell
   Gallery; confirm `Find-Module Specrew -AllowPrerelease` shows it live.

Beta-before-stable is universal; stable promotion is a later, separate human-validated step.

## Branch Hygiene at Closeout

- Branch `174-hook-driven-session-bootstrap`; `origin/main` integrated via `727a1a9b`. Ahead of
  `origin/174-hook-driven-session-bootstrap` (the branch has not yet been pushed; the push is the first
  authorized next step).
- Working tree clean before the feature-closeout sync except the canonical session/cache churn
  (`.specrew/start-context.json`, `.squad/identity/now.md`, `.squad/decisions.md`, …) which the working-tree
  gate legitimately excludes; closeout commits are path-limited to F-174 artifacts.

## Final Status

Feature 174 is complete: twelve iterations delivered (007 abandoned-superseded), all reviewed and retro'd and
accepted; hook-driven bootstrap + cross-host rolling-handover continuity + verdict integrity on resume + the
two new commands shipped; real-host-confirmed on Claude/Codex/Copilot (Cursor pending; rich-packet/verdict
capture Claude-only, documented honestly); the F-182 merge reconciled; the user-facing documentation brought
current; version `0.37.0-beta1`. The maintainer has authorized the PR + beta-publish SDLC steps, which proceed
per the standing mandate.
