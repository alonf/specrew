# Closed/Open Table After T006 (evidence)

**Generated**: 2026-11-11, by the unchanged generator
`specs/206-bug-bash/iterations/001/closed-open-table.ps1`, on the T006 fix tree (option 1 with conditions).
The pre-fix record is `closed-open-table.md` beside this file and is kept as it was (maintainer, 2026-11-11).

**What to read**: the "New" column and the totals (161 iterations: 126 closed, 17 open, 18 frozen) are
unchanged from the pre-fix table in every row. 21 rows differ, and only in "Renderer today" (and with it
"Change"), because that column asks the renderer's code, which T006 rewrote:

- 18 rows are the renderer changes the pre-fix table predicted; the renderer now gives the "New" answer.
- 3 frozen rows (048/001, 197/001, 198/008) show the renderer answering open: the frozen list is written by
  T007, and until then they are ordinary iterations with status retro or blocked. After T007 the table is
  rerun once more to confirm all 18 frozen rows agree.

The generator on the pre-fix code (`719f1cef`) reproduces `closed-open-table.md` row for row.
`Test-SpecrewIterationClosed` and the renderer agree with the "New" column for all 161 iterations.

| Iteration | Iteration Status | Index | Heuristic | Validator today | Renderer today | New | Change |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 001-specrew-product/000 | Terminal state reached | closed | closed | closed | closed | closed | - |
| 001-specrew-product/001 | Terminal state reached | closed | closed | closed | closed | closed | - |
| 001-specrew-product/002 | (none) | open | open | open | open | open | - |
| 001-specrew-product/005 | (none) | open | open | open | open | open | - |
| 001-specrew-product/006 | (none) | open | open | open | open | open | - |
| 001-specrew-product/007 | (none) | open | open | open | open | open | - |
| 001-specrew-product/008 | (none) | open | open | open | open | open | - |
| 001-specrew-product/009 | (none) | open | open | open | open | open | - |
| 001-specrew-product/010 | (none) | open | open | open | open | open | - |
| 001-specrew-product/011 | (none) | open | open | open | open | open | - |
| 001-specrew-product/012 | (none) | open | open | open | open | open | - |
| 005-stack-aware-quality-bar/001 | (none) | open | open | open | open | open | - |
| 005-stack-aware-quality-bar/002 | (none) | open | open | open | open | open | - |
| 005-stack-aware-quality-bar/003 | (none) | closed | closed | closed | closed | closed | - |
| 005-stack-aware-quality-bar/004 | (none) | closed | closed | closed | closed | closed | - |
| 007-user-facing-progress-handoff/001 | (none) | closed | closed | closed | closed | closed | - |
| 007-user-facing-progress-handoff/002 | (none) | open | open | open | open | open | - |
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
| 048-beta-before-stable-sdlc/001 | retro | open | open | open | open | frozen | validator: open -> frozen; renderer: open -> frozen |
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
| 197-continuous-co-review/001 | retro | open | open | open | open | frozen | validator: open -> frozen; renderer: open -> frozen |
| 197-continuous-co-review/002 | abandoned | open | open | open | closed | closed | validator: open -> closed |
| 197-continuous-co-review/003 | complete | closed | closed | closed | closed | frozen | validator: closed -> frozen; renderer: closed -> frozen |
| 197-continuous-co-review/004 | complete | closed | closed | closed | closed | frozen | validator: closed -> frozen; renderer: closed -> frozen |
| 197-continuous-co-review/005 | complete | closed | closed | closed | closed | frozen | validator: closed -> frozen; renderer: closed -> frozen |
| 197-continuous-co-review/006 | retro | open | open | open | open | open | - |
| 197-continuous-co-review/007 | abandoned | open | open | open | closed | closed | validator: open -> closed |
| 197-continuous-co-review/008 | abandoned | open | open | open | closed | closed | validator: open -> closed |
| 197-continuous-co-review/009 | complete | closed | closed | closed | closed | closed | - |
| 197-continuous-co-review/010 | complete | closed | closed | closed | closed | closed | - |
| 198-beta2-hardening/001 | complete | closed | closed | closed | closed | closed | - |
| 198-beta2-hardening/002 | complete | closed | closed | closed | closed | closed | - |
| 198-beta2-hardening/003 | complete | closed | closed | closed | closed | frozen | validator: closed -> frozen; renderer: closed -> frozen |
| 198-beta2-hardening/005 | abandoned | open | open | open | closed | closed | validator: open -> closed |
| 198-beta2-hardening/006 | complete | closed | closed | closed | closed | closed | - |
| 198-beta2-hardening/007 | complete | closed | closed | closed | closed | closed | - |
| 198-beta2-hardening/008 | blocked | open | open | open | open | frozen | validator: open -> frozen; renderer: open -> frozen |
| 198-beta2-hardening/009 | reviewing | closed | closed | closed | closed | closed | - |
| 198-beta2-hardening/010 | reviewing | open | open | open | open | open | - |
| 198-beta2-hardening/011 | retro | open | open | open | open | open | - |
| 199-beta3-stabilization/001 | complete | closed | closed | closed | closed | closed | - |
| 199-beta3-stabilization/002 | complete | closed | closed | closed | closed | closed | - |
| 199-beta3-stabilization/003 | complete | closed | closed | closed | closed | closed | - |
| 202-beta4-1-ux-stabilization/001 | complete | closed | closed | closed | closed | closed | - |
| 202-beta4-1-ux-stabilization/002 | complete | closed | closed | closed | closed | closed | - |
| 202-beta4-1-ux-stabilization/003 | complete | closed | closed | closed | closed | closed | - |
| 206-bug-bash/001 | executing | open | open | open | open | open | - |
