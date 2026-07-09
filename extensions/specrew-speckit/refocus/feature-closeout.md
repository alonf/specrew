---
scope: boundary.feature-closeout
sources:
  - docs/methodology/lifecycle-discipline.md
  - extensions/specrew-speckit/squad-templates/coordinator/specrew-governance.md
reviewed_at: 2026-06-07
---
## Feature-closeout-stage discipline

1. **Closeout is an artifact, not a feeling.** `closeout.md` (delivered scope with evidence, tests/validation record, known non-blocking warnings WITH dispositions, branch hygiene, final status) + the auto-rendered `closeout-dashboard.md`. Verify the dashboard actually rendered.
2. **Branch hygiene is part of done.** Branch pushed and in sync with upstream; working tree clean or every dirty path explicitly dispositioned; no unrelated churn smuggled into closeout commits (path-limited staging).
3. **Name the release constraints explicitly.** What this closeout does NOT authorize: release, tag, merge, PR, push-to-main — each needs its own human authorization. "Branch-ready evidence only" is a complete, honest final status.
<!-- specrew-self-ok: tracked debt - FR-030 (F-198 iteration 004) scopes this to publish-target projects via the release-model resolver -->
4. **The SDLC steps have owners.** Steps 5-14 (push → PR → host review addressed → merge-commit → beta tag → publish → MANUAL runtime validation on the real host → stable promotion) are agent-driven WITH human approval — beta-before-stable is universal, and beta validation exercises the runtime deliverable, never file presence.
5. **Run the REAL CI/parity sets before the PR.** Latent regressions hide in test sets the iterations never ran; triage each red with fail-on-main (pass-on-main ⇒ branch-introduced ⇒ must fix).
6. **Carried items get names.** Follow-ups, deferred gaps, and proposal candidates are listed with their disposition — nothing rolls forward invisibly.

Known traps: feature "closed" with the worktree dirty; closeout claims contradicting verdict history; skipping the beta because the change "is just docs/tests" (the mandate has no exceptions for runtime-touching artifacts); merging without reading the host's automated PR review.

Deep sources:

- {{project_root}}/docs/methodology/lifecycle-discipline.md