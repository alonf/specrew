# Drift Log: Iteration 012

**Schema**: v1
**Spec**: [../../spec.md](../../spec.md)

Divergences between spec / plan / tasks and the implementation, each with the requirement citation and the
reconciliation path (lifecycle-discipline rule 4: drift is logged, not absorbed).

Iteration 012 is documentation-only by charter. The three entries below are **F-182 merge reconciliation** —
deviations introduced or surfaced when `origin/main` (Feature 182, work-kind & branch governance) was merged into
this branch mid-iteration (merge commit `727a1a9b`). They are code/test fixes outside the docs-only scope,
recorded here as drift (maintainer ruling 2026-06-15: attribute the merge-induced fixes as drift, not a new
iteration) rather than absorbed silently.

## D-011 — specify.md refocus digest carried un-host-scoped gate-stop phrasing (F-165 host-scoping gap)

- **Status**: resolved 2026-06-15.
- **Requirement**: FR-026/FR-027 (verdict-boundary integrity surfacing); F-165 host-scoped gate-stop.
- **Divergence**: the F-165 host-scoping (the `specrew-gate-stop` skill is Claude-only; non-Claude hosts render
  the packet directly) reached `refocus/general.md` (rule 9) but not `refocus/specify.md` — its boundary digest
  interposed "(picker disabled, packet rendered as prose)" so it no longer carried the host-scoped contract
  substring `refocus-digests.tests.ps1` pins. Pre-existing (not introduced by this iteration); surfaced when the
  refocus-digest lane was run during the merge reconciliation.
- **Reconciliation**: moved the parenthetical to the end so `specify.md` carries "On Claude, invoke
  `specrew-gate-stop`; on non-Claude hosts, render directly …" (both deployed copies). `refocus-digests` green.

## D-010 — F-182 forge-neutralization sweep flagged specrew-start.ps1 post-relocation (anticipated reconciliation)

- **Status**: resolved 2026-06-15.
- **Requirement**: F-182 FR-019/FR-022/SC-015 (no bare forge/registry mandate in downstream-governing surfaces).
- **Divergence**: F-182's widened sweep (`forge-neutralization-sweep.tests.ps1`) scans `.ps1` launch surfaces.
  After F-174 iter-006 relocated `Get-StartPrompt` + the closeout-SDLC block out of `specrew-start.ps1` into
  `scripts/internal/launch-contract.ps1`, `specrew-start.ps1` still carried Specrew's own PSGallery update-check
  (`Get-PSGalleryUpdateWarning`, `--skip-update-check` help) with no example marker, and the sweep's
  positive-assertion list still named `specrew-start.ps1` for the (now-moved) marker. F-182's own note
  anticipated this: "F-174 neutralizes post-rebase; F-182's widened sweep catches that site."
- **Reconciliation**: labeled Specrew's own update-check as Specrew-specific ("NOT a downstream mandate") in
  `specrew-start.ps1`, and added the relocated `scripts/internal/launch-contract.ps1` (which carries the genericized
  closeout-SDLC block + marker, ported during the merge) to the sweep's positive-assertion list. Sweep green.

## D-009 — F-182 merge breached the SessionStart cap (the D-007 CAP-1 prediction triggered)

- **Status**: resolved (interim) 2026-06-15; durable fix tracked in Proposal 191 (+ 179).
- **Requirement**: FR-002/FR-004 (the SessionStart payload must fit the host hook-output cap and the orientation
  must reach the model). Parent: iter-011 drift [D-007](../011/drift-log.md) (CAP-1 — the two fragment budgets do
  not compose).
- **Divergence**: the merge grew the co-resident **refocus** fragment (F-182 added an always-on "Work-kind
  lifecycle" section), pushing the measured worst-case SessionStart payload from ~9,103 to 9,323 — past the 9,300
  `DirectiveDeliveryCap` safety margin, AND (masked behind the margin assertion) the integrity-critical
  verdict-worst case to ~10,090, **over the 10,000 hard cap** — i.e. the exact D-007 prediction, triggered by
  ordinary digest growth. (An interim crew change first cut the reconciliation excerpt 300→100 to recover the
  margin; that spent the fix against the feature's resume behavior and was reverted on the maintainer's ruling —
  the cause was refocus growth, not resume size.)
- **Reconciliation**: (1) reverted the reconciliation excerpt to its dogfooded **300** floor (handover stays 380);
  (2) recovered the headroom from the refocus B2 tail per the maintainer's directive — trimmed
  `refocus/general.md`'s "Deep sources" to one pointer + dropped the Stage-scoped line (kept the nine always-true
  rules + the `{{project_root}}` pointer the digest test pins); (3) added a **resume-floor guard** to
  `DirectiveDeliveryCap.Tests.ps1` (fails if handover budget < 380 or reconciliation cap < 300) so the cap can
  never again be "solved" by starving resume. Result: primary 9,127 (< 9,300), verdict-worst 9,894 (< 10,000).
- **Durable fix**: Proposal 191 (pre-compute the in-flight digest to a file + pointer — lead pilot, ~700–850 char
  reclaim, supersedes this interim trim) + Proposal 179 (dispatcher fragment-priority drop backstop). D-007 stays
  open as the architectural parent until 191/179 land.
