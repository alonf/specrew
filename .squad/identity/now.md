---
focus_area: "Feature 049 — all 5 iterations closed (last boundary iteration-closeout); feature-closeout PR #1152 open at v0.28.0, in human review before merge"
active_issues: "[]"
schema: v1
updated_at: 2026-05-29T00:50:00Z
session_state_active: true
session_state_boundary: iteration-closeout
session_state_feature: 049-pipeline-hardening-intake
session_state_feature_path: "C:\Dev\Specrew\specs\049-pipeline-hardening-intake"
session_state_iteration: 004
session_state_task: "(none)"
session_state_auth_commit: 515726b0
session_state_recorded_at: 2026-05-29T00:40:00Z
---

# What We're Focused On

Feature 049 (049-pipeline-hardening-intake): all five iterations are closed (last completed lifecycle boundary = **iteration-closeout**). The **feature-closeout** release SDLC is in progress — **PR [#1152](https://github.com/alonf/specrew/pull/1152)** is open (base `main` ← `049-pipeline-hardening-intake`) targeting **v0.28.0**, in human review before merge. (feature-closeout becomes the recorded boundary only when the PR merges + `sync-feature-closeout` runs.)

- Cleanup decisions applied: D1 = defer B-001 + A-001 to a separate framework-fix slice; D2 = formalize capacity 25 for the self-host repo only (shipped default stays 20); D3 = version bump to **0.28.0** across all manifests + README + CHANGELOG.
- Current status: cross-review DECLINED merge for narrow release-metadata truth fixes (README Status section, capacity-default consistency, this now.md staleness, psd1 prerelease beta.2→beta.1, decisions.md conflict-marker example). Addressing them now, then re-presenting the merge verdict.
- Next human gate: **merge verdict** (after re-presentation + optional cross-review). Then SDLC Step 9+ (tag v0.28.0-beta.1 → verify → manual-install PASS/FAIL → stable). F-049 PR merges before F-050 (Charter Item 5).
- Deferred follow-ups (framework-fix candidates): B-001 (duplicate Get-ObjectPropertyString) + A-001 (Get-QualityEvidenceContent StrictMode crash); validator grandfather-closed-iterations slice (58 capacity-drift FAILs). See iterations/004/drift-log.md + CHANGELOG "Known follow-ups".
- Closed history: Iterations 001–005 all closed.
- Guardrail: no new iteration/feature work; no merge before the human's verdict.
