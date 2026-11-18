# Closed/open table: iteration 001, T005 (FR-008a, design condition 1)

**Written**: 2026-11-11, before T006 changes any definition | **Generator**:
`specs/206-bug-bash/iterations/001/closed-open-table.ps1` (read-only; it calls the validator's and the renderer's
own functions and writes only this table's rows)

## The four answers

| Column | Rule | Used today by |
| --- | --- | --- |
| Index | the iteration is in `.specrew/closed-iterations.yml` | the validator's closed filter |
| Heuristic | `Get-SpecrewClosedIterationFromStateFile`: state.md text such as `Current Phase: iteration-closeout`, `RETRO COMPLETE`, `Status: complete`, `iteration closed` | the validator's closed filter (unscoped runs: the nightly) and the index rebuild |
| Validator today | Index **or** Heuristic: what the nightly skips as closed | the nightly |
| Renderer today | `Current Phase` matches closed/complete, or `Iteration Status` matches closed, or `review.md` Overall Verdict matches `accepted` | the dashboard and the dashboard check |
| New | D3: Index **or** canonical `Iteration Status` `complete`/`abandoned`; a frozen-list entry is `frozen` (judged by no check, not closed) | T006 makes it the one rule for all three users |

## Summary

- 161 iterations. Under the new rule: 126 closed, 17 open, 18 frozen.
- 36 iterations change their answer for at least one user (below, by group, each with its reason). The other 125
  answer the same under every rule that uses them.
- Whether any change produces a new finding is T010's check (the local nightly replay after T007, T008, T009 and
  T011). If one does, the work stops and that iteration goes to the maintainer; nothing is added to the frozen
  list.

## What changes, and why

### A. The 18 frozen entries: closed or open today, judged by nothing after T008 (FR-006, FR-007)

- `048-beta-before-stable-sdlc/001` (`retro`), `197-continuous-co-review/001` (`retro`): validator open, renderer
  closed (review `accepted`).
- `198-beta2-hardening/008` (`blocked`): validator open; renderer closed only because its blocked-verdict text
  contains the word "accepted" ("T066 review signoff is accepted").
- The 15 dashboard entries (141/006-008, 174/006, 174/008-011, 182/002-004, 197/003-005, 198/003): `complete`,
  closed under every rule today; frozen because they predate automatic dashboards.

### B. Abandoned and not in the index: open today, closed after (4)

`197-continuous-co-review/002`, `197-continuous-co-review/007`, `197-continuous-co-review/008`,
`198-beta2-hardening/005`. Their `Iteration Status` is `abandoned`, which no current rule reads. Effect: the
nightly stops validating them as open and the closed-iteration checks apply instead. The dashboard check does not
apply (it judges `complete` iterations only, T009).

### C. Closed for the renderer only by an accepted review: open after (12)

`001-specrew-product/002`, `/005` to `/012`; `005-stack-aware-quality-bar/001`, `/002`;
`007-user-facing-progress-handoff/002`. Schema v1 state files: no `Iteration Status`, no `Current Phase`, not in
the index; `review.md` says `accepted`. The new rule drops the review-verdict rule, so they are open everywhere.
Effect: the nightly already validates them as open today, so its answer does not change; the dashboard check
skips features before 017, so it does not change either; **the rendered dashboards will show them as open.**
That display change is the only effect, and it is the maintainer's to accept or redirect.

### D. `197-continuous-co-review/006` (`retro`): renderer closed today, open after T006, closed after T007

Renderer closed by review `accepted`. The maintainer's ruling (2026-11-10) marks it `abandoned` in T007, which
makes it closed under the new rule. Not a frozen entry (feature plan, "197/006, resolved").

### E. `198-beta2-hardening/009` (`reviewing`): renderer open today, closed after

In the index since the 2026-08-06 rebuild (and closed by the heuristic), while its own `state.md` says
`Current Phase: review-signoff`, `Iteration Status: reviewing`. The new rule follows the index, as the validator
already does. The dashboard check will not judge it (status is not `complete`); its `dashboard.md` exists. **The
index entry contradicts the state file; 206 changes neither and reports it here.**

