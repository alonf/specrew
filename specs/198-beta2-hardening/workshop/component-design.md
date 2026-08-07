# Workshop Record: component-design (medium)

**Feature**: 198-beta2-hardening
**Date**: 2026-07-09
**Confirmation**: human-confirmed (map approved as rendered)

## Component map (agreed — 24 components)

Vocabulary per architecture-core A1: data seams / host-neutral governed
scripts. Dependencies point inward: everything depends on the data seams; the
data seams depend on nothing.

```text
 CI LANES & TEMPLATES        DEPLOY & HEAL SURFACE       REVIEWER RUNTIME
 ────────────────────        ─────────────────────       ────────────────
 SelfLeakLintLane            TemplateSurfaceInstaller    WorktreeMaterializer
 PromptFixtureTest           InitBootstrap               ReviewerBundleBuilder
 MethodologyGateTemplate     UpdateHealer                SlimPromptBuilder
 WorkKindTemplate                  │                     ContainmentDetector
       │                           │                     RecordedTestRunner
       │                           │                     CheckpointNavigator
       │                           │                     RoundCeilingGovernor
       │                           │                     BudgetResolver
       │                           │                     LiveDoorIdentity
       └───────────┬───────────────┴─────────────┬───────────────┘
                   ▼                             ▼
            GOVERNANCE CORE (host-neutral scripts)
            BoundarySyncRatchet ──► BoundaryAuthorizationCheck ◄── GovernanceValidator
            DigestIdentity ──► TrackerHonestyCheck
            ReleaseModelResolver
                   │
                   ▼
            DATA SEAMS (stable; depended on by everything)
            ReviewerHostCatalog · SelfLeakDenyList · MachineryPathList
            RepositoryGovernance · ToolchainPins
```

### Data seams

- ReviewerHostCatalog — per-host harness data; gains `default_timeout_seconds`
  column (W16). Stays the ONLY harness-data seam; no separate budget file.
- SelfLeakDenyList (new, versioned, shipped with module) — self-fact patterns
  plus the `specrew-self-ok` annotation escape; single truth for repo lint and
  consumer checks (205-W1/W5/W6).
- MachineryPathList (new, ONE list) — path-granular machinery globs (S2);
  single truth for digest strip and worktree strip (203-W5).
- RepositoryGovernance — repository-governance.yml; gains the recorded
  release model (204-W7; init asks once / infers).
- ToolchainPins — SPEC_KIT_VERSION 0.12.9 / SQUAD_VERSION 0.11.0 across CI
  env, version-check supported-versions, extension.yml requires,
  Get-SpecKitGitReference.

### Governance core

- BoundaryAuthorizationCheck — Test-SpecrewBoundaryAuthorization resurrected
  as THE shared delta primitive (#2906).
- BoundarySyncRatchet — sync call site; refuses second unapproved advance;
  teaches reconciliation (#2906).
- GovernanceValidator — validate call site; skipped-boundary FAIL finding
  (#2906).
- DigestIdentity — consumes MachineryPathList; routes tracker-only deltas
  through the honesty check (W13, W5).
- TrackerHonestyCheck (new) — deterministic claims-subset comparison vs
  accepted review.md + run records; fail-closed (W13).
- ReleaseModelResolver (new) — repository-governance.yml else inference (no
  remote → local-only; remote no forge → push-only; forge → PR flow; publish
  target → beta→stable); feeds closeout rendering AND init recording (204-W7).

### Reviewer runtime

- WorktreeMaterializer — materializes certified digest tree OUTSIDE origin
  root; consumes MachineryPathList (W1, W5).
- ReviewerBundleBuilder — strips origin-absolute paths from reviewer-visible
  context (W2).
- SlimPromptBuilder — carries W3 confinement contract + W6 stripped-paths
  teaching.
- ContainmentDetector (new, T100 registry) — cwd/commandline sampling; marks
  containment-violated, loud, never kills (W4/S1).
- RecordedTestRunner (new) — Invoke-ContinuousCoReviewRecordedTestRun runs
  the suite itself (Pester -PassThru first), records what IT observed;
  recorded command stays the reviewer re-run handle (W8).
- CheckpointNavigator — last-REVIEWED checkpoint identity as next baseline
  (merge-base fallback) (W9); fire-time tree id through the detached entry,
  stale-vs-current labeling (W10).
- RoundCeilingGovernor — fix-responsive rounds do not burn the ceiling; halt
  text per S3 (W11/W12).
- BudgetResolver — explicit → config → catalog → 600 floor; W14 warning off
  resolved value (W16/W14).
- LiveDoorIdentity — env cascade + independence_source provenance (W15/S4).

### Deploy & heal surface

- TemplateSurfaceInstaller — deploys ONLY the consumer-ized set;
  deny-by-default manifest (204-W3 + 205-W3).
- InitBootstrap — specrew-init.ps1: Spec-Kit --integration migration, W5b
  bootstrap commit (brownfield-aware offer), 204-W4 .gitignore entry,
  release-model ask-once.
- UpdateHealer — F-116 surface: hash-guarded retired-template removal (never
  user-modified files), refocus-scopes.json sync (#2903), deny-list
  detect-then-heal (205-W5).

### CI lanes & templates

- SelfLeakLintLane (new repo lane) — scans exactly the deploy allowlist
  against SelfLeakDenyList; unannotated hit = red (205-W1). Lands first
  (iteration 001).
- PromptFixtureTest (new Pester fixture) — renders every built prompt surface
  against an anything-but-Specrew fixture; zero deny hits (205-W4).
- MethodologyGateTemplate (new consumer template) — markdownlint (F-033
  ignore set) + deployed-path validator + conditional PSSA; generic NNN-*
  triggers; advisory-first (204-W1).
- WorkKindTemplate — deployed-path fix only; advisory default kept (204-W2).

## Key flow (agreed) — deny-list single-truth loop

```text
  author edits a template
    → repo CI: SelfLeakLintLane reads SelfLeakDenyList over the deploy
      allowlist → unannotated self-fact = RED → fix or annotate
    → ships clean → consumer runs specrew update
    → UpdateHealer + MethodologyGate advisory read the SAME shipped list
    → prevention and detection cannot disagree about what a leak is (205-W6)
```