## Unchanged, but named

- `198-beta2-hardening/011` (`retro`): open under every rule today and after T006. The maintainer's ruling
  (2026-11-10) marks it `abandoned` in T007, which closes it under the new rule.
- **`198-beta2-hardening/010`: awaiting the maintainer's ruling. Marked nothing.**
  - Status: open under every rule (row below). `state.md`: `Iteration Status: reviewing`, phase `review-signoff`,
    last updated 2026-08-01; `plan.md`: `planning`. Not in the index; no `review.md`.
  - T082, "DRIFT-198-I009-041 — authority-store containment against reparse points" (FR-008, 5.0 SP), corrected
    from `done` to `needs-rework` on 2026-08-01.
  - Blocking finding DRIFT-198-I010-004: containment covers path resolution, not enumeration; four enumeration
    sites in `scripts/internal/continuous-co-review/review-authority-store.ps1` (203's protected file). Handed to
    feature 203 as HO-206-4 whatever the ruling.
  - Passes today only at capacity 20 (seen during OVERRIDE 5); the nightly never reported it.

## Rulings at the T005 stop (maintainer, 2026-11-11)

- **198/010**: abandoned and superseded, applied in T007. Its `state.md` says in plain words that
  DRIFT-198-I010-004 stays open and was handed to feature 203 as HO-206-4; T082 stays `needs-rework`.
- **Group C**: the display change is accepted for iteration 001; listed for iteration 002 as candidate T020, with
  the option of adding the 12 iterations to the closed index.
- **Group E (198/009)**: change neither; kept in the 203 hand-over record as HO-206-7.

## Every iteration

| Iteration | Iteration Status | Index | Heuristic | Validator today | Renderer today | New | Change |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 001-specrew-product/000 | Terminal state reached | closed | closed | closed | closed | closed | - |
| 001-specrew-product/001 | Terminal state reached | closed | closed | closed | closed | closed | - |
| 001-specrew-product/002 | (none) | open | open | open | closed | open | renderer: closed -> open |
| 001-specrew-product/005 | (none) | open | open | open | closed | open | renderer: closed -> open |
| 001-specrew-product/006 | (none) | open | open | open | closed | open | renderer: closed -> open |
| 001-specrew-product/007 | (none) | open | open | open | closed | open | renderer: closed -> open |
| 001-specrew-product/008 | (none) | open | open | open | closed | open | renderer: closed -> open |
| 001-specrew-product/009 | (none) | open | open | open | closed | open | renderer: closed -> open |
| 001-specrew-product/010 | (none) | open | open | open | closed | open | renderer: closed -> open |
| 001-specrew-product/011 | (none) | open | open | open | closed | open | renderer: closed -> open |
| 001-specrew-product/012 | (none) | open | open | open | closed | open | renderer: closed -> open |
| 005-stack-aware-quality-bar/001 | (none) | open | open | open | closed | open | renderer: closed -> open |
| 005-stack-aware-quality-bar/002 | (none) | open | open | open | closed | open | renderer: closed -> open |
| 005-stack-aware-quality-bar/003 | (none) | closed | closed | closed | closed | closed | - |
| 005-stack-aware-quality-bar/004 | (none) | closed | closed | closed | closed | closed | - |
| 007-user-facing-progress-handoff/001 | (none) | closed | closed | closed | closed | closed | - |
| 007-user-facing-progress-handoff/002 | (none) | open | open | open | closed | open | renderer: closed -> open |
| 008-reviewer-escalation-symmetry/001 | Retrospective complete - iteration cl... | closed | closed | closed | closed | closed | - |
| 008-reviewer-escalation-symmetry/002 | retrospective complete - awaiting Alo... | closed | closed | closed | closed | closed | - |
| 008-reviewer-escalation-symmetry/003 | US2 accepted, retro/closeout artifact... | closed | closed | closed | closed | closed | - |
| 008-reviewer-escalation-symmetry/004 | Closed after successful implementatio... | closed | closed | closed | closed | closed | - |
| 008-reviewer-escalation-symmetry/005 | Closed after successful implementatio... | closed | closed | closed | closed | closed | - |
| 009-project-path-resolution/002 | (none) | closed | closed | closed | closed | closed | - |
| 011-specrew-start-conditional-pause/001 | Closeout validation green; iteration ... | closed | closed | closed | closed | closed | - |
| 011-specrew-start-conditional-pause/002 | Closeout validation green; iteration ... | closed | closed | closed | closed | closed | - |
| 012-descriptive-id-handoffs/001 | Closeout validation green; iteration ... | closed | closed | closed | closed | closed | - |
| 012-descriptive-id-handoffs/002 | Closeout validation green; iteration ... | closed | closed | closed | closed | closed | - |
| 013-validator-hardening/001 | Closeout validation green; iteration ... | closed | closed | closed | closed | closed | - |
| 013-validator-hardening/002 | Closeout validation green; iteration ... | closed | closed | closed | closed | closed | - |
| 014-handoff-format-scoping/001 | closed by Alon Fliess on 2026-05-12; ... | closed | closed | closed | closed | closed | - |
| 015-public-readiness-pass/001 | complete on 2026-05-13 by Alon Fliess... | closed | closed | closed | closed | closed | - |
| 015-public-readiness-pass/002 | iteration closed on 2026-05-13 via it... | closed | closed | closed | closed | closed | - |
| 016-substantive-interaction-model/001 | iteration closed via iteration-closeo... | closed | closed | closed | closed | closed | - |
| 016-substantive-interaction-model/002 | Post-implementation verification reco... | closed | closed | closed | closed | closed | - |
| 017-velocity-dashboard/001 | (none) | closed | closed | closed | closed | closed | - |
| 017-velocity-dashboard/002 | closed via iteration-closeout boundar... | closed | closed | closed | closed | closed | - |
| 018-velocity-dashboard-visual-richness/001 | Feature 018 Iteration 001 is closed a... | closed | closed | closed | closed | closed | - |
| 019-specrew-distribution-module/001 | Iteration 001 formally closed via clo... | closed | closed | closed | closed | closed | - |
| 019-specrew-distribution-module/002 | CLOSED — Iteration 002 delivered (8 S... | closed | closed | closed | closed | closed | - |
| 020-session-state-durability/001 | CLOSED — Iteration 001 delivered the ... | closed | closed | closed | closed | closed | - |
| 020-session-state-durability/002 | CLOSED — Iteration 002 delivered the ... | closed | closed | closed | closed | closed | - |
| 021-specrew-slash-commands/001 | iteration-closeout complete on 2026-0... | closed | closed | closed | closed | closed | - |
| 022-hotfix-schema-tests/001 | iteration-closeout complete on branch... | closed | closed | closed | closed | closed | - |
| 023-legacy-state-read-tolerance/001 | CLOSED — Iteration 001 iteration-clos... | closed | closed | closed | closed | closed | - |
| 024-slash-command-multi-host-correctness/001 | Iteration-closeout is complete on the... | closed | closed | closed | closed | closed | - |
| 028-review-evidence-integrity/001 | CLOSED — Iteration 001 review, retro,... | closed | closed | closed | closed | closed | - |
| 029-baseline-hygiene/001 | CLOSED — Iteration 001 review, retro,... | closed | closed | closed | closed | closed | - |
| 030-validator-speedup/001 | Iteration 001 is closed. Feature-clos... | closed | closed | closed | closed | closed | - |
| 031-commit-push-discipline/001 | REVIEW-APPROVED + RETRO-COMPLETE — pe... | closed | closed | closed | closed | closed | - |
| 032-closeout-lifecycle-sync/001 | Iteration 001 is closed. Feature-clos... | closed | closed | closed | closed | closed | - |
| 033-markdown-lint-pre-boundary/001 | Iteration 001 is closed. Feature-clos... | closed | closed | closed | closed | closed | - |
| 034-validator-memoization/001 | Iteration 001 is closed. Feature-clos... | closed | closed | closed | closed | closed | - |
| 035-validator-iteration-parallelization/001 | Iteration 001 is closed. Feature-clos... | closed | closed | closed | closed | closed | - |
| 036-closed-iteration-index/001 | Iteration 001 is closed. Feature-clos... | closed | closed | closed | closed | closed | - |
| 037-validator-repetition-detector/001 | Iteration 001 is closed. Feature-clos... | closed | closed | closed | closed | closed | - |
| 038-pr-review-integration/001 | Iteration 001 is closed. Feature-clos... | closed | closed | closed | closed | closed | - |
| 039-launch-mode-boundary-enforcement/001 | Iteration 001 has been advanced to th... | closed | closed | closed | closed | closed | - |
| 040-multi-host-launch-path/001 | (none) | open | open | open | open | open | - |
| 043-multi-host-onboarding/001 | complete | closed | closed | closed | closed | closed | - |
| 044-per-host-architecture-refactor/001 | complete | closed | closed | closed | closed | closed | - |
| 044-per-host-architecture-refactor/002 | complete | closed | closed | closed | closed | closed | - |
| 044-per-host-architecture-refactor/003 | complete | closed | closed | closed | closed | closed | - |
| 044-per-host-architecture-refactor/004 | complete | closed | closed | closed | closed | closed | - |
| 044-per-host-architecture-refactor/005 | complete | closed | closed | closed | closed | closed | - |
| 044-per-host-architecture-refactor/006 | complete | closed | closed | closed | closed | closed | - |
| 044-per-host-architecture-refactor/007 | complete | closed | closed | closed | closed | closed | - |
| 044-per-host-architecture-refactor/008 | complete | closed | closed | closed | closed | closed | - |
| 044-per-host-architecture-refactor/009 | complete | closed | closed | closed | closed | closed | - |
| 044-per-host-architecture-refactor/011 | complete | closed | closed | closed | closed | closed | - |
| 044-per-host-architecture-refactor/012 | complete | closed | closed | closed | closed | closed | - |
| 045-v0271-bugfix-bundle/001 | complete | closed | closed | closed | closed | closed | - |
| 045-v0271-bugfix-bundle/002 | complete | closed | closed | closed | closed | closed | - |
| 046-046-bug-bash/001 | complete (with retroactive review-rep... | closed | closed | closed | closed | closed | - |
| 047-bug-bash-trust-hardening/001 | complete | closed | closed | closed | closed | closed | - |
| 048-beta-before-stable-sdlc/001 | retro | open | open | open | closed | frozen | validator: open -> frozen; renderer: closed -> frozen |
| 049-pipeline-hardening-intake/001 | complete | closed | closed | closed | closed | closed | - |
| 049-pipeline-hardening-intake/002 | T008-T011 and the Iteration 002 retro... | closed | closed | closed | closed | closed | - |
| 049-pipeline-hardening-intake/003 | complete | closed | closed | closed | closed | closed | - |
| 049-pipeline-hardening-intake/004 | complete | closed | closed | closed | closed | closed | - |
| 049-pipeline-hardening-intake/005 | complete | closed | closed | closed | closed | closed | - |
| 050-cursor-host-support/001 | complete | closed | closed | closed | closed | closed | - |
| 050-cursor-host-support/002 | complete | closed | closed | closed | closed | closed | - |
| 050-cursor-host-support/003 | complete | closed | closed | closed | closed | closed | - |
| 051-multi-session-foundation/001 | complete | closed | closed | closed | closed | closed | - |
| 051-multi-session-foundation/002 | complete | closed | closed | closed | closed | closed | - |
| 051-multi-session-foundation/003 | complete | closed | closed | closed | closed | closed | - |
| 054-activate-spec-surfaces/001 | complete | closed | closed | closed | closed | closed | - |
| 139-boundary-authorization-prompt-truth/001 | complete | closed | closed | closed | closed | closed | - |
| 140-design-analysis-gate/001 | complete | closed | closed | closed | closed | closed | - |
| 140-unix-native-install/001 | complete | closed | closed | closed | closed | closed | - |
| 140-unix-native-install/002 | complete | closed | closed | closed | closed | closed | - |
| 140-unix-native-install/003 | closing (review-signoff APPROVE — *ac... | closed | closed | closed | closed | closed | - |
| 141-design-gate-runtime-hardening/001 | complete | closed | closed | closed | closed | closed | - |
| 141-design-gate-runtime-hardening/002 | complete | closed | closed | closed | closed | closed | - |
| 141-design-gate-runtime-hardening/003 | complete | closed | closed | closed | closed | closed | - |
| 141-design-gate-runtime-hardening/004 | complete | closed | closed | closed | closed | closed | - |
| 141-design-gate-runtime-hardening/005 | complete | closed | closed | closed | closed | closed | - |
| 141-design-gate-runtime-hardening/006 | complete | closed | closed | closed | closed | frozen | validator: closed -> frozen; renderer: closed -> frozen |
| 141-design-gate-runtime-hardening/007 | complete | closed | closed | closed | closed | frozen | validator: closed -> frozen; renderer: closed -> frozen |
| 141-design-gate-runtime-hardening/008 | complete | closed | closed | closed | closed | frozen | validator: closed -> frozen; renderer: closed -> frozen |
| 141-design-gate-runtime-hardening/009 | complete | closed | closed | closed | closed | closed | - |
| 141-design-gate-runtime-hardening/010 | complete | closed | closed | closed | closed | closed | - |
| 141-design-gate-runtime-hardening/011 | complete | closed | closed | closed | closed | closed | - |
| 141-design-gate-runtime-hardening/012 | complete | closed | closed | closed | closed | closed | - |
| 159-update-ux-small-fixes/001 | complete | closed | closed | closed | closed | closed | - |
| 160-unix-resolver-sidecar-hardening/001 | complete | closed | closed | closed | closed | closed | - |
| 161-managed-skill-preserving-guard/001 | complete | closed | closed | closed | closed | closed | - |
| 168-post-ship-proposal-amendment-discipline/001 | complete | closed | closed | closed | closed | closed | - |
| 170-retire-evaluation-surface/001 | complete | closed | closed | closed | closed | closed | - |
| 171-specrew-refocus/001 | complete | closed | closed | closed | closed | closed | - |
| 171-specrew-refocus/002 | complete | closed | closed | closed | closed | closed | - |
| 172-profile-setup-ux-copy/001 | complete | closed | closed | closed | closed | closed | - |
| 174-hook-driven-session-bootstrap/001 | complete | closed | closed | closed | closed | closed | - |
| 174-hook-driven-session-bootstrap/002 | complete | closed | closed | closed | closed | closed | - |
| 174-hook-driven-session-bootstrap/003 | complete | closed | closed | closed | closed | closed | - |
| 174-hook-driven-session-bootstrap/004 | complete | closed | closed | closed | closed | closed | - |
| 174-hook-driven-session-bootstrap/005 | complete | closed | closed | closed | closed | closed | - |
| 174-hook-driven-session-bootstrap/006 | complete | closed | closed | closed | closed | frozen | validator: closed -> frozen; renderer: closed -> frozen |
| 174-hook-driven-session-bootstrap/007 | abandoned | closed | closed | closed | closed | closed | - |
| 174-hook-driven-session-bootstrap/008 | complete | closed | closed | closed | closed | frozen | validator: closed -> frozen; renderer: closed -> frozen |
| 174-hook-driven-session-bootstrap/009 | complete | closed | closed | closed | closed | frozen | validator: closed -> frozen; renderer: closed -> frozen |
| 174-hook-driven-session-bootstrap/010 | complete | closed | closed | closed | closed | frozen | validator: closed -> frozen; renderer: closed -> frozen |
| 174-hook-driven-session-bootstrap/011 | complete | closed | closed | closed | closed | frozen | validator: closed -> frozen; renderer: closed -> frozen |
| 174-hook-driven-session-bootstrap/012 | complete | closed | closed | closed | closed | closed | - |
| 176-product-domain-lens/001 | complete | closed | closed | closed | closed | closed | - |
| 177-software-development-rules-lens/001 | complete | closed | closed | closed | closed | closed | - |
| 177-software-development-rules-lens/002 | complete | closed | closed | closed | closed | closed | - |
| 182-work-kind-branch-governance/001 | complete | closed | closed | closed | closed | closed | - |
| 182-work-kind-branch-governance/002 | complete | closed | closed | closed | closed | frozen | validator: closed -> frozen; renderer: closed -> frozen |
| 182-work-kind-branch-governance/003 | complete | closed | closed | closed | closed | frozen | validator: closed -> frozen; renderer: closed -> frozen |
| 182-work-kind-branch-governance/004 | complete | closed | closed | closed | closed | frozen | validator: closed -> frozen; renderer: closed -> frozen |
| 183-stability-quality-bundle/001 | complete | closed | closed | closed | closed | closed | - |
| 184-full-antigravity-refocus/001 | complete | closed | closed | closed | closed | closed | - |
| 184-full-antigravity-refocus/002 | complete | closed | closed | closed | closed | closed | - |
| 197-continuous-co-review/001 | retro | open | open | open | closed | frozen | validator: open -> frozen; renderer: closed -> frozen |
| 197-continuous-co-review/002 | abandoned | open | open | open | open | closed | validator: open -> closed; renderer: open -> closed |
| 197-continuous-co-review/003 | complete | closed | closed | closed | closed | frozen | validator: closed -> frozen; renderer: closed -> frozen |
| 197-continuous-co-review/004 | complete | closed | closed | closed | closed | frozen | validator: closed -> frozen; renderer: closed -> frozen |
| 197-continuous-co-review/005 | complete | closed | closed | closed | closed | frozen | validator: closed -> frozen; renderer: closed -> frozen |
| 197-continuous-co-review/006 | retro | open | open | open | closed | open | renderer: closed -> open |
| 197-continuous-co-review/007 | abandoned | open | open | open | open | closed | validator: open -> closed; renderer: open -> closed |
| 197-continuous-co-review/008 | abandoned | open | open | open | open | closed | validator: open -> closed; renderer: open -> closed |
| 197-continuous-co-review/009 | complete | closed | closed | closed | closed | closed | - |
| 197-continuous-co-review/010 | complete | closed | closed | closed | closed | closed | - |
| 198-beta2-hardening/001 | complete | closed | closed | closed | closed | closed | - |
| 198-beta2-hardening/002 | complete | closed | closed | closed | closed | closed | - |
| 198-beta2-hardening/003 | complete | closed | closed | closed | closed | frozen | validator: closed -> frozen; renderer: closed -> frozen |
| 198-beta2-hardening/005 | abandoned | open | open | open | open | closed | validator: open -> closed; renderer: open -> closed |
| 198-beta2-hardening/006 | complete | closed | closed | closed | closed | closed | - |
| 198-beta2-hardening/007 | complete | closed | closed | closed | closed | closed | - |
| 198-beta2-hardening/008 | blocked | open | open | open | closed | frozen | validator: open -> frozen; renderer: closed -> frozen |
| 198-beta2-hardening/009 | reviewing | closed | closed | closed | open | closed | renderer: open -> closed |
| 198-beta2-hardening/010 | reviewing | open | open | open | open | open | - |
| 198-beta2-hardening/011 | retro | open | open | open | open | open | - |
| 199-beta3-stabilization/001 | complete | closed | closed | closed | closed | closed | - |
| 199-beta3-stabilization/002 | complete | closed | closed | closed | closed | closed | - |
| 199-beta3-stabilization/003 | complete | closed | closed | closed | closed | closed | - |
| 202-beta4-1-ux-stabilization/001 | complete | closed | closed | closed | closed | closed | - |
| 202-beta4-1-ux-stabilization/002 | complete | closed | closed | closed | closed | closed | - |
| 202-beta4-1-ux-stabilization/003 | complete | closed | closed | closed | closed | closed | - |
| 206-bug-bash/001 | executing | open | open | open | open | open | - |
